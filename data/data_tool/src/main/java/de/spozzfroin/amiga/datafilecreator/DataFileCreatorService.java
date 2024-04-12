package de.spozzfroin.amiga.datafilecreator;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.zip.GZIPOutputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.ConfigReaderService;
import de.spozzfroin.amiga.datafilecreator.config.TargetFile;
import de.spozzfroin.amiga.datafilecreator.converters.SourceFileConverter;
import de.spozzfroin.amiga.datafilecreator.converters.SourceFileConverterFactory;

@Service
class DataFileCreatorService {

	private static final Logger LOG = LoggerFactory.getLogger(DataFileCreatorService.class);

	@FunctionalInterface
	interface MetadataOperation {
		void addMetadata(PrintWriter writer, TargetFile tf) throws IOException;
	}

	private final ConfigReaderService configReaderService;
	private final SourceFileConverterFactory sourceFileConverterFactory;

	DataFileCreatorService(ConfigReaderService theConfigReaderService,
			SourceFileConverterFactory theSourceFileConverterFactory) {
		this.configReaderService = theConfigReaderService;
		this.sourceFileConverterFactory = theSourceFileConverterFactory;
	}

	void run(String... args) throws Exception {
		var config = this.configReaderService.readConfig(args);
		this.convertAll(config);
	}

	private void convertAll(Config config) {
		config.getTargetFiles().stream().forEach(tf -> this.convert(config, tf));
		this.writeIndexFile(config);
		this.writeDescriptorFile(config);
	}

	private void convert(Config config, TargetFile targetFile) {
		LOG.info("Creating target file " + targetFile.getFilename());
		this.processAllSourceFiles(config, targetFile);
		Path gzippedDataFile = this.gzipDataFile(config, targetFile);
		this.copyToDestinationFolders(config, targetFile, gzippedDataFile);
	}

	private void processAllSourceFiles(Config config, TargetFile targetFile) {
		try (FileOutputStream data = new FileOutputStream(targetFile.getDataFile(config, false).toFile())) {
			targetFile.getSourceFiles().stream().forEach(sourceFile -> {
				LOG.info("Converting source file " + sourceFile.getFilename());
				try {
					SourceFileConverter converter = this.sourceFileConverterFactory.getFor(sourceFile, targetFile);
					converter.convertToRawData(config, data);
					converter.addToIndex(targetFile.getIndex(), targetFile.getConstants());
				} catch (IOException e) {
					throw new RuntimeException(e);
				}
			});
			data.flush();
		} catch (RuntimeException e) {
			throw e;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	private Path gzipDataFile(Config config, TargetFile targetFile) {
		LOG.info("Zipping target file " + targetFile.getFilename());
		Path gzippedDataFile = targetFile.getDataFile(config, true);
		try (GZIPOutputStream gos = new GZIPOutputStream(new FileOutputStream(gzippedDataFile.toFile()));
				FileInputStream fis = new FileInputStream(targetFile.getDataFile(config, false).toFile())) {
			byte[] buffer = new byte[1024];
			int length;
			while ((length = fis.read(buffer)) > 0) {
				gos.write(buffer, 0, length);
			}
			gos.flush();
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		// remove first 10 bytes (GZip-Header), not needed
		long size;
		byte[] contents;
		try {
			size = Files.size(gzippedDataFile);
			size -= 10;
			contents = new byte[(int) size];
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		try (FileInputStream fis = new FileInputStream(gzippedDataFile.toFile())) {
			fis.skip(10);
			fis.read(contents);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		try (FileOutputStream fos = new FileOutputStream(gzippedDataFile.toFile())) {
			fos.write(contents);
			fos.flush();
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		//
		try {
			size = Files.size(gzippedDataFile);
			targetFile.setSizeGzippedDataFile(size);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		return gzippedDataFile;
	}

	private void copyToDestinationFolders(Config config, TargetFile targetFile, Path gzippedDataFile) {
		targetFile.getTargetDataFiles(config).stream().forEach(file -> {
			try {
				Files.copy(gzippedDataFile, file, StandardCopyOption.REPLACE_EXISTING);
			} catch (IOException e) {
				throw new RuntimeException(e);
			}
		});
	}

	private void writeIndexFile(Config config) {
		LOG.info("Writing index file");
		Path indexFile = Paths.get(config.getIndexFilename());
		this.writeMetadataFile(config, indexFile, (writer, tf) -> tf.writeToIndexFile(writer));
	}

	private void writeDescriptorFile(Config config) {
		LOG.info("Writing descriptor file");
		Path indexFile = Paths.get(config.getDescriptorFilename());
		this.writeMetadataFile(config, indexFile, (writer, tf) -> tf.writeToDescriptorFile(writer));
	}

	private void writeMetadataFile(Config config, Path metadataFile, MetadataOperation operation) {
		try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(metadataFile, Charset.forName("UTF-8")))) {
			writer.println("; generated " + LocalDateTime.now().toString());
			config.getTargetFiles().stream().forEach(tf -> {
				try {
					operation.addMetadata(writer, tf);
				} catch (IOException e) {
					throw new RuntimeException(e);
				}
			});
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}
}

package de.spozzfroin.amiga.datafilecreator.config;

import java.io.File;
import java.io.FileInputStream;
import java.util.Arrays;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.yaml.snakeyaml.LoaderOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;
import org.yaml.snakeyaml.introspector.BeanAccess;

@Service
public class ConfigReaderService {

	private static final Logger LOG = LoggerFactory.getLogger(ConfigReaderService.class);

	private static final String CONFIG_FILE_ARG = "config.file";

	public Config readConfig(String... args) throws Exception {
		LOG.info("Reading config");
		//
		var configfile = this.getArgValue(CONFIG_FILE_ARG, args);
		//
		var yaml = new Yaml(new Constructor(Config.class, new LoaderOptions()));
		yaml.setBeanAccess(BeanAccess.FIELD);
		var inputStream = new FileInputStream(configfile);
		Config config = yaml.load(inputStream);
		//
		var configFile = new File(configfile);
		var fullFilename = configFile.getCanonicalPath().replace('\\', '/');
		var baseFolder = fullFilename.substring(0, fullFilename.lastIndexOf('/') + 1);
		config.setBaseFolder(baseFolder);
		//
		return config;
	}

	private String getArgValue(String argID, String... args) {
		var argsList = Arrays.asList(args);
		var arg = argsList.stream().filter(a -> a.startsWith(argID + "=")).findFirst();
		if (arg.isEmpty()) {
			return null;
		}
		var argValue = arg.get();
		argValue = argValue.substring(argValue.indexOf("=") + 1);
		return argValue;
	}
}
package de.spozzfroin.amiga.datafilecreator.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.yaml.snakeyaml.LoaderOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;
import org.yaml.snakeyaml.introspector.BeanAccess;

import java.io.File;
import java.io.FileInputStream;

@Service
public class ConfigReaderService {

    private static final Logger LOG = LoggerFactory.getLogger(ConfigReaderService.class);

    public Config readConfig(String... args) throws Exception {
        LOG.info("Reading config");
        //
        var yaml = new Yaml(new Constructor(Config.class, new LoaderOptions()));
        yaml.setBeanAccess(BeanAccess.FIELD);
        var inputStream = new FileInputStream(args[0]);
        Config config = yaml.load(inputStream);
        //
        var configFile = new File(args[0]);
        var fullFilename = configFile.getCanonicalPath().replace('\\', '/');
        var baseFolder = fullFilename.substring(0, fullFilename.lastIndexOf('/') + 1);
        config.setBaseFolder(baseFolder);
        //
        return config;
    }
}
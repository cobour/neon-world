package de.spozzfroin.amiga.datafilecreator;

import org.springframework.beans.BeansException;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;

/**
 * Example call: ./mvnw spring-boot:run
 * -Dspring-boot.run.arguments="config.file=./data_files_config.yml"
 */
@SpringBootApplication
public class DataFileCreatorApplication implements ApplicationContextAware, CommandLineRunner {

	private ApplicationContext context;

	public static void main(String[] args) {
		SpringApplication.run(DataFileCreatorApplication.class, args);
	}

	@Override
	public void setApplicationContext(ApplicationContext theContext) throws BeansException {
		this.context = theContext;
	}

	@Override
	public void run(String... args) throws Exception {
		var configReader = this.context.getBean(DataFileCreatorService.class);
		configReader.run(args);
	}
}

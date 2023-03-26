class SourceFileConverterFactory {

    static SourceFileConverter getFor(SourceFile sourceFile, TargetFile targetFile) {
        if ("mod".equals(sourceFile.getType())) {
            return new PtModSourceFileConverter(sourceFile, targetFile);
        } else if ("iff".equals(sourceFile.getType())) {
            return new IffSourceFileConverter(sourceFile);
        } else if ("tmx".equals(sourceFile.getType())) {
            return new TiledSourceFileConverter(sourceFile);
        } else if ("wav".equals(sourceFile.getType())) {
            return new WavSourceFileConverter(sourceFile);
        }
        throw new IllegalArgumentException("Could not create Converter for type: " + sourceFile.getType());
    }
}

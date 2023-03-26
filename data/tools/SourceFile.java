import java.util.HashMap;
import java.util.Map;

class SourceFile {

    static SourceFileBuilder builder() {
        return new SourceFileBuilder();
    }

    static class SourceFileBuilder {
        private String filename;
        private Map<ParamType, String> params;

        private SourceFileBuilder() {
            this.params = new HashMap<>();
        }

        SourceFileBuilder file(String theFilename) {
            this.filename = theFilename;
            return this;
        }

        SourceFileBuilder param(ParamType type, String value) {
            this.params.put(type, value);
            return this;
        }

        SourceFile get() {
            return new SourceFile(filename, params);
        }
    }

    final String filename;
    final Map<ParamType, String> params;

    private SourceFile(String theFilename, Map<ParamType, String> theParams) {
        this.filename = theFilename;
        this.params = theParams;
    }

    String getType() {
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }

    boolean getParamAsBoolean(ParamType param) {
        if (this.params.containsKey(param)) {
            return this.params.get(param).equalsIgnoreCase("true");
        }
        return false;
    }
}

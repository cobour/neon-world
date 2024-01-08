package de.spozzfroin.amiga.datafilecreator.converters;

import com.github.miachm.sods.SpreadSheet;
import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.SourceFile;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.AbstractMap;
import java.util.List;

class OdsSourceFileConverter implements SourceFileConverter {

    private final SourceFile sourceFile;

    private byte[] raw;

    OdsSourceFileConverter(SourceFile theSourceFile) {
        this.sourceFile = theSourceFile;
    }

    @Override
    public void convertToRawData(Config config, OutputStream data) throws IOException {
        var spread = new SpreadSheet(new File(this.sourceFile.getFullFilename(config)));
        var source = spread.getSheet(0).getDataRange();
        var rowCount = source.getNumRows() - 1; // first is base row for diffs
        this.raw = new byte[rowCount * 4];
        //
        var lastX = ((Double) source.getCell(0, 0).getValue()).intValue();
        var lastY = ((Double) source.getCell(0, 1).getValue()).intValue();
        //
        int adjustX = 0;
        try {
            var cellAdjustX = source.getCell(0, 2);
            if (cellAdjustX != null) {
                adjustX = ((Double) cellAdjustX.getValue()).intValue();
            }
        } catch (IndexOutOfBoundsException e) {
            // empty
        }
        for (int actRow = 1, actByte = 0; actRow < source.getNumRows(); actRow++) {
            var newX = ((Double) source.getCell(actRow, 0).getValue()).intValue();
            var newY = ((Double) source.getCell(actRow, 1).getValue()).intValue();
            var diffX = newX - lastX + adjustX;
            var diffY = newY - lastY;
            diffY *= -1; // convert from bottom-up to top-down
            //
            var byteBufferX = ByteBuffer.allocate(4);
            byteBufferX.order(ByteOrder.BIG_ENDIAN);
            byteBufferX.putInt(diffX);
            var bytes = byteBufferX.array();
            this.raw[actByte++] = bytes[2];
            this.raw[actByte++] = bytes[3];
            //
            var byteBufferY = ByteBuffer.allocate(4);
            byteBufferY.order(ByteOrder.BIG_ENDIAN);
            byteBufferY.putInt(diffY);
            bytes = byteBufferY.array();
            this.raw[actByte++] = bytes[2];
            this.raw[actByte++] = bytes[3];
            //
            lastX = newX;
            lastY = newY;
        }
        //
        data.write(this.raw);
    }

    @Override
    public void addToIndex(List<AbstractMap.SimpleEntry<String, Long>> index, List<AbstractMap.SimpleEntry<String, String>> constants) throws IOException {
        var label = generateLabel(this.sourceFile.getFilename());
        index.add(new AbstractMap.SimpleEntry<>(label, (long) this.raw.length));
        //
        label = generateLabel(this.sourceFile.getFilename(), "steps");
        constants.add(new AbstractMap.SimpleEntry<>(label, Integer.toString(this.raw.length / 4)));
    }
}

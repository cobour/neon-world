package de.spozzfroin.amiga.datafilecreator.converters;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.StringReader;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.SourceFile;

class TiledSourceFileConverter implements SourceFileConverter {

	private static class LevelObject {
		int enemy_desc = -1;
		int movement_desc = -1;
		int spawn_frame = -1;
		int xpos = -1;
		int ypos = -1;
		int count = -1;
		int count_spawn_delay = -1;
		boolean add_xpos = false;
		int movement_start_offset = 0;

		void calcSpawnFrameIfNotSet() {
			if (spawn_frame == -1) {
				spawn_frame = xpos - 322;
				xpos -= spawn_frame; // convert level-xpos to screen-xpos
			}
		}

		boolean isValid() {
			return enemy_desc != -1 && movement_desc != -1 && spawn_frame != -1 && xpos != -1 && ypos != -1
					&& ((count == -1 && count_spawn_delay == -1) || (count > 0 && count_spawn_delay > 0));
		}

		LevelObject duplicate() {
			var o = new LevelObject();
			o.enemy_desc = this.enemy_desc;
			o.movement_desc = this.movement_desc;
			o.spawn_frame = this.spawn_frame;
			o.xpos = this.xpos;
			o.ypos = this.ypos;
			return o;
		}
	}

	private final SourceFile sourceFile;

	private int size;
	private int objectsSize = 0; // optional
	private int respawnInfoSize = 0; // optional
	private String width; // number of tiles
	private String height; // number of tiles

	private final List<LevelObject> levelObjects = new ArrayList<>();

	// details about tiles gfx
	private int tilesPixelWidth = -1;
	private int tilesBitplanes = -1;
	private int tilesTilesPerRow = -1;
	private int tilesBytesPerRow = -1;

	TiledSourceFileConverter(SourceFile theSourceFile) {
		this.sourceFile = theSourceFile;
	}

	@Override
	public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
			throws IOException {
		String label = generateLabel(sourceFile.getFilename());
		index.add(new SimpleEntry<>(label, Long.valueOf(size)));
		if (!levelObjects.isEmpty()) {
			label = generateLabel(sourceFile.getFilename(), "objects");
			index.add(new SimpleEntry<>(label, Long.valueOf(objectsSize)));
		}
		if (respawnInfoSize > 0) {
			label = generateLabel(sourceFile.getFilename(), "respawn_info");
			index.add(new SimpleEntry<>(label, Long.valueOf(respawnInfoSize)));
		}
		//
		label = generateLabel(sourceFile.getFilename(), "tiles_width");
		constants.add(new SimpleEntry<>(label, width));
		label = generateLabel(sourceFile.getFilename(), "tiles_height");
		constants.add(new SimpleEntry<>(label, height));
		label = generateLabel(sourceFile.getFilename(), "size");
		constants.add(new SimpleEntry<>(label, Integer.toString(size)));
		if (!levelObjects.isEmpty()) {
			label = generateLabel(sourceFile.getFilename(), "objects_size");
			constants.add(new SimpleEntry<>(label, Integer.toString(objectsSize)));
			label = generateLabel(sourceFile.getFilename(), "objects_count");
			constants.add(new SimpleEntry<>(label, Integer.toString(levelObjects.size())));
		}
		if (respawnInfoSize > 0) {
			label = generateLabel(sourceFile.getFilename(), "respawn_info_size");
			constants.add(new SimpleEntry<>(label, Integer.toString(respawnInfoSize)));
		}
	}

	@Override
	public void convertToRawData(Config config, OutputStream data) throws IOException {
		try {
			readTiles(config);
			Document document = getDocument(config);
			//
			Node dataNode = getDataNode(document);
			List<List<Integer>> allOffsets = readAndConvert(dataNode);
			write(allOffsets, data);
			//
			readObjectList(document);
			if (!levelObjects.isEmpty()) {
				writeObjects(data);
			}
			//
			if (this.sourceFile.isCreateRespawnInfo()) {
				Node respawnNode = getRespawnDataNode(document);
				List<List<Integer>> allRespawnOffsets = readAndConvert(respawnNode);
				writeRespawnInfo(allRespawnOffsets, data);
			}
		} catch (IOException e) {
			throw e;
		} catch (Exception e) {
			throw new IOException(e);
		}
	}

	private void readTiles(Config config) throws IOException {
		var tilesSourceFile = new SourceFile(this.sourceFile.getTilesFilename());
		var tilesConverter = new IffSourceFileConverter(tilesSourceFile);
		tilesConverter.convertToRawData(config, OutputStream.nullOutputStream());
		this.tilesPixelWidth = tilesConverter.getWidth();
		this.tilesBitplanes = tilesConverter.getBitplanes();
	}

	private Document getDocument(Config config) throws Exception {
		DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document document = builder.parse(new File(sourceFile.getFullFilename(config)));
		document.getDocumentElement().normalize();
		//
		Node mapNode = document.getElementsByTagName("map").item(0);
		//
		String orientation = mapNode.getAttributes().getNamedItem("orientation").getTextContent();
		if (!"orthogonal".equalsIgnoreCase(orientation)) {
			throw new IllegalArgumentException("invalid orientation");
		}
		//
		this.width = mapNode.getAttributes().getNamedItem("width").getTextContent().trim();
		this.height = mapNode.getAttributes().getNamedItem("height").getTextContent().trim();
		//
		String renderorder = mapNode.getAttributes().getNamedItem("renderorder").getTextContent();
		if (!"right-down".equalsIgnoreCase(renderorder)) {
			throw new IllegalArgumentException("invalid renderorder");
		}
		//
		// calc details about tiles gfx
		var tilewidth = Integer.parseInt(mapNode.getAttributes().getNamedItem("tilewidth").getTextContent().trim());
		var tileheight = Integer.parseInt(mapNode.getAttributes().getNamedItem("tileheight").getTextContent().trim());
		this.tilesTilesPerRow = this.tilesPixelWidth / tilewidth;
		this.tilesBytesPerRow = (this.tilesPixelWidth / 8) * tileheight * this.tilesBitplanes;
		//
		return document;
	}

	private Node getDataNode(Document document) throws XPathExpressionException {
		var xPathFactory = XPathFactory.newInstance();
		var layerExpression = xPathFactory.newXPath().compile("/map/layer");
		var layers = (NodeList) layerExpression.evaluate(document, XPathConstants.NODESET);
		var dataNodeExpression = xPathFactory.newXPath().compile("//data");
		Node dataNode = null;
		if (layers.getLength() > 1) {
			var playfieldLayerExpression = xPathFactory.newXPath().compile("//layer[@name='playfield layer']");
			var playfieldLayer = (NodeList) playfieldLayerExpression.evaluate(document, XPathConstants.NODESET);
			if (playfieldLayer.getLength() != 1) {
				throw new IllegalStateException("playfield layer not found");
			}
			dataNode = (Node) dataNodeExpression.evaluate(playfieldLayer.item(0), XPathConstants.NODE);
		} else {
			dataNode = (Node) dataNodeExpression.evaluate(layers.item(0), XPathConstants.NODE);
		}
		var encoding = dataNode.getAttributes().getNamedItem("encoding").getTextContent();
		if (!"csv".equalsIgnoreCase(encoding)) {
			throw new IllegalArgumentException("invalid encoding");
		}
		return dataNode;
	}

	private Node getRespawnDataNode(Document document) {
		var dataNodes = document.getElementsByTagName("data");
		Node dataNode = null;
		for (int i = 0; i < dataNodes.getLength(); i++) {
			var aNode = dataNodes.item(i);
			var layerName = aNode.getParentNode().getAttributes().getNamedItem("name").getTextContent();
			if (layerName.equals("respawn layer")) {
				dataNode = aNode;
				break;
			}
		}
		if (dataNode == null) {
			throw new IllegalArgumentException("respawn layer not found");
		}
		var encoding = dataNode.getAttributes().getNamedItem("encoding").getTextContent();
		if (!"csv".equalsIgnoreCase(encoding)) {
			throw new IllegalArgumentException("invalid encoding");
		}
		return dataNode;
	}

	private List<List<Integer>> readAndConvert(Node dataNode) throws IOException {
		List<List<Integer>> allOffsets = new ArrayList<>();
		String content = dataNode.getTextContent().trim();
		BufferedReader reader = new BufferedReader(new StringReader(content));
		String line = null;
		while ((line = reader.readLine()) != null) {
			List<String> lineTiles = Arrays.asList(line.trim().split(","));
			List<Integer> lineOffsets = new ArrayList<>();
			lineTiles.stream().forEach(tileString -> {
				int tile = Integer.parseInt(tileString) - 1; // values in file start at 1, we need start at zero
				int rowIndex = tile / this.tilesTilesPerRow; // giving zero-based row number
				int columnIndex = ((tile) % this.tilesTilesPerRow); // zero-based column of tile in row
				int offset = rowIndex * this.tilesBytesPerRow; // offset for row in tile-bitmap
				offset += (columnIndex * 2); // add x-offset for tile (16 pixels aka 2 bytes per tile)
				lineOffsets.add(Integer.valueOf(offset));
			});
			allOffsets.add(lineOffsets);
		}
		//
		if (this.sourceFile.isColumnOrientation()) {
			List<List<Integer>> columnAllOffsets = new ArrayList<>();
			AtomicInteger columnIndex = new AtomicInteger(0);
			allOffsets.get(0).stream().forEach(i -> { // iterate over first list representing first row -> one i for
				// every column
				int index = columnIndex.getAndIncrement();
				List<Integer> column = allOffsets.stream().map(row -> row.get(index)).collect(Collectors.toList());
				columnAllOffsets.add(column);
			});
			return columnAllOffsets;
		}
		return allOffsets;
	}

	private void readObjectList(Document document) {
		var objects = document.getElementsByTagName("object");
		levelObjects.clear();
		for (int i = 0; i < objects.getLength(); i++) {
			var object = (Element) objects.item(i);
			var levelObject = new LevelObject();
			levelObject.xpos = Integer.parseInt(object.getAttribute("x"));
			levelObject.ypos = Integer.parseInt(object.getAttribute("y"));
			// Tiled uses the lower left corner of a tile as "hotspot" for x- and
			// y-position.
			// In the game we use the upper left corner, so we have to adjust the y-position
			// here.
			levelObject.ypos -= Integer.parseInt(object.getAttribute("height"));
			var properties = object.getElementsByTagName("property");
			for (int p = 0; p < properties.getLength(); p++) {
				var property = (Element) properties.item(p);
				var propertyName = property.getAttribute("name");
				switch (propertyName) {
				case "enemy_desc":
					levelObject.enemy_desc = Integer.parseInt(property.getAttribute("value"));
					break;
				case "movement_desc":
					levelObject.movement_desc = Integer.parseInt(property.getAttribute("value"));
					break;
				case "spawn_frame":
					levelObject.spawn_frame = Integer.parseInt(property.getAttribute("value"));
					levelObject.xpos -= levelObject.spawn_frame; // convert level-xpos to screen-xpos
					break;
				case "count":
					levelObject.count = Integer.parseInt(property.getAttribute("value"));
					break;
				case "count_spawn_delay":
					levelObject.count_spawn_delay = Integer.parseInt(property.getAttribute("value"));
					break;
				case "add_xpos":
					levelObject.add_xpos = Boolean.parseBoolean(property.getAttribute("value"));
					break;
				case "movement_start_offset":
					levelObject.movement_start_offset = Integer.parseInt(property.getAttribute("value"));
					break;
				default:
					throw new IllegalArgumentException("unknown property: " + propertyName);
				}
			}
			//
			levelObject.calcSpawnFrameIfNotSet();
			if (!levelObject.isValid()) {
				throw new IllegalStateException("not all attributes set in level object!");
			}
			levelObjects.add(levelObject);
		}
	}

	private void write(List<List<Integer>> allOffsets, OutputStream data) throws IOException {
		byte[] allBytes = createByteArray(allOffsets);
		data.write(allBytes);
	}

	private void writeRespawnInfo(List<List<Integer>> allOffsets, OutputStream data) throws IOException {
		respawnInfoSize = allOffsets.size() * 2; // one word value for each column/row
		for (var v : allOffsets) {
			int index = -1;
			do {
				index++;
			} while (v.get(index) == -2);
			writeWord((index * 16) + 44, data); // magic value 44 = ScreenStartY (because the player is a hardware
												// sprite and no bob)
		}
	}

	private byte[] createByteArray(List<List<Integer>> allOffsets) {
		List<Integer> flatListAllOffsets = allOffsets.stream().flatMap(List::stream).collect(Collectors.toList());
		size = flatListAllOffsets.size() * 2;
		byte[] byteArray = new byte[size];
		AtomicInteger index = new AtomicInteger(0);
		flatListAllOffsets.stream().forEach(offset -> {
			if (offset.intValue() > 65535) {
				throw new RuntimeException("does not fit in word");
			}
			byte[] offsetByteArray = ByteBuffer.allocate(4).putInt(offset.intValue()).array();
			byteArray[index.getAndIncrement()] = offsetByteArray[2]; // just use low-word
			byteArray[index.getAndIncrement()] = offsetByteArray[3];
		});
		return byteArray;
	}

	private void writeObjects(OutputStream data) throws IOException {
		// add multiplied objects (count, count_spawn_delay)
		var objectsToAdd = new ArrayList<LevelObject>();
		levelObjects.stream().filter(o -> o.count > 0).forEach(o -> {
			var mso = o.movement_start_offset;
			// start-offset in movement-table
			if (o.movement_start_offset > 0) {
				o.movement_start_offset = o.count * mso;
			}
			int mov_so = o.movement_start_offset;
			// create dependendant objects
			for (int i = 1; i < o.count; i++) {
				var other = o.duplicate();
				if (o.add_xpos) {
					other.xpos -= i * o.count_spawn_delay;
				}
				other.spawn_frame = o.spawn_frame + (i * o.count_spawn_delay);
				if (o.movement_start_offset > 0) {
					mov_so -= mso;
					other.movement_start_offset = mov_so;
				}
				objectsToAdd.add(other);
			}
		});
		levelObjects.addAll(objectsToAdd);
		// sort by spawn_frame
		levelObjects.sort(new Comparator<LevelObject>() {
			@Override
			public int compare(LevelObject lo1, LevelObject lo2) {
				var sf1 = Integer.valueOf(lo1.spawn_frame);
				var sf2 = Integer.valueOf(lo2.spawn_frame);
				return sf1.compareTo(sf2);
			}
		});
		// write bytes to data
		for (LevelObject lo : levelObjects) {
			writeLong(lo.spawn_frame, data);
			writeWord(lo.xpos, data);
			writeWord(lo.ypos, data);
			writeWord(lo.enemy_desc, data);
			writeWord(lo.movement_desc, data);
			writeWord(lo.movement_start_offset, data);
			objectsSize += 14; // see obj_size in constants.i (MUST be the same value)
		}
	}

	private void writeWord(int value, OutputStream data) throws IOException {
		var byteBufferX = ByteBuffer.allocate(4);
		byteBufferX.order(ByteOrder.BIG_ENDIAN);
		byteBufferX.putInt(value);
		var bytes = byteBufferX.array();
		data.write(bytes[2]);
		data.write(bytes[3]);
	}

	private void writeLong(int value, OutputStream data) throws IOException {
		var byteBufferX = ByteBuffer.allocate(4);
		byteBufferX.order(ByteOrder.BIG_ENDIAN);
		byteBufferX.putInt(value);
		var bytes = byteBufferX.array();
		data.write(bytes);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./LibString.sol";
import "./SafeCastLib.sol";
import "./OwnableRoles.sol";

contract NFTPaint is ERC721, OwnableRoles {
    struct Painting {
        bytes pixels;
        uint16 paletteId;
        bytes3 background;
    }

    struct SVGParams {
        uint16 svgSize;
        uint16 effectiveGridSize;
        uint16 cellSize;
        uint16 xOffset;
        uint16 yOffset;
        bytes svgStart;
        bytes backgroundRect;
    }

    string private _name;
    string private _symbol;
    string private _baseURI;
    uint256 private _totalSupply;
    mapping(uint256 => Painting) public paintings;
    mapping(uint16 => bytes3[]) public palettes;
    mapping(uint16 => bool) public pixelGridSizes;
    mapping(bytes32 => bool) paintingHashes;
    mapping(bytes3 => bool) backgroundColors;

    /// @dev Emits artist of newly minted painting
    event PaintingMinted(address indexed creator, uint256 indexed id);

    constructor() {
        _name = "NFT Paint";
        _symbol = "PNT";
        super._initializeOwner(msg.sender);
    }

    /// @notice returns information for requested paintings
    /// @param paintingIds an array of the NFT ids you would like to retreive information for
    /// @return paintingsArray array of Painting structs, contains artist, title, pixels, palette, and background
    function getPaintings(
        uint256[] memory paintingIds
    ) external view returns (Painting[] memory) {
        Painting[] memory paintingsArray = new Painting[](paintingIds.length);

        for (uint256 i = 0; i < paintingIds.length; i++) {
            paintingsArray[i] = paintings[paintingIds[i]];
        }

        return paintingsArray;
    }

    /// @notice Mints a new painting
    /// @param pixels a 1D array representing the pixel grid. Colors given as index positions in respective palette array
    /// @param paletteId id of the palette used for the painting
    /// @param background optional background color
    function mintPainting(
        bytes memory pixels,
        uint16 paletteId,
        bytes3 background
    ) public {
        require(
            pixelGridSizes[SafeCastLib.toUint16(pixels.length)],
            "Unsupported pixel grid size."
        );
        bytes32 pixelHash = keccak256(abi.encodePacked(pixels, paletteId));
        require(
            !paintingHashes[pixelHash],
            "Painting with these pixels and palette already exists."
        );
        if (background != bytes3(0)) {
            require(
                backgroundColors[background],
                "Unacceptable background color."
            );
        }

        uint256 paintingId = _totalSupply + 1;

        paintings[paintingId] = Painting({
            pixels: pixels,
            paletteId: paletteId,
            background: background
        });

        paintingHashes[pixelHash] = true;
        _mint(msg.sender, paintingId);
    }

    /// @notice Contract owners and maintainers can add a new supported background color
    /// @param newColor bytes3 representation of color hex string
    function addBackgroundColor(
        bytes3 newColor
    ) external onlyOwnerOrRoles(_ROLE_0) {
        require(
            !backgroundColors[newColor],
            "Background color already exists."
        );

        backgroundColors[newColor] = true;
    }

    /// Contract owners and maintainers can add a new grid sizes
    /// @param pixelCount the total amount of pixels for the new grid size, must be perfect square
    function addGridSize(uint16 pixelCount) external onlyOwnerOrRoles(_ROLE_0) {
        uint16 sqrtValue = sqrt(pixelCount);
        require(
            sqrtValue * sqrtValue == pixelCount,
            "Pixel count must be a perfect square."
        );
        pixelGridSizes[pixelCount] = true;
    }

    /// @notice Contract owners and maintainers can add a new supported color palette
    /// @param _id an id for the pallete
    /// @param _colors an array of the colors for the palette
    /// @dev the colors are color hex codes converted to byte3
    function addPalette(
        uint8 _id,
        bytes3[] memory _colors
    ) external onlyOwnerOrRoles(_ROLE_0) {
        require(
            palettes[_id].length == 0,
            "Palette with this ID already exists."
        );
        require(_colors.length <= 128, "Max Palette size 128 colors");
        palettes[_id] = _colors;
    }

    /// @notice Renders specified painting in SVG format
    /// @param paintingId id of painting to render
    function getPaintingSVG(
        uint256 paintingId
    ) external view returns (string memory) {
        Painting memory painting = paintings[paintingId];
        bytes3[] memory palette = palettes[painting.paletteId];
        uint16 gridSize = sqrt(uint16(painting.pixels.length));
        SVGParams memory params = _getSVGParams(painting, gridSize);
        bytes[] memory rectsArray = _getRectsArray(
            painting,
            palette,
            params,
            gridSize
        );
        bytes memory rects = _combineRects(rectsArray);

        return
            string(
                abi.encodePacked(
                    params.svgStart,
                    params.backgroundRect,
                    rects,
                    "</svg>"
                )
            );
    }

    // ---- custom helpers ----
    function sqrt(uint16 x) internal pure returns (uint16 y) {
        uint16 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function bytes3ToHex(bytes3 value) internal pure returns (string memory) {
        bytes memory lookup = "0123456789abcdef";
        bytes memory result = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            result[i * 2] = lookup[uint8(value[i] >> 4)];
            result[i * 2 + 1] = lookup[uint8(value[i] & 0x0f)];
        }
        return string(result);
    }

    function _getSVGParams(
        Painting memory painting,
        uint16 gridSize
    ) private pure returns (SVGParams memory params) {
        uint16 padding = 1;
        uint16 cellSize = 10;
        params.svgSize = gridSize * cellSize;

        if (painting.background != bytes3(0)) {
            uint16 bgOffset = 115;
            uint16 backgroundSize = (params.svgSize * bgOffset) / 100;

            params.effectiveGridSize = params.svgSize;
            params.cellSize = cellSize;
            params.xOffset = (backgroundSize - params.svgSize) / 2;
            params.yOffset =
                2 *
                padding +
                (backgroundSize - params.svgSize - 2 * padding);
        } else {
            params.effectiveGridSize = params.svgSize;
            params.cellSize = cellSize;
            params.xOffset = 0;
            params.yOffset = 0;
        }

        string memory _svgDimension = LibString.toString(
            painting.background != bytes3(0)
                ? (params.svgSize * 115) / 100
                : params.svgSize
        );
        params.svgStart = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="',
            _svgDimension,
            '" height="',
            _svgDimension,
            '" shape-rendering="crispEdges">'
        );

        if (painting.background != bytes3(0)) {
            params.backgroundRect = abi.encodePacked(
                '<rect x="',
                "0",
                '" y="',
                "0",
                '" width="',
                _svgDimension,
                '" height="',
                _svgDimension,
                '" fill="#',
                bytes3ToHex(painting.background),
                '"/>'
            );
        } else {
            params.backgroundRect = bytes("");
        }

        return params;
    }

    function _getRectsArray(
        Painting memory painting,
        bytes3[] memory palette,
        SVGParams memory params,
        uint16 gridSize
    ) private pure returns (bytes[] memory rectsArray) {
        rectsArray = new bytes[](painting.pixels.length);
        string memory _cellSize = LibString.toString(params.cellSize);

        string[] memory xValues = new string[](gridSize);
        string[] memory yValues = new string[](gridSize);
        for (uint16 i = 0; i < gridSize; i++) {
            xValues[i] = LibString.toString(
                params.xOffset + i * params.cellSize
            );
            yValues[i] = LibString.toString(
                params.yOffset + i * params.cellSize
            );
        }

        bytes[] memory colorValues = new bytes[](palette.length);
        bytes memory _none = bytes("none");
        for (uint16 i = 0; i < palette.length; i++) {
            colorValues[i] = abi.encodePacked("#", bytes3ToHex(palette[i]));
        }
        uint16 xCounter = 0;
        uint16 yCounter = 0;
        bytes memory fillColor;
        uint8 pixelIndex;
        for (uint256 i = 0; i < painting.pixels.length; i++) {
            pixelIndex = uint8(painting.pixels[i]);
            fillColor = (pixelIndex == 129)
                ? _none
                : colorValues[pixelIndex];

            rectsArray[i] = abi.encodePacked(
                '<rect x="',
                xValues[xCounter],
                '" y="',
                yValues[yCounter],
                '" width="',
                _cellSize,
                '" height="',
                _cellSize,
                '" fill="',
                fillColor,
                '"/>'
            );

            xCounter++;
            if (xCounter == gridSize) {
                xCounter = 0;
                yCounter++;
            }
        }

        return rectsArray;
    }

    function _combineRects(
        bytes[] memory rectsArray
    ) private pure returns (bytes memory rects) {
        uint256 totalLength = 0;
        for (uint256 i = 0; i < rectsArray.length; i++) {
            totalLength += rectsArray[i].length;
        }

        rects = new bytes(totalLength);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < rectsArray.length; i++) {
            bytes memory currentRect = rectsArray[i];
            for (uint256 j = 0; j < currentRect.length; j++) {
                rects[currentIndex + j] = currentRect[j];
            }
            currentIndex += currentRect.length;
        }

        return rects;
    }

    // ---- 721 Logic ----
    function setBaseURI(
        string memory baseURI_
    ) public onlyOwnerOrRoles(_ROLE_0) {
        _baseURI = baseURI_;
    }

    function _mint(address to, uint256 id) internal override {
        _totalSupply += 1;
        emit PaintingMinted(msg.sender, id);
        super._mint(to, id);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}

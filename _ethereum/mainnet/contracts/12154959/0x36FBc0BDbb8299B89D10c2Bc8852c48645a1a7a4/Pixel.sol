// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./console.sol";
import "./Counters.sol";

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

struct PixelInfo {
    uint256 pixelId;
    uint32 color;
    bytes32 signature;
    uint256 coordinates;
    address owner;
}

contract Pixel is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // How many days will be available to make last second changes to the tokens (expressed in seconds)
    uint256 public thermalDeathDays;

    // Define canvas size
    uint16 public canvasWidth;
    uint16 public canvasHeight;

    // Max tokens
    uint32 public maxTokens;

    // Define pixel prices
    uint256 public pricePerPixelWei;

    // Art piece lifecycle
    bool public hasLastPixelBeenPlaced = false;
    uint256 public thermalDeathDeadline = 0;

    // Mapping for owned pixels (encodedCoord => pixelId)
    mapping (uint256 => uint256) private _ownedPixels;

    // Mapping for pixel coordinates (pixelId => encodedCoord)
    mapping (uint256 => uint256) private _coordinates;

    // Mapping for pixel colors (pixelId => color)
    mapping (uint256 => uint32) private _colors;

    // Mapping for pixel signatures (pixelId => signature)
    mapping (uint256 => bytes32) private _signatures;

    // Mapping for stored ethereum on contract
    mapping (address => uint256) private _withdrawals;

    // Invoked when the last pixels has been placed
    event LastPixelPlaced();

    event PixelUpdated(
        uint256 indexed pixelId,
        uint256 coordinates,
        uint32 color,
        bytes32 signature,
        address owner
    );
    event PixelPlaced(
        uint256 indexed pixelId,
        uint256 coordinates,
        uint32 color,
        bytes32 signature,
        address owner
    );

    constructor(
        uint16 width,
        uint16 height,
        uint256 price,
        uint256 daysBeforeThermalDeath
    ) ERC721("Thermal Death", "TDPX") Ownable() {
        canvasWidth = width;
        canvasHeight = height;
        pricePerPixelWei = price;
        thermalDeathDays = daysBeforeThermalDeath;

        maxTokens = width * height;
    }

    /**
     * @dev Checks if the art piece has been completed and frozen, reverts if so.
     */
    modifier notInThermalDeath() {
        require(!hasLastPixelBeenPlaced || block.timestamp <= thermalDeathDeadline, "ART_IS_COMPLETE");

        _;
    }

    /**
     * @dev Allows the message sender to buy a single pixel.
     */
    function buyPixel(uint16 x, uint16 y, uint32 color, bytes32 signature)
        public
        payable
        returns (uint256 _pixelId)
    {
        // Check if the signature is set
        require(signature != "", "SIGNATURE_IS_EMPTY");

        // Check if input coordinates are inside the canvas
        require(x >= 0 && y >= 0 && x < canvasWidth && y < canvasHeight, "COORDS_OUT_OF_BOUNDS");

        //Check if it's a valid 24 bit rgb color
        require((color >> 24 & 0xff) == 0x0, "INVALID_COLOR_FORMAT: RGB ONLY");

        // Check if the requested pixels hadn't already been taken
        uint256 encodedPixelCoords = _encodePixelCoords(x, y);
        require(_ownedPixels[encodedPixelCoords] == 0x0, "PIXEL_ALREADY_TAKEN");

        // Validate sent value
        require(msg.value >= pricePerPixelWei, "PRICE_NOT_MATCHING");

        // Store owner gain
        _withdrawals[owner()] += pricePerPixelWei;

        // Store exceeding ethers for future sender withdrawal
        _withdrawals[msg.sender] += msg.value - pricePerPixelWei;

        return _generatePixel(msg.sender, encodedPixelCoords, color, signature);
    }

    /**
     * @dev Allows the message sender to buy multiple pixels.
     */
    function buyPixelsBatch(uint256[] calldata pixels, bytes32[] calldata signatures)
        public
        payable
        returns (uint256[] memory _pixelIds)
    {
        // Input pixel array must be non empty
        require(pixels.length > 0, "INVALID_PIXEL_DATA");

        // Input signature array must be non empty
        require(signatures.length > 0, "INVALID_SIGNATURE_DATA");

        // Input arrays must have the same length
        require(pixels.length == signatures.length, "ARRAY_SIZE_MISMATCH");

        // Calculate total price and validate sent value
        uint256 totalPrice = pricePerPixelWei * pixels.length;
        require(msg.value >= totalPrice, "PRICE_NOT_MATCHING");

        uint256[] memory pixelIds = new uint256[](pixels.length);

        // Create and validate each requested pixel
        for (uint256 i = 0; i < pixels.length; i++) {
            // Check if the signature is set
            require(signatures[i] != "", "SIGNATURE_IS_EMPTY");

            (uint32 x, uint32 y, uint32 color) = _decodePixelCoordsAndColor(pixels[i]);

            // Check if input coordinates are inside the canvas
            require(x >= 0 && y >= 0 && x < canvasWidth && y < canvasHeight, "COORDS_OUT_OF_BOUNDS");

            //Check if it's a valid 24 bit rgb color
            require((color >> 24 & 0xff) == 0x0, "INVALID_COLOR_FORMAT: RGB ONLY");

            // Check if the requested pixels hadn't already been taken
            uint256 pixelCoords = _encodePixelCoords(x, y);
            require(_ownedPixels[pixelCoords] == 0x0, "PIXEL_ALREADY_TAKEN");

            pixelIds[i] = _generatePixel(msg.sender, pixelCoords, color, signatures[i]);
        }

        // Store owner gain
        _withdrawals[owner()] += totalPrice;

        // Store exceeding ethers for future sender withdrawal
        _withdrawals[msg.sender] += msg.value - totalPrice;

        return pixelIds;
    }

    /**
     * @dev Update a single pixel's color.
            You must always update the signature when updating the color.
     */
    function updatePixel(uint256 pixelId, uint32 color, bytes32 signature) public notInThermalDeath {
        // Check if the signature is set
        require(signature != "", "SIGNATURE_IS_EMPTY");

        //Check if it's a valid 24 bit rgb color
        require((color >> 24 & 0xff) == 0x0, "INVALID_COLOR_FORMAT: RGB ONLY");

        // Message sender must be able to update the pixel
        require(_isApprovedOrOwner(msg.sender, pixelId), "FORBIDDEN");

        _colors[pixelId] = color;
        _signatures[pixelId] = signature;

        emit PixelUpdated(pixelId, _coordinates[pixelId], color, signature, msg.sender);
    }

    /**
     * @dev Returns the complete details of a pixel from its id.
     */
    function pixelInfo(uint256 pixelId) public view returns (PixelInfo memory _pixelInfo) {
        return PixelInfo(pixelId, _colors[pixelId], _signatures[pixelId], _coordinates[pixelId], unsafeOwnerOf(pixelId));
    }

    /**
     * @dev Withdraw stored ethers.
     */
    function withdraw(address payable to) public {
        uint256 balance = _withdrawals[msg.sender];
        require(balance > 0, "NO_ETH_TO_WITHDRAW");

        _withdrawals[msg.sender] = 0;

        to.transfer(balance);
    }

    /**
     * @dev Returns the amount of ethers an account can withdraw from the contract.
     */
    function withdrawalBalance(address account) public view returns (uint256 _balance) {
        return _withdrawals[account];
    }

    /**
     * @dev Returns all pixels that has been bought. Min pixelId = 1, Max pixelId = last pixelId bought
     *
     * Requirements:
     *
     * - both `fromPixelId` and `toPixelId` must be in a range of existing pixels
     */
    function getPixels(uint256 fromPixelId, uint256 toPixelId) public view returns (PixelInfo[] memory _pixelInfo) {
        uint256 canvasLength = canvasWidth * canvasHeight;

        require(fromPixelId > 0, "FROM_VALUE_TOO_LOW");
        require(toPixelId >= fromPixelId, "TO_VALUE_TOO_LOW");
        require(toPixelId <= _tokenIds.current(), "TO_VALUE_TOO_HIGH");
        require(toPixelId <= canvasLength, "OUT_OF_BOUNDS");

        uint256 size = (toPixelId - fromPixelId) + 1;
        PixelInfo[] memory result = new PixelInfo[](size);

        for (uint256 i = fromPixelId; i <= toPixelId; i++) {
            PixelInfo memory info;
            info.pixelId = i;
            info.color = _colors[i];
            info.signature = _signatures[i];
            info.coordinates = _coordinates[i];
            info.owner = unsafeOwnerOf(i);

            uint256 arrIndex = i - fromPixelId;
            result[arrIndex] = info;
        }

        return result;
    }

    /**
     * @dev Moves owner ethers to the new owner.
     */
    function _beforeTransferOwnership(address oldOwner, address newOwner) internal virtual override {
        _withdrawals[newOwner] = _withdrawals[oldOwner];
        _withdrawals[oldOwner] = 0;
    }

    /**
     * @dev Creates the pixel ERC721 token.
     */
    function _generatePixel(address owner, uint256 encodedPixelCoords, uint32 color, bytes32 signature) internal returns (uint256 _pixelId) {
        _tokenIds.increment();

        uint256 pixelId = _tokenIds.current();
        _mint(owner, pixelId);
        _ownedPixels[encodedPixelCoords] = pixelId;
        _colors[pixelId] = color;
        _signatures[pixelId] = signature;
        _coordinates[pixelId] = encodedPixelCoords;

        if (pixelId == maxTokens) {
            _onLastToken();
        }

        emit PixelPlaced(pixelId, encodedPixelCoords, color, signature, owner);

        return pixelId;
    }

    /**
     * @dev Sets the contract on its final state and sets the freeze date.
     */
    function _onLastToken() internal {
        hasLastPixelBeenPlaced = true;
        thermalDeathDeadline = block.timestamp + thermalDeathDays;

        emit LastPixelPlaced();
    }

    /**
     * @dev Decodes a set of coordinates (uint32) and a color from an uint256.
     */
    function _decodePixelCoordsAndColor(uint256 encoded) internal pure returns (uint32 _x, uint32 _y, uint32 _color) {
        uint32 y = (uint32)(encoded & 0xffffffff);
        uint32 x = (uint32)((encoded >> 32) & 0xffffffff);
        uint32 color = (uint32)((encoded >> 64) & 0xffffffff);

        return (x, y, color);
    }

    /**
     * @dev Encodes a set of coordinates (uint32) into an uint256.
     */
    function _encodePixelCoords(uint32 x, uint32 y) internal pure returns (uint256 _encoded) {
        return x | ((uint256)(y) << 32);
    }
}

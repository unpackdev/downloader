//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./console.sol";

contract NFTCanvas is ERC721Burnable, Ownable, Pausable {
    using SafeMath for uint256;

    // Emitted when metadata is set
    event MetadataEvent(uint256 indexed index, address indexed owner, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 tokenId, string tokenURI);

    // Block size is 10x10 pixels
    uint256 public constant blockSize = 100;

    // Max ranges in block sizes
    uint256 public constant xRange = 384;
    uint256 public constant yRange = 216;

    // Current price per pixel in US Cents
    uint256 public currentPriceUSCents;

    // Current metadata event index
    uint256 private eventIndex;

    // Mapping of owned blocks
    mapping (uint256 => bool) private _ownedBlocks;

    // Price feed oracle
    AggregatorV3Interface private priceFeed;

    /**
    * Contract constructor
    *
    * @param _currentPriceUSCents price per block (10x10 pixels) in US cents
    */
    constructor(uint256 _currentPriceUSCents) ERC721("NFTCanvas", "nftc") {
        require(_currentPriceUSCents > 0, "Invalid price");
        currentPriceUSCents = _currentPriceUSCents;

        // Aggregator: ETH/USD
        // Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
    * @dev Purchase an area of pixel blocks
    *
    * @param x1, y1, x2, y2 - area coordinates
    * @param tokenURI - token URI
    */
    function purchaseArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2, string memory tokenURI) external payable whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this));
        require(_isValidRange(x1, y1, x2, y2), "Cannot purchase area: Invalid area");
        require(msg.value >= getAreaPrice(x1, y1, x2, y2), "Cannot purchase area: Price is too low");

        // Generate token id representing the area
        uint256 tokenId = _getTokenId(x1, y1, x2, y2);

        _buyArea(msg.sender, x1, y1, x2, y2, tokenId, tokenURI);

        emit MetadataEvent(eventIndex, msg.sender, x1, y1, x2, y2, tokenId, tokenURI);
        eventIndex++;
    }

    /**
    * @dev Set metadata on an owned area
    *
    * @param x1, y1, x2, y2 - area coordinates
    * @param tokenURI - token URI
    */
    function setMetadataOnArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2, string memory tokenURI) external whenNotPaused {
        require(_isValidRange(x1, y1, x2, y2), "Cannot set metadata: Invalid area");
        uint256 tokenId = _getTokenId(x1, y1, x2, y2);
        _setAreaMetadata(msg.sender, tokenURI, tokenId);
        emit MetadataEvent(eventIndex, msg.sender, x1, y1, x2, y2, tokenId, tokenURI);
        eventIndex++;
    }

    /**
    * @dev Send / withdraw amount to payee
    *
    * @param payee address payee
    * @param amount uint256 amount
    */
    function sendTo(address payable payee, uint256 amount) public onlyOwner {
        require(payee != address(0) && payee != address(this), "Invalid payee");
        require(amount > 0 && amount <= address(this).balance, "Amount out of range");
        payee.transfer(amount);
    }

    /**
    * @dev Updates current price
    *
    * @param _currentPriceUSCents address payee
    */
    function setCurrentPrice(uint256 _currentPriceUSCents) public onlyOwner {
        require(_currentPriceUSCents > 0, "Invalid price");
        currentPriceUSCents = _currentPriceUSCents;
    }

    /**
    * @dev Get price for a given area in ETH
    *
    * @param x1, y1, x2, y2 - area coordinates
    */
    function getAreaPrice(uint256 x1, uint256 y1, uint256 x2, uint256 y2) public view returns (uint256) {   
        // Check for valid range
        require(_isValidRange(x1, y1, x2, y2), "Invalid area");
        return _getBlockPriceInEth() * _getNumBlocksInArea(x1, y1, x2, y2);
    }

    /**
    * @dev Buy an area
    *
    * @param buyer buyer address
    * @param x1, y1, x2, y2 - area coordinates
    * @param tokenURI - token URI
    */
    function _buyArea(address buyer, uint256 x1, uint256 y1, uint256 x2, uint256 y2, uint256 tokenId, string memory tokenURI) private {
        // Check that blocks comprising area are not already owned & mark them as owned
        for (uint256 x = x1; x < x2; x++) {
            for (uint256 y = y1; y < y2; y++) {
                uint256 blockId = _getBlockId(x, y);
                require(!_ownedBlocks[blockId], "Cannot buy area: Area already owned");
                _ownedBlocks[blockId] = true;
            }
        }

        // Mint the token
        _mint(buyer, tokenId);

        // Set metadata on area
        _setAreaMetadata(buyer, tokenURI, tokenId);
    }

    /**
    * @dev Sets metadata on area
    *
    * @param owner owner address
    * @param tokenURI token URI
    * @param tokenId token id
    */
    function _setAreaMetadata(address owner, string memory tokenURI, uint256 tokenId) private {
        require(_isApprovedOrOwner(owner, tokenId), "Cannot set metadata: Not owner or approver");
        _setTokenURI(tokenId, tokenURI);
    }

    /**
    * @dev Computes block id given coordinates
    *
    * @param x, y - coordinates
    */
    function _getBlockId(uint256 x, uint256 y) private pure returns (uint256) {
        return x + (y << 16);
    }

    /**
    * @dev Compute token id given area
    *
    * @param x1, y1, x2, y2 - area coordinates
    */
    function _getTokenId(uint256 x1, uint256 y1, uint256 x2, uint256 y2) private pure returns (uint256) {
        return _getBlockId(x1, y1) + (_getBlockId(x2, y2) << 32);
    }

    /**
    * @dev Get price of a block (10 x 10 pixels) in eth
    *
    */
    function _getBlockPriceInEth() private view returns (uint256) {
        return _getPixelPriceInEth() * blockSize;
    }

    /**
    * @dev Get price of a pixel in eth
    *
    */
    function _getPixelPriceInEth() private view returns (uint256) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint256 oneEth = 1 ether;
        uint256 decimals = priceFeed.decimals();
        require(decimals > 2);
        uint256 weiPerCent = oneEth.div(uint256(price).div(10 ** (decimals - 2)));
        require(price > 0 && weiPerCent > 0, "Invalid price");
        return weiPerCent.mul(currentPriceUSCents);
    }

    /**
    * @dev Get number of blocks for given area
    *
    * @param x1, y1, x2, y2 - area coordinates
    */
    function _getNumBlocksInArea(uint256 x1, uint256 y1, uint256 x2, uint256 y2) private pure returns (uint256) {
        return (x2-x1)*(y2-y1);
    }

    /**
    * @dev Determine if given area coordinates represent a valid area
    *
    * @param x1, y1, x2, y2 - area coordinates
    */
    function _isValidRange(uint256 x1, uint256 y1, uint256 x2, uint256 y2) private pure returns(bool) {
        return (x1 < x2 && y1 < y2 && x2 <= xRange && y2 <= yRange);
    }
}

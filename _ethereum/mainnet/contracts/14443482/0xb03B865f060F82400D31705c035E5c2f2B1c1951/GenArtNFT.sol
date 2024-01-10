// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./NFTDescriptor.sol";

contract GenArtNFT is ERC721 {
    uint256 internal constant MAX_SUPPLY = 3000;

    bool public mintable;
    uint16 public dimensionLimits;
    uint24 public totalSupply;
    address public tokenDescriptor;
    address public owner;
    uint128[MAX_SUPPLY] public tokenData;

    constructor() ERC721(unicode"███", unicode"███") {
        owner = msg.sender;
        dimensionLimits = 0x6166;
    }

    function mint(uint128 data) external {
        require(mintable, "Minting disabled");
        uint256 ncol = (data >> 0) & 0x7;
        uint256 nrow = (data >> 3) & 0x7;
        uint256 dim = dimensionLimits;
        //prettier-ignore
        require(
            ncol >= ((dim >> 0)  & 0xF) &&
            ncol <= ((dim >> 4)  & 0xF) &&
            nrow >= ((dim >> 8)  & 0xF) &&
            nrow <= ((dim >> 12) & 0xF),
            "Invalid Data"
        );
        uint256 tokenId = ++totalSupply;
        require(tokenId <= MAX_SUPPLY, "Exceed max supply");
        uint256 rand = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, tokenId))) % 8;
        tokenData[tokenId] = (uint128(rand) << 120) | uint120(data);
        _mint(msg.sender, tokenId);
    }

    function _getData(uint256 tokenId)
        internal
        view
        returns (
            uint256 ncol,
            uint256 nrow,
            uint256 result,
            uint256 salt
        )
    {
        uint256 data = tokenData[tokenId];
        require(data != 0, "Token not exists");
        ncol = (data >> 0) & 0x7;
        nrow = (data >> 3) & 0x7;
        result = uint120(data) >> 6;
        salt = data;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenDescriptor != address(0)) {
            return IERC721Descriptor(tokenDescriptor).tokenURI(tokenId);
        }
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.constructTokenURI(tokenId, result, ncol, nrow, salt, name);
    }

    function imageURI(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.makeImageURI(result, ncol, nrow, salt);
    }

    function squares(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, ) = _getData(tokenId);
        return NFTDescriptor.makeSquares(result, ncol, nrow);
    }

    // ----------

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setInfo(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setDimensionLimit(uint16 _dimensionLimits) external onlyOwner {
        dimensionLimits = _dimensionLimits;
    }

    // only in case we need to patch the art logic
    function setTokenDescriptor(address _descriptor) external onlyOwner {
        tokenDescriptor = _descriptor;
    }
}

interface IERC721Descriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

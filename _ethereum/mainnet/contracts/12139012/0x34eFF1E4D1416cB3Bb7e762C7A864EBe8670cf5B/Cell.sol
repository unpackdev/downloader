pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title Cell
 */
contract Cell is ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    
    // Mapping from token ID to 10x10 cell image
    mapping (uint256 => bytes) private _image;

    // Cell token count
    uint256 private _cellCount;

    // The sale contract address
    address private _minterContract;

    /**
     * Event for token change image logging
     * @param tokenId uint256 ID of the token to be change image
     * @param image byte code that represents the image of a 10 x 10 pixel
     */
    event SetImage(uint256 tokenId, bytes image);

    constructor (string memory name, string memory symbol, uint256 cellCount) ERC721(name, symbol) { 
        _cellCount = cellCount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner{
        _baseTokenURI = newBaseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setImage(uint256 tokenId, bytes memory image) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Cell: caller is not owner nor approved");
        _image[tokenId] = image;
        emit SetImage(tokenId, image);
    }

    function setBatchImage(uint256[] memory tokenIds, bytes[] memory images) public {
        require(tokenIds.length == images.length, "Cell: tokenIds and images must have the same length");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            setImage(tokenIds[i], images[i]);
        }
    }

    function getImage(uint256 tokenId) public view returns (bytes memory) {
        require(tokenId < getCellCount(), "Cell: tokenId must be less than cell count");
        return _image[tokenId];
    }
    
    function getMinterAddrass() public view returns (address) {
        return _minterContract;
    }
    
    function setMinterAddrass(address minterContract) public onlyOwner {
        _minterContract = minterContract;
    }
    
    function getCellCount() public view returns (uint256) {
        return _cellCount;
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, bytes memory _data) public {
        _safeMint(to, tokenId, _data);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override{ 
        require(tokenId < getCellCount(), "Cell: tokenId must be less than cell count");
        require(from != address(0) || _msgSender() == _minterContract, "Cell: only the sale contract can be mint a new token");
        
        super._beforeTokenTransfer(from, to, tokenId);
    }
} 
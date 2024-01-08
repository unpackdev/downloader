/// @title ERC-721 contract for the Lost Souls project by strangeworld.eth
/// @author dd0sxx

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract LostSouls is ERC721, Ownable {

    using Strings for uint256;

    string private _baseTokenURI;
    uint256 public totalSupply;

    constructor(string memory baseURI) ERC721('Lost Souls', 'SOULS') {
       setBaseURI(baseURI);
       transferOwnership(0xAF8Badc097f0ee1e098CC3928a38857B3FeaA074);
    }

    function mint(uint256 num) external onlyOwner {
        uint256 supply = totalSupply;
         for(uint256 i = 1; i <= num; i++) {
            _mint( msg.sender, supply + i );
        }
        totalSupply += supply + num;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

}
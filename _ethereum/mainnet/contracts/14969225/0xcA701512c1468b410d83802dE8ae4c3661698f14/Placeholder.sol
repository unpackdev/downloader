pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Strings.sol";
contract Placeholder is ERC721A {
    using Strings for uint256;
    string public baseUri = "https://mint.web3nycgallery.com/token/";
    string public endingUri = ".json";
    constructor() ERC721A("Placeholder", "TKPK") {
        _mint(msg.sender, 1000);
    }

    function tokenURI(uint256 tokenId) public view  virtual override returns (string memory) {
        return string(abi.encodePacked(baseUri, tokenId.toString(), endingUri));
    }

}
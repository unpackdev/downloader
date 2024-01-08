// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract BroadcastersHonorary is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI = "https://bcsnft.s3.us-east-2.amazonaws.com/honorary-meta/";

    constructor() ERC721("Broadcasters Honorary", "BCH") {
        //
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), tokenId.toString()));
    }

    //OnlyOwner>

    function mint(uint256 qty) public onlyOwner {
        require(qty > 0, "qty");

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
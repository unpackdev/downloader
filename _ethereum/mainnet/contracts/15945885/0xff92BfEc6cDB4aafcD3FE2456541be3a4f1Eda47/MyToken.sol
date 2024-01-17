// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract JJPFP is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply = 0;

    constructor() ERC721("JJ PFP", "JJ") {}

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "token/", Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal override pure returns (string memory) {
        return "https://pfp.konojunya.com/";
    }

    function safeMint(address to) public onlyOwner {
        _totalSupply = _totalSupply.add(1);

        uint256 tokenId = _totalSupply;
        _safeMint(to, tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

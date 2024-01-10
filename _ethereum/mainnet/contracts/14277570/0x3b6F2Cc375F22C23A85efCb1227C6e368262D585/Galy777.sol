//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Galy777MECEdition is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public BASE_URI;
    uint256 public constant MAX_SUPPLY = 777;
    uint256 public constant PRICE = 0.0777 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory baseURI)
        public
        ERC721("Galy 777 MEC Edition", "GALY777MEC")
    {
        BASE_URI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(BASE_URI, "/"));
    }

    function mint(address addr) public payable returns (uint256) {
        uint256 supply = totalSupply();
        require(supply <= MAX_SUPPLY, "Would exceed max supply");
        require(msg.value >= PRICE, "insufficient funds");
        uint256 tokenId = supply + 1;
        _safeMint(addr, tokenId);

        return tokenId;
    }

    function withdrawAll() external onlyOwner {
        require(
            address(this).balance > 0,
            "Withdrawble: No amount to withdraw"
        );
        payable(msg.sender).transfer(address(this).balance);
    }
}

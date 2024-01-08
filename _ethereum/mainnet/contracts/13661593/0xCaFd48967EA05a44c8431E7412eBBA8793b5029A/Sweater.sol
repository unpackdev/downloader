// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Sweater is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant PRICE = 10 * 10**16; // 0.1 ETH
    uint256 public constant MAX_MINT = 10;

    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("Sweater", "SWEATER") {
        setBaseURI(baseURI);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(numberOfTokens != 0, "You need to mint at least 1 token");
        require(numberOfTokens <= MAX_MINT, "You can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Minting would exceed max. supply");
        require(PRICE.mul(numberOfTokens) <= msg.value, "Not enough Ether sent.");
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if(mintIndex < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getBackAToken(IERC20 erc20Token) public onlyOwner {
      erc20Token.transfer(owner(), erc20Token.balanceOf(address(this)));
    }
}
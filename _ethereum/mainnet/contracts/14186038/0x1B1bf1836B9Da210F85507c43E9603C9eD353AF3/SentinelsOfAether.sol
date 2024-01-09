// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title SentinelsOfAether
 * SentinelsOfAether - Angelic NFT Collectible
 */
contract SentinelsOfAether is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public isMintActive = false;
    string public PROVENANCE = "-";
    uint256 public maxTokensCount = 22;
    string private baseURI;
    string public baseTokenURI;
    string public contractURI;

    constructor() ERC721("SentinelsOfAether", "SOA") {
    }

    function activateMinting() public onlyOwner {
        isMintActive = true;
    }

    function deactivateMinting() public onlyOwner {
        isMintActive = false;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPROVENANCE(string memory prov) public onlyOwner {
        PROVENANCE = prov;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintSentinelOfAether(uint mintIndex) public onlyOwner {
        require(isMintActive, "Mint must be active to be able to mint");

        if (totalSupply() < maxTokensCount) {
            _safeMint(msg.sender, mintIndex);
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}

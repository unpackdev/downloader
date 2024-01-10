// src/BoilerplateNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ZipWeekNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Strings for uint256;
    string public BASE_URI;
    uint256 public MAX_TOKENS;

    uint256[] public tokenIdPrice;
    mapping(uint256 => bool) public isMinted;
    // mapping(uint256 => bool) public isLive;

    uint256 public startTime;

    mapping(address => uint256) public beneficiaryBalance;
    address[4] private beneficiaryList;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseuri,
        uint256 maxTokens,
        address beneficiary,
        uint256[] memory tokenPrices,
        address[4] memory benefitList
    ) ERC721(name, symbol) {
        transferOwnership(beneficiary);
        require(owner() == beneficiary, "Ownership not transferred");
        BASE_URI = baseuri;
        MAX_TOKENS = maxTokens;
        tokenIdPrice = tokenPrices;
        startTime = block.timestamp;
        beneficiaryList = benefitList;
    }

    function safeMint(address to, uint256 tokenId) public payable returns (uint256, string memory) {
        require(tokenId <= MAX_TOKENS, "Token does not exists");
        require(isMintable(tokenId), "Token not mintable");
        require(isLive(tokenId), "Token is not yet available");
        require(tokenIdPrice[tokenId] <= msg.value, "Ether value sent is not correct");

        isMinted[tokenId] = true;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        string memory _tokenURI = tokenURI(tokenId);

        uint256 twentieth = msg.value / 20;
        beneficiaryBalance[beneficiaryList[0]] += twentieth * 5;
        beneficiaryBalance[beneficiaryList[1]] += twentieth * 5;
        beneficiaryBalance[beneficiaryList[2]] += twentieth * 8;
        beneficiaryBalance[beneficiaryList[3]] += twentieth * 2;

        return (tokenId, _tokenURI);
    }

    function withdrawBenefit() external returns (bool) {
        require(
            msg.sender == beneficiaryList[0] ||
                msg.sender == beneficiaryList[1] ||
                msg.sender == beneficiaryList[2] ||
                msg.sender == beneficiaryList[3],
            "Address not a beneficiary"
        );
        require(beneficiaryBalance[msg.sender] > 0, "No benefits to withdraw");

        uint256 amount = beneficiaryBalance[msg.sender];
        beneficiaryBalance[msg.sender] = 0; // Optimistic accounting.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
        return success;
    }

    function viewBenefit() public view returns (uint256) {
        return beneficiaryBalance[msg.sender];
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setStartTime(uint256 newStart) public onlyOwner {
        startTime = newStart;
    }

    function safeMintSpecial(address to) public onlyOwner returns (uint256, string memory) {
        uint256 tokenId = 4;
        isMinted[tokenId] = true;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        string memory _tokenURI = tokenURI(tokenId);
        return (tokenId, _tokenURI);
    }

    function isMintable(uint256 tokenId) public view returns (bool) {
        if (tokenId == 4) {
            return false;
        }
        if (tokenId >= MAX_TOKENS) {
            return false;
        }
        return !isMinted[tokenId];
    }

    function setTokenPrice(uint256 tokenId, uint256 price) public onlyOwner {
        tokenIdPrice[tokenId] = price;
    }

    function isLive(uint256 tokenId) public view returns (bool) {
        if (block.timestamp >= startTime + tokenId * 1 days) {
            return true;
        }
        return false;
    }

    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenId <= MAX_TOKENS, "Token does not exists");
        return tokenIdPrice[tokenId];
    }

    // Override
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return BASE_URI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

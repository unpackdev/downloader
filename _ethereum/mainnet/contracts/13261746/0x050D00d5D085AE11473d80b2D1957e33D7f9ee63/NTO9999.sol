//SPDX-License-Identifier: GPL-3.0
//Created by BaiJiFeiLong@gmail.com at 2021/9/14
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NTO9999 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _settleCounts;
    mapping(uint256 => uint256) private _segmentMints;

    constructor() ERC721("NotTheOwner9999", "NTO9999") {
        console.log("Constructing...");
        for (uint256 i = 0; i < 10; ++i) {
            _mintOne();
        }
        console.log("Constructed.");
    }

    function settleCount(uint256 tokenId) public view returns (uint256) {
        return _settleCounts[tokenId];
    }

    function luckySupply() public pure returns (uint256) {
        return 10000;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmcQtZEMHUb9AqWf5s5535fr1qJsSqee8aFnXvdF3kPqDu";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        } else if (tokenId >= luckySupply()) {
            return "ipfs://QmNNtSbKUb5gXttkgrYv965B5FdqhG6zERabuRmvugZu8P";
        } else {
            string memory padding = tokenId < 10 ? "000" : tokenId < 100 ? "00" : tokenId < 1000 ? "0" : "";
            return string(abi.encodePacked(_baseURI(), "/nto", padding, tokenId.toString(), ".json"));
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply())));
    }

    function _fragmentSize() private pure returns (uint256) {
        return 100;
    }

    function _nextRandomTokenId() private view returns (uint256) {
        uint256 i = _random() % luckySupply();
        while (i < luckySupply()) {
            if (!_exists(i)) {
                return i;
            }
            if (_segmentMints[i / _fragmentSize()] >= _fragmentSize()) {
                i = (i + _fragmentSize()) % luckySupply();
            } else {
                i = i - (i % _fragmentSize()) + ((i + 1) % _fragmentSize());
            }
        }
        revert("Impossible");
    }

    function _mintOne() private {
        uint256 newTokenId = totalSupply() >= luckySupply() ? totalSupply() : _nextRandomTokenId();
        console.log("Minting...", _msgSender(), newTokenId);
        _mint(_msgSender(), newTokenId);
        if (newTokenId < luckySupply()) {
            _segmentMints[newTokenId / _fragmentSize()] += 1;
        }
    }

    function luckyMint() public payable {
        console.log("Paid value:", msg.value);
        uint256 minPrice = totalSupply() >= luckySupply() ? 0.01 ether : (totalSupply() / 1000 + 1) * 0.01 ether;
        console.log("Minimum mint price:", minPrice);
        require(msg.value >= minPrice, "Provided ethers not enough");
        uint256 previousTokenId = tokenByIndex(totalSupply() - 1);
        address previousAddress = ownerOf(previousTokenId);
        uint256 luckyTokenId = tokenByIndex(_random() % totalSupply() % luckySupply());
        address luckyAddress = ownerOf(luckyTokenId);
        console.log("Previous token:", previousTokenId, previousAddress);
        console.log("Lucky token:", luckyTokenId, luckyAddress);
        payable(previousAddress).transfer(msg.value / 2);
        payable(luckyAddress).transfer(msg.value - msg.value / 2);
        _mintOne();
    }

    function luckySettle(uint256 tokenId, string memory uri) public payable {
        console.log("Paid value:", msg.value);
        uint256 tokenSettleCount = settleCount(tokenId);
        console.log("Token settle count:", tokenSettleCount);
        uint256 minPrice = (tokenSettleCount + 1) * 0.001 ether;
        console.log("Minimum settle price:", minPrice);
        require(msg.value >= minPrice, "Provided ethers not enough");
        address tokenAddress = ownerOf(tokenId);
        uint256 luckyTokenId = tokenByIndex(_random() % totalSupply() % luckySupply());
        address luckyAddress = ownerOf(luckyTokenId);
        console.log("Settle token:", tokenId, tokenAddress);
        console.log("Lucky token:", luckyTokenId, luckyAddress);
        payable(tokenAddress).transfer(msg.value / 2);
        payable(luckyAddress).transfer(msg.value - msg.value / 2);
        _tokenURIs[tokenId] = uri;
        _settleCounts[tokenId] += 1;
    }
}
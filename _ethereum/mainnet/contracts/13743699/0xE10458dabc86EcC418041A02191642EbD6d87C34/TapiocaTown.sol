//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Counters.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract TapiocaTown is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 private _mintPrice;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event MintPriceChanged(uint256 price);
    event MintId(uint256 nftId);

    function initialize(uint256 mintPrice) public initializer {
        __ERC721_init_unchained("TapiocaTown", "BOBA");
        __Ownable_init_unchained();
        _mintPrice = mintPrice;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
        emit MintPriceChanged(price);
        return;
    }

    function withdraw() public onlyOwner {
        (bool sent, bytes memory data) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    function getTokenCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function mintNFT(address recipient, string memory tokenURI) public virtual payable returns (uint256) {
        require(msg.value >= _mintPrice, "Not enough Eth");

        _tokenIds.increment();

        uint256 newNftId = _tokenIds.current();
        _mint(recipient, newNftId);
        _setTokenURI(newNftId, tokenURI);

        MintId(newNftId);
        return newNftId;
    }
}

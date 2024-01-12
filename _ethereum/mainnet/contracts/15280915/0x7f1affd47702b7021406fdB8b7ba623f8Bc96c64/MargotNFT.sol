// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import {ERC1155Supply, ERC1155} from "ERC1155Supply.sol";
import {Ownable} from "Ownable.sol";
import {SafeMath} from "SafeMath.sol";
import {Strings} from "Strings.sol";
import {Address} from "Address.sol";

error SaleNotStarted();
error TokenAlreadyMinted();
error TokenIdOutOfLimits();
error InsufficientFunds();
error WithdrawFailed();

contract MargotNFT is ERC1155Supply, Ownable {
    using Strings for uint256;

    uint256 public immutable maxSupply = 1;
    uint256 public currentId = 0;
    uint256 public saleStartTime = 1659684600;
    string public constant name = "Margot NFT Collection";
    string public constant symbol = "MNC";
    string private _baseTokenURI;
    address private ownerWallet = 0x73b8Bd0E0876726FDdB275FBD4A10EBAB49fb72a;

    mapping(uint256 => uint256) public tokenIdToPrice;
    mapping(uint256 => address) public ownerOfTokenId;

    constructor(string memory _baseUri) ERC1155("") {
        setBaseURI(_baseUri);
    }

    function mint(uint256 tokenId) external payable {
        // Validation
        if (tokenId >= currentId) revert TokenIdOutOfLimits();
        if (saleStartTime == 0 || block.timestamp < saleStartTime) revert SaleNotStarted();
        if (totalSupply(tokenId) != 0) revert TokenAlreadyMinted();
        uint256 price = tokenIdToPrice[tokenId];
        if (price == 0 || msg.value != price) revert InsufficientFunds();
        // State update
        ownerOfTokenId[tokenId] = msg.sender;
        // Interaction
        _mint(msg.sender, tokenId, 1, "");
    }

    function addTokenIdPrices(uint256[] calldata prices) external onlyOwner {
        for (uint i; i < prices.length; i++) {
            tokenIdToPrice[currentId++] = prices[i];
        }
    }

    function modifyTokenIdPrice(uint256 tokenId, uint256 price) external onlyOwner {
        tokenIdToPrice[tokenId] = price;
    }

    function getTokenIdPrice(uint256 tokenId) public view returns(uint256) {
        return tokenIdToPrice[tokenId];
    }

    function setSaleStartTime(uint128 _timestamp) external onlyOwner {
        saleStartTime = _timestamp;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    function ownerOf(uint256 tokenId) public view returns(address) {
        return ownerOfTokenId[tokenId];
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = ownerWallet.call{value: balance}("");
        if(!transferTx) revert WithdrawFailed();
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = _baseTokenURI;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}

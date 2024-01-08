// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Tradable.sol";

/**
 * @title MintPass
 * MintPass - a contract for the MintPass
 */

contract MintPass is ERC1155Tradable {

    using SafeMath for uint256;
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    uint256 public preSalePrice = 0.01420 ether;
    uint256 public pubSalePrice = 0.01420 ether;
    uint256 public maxPerWallet = 10;
    uint256 public maxPerTransaction = 10;

    struct Supply {
        uint256 supply;
    }
    mapping(uint256 => Supply) public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _id,
        uint256 _initialSupply,
        uint256 _maxSupply,
        address _proxyRegistryAddress
    ) ERC1155Tradable(_name, _symbol, _uri, _proxyRegistryAddress) {

        create(msg.sender, _id, _initialSupply, _uri, "");
        maxSupply[_id].supply = _maxSupply; // setMaxSupply()
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        maxSupply[_id].supply = _maxSupply;
    }

    function getMaxSupply(uint256 _id) public view returns (uint256) {
        return maxSupply[_id].supply;
    }

    function getCurrentSupply(uint256 _id) public view returns (uint256) {
        return totalSupply(_id);
    }

    function setPubSalePrice(uint256 _price) external onlyOwner {
        pubSalePrice = _price;
    }

    function getPubSalePrice() public view returns (uint256) {
        return pubSalePrice;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function getPreSalePrice() public view returns (uint256) {
        return preSalePrice;
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function airdrop(
        address[] memory _addrs,
        uint256 _quantity,
        uint256 _id
    )
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            mint(_addrs[i], _id, _quantity, "");
        }
    }

    function mint(uint256 _quantity, uint256 _id) public payable {
        require(saleIsActive, "Sale is not active.");
        require(
            totalSupply(_id).add(_quantity) <= getMaxSupply(_id),
            "Mint has already ended."
        );

        require(_quantity > 0, "numberOfTokens cannot be 0.");
        require(
            pubSalePrice.mul(_quantity) <= msg.value,
            "ETH sent is incorrect."
        );

        require(
            balanceOf(msg.sender, _id).add(_quantity) <= maxPerWallet,
            "Exceeds limit per wallet."
        );
        require(
            _quantity <= maxPerWallet,
            "Exceeds per transaction limit."
        );

        mint(msg.sender, _id, _quantity, "");
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
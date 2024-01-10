// SPDX-License-Identifier: MIT
// Creator: Stellar Labs

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Strings.sol";
import "ERC721A.sol";

contract MetaStellar is Ownable, ERC721A {
    uint256 public immutable collectionSize;

    uint256 public maxPerAddressDuringMint;
    uint64 public whitelistPrice;
    uint64 public publicPrice;
    uint96 public royaltyfeeNumerator;
    bool public saleIsActive;
    bool public whitelistSaleIsActive;

    mapping(address => bool) public whiteList;
    mapping(address => address) private payments;

    constructor() ERC721A("MetaStellar", "METASTELLAR") {
        collectionSize = 10000;
        saleIsActive = false;
        whitelistSaleIsActive = true;
        publicPrice = 500000000000000000;
        whitelistPrice = 200000000000000000;
        maxPerAddressDuringMint = 50;
        royaltyfeeNumerator = 1000;
        _setDefaultRoyalty(msg.sender, royaltyfeeNumerator);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CIU");
        _;
    }

    modifier saleQuantity(uint256 quantity) {
        require(_totalMinted() + quantity <= collectionSize, "SQ1");
        require(
            _numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "SQ2"
        );
        _;
    }

    function publicSaleChangeState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function whitelistSaleChangeState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function setRoyaltyFeeNumerator(uint96 _fee) external onlyOwner {
        royaltyfeeNumerator = _fee;
    }

    function setWhitelistPrice(uint64 price) external onlyOwner {
        whitelistPrice = price;
    }

    function setPublicPrice(uint64 price) external onlyOwner {
        publicPrice = price;
    }

    function setMaxPerAdressDuringMint(uint256 num) external onlyOwner {
        maxPerAddressDuringMint = num;
    }

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        saleQuantity(quantity)
    {
        require(saleIsActive, "S1");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function whitelistMint(uint256 quantity)
        external
        payable
        callerIsUser
        saleQuantity(quantity)
    {
        require(whitelistSaleIsActive, "W1");
        _safeMint(msg.sender, quantity);
        if (msg.sender != owner()) {
            require(whiteList[msg.sender], "W2");
            refundIfOver(whitelistPrice * quantity);
        }
    }

    function addToWhitelist(address _addr) external onlyOwner {
        whiteList[_addr] = true;
    }

    function deteleWhiteList(address _addr) external onlyOwner {
        delete whiteList[_addr];
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setURIsuffix(string calldata suffix) external onlyOwner {
        uriSuffix = suffix;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _burnCounter;
    }

    function burn(uint256 tokenId) external callerIsUser {
        _burn(tokenId, true);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "ME");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "TF");
    }

    function setTokenRoyalty(uint256 tokenId, address receiver)
        external
        onlyOwner
    {
        _setTokenRoyalty(tokenId, receiver, royaltyfeeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address receiver) external onlyOwner {
        _setDefaultRoyalty(receiver, royaltyfeeNumerator);
    }

    function setPaymentMapping(address _payspitteraddr, address _minter)
        external
        onlyOwner
    {
        payments[_minter] = _payspitteraddr;
    }

    function getPaymentAddress(address _minter)
        external
        view
        returns (address)
    {
        if (msg.sender != owner()) {
            require(msg.sender == _minter, "PA");
        }
        return payments[_minter];
    }
}

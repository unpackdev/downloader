// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract TheHodlerzSale is ERC721A("THE HODLERZ", "HODL"), Ownable, ERC721AQueryable, ERC721ABurnable, ERC2981 {
    uint256 public constant maxSupply = 9999;
    uint256 public reservedHodlerz = 99;

    uint256 public freeHodlerz = 0;
    uint256 public freeMaxHodlerzPerWallet = 0;
    uint256 public freeSaleActiveTime = type(uint256).max;

    uint256 public firstFreeMints = 1;
    uint256 public maxHodlerzPerWallet = 3;
    uint256 public hodlerPrice = 0.03 ether;
    uint256 public saleActiveTime = type(uint256).max;

    string hodlerMetadataURI;

    function buyHodlerz(uint256 _hodlerzQty) external payable saleActive(saleActiveTime) callerIsUser mintLimit(_hodlerzQty, maxHodlerzPerWallet) priceAvailableFirstNftFree(_hodlerzQty) hodlerzAvailable(_hodlerzQty) {
        require(_totalMinted() >= freeHodlerz, "Get your Hodler for free");

        _mint(msg.sender, _hodlerzQty);
    }

    function buyHodlerzFree(uint256 _hodlerzQty) external saleActive(freeSaleActiveTime) callerIsUser mintLimit(_hodlerzQty, freeMaxHodlerzPerWallet) hodlerzAvailable(_hodlerzQty) {
        require(_totalMinted() < freeHodlerz, "Hodlerz max free limit reached");

        _mint(msg.sender, _hodlerzQty);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setHodlerPrice(uint256 _newPrice) external onlyOwner {
        hodlerPrice = _newPrice;
    }

    function setFreeHodlerz(uint256 _freeHodlerz) external onlyOwner {
        freeHodlerz = _freeHodlerz;
    }

    function setFirstFreeMints(uint256 _firstFreeMints) external onlyOwner {
        firstFreeMints = _firstFreeMints;
    }

    function setReservedHodlerz(uint256 _reservedHodlerz) external onlyOwner {
        reservedHodlerz = _reservedHodlerz;
    }

    function setMaxHodlerzPerWallet(uint256 _maxHodlerzPerWallet, uint256 _freeMaxHodlerzPerWallet) external onlyOwner {
        maxHodlerzPerWallet = _maxHodlerzPerWallet;
        freeMaxHodlerzPerWallet = _freeMaxHodlerzPerWallet;
    }

    function setSaleActiveTime(uint256 _saleActiveTime, uint256 _freeSaleActiveTime) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
    }

    function setHodlerMetadataURI(string memory _hodlerMetadataURI) external onlyOwner {
        hodlerMetadataURI = _hodlerMetadataURI;
    }

    function giftHodlerz(address[] calldata _sendNftsTo, uint256 _hodlerzQty) external onlyOwner hodlerzAvailable(_sendNftsTo.length * _hodlerzQty) {
        reservedHodlerz -= _sendNftsTo.length * _hodlerzQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _hodlerzQty);
    }

    function _baseURI() internal view override returns (string memory) {
        return hodlerMetadataURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(block.timestamp > _saleActiveTime, "Hey Hodler please, come back when the sale goes live");
        _;
    }

    modifier mintLimit(uint256 _hodlerzQty, uint256 _maxHodlerzPerWallet) {
        require(_numberMinted(msg.sender) + _hodlerzQty <= _maxHodlerzPerWallet, "Hodlerz max x wallet exceeded");
        _;
    }

    modifier hodlerzAvailable(uint256 _hodlerzQty) {
        require(_hodlerzQty + totalSupply() + reservedHodlerz <= maxSupply, "Too late, we are sold out");
        _;
    }

    modifier priceAvailable(uint256 _hodlerzQty) {
        require(msg.value == _hodlerzQty * hodlerPrice, "Hey Hodler please, send the right amount of ETH");
        _;
    }

    function getPrice(uint256 _qty) public view returns (uint256 price) {
        uint256 totalPrice = _qty * hodlerPrice;
        uint256 numberMinted = _numberMinted(msg.sender);
        uint256 discountQty = firstFreeMints > numberMinted ? firstFreeMints - numberMinted : 0;
        uint256 discount = discountQty * hodlerPrice;
        price = totalPrice > discount ? totalPrice - discount : 0;
    }

    modifier priceAvailableFirstNftFree(uint256 _hodlerzQty) {
        require(msg.value == getPrice(_hodlerzQty), "Hey Hodler please, send the right amount of ETH");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}

contract HodlerApprovesMarketplaces is TheHodlerzSale {
    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A, IERC721) returns (bool) {
        // Opensea, LooksRare, Rarible, X2y2, Any Other Marketplace

        if (_operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner)) return true;
        else if (_operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e) return true;
        else if (_operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be) return true;
        else if (_operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354) return true;
        else if (allowed[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
}

contract TheHodlerzStaking is HodlerApprovesMarketplaces {
    mapping(address => bool) public canStake;

    function addToWhitelistForStaking(address _operator) external onlyOwner {
        canStake[_operator] = !canStake[_operator];
    }

    modifier onlyWhitelistedForStaking() {
        require(canStake[msg.sender], "This contract is not allowed to stake");
        _;
    }

    mapping(uint256 => bool) public staked;

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256
    ) internal view override {
        require(!staked[startTokenId], "Hey Hodler please, unstake your Hodlerz first");
    }

    function stakeHodlerz(uint256[] calldata _tokenIds, bool _stake) external onlyWhitelistedForStaking {
        for (uint256 i = 0; i < _tokenIds.length; i++) staked[_tokenIds[i]] = _stake;
    }
}

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract TheHodlerz is TheHodlerzStaking {}

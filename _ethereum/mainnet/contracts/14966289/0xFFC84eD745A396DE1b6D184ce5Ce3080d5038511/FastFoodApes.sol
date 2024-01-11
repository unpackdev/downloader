// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";

contract FastFoodApesSale is ERC721A("Fast Food Apes", "FFA"), Ownable, ERC721AQueryable, ERC721ABurnable, ERC2981 {
    uint256 public freeApes = 2444;
    uint256 public freeMaxApesPerWallet = 2;
    uint256 public freeSaleActiveTime = type(uint256).max;

    uint256 public maxApesPerWallet = 20;
    uint256 public apePrice = 0.0069 ether;
    uint256 public saleActiveTime = type(uint256).max;

    uint256 public constant maxSupply = 8888;

    uint256 public reservedApes = 444;

    string apeMetadataURI;

    function buyApes(uint256 _apesQty) external payable saleActive(saleActiveTime) callerIsUser mintLimit(_apesQty, maxApesPerWallet) priceAvailable(_apesQty) apesAvailable(_apesQty) {
        require(_totalMinted() >= freeApes, "Why pay for Apes when you can get them for free.");

        _mint(msg.sender, _apesQty);
    }

    function buyApesFree(uint256 _apesQty) external saleActive(freeSaleActiveTime) callerIsUser mintLimit(_apesQty, freeMaxApesPerWallet) apesAvailable(_apesQty) {
        require(_totalMinted() < freeApes, "Max free limit reached");

        _mint(msg.sender, _apesQty);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setApePrice(uint256 _newPrice) external onlyOwner {
        apePrice = _newPrice;
    }

    function setFreeApes(uint256 _freeApes) external onlyOwner {
        freeApes = _freeApes;
    }

    function setReservedApes(uint256 _reservedApes) external onlyOwner {
        reservedApes = _reservedApes;
    }

    function setMaxApesPerWallet(uint256 _maxApesPerWallet, uint256 _freeMaxApesPerWallet) external onlyOwner {
        maxApesPerWallet = _maxApesPerWallet;
        freeMaxApesPerWallet = _freeMaxApesPerWallet;
    }

    function setSaleActiveTime(uint256 _saleActiveTime, uint256 _freeSaleActiveTime) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
    }

    function setApeMetadataURI(string memory _apeMetadataURI) external onlyOwner {
        apeMetadataURI = _apeMetadataURI;
    }

    function giftApes(address[] calldata _sendNftsTo, uint256 _apesQty) external onlyOwner apesAvailable(_sendNftsTo.length * _apesQty) {
        reservedApes -= _sendNftsTo.length * _apesQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _apesQty);
    }

    function _baseURI() internal view override returns (string memory) {
        return apeMetadataURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(block.timestamp > _saleActiveTime, "Please, come back when the sale goes live");
        _;
    }

    modifier mintLimit(uint256 _apesQty, uint256 _maxApesPerWallet) {
        require(_numberMinted(msg.sender) + _apesQty <= _maxApesPerWallet, "Max x wallet exceeded");
        _;
    }

    modifier apesAvailable(uint256 _apesQty) {
        require(_apesQty + totalSupply() + reservedApes <= maxSupply, "Sorry, we are sold out");
        _;
    }

    modifier priceAvailable(uint256 _apesQty) {
        require(msg.value == _apesQty * apePrice, "Please, send the exact amount of ETH");
        _;
    }

    // Auto Approve Marketplaces

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

contract FastFoodApesPresale is FastFoodApesSale {
    mapping(uint256 => uint256) public maxMintPresales;
    mapping(uint256 => uint256) public apePricePresales;
    mapping(uint256 => bytes32) public whitelistMerkleRoots;
    uint256 public presaleActiveTime = type(uint256).max;

    function inWhitelist(
        address _owner,
        bytes32[] memory _proof,
        uint256 _from,
        uint256 _to
    ) external view returns (uint256) {
        for (uint256 i = _from; i < _to; i++) if (_inWhitelist(_owner, _proof, i)) return i;
        return type(uint256).max;
    }

    function _inWhitelist(
        address _owner,
        bytes32[] memory _proof,
        uint256 _rootNumber
    ) private view returns (bool) {
        return MerkleProof.verify(_proof, whitelistMerkleRoots[_rootNumber], keccak256(abi.encodePacked(_owner)));
    }

    function buyApesWhitelist(
        uint256 _apesQty,
        bytes32[] calldata _proof,
        uint256 _rootNumber
    ) external payable callerIsUser apesAvailable(_apesQty) {
        require(block.timestamp > presaleActiveTime, "Please, come back when the presale goes live");
        require(_inWhitelist(msg.sender, _proof, _rootNumber), "Sorry, you are not allowed");
        require(msg.value == _apesQty * apePricePresales[_rootNumber], "Please, send the exact amount of ETH");
        require(_numberMinted(msg.sender) + _apesQty <= maxMintPresales[_rootNumber], "Max x wallet exceeded");

        _mint(msg.sender, _apesQty);
    }

    function setPresale(
        uint256 _rootNumber,
        bytes32 _whitelistMerkleRoot,
        uint256 _maxMintPresales,
        uint256 _apePricePresale
    ) external onlyOwner {
        maxMintPresales[_rootNumber] = _maxMintPresales;
        apePricePresales[_rootNumber] = _apePricePresale;
        whitelistMerkleRoots[_rootNumber] = _whitelistMerkleRoot;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime) external onlyOwner {
        presaleActiveTime = _presaleActiveTime;
    }
}

contract FastFoodApesStaking is FastFoodApesPresale {
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
        require(!staked[startTokenId], "Please, unstake the NFT first");
    }

    function stakeApes(uint256[] calldata _tokenIds, bool _stake) external onlyWhitelistedForStaking {
        for (uint256 i = 0; i < _tokenIds.length; i++) staked[_tokenIds[i]] = _stake;
    }
}

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract FastFoodApes is FastFoodApesStaking {}

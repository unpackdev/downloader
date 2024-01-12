// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

import "./Ownable.sol";
import "./ERC2981.sol";

contract MoonHedgehogsSale is
    ERC721A("MoonHedgehogs", "MH"),
    Ownable,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981
{
    // variables
   uint256 public constant maxSupply = 10000;
    uint256 public reservedHedgehogs = 500;

    uint256 public freeHedgehogs = 0;
    uint256 public freeMaxHedgehogsPerWallet = 0;
    uint256 public freeSaleActiveTime = type(uint256).max;

    uint256 public firstFreeMints = 1;
    uint256 public maxHedgehogsPerWallet = 2;
    uint256 public hedgehogsPrice = 0.01 ether;
    uint256 public saleActiveTime = type(uint256).max;

    string hedgehogsMetadataURI;

    // these lines are called only once when the contract is deployed
    constructor() {
        autoApproveMarketplace(0x1E0049783F008A0085193E00003D00cd54003c71); // OpenSea
        autoApproveMarketplace(0xDef1C0ded9bec7F1a1670819833240f027b25EfF); // Coinbase
        autoApproveMarketplace(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e); // LooksRare
        autoApproveMarketplace(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be); // Rarible
        autoApproveMarketplace(0xF849de01B080aDC3A814FaBE1E2087475cF2E354); // X2y2
    }

    // airdrop Hedgehogs
    function giftHedgehogs(address[] calldata _sendNftsTo, uint256 _hedgehogsQty)
        external
        onlyOwner
        hedgehogsAvailable(_sendNftsTo.length * _hedgehogsQty)
    {
        reservedHedgehogs -= _sendNftsTo.length * _hedgehogsQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _hedgehogsQty);
    }

    // buy / mint Hedgehogs here
    function buyHedgehogs(uint256 _hedgehogsQty)
        external
        payable
        saleActive(saleActiveTime)
        callerIsUser
        mintLimit(_hedgehogsQty, maxHedgehogsPerWallet)
        priceAvailableFirstNftFree(_hedgehogsQty)
        hedgehogsAvailable(_hedgehogsQty)
    {
        require(
            _totalMinted() >= freeHedgehogs,
            "Get your MoonHedgehogs for free"
        );

        _mint(msg.sender, _hedgehogsQty);
    }

    function buyHedgehogsFree(uint256 _hedgehogsQty)
        external
        saleActive(freeSaleActiveTime)
        callerIsUser
        mintLimit(_hedgehogsQty, freeMaxHedgehogsPerWallet)
        hedgehogsAvailable(_hedgehogsQty)
    {
        require(
            _totalMinted() < freeHedgehogs,
            "MoonHedgehogs max free limit reached"
        );

        _mint(msg.sender, _hedgehogsQty);
    }

    // withdraw
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // setters
    function setHedgehogsPrice(uint256 _newPrice) external onlyOwner {
        hedgehogsPrice = _newPrice;
    }

    function setFreeHedgehogs(uint256 _freeHedgehogs) external onlyOwner {
        freeHedgehogs = _freeHedgehogs;
    }

    function setFirstFreeMints(uint256 _firstFreeMints) external onlyOwner {
        firstFreeMints = _firstFreeMints;
    }

    function setReservedHedgehogs(uint256 _reservedHedgehogs) external onlyOwner {
        reservedHedgehogs = _reservedHedgehogs;
    }

    function setMaxHedgehogsPerWallet(
        uint256 _maxHedgehogsPerWallet,
        uint256 _freeMaxHedgehogsPerWallet
    ) external onlyOwner {
        maxHedgehogsPerWallet = _maxHedgehogsPerWallet;
        freeMaxHedgehogsPerWallet = _freeMaxHedgehogsPerWallet;
    }

    function setSaleActiveTime(
        uint256 _saleActiveTime,
        uint256 _freeSaleActiveTime
    ) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
    }

    function setHedgehogsMetadataURI(string memory _hedgehogsMetadataURI)
        external
        onlyOwner
    {
        hedgehogsMetadataURI = _hedgehogsMetadataURI;
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // system related
    function _baseURI() internal view override returns (string memory) {
        return hedgehogsMetadataURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // helper modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a smart contract");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(
            block.timestamp > _saleActiveTime,
            "Nope, sale is not open"
        );
        _;
    }

    modifier mintLimit(uint256 _hedgehogsQty, uint256 _maxHedgehogsPerWallet) {
        require(
            _numberMinted(msg.sender) + _hedgehogsQty <= _maxHedgehogsPerWallet,
            "MoonHedgehogs max x wallet exceeded"
        );
        _;
    }

    modifier hedgehogsAvailable(uint256 _hedgehogsQty) {
        require(
            _hedgehogsQty + totalSupply() + reservedHedgehogs <= maxSupply,
            "We are currently sold out"
        );
        _;
    }

    modifier priceAvailable(uint256 _hedgehogsQty) {
        require(
            msg.value == _hedgehogsQty * hedgehogsPrice,
            "Hey hey, send the right amount of ETH"
        );
        _;
    }

    function getPrice(uint256 _qty) public view returns (uint256 price) {
        uint256 minted = _numberMinted(msg.sender) + _qty;
        if (minted > firstFreeMints) price = (minted - firstFreeMints) * hedgehogsPrice;
    }

    modifier priceAvailableFirstNftFree(uint256 _hedgehogsQty) {
        require(
            msg.value == getPrice(_hedgehogsQty),
            "Hey hey, send the right amount of ETH"
        );
        _;
    }

    // MoonHedgehogs auto approves marketplaces
    mapping(address => bool) private allowed;

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A, IERC721)
        returns (bool)
    {
        if (
            _operator ==
            OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner)
        ) return true;
        else if (allowed[_operator]) return true; // opensea or any other marketplace
        return super.isApprovedForAll(_owner, _operator);
    }
}

contract MoonHedgehogsStaking is MoonHedgehogsSale {
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
        require(!staked[startTokenId], "Nope, unstake your MoonHedgehogs first");
    }

    function stakeHedgehogs(uint256[] calldata _tokenIds, bool _stake)
        external
        onlyWhitelistedForStaking
    {
        for (uint256 i = 0; i < _tokenIds.length; i++)
            staked[_tokenIds[i]] = _stake;
    }
}

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract MoonHedgehogs is MoonHedgehogsStaking {}

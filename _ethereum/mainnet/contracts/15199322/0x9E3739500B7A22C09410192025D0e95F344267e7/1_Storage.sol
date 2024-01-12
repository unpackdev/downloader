// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

import "./Ownable.sol";
import "./ERC2981.sol";

contract NftSale is
    ERC721A("Nft", "NFT"),
    Ownable,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981
{
    // Variables
    uint256 public constant maxSupply = 10000;
    uint256 public reservedNft = 500;

    uint256 public freeNft = 9000;
    uint256 public freeMaxNftPerWallet = 1;
    uint256 public freeSaleActiveTime = 0;

    uint256 public firstFreeMints = 1;
    uint256 public maxNftPerWallet = 2;
    uint256 public nftPrice = 0.01 ether;
    uint256 public saleActiveTime = type(uint256).max;

    string nftMetadataURI = 'ipfs://QmYPUsj8JHzrr2SBtppvj1EmmvU1wFf9TKSrkD7cxBYhhY/';

    // these lines are called only once when the contract is deployed
    constructor() {
        approveSpender(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e); // LooksRare
        approveSpender(0xDef1C0ded9bec7F1a1670819833240f027b25EfF); // Coinbase
        approveSpender(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be); // Rarible
        approveSpender(0xF849de01B080aDC3A814FaBE1E2087475cF2E354); // X2y2
        approveSpender(0x1E0049783F008A0085193E00003D00cd54003c71); // OpenSea
    }

    // setters
    function setNftPrice(uint256 _newPrice) external onlyOwner {
        nftPrice = _newPrice;
    }

    function setFreeNft(uint256 _freeNft) external onlyOwner {
        freeNft = _freeNft;
    }

    function setFirstFreeMints(uint256 _firstFreeMints) external onlyOwner {
        firstFreeMints = _firstFreeMints;
    }

    function setReservedNft(uint256 _reservedNft) external onlyOwner {
        reservedNft = _reservedNft;
    }

    // Airdrop Nft
    function giftNft(address[] calldata _sendNftsTo, uint256 _nftQty)
        external
        onlyOwner
        nftAvailable(_sendNftsTo.length * _nftQty)
    {
        reservedNft -= _sendNftsTo.length * _nftQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _nftQty);
    }

    // buy / mint Nft Nfts here
    function buyNft(uint256 _nftQty)
        external
        payable
        saleActive(saleActiveTime)
        callerIsUser
        mintLimit(_nftQty, maxNftPerWallet)
        priceAvailableFirstNftFree(_nftQty)
        nftAvailable(_nftQty)
    {
        require(_totalMinted() >= freeNft, "Get your Nft for free");

        _mint(msg.sender, _nftQty);
    }

    function buyNftFree(uint256 _nftQty)
        external
        saleActive(freeSaleActiveTime)
        callerIsUser
        mintLimit(_nftQty, freeMaxNftPerWallet)
        nftAvailable(_nftQty)
    {
        require(_totalMinted() < freeNft, "Nft max free limit reached");

        _mint(msg.sender, _nftQty);
    }

    // withdraw eth
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxNftPerWallet(
        uint256 _maxNftPerWallet,
        uint256 _freeMaxNftPerWallet
    ) external onlyOwner {
        maxNftPerWallet = _maxNftPerWallet;
        freeMaxNftPerWallet = _freeMaxNftPerWallet;
    }

    function setSaleActiveTime(
        uint256 _saleActiveTime,
        uint256 _freeSaleActiveTime
    ) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
    }

    function setNftMetadataURI(string memory _nftMetadataURI)
        external
        onlyOwner
    {
        nftMetadataURI = _nftMetadataURI;
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // System Related
    function _baseURI() internal view override returns (string memory) {
        return nftMetadataURI;
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

    // Helper Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(block.timestamp > _saleActiveTime, "Nope, sale is not open");
        _;
    }

    modifier mintLimit(uint256 _nftQty, uint256 _maxNftPerWallet) {
        require(
            _numberMinted(msg.sender) + _nftQty <= _maxNftPerWallet,
            "Nft max x wallet exceeded"
        );
        _;
    }

    modifier nftAvailable(uint256 _nftQty) {
        require(
            _nftQty + totalSupply() + reservedNft <= maxSupply,
            "Hmm, we are sold out"
        );
        _;
    }

    modifier priceAvailable(uint256 _nftQty) {
        require(
            msg.value == _nftQty * nftPrice,
            "Send the right amount of ETH"
        );
        _;
    }

    function getPrice(uint256 _qty) public view returns (uint256 price) {
        uint256 minted = _numberMinted(msg.sender) + _qty;
        if (minted > firstFreeMints)
            price = (minted - firstFreeMints) * nftPrice;
    }

    modifier priceAvailableFirstNftFree(uint256 _nftQty) {
        require(msg.value == getPrice(_nftQty), "Send the right amount of ETH");
        _;
    }

    // Nft Auto Approves Marketplaces
    mapping(address => bool) private allowed;

    function approveSpender(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A, IERC721)
        returns (bool)
    {
        if (allowed[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
}

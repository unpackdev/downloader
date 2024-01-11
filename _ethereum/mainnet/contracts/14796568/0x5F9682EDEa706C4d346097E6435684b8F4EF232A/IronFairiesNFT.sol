// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./ERC721A.sol";


contract IronFairiesNFT is ERC721A, Ownable, ReentrancyGuard, AccessControl{
    using Counters for Counters.Counter;

    uint8 MAX_MINTS = 50;
    uint16 MAX_SUPPLY = 9999;
    uint16 MAX_PRIVATESALE_SUPPLY = 300;
    uint16 MAX_PUBLICSALE_SUPPLY = 9200;
    uint256 public presaleCost = 0.40 ether;
    uint256 public publicsaleCost = 0.45 ether;

    string public contractURI;
    string public baseURI;
    uint96 royaltyFeesInBips;
    address royaltyAddress;
    Counters.Counter private privateSaleCounters;
    Counters.Counter private publicSaleCounters;

    address payable _owner;
    bool private _paused;
    bool private _pausedPublicSale;
    bool private _pausedPrivateSale;

    bytes32 public constant NFT_ADMIN = keccak256("NFT_ADMIN");

    constructor(
        uint96 _royaltyFeesInBips, 
        string memory _contractURI, 
        string memory _baseURIstring,
        uint16 _initialMint
    ) ERC721A("IronFairiesNFT", "IFN") {
        royaltyFeesInBips = _royaltyFeesInBips;
        royaltyAddress = owner();
        contractURI = _contractURI;
        baseURI = _baseURIstring;

        _owner = payable(msg.sender);
        _safeMint(msg.sender, _initialMint);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier whenNotPaused() {
        require(!_paused, "[IronFairiesNFT.whenNotPaused] Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "[IronFairiesNFT.whenPaused] Not Paused");
        _;
    }

    modifier whenPublicSaleNotPaused() {
        require(!_pausedPublicSale, "[IronFairiesNFT.whenPublicSaleNotPaused] Public Sale Paused");
        _;
    }

    modifier whenPublicSalePaused() {
        require(_pausedPublicSale, "[IronFairiesNFT.whenPublicSalePaused] Public Sale Not Paused");
        _;
    }

    modifier whenPrivateSaleNotPaused() {
        require(!_pausedPrivateSale, "[IronFairiesNFT.whenPrivateSaleNotPaused] Private Sale Paused");
        _;
    }

    modifier whenPrivateSalePaused() {
        require(_pausedPrivateSale, "[IronFairiesNFT.whenPrivateSalePaused] Private Sale Not Paused");
        _;
    }

    function mintPrivateSale(uint8 quantity) external payable nonReentrant whenPrivateSaleNotPaused{
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= presaleCost * quantity);
        require(privateSaleCounters.current() < MAX_PRIVATESALE_SUPPLY);
                
        _owner.transfer(presaleCost * quantity);
        privateSaleCounters.increment();

        _safeMint(msg.sender, quantity);
    }

    function mintPublicSale(uint8 quantity) external payable nonReentrant whenPublicSaleNotPaused {
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= publicsaleCost * quantity);
        require(publicSaleCounters.current() < MAX_PUBLICSALE_SUPPLY);

        _owner.transfer(publicsaleCost * quantity);
        publicSaleCounters.increment();

        _safeMint(msg.sender, quantity);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner whenNotPaused{
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner whenNotPaused{
        contractURI = _contractURI;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice) view public whenNotPaused returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev Set tokenURI of NFT's Metadata
     * @param _baseURIstring - token uri you want to set
     */
    function setBaseURI(string memory _baseURIstring) public onlyOwner whenNotPaused{
        baseURI = _baseURIstring;
    }

    /**
     * @dev Get baseTokenURI of Metadata
     * @return baseTokenURI value 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev burn NFT of given token id
     * @param _tokenId - token id of specific NFT
     */
    function burnNFT(uint256 _tokenId) public whenNotPaused onlyRole(NFT_ADMIN){
        _burn(_tokenId);
    }

    function setPublicCost(uint256 _newCost) public onlyOwner whenPaused {
        publicsaleCost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner whenPaused {
        presaleCost = _newCost;
    }

    function totalPublicSaleMint() public view returns (uint256) {
        return publicSaleCounters.current();
    }

    function totalPrivateSaleMint() public view returns (uint256) {
        return privateSaleCounters.current();
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
    }

    function pausePublicSale() external onlyOwner whenPublicSaleNotPaused {
        _pausedPublicSale = true;
    }

    function unpausePublicSale() external onlyOwner whenPublicSalePaused {
        _pausedPublicSale = false;
    }

    function pausePrivateSale() external onlyOwner whenPrivateSaleNotPaused {
        _pausedPrivateSale = true;
    }

    function unpausePrivateSale() external onlyOwner whenPrivateSalePaused {
        _pausedPrivateSale = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
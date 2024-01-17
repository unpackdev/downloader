// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// @author Yumenosuke Kokata (Founder / CTO of NEXUM)
// @title EDUCATION PASSPORT NFT

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC2981Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract EPASSVer1 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using MerkleProofUpgradeable for bytes32[];
    using StringsUpgradeable for uint256;

    function initialize() public initializer {
        __ERC721_init("EDUCATION PASSPORT NFT", "EPASS");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();

        // set correct values from deploy script!
        mintLimit = 0;
        isPublicMintPaused = true;
        isAllowlistMintPaused = true;
        publicPrice = 1 ether;
        allowListPrice = 0.01 ether;
        allowlistedMemberMintLimit = 1;
        contractURI = "";
        _tokenURI = "";
        _royaltyFraction = 0;
        _royaltyReceiver = msg.sender;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////
    //// ERC2981
    ///////////////////////////////////////////////////////////////////

    uint96 private _royaltyFraction;

    /**
     * @dev set royalty in percentage x 100. e.g. 5% should be 500.
     */
    function setRoyaltyFraction(uint96 royaltyFraction) external onlyOwner {
        _royaltyFraction = royaltyFraction;
    }

    address private _royaltyReceiver;

    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _royaltyReceiver = receiver;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        checkTokenIdExists(tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyFraction) / 10_000;
    }

    ///////////////////////////////////////////////////////////////////
    //// URI
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Token URI
    //////////////////////////////////

    string private _tokenURI;

    function setTokenURI(string memory tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        checkTokenIdExists(tokenId)
        returns (string memory)
    {
        return _tokenURI;
    }

    //////////////////////////////////
    //// Contract URI
    //////////////////////////////////

    string public contractURI;

    function setContractURI(string memory contractURI_) external onlyOwner {
        contractURI = contractURI_;
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Tokens
    ///////////////////////////////////////////////////////////////////

    CountersUpgradeable.Counter private _tokenIdCounter;

    function _safeMintTokens(address to, uint256 quantity) private checkMintLimit(quantity) {
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current()); // tokenId starts from 1
        }
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    mapping(address => uint256) allowListMemberMintCount;

    function allowlistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        whenAllowlistMintNotPaused
        checkAllowlist(merkleProof)
        checkAllowlistMintLimit(quantity)
        checkPay(allowListPrice, quantity)
    {
        _incrementNumberAllowlistMinted(msg.sender, quantity);
        _safeMintTokens(msg.sender, quantity);
    }

    function numberAllowlistMinted(address owner) public view returns (uint256) {
        return allowListMemberMintCount[owner];
    }

    function _incrementNumberAllowlistMinted(address owner, uint256 quantity) private {
        allowListMemberMintCount[owner] += quantity;
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    function publicMint(uint256 quantity) external payable whenPublicMintNotPaused checkPay(publicPrice, quantity) {
        _safeMintTokens(msg.sender, quantity);
    }

    //////////////////////////////////
    //// Admin Mint
    //////////////////////////////////

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMintTokens(msg.sender, quantity);
    }

    function adminMintTo(address to, uint256 quantity) external onlyOwner {
        _safeMintTokens(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Limit
    ///////////////////////////////////////////////////////////////////

    uint256 public mintLimit;

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    modifier checkMintLimit(uint256 quantity) {
        require(_tokenIdCounter.current() + quantity <= mintLimit, "minting exceeds the limit");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pricing
    ///////////////////////////////////////////////////////////////////

    uint256 public allowListPrice;

    function setAllowListPrice(uint256 allowListPrice_) external onlyOwner {
        allowListPrice = allowListPrice_;
    }

    uint256 public publicPrice;

    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    modifier checkPay(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "not enough eth");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Allowlist
    ///////////////////////////////////////////////////////////////////

    bytes32 private _merkleRoot;

    function setAllowlist(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    uint256 public allowlistedMemberMintLimit;

    function setAllowlistedMemberMintLimit(uint256 quantity) external onlyOwner {
        allowlistedMemberMintLimit = quantity;
    }

    function isAllowlisted(bytes32[] calldata merkleProof) public view returns (bool) {
        return merkleProof.verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    modifier checkAllowlist(bytes32[] calldata merkleProof) {
        require(isAllowlisted(merkleProof), "invalid merkle proof");
        _;
    }

    modifier checkAllowlistMintLimit(uint256 quantity) {
        require(
            numberAllowlistMinted(msg.sender) + quantity <= allowlistedMemberMintLimit,
            "WL minting exceeds the limit"
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pausing
    ///////////////////////////////////////////////////////////////////

    event PublicMintPaused();
    event PublicMintUnpaused();
    event AllowlistMintPaused();
    event AllowlistMintUnpaused();

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    bool public isPublicMintPaused;

    function pausePublicMint() external onlyOwner whenPublicMintNotPaused {
        isPublicMintPaused = true;
        emit PublicMintPaused();
    }

    function unpausePublicMint() external onlyOwner whenPublicMintPaused {
        isPublicMintPaused = false;
        emit PublicMintUnpaused();
    }

    modifier whenPublicMintNotPaused() {
        require(!isPublicMintPaused, "public mint: paused");
        _;
    }

    modifier whenPublicMintPaused() {
        require(isPublicMintPaused, "public mint: not paused");
        _;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    bool public isAllowlistMintPaused;

    function pauseAllowlistMint() external onlyOwner whenAllowlistMintNotPaused {
        isAllowlistMintPaused = true;
        emit AllowlistMintPaused();
    }

    function unpauseAllowlistMint() external onlyOwner whenAllowlistMintPaused {
        isAllowlistMintPaused = false;
        emit AllowlistMintUnpaused();
    }

    modifier whenAllowlistMintNotPaused() {
        require(!isAllowlistMintPaused, "allowlist mint: paused");
        _;
    }

    modifier whenAllowlistMintPaused() {
        require(isAllowlistMintPaused, "allowlist mint: not paused");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Withdraw
    ///////////////////////////////////////////////////////////////////

    address[] private _distributees;
    uint256 private _distributionRate;

    /**
     * @dev configure distribution settings.
     * max distributionRate should be 10_000 and it means 100% balance of this contract.
     * e.g. set 500 to deposit 5% to every distributee.
     */
    function setDistribution(address[] calldata distributees, uint256 distributionRate) external onlyOwner {
        require(distributionRate * distributees.length <= 10_000, "too much distribution rate");
        _distributees = distributees;
        _distributionRate = distributionRate;
    }

    function getDistribution()
        external
        view
        onlyOwner
        returns (address[] memory distributees, uint256 distributionRate)
    {
        distributees = _distributees;
        distributionRate = _distributionRate;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        uint256 distribution = (amount * _distributionRate) / 10_000;
        for (uint256 index = 0; index < _distributees.length; index++) {
            payable(_distributees[index]).transfer(distribution);
        }
        uint256 amountLeft = amount - distribution * _distributees.length;
        payable(msg.sender).transfer(amountLeft);
    }

    ///////////////////////////////////////////////////////////////////
    //// Admin Force Transfer
    ///////////////////////////////////////////////////////////////////

    function adminForceTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _safeTransfer(from, to, tokenId, "");
    }

    ///////////////////////////////////////////////////////////////////
    //// Utilities
    ///////////////////////////////////////////////////////////////////

    modifier checkTokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenId not exist");
        _;
    }
}

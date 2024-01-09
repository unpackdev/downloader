// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IAllowlist.sol";
import "./IRandom.sol";

contract RetroPhones is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    IAllowlist public allowlist;
    bytes32 public PROVENANCE_HASH = "";
    uint256 public MAX_RETROPHONES = 10000;
    uint256 public OFFSET_VALUE = 0;
    bool public METADATA_FROZEN = false;
    bool public PROVENANCE_FROZEN = false;

    string public baseUri = "";
    bool public presaleIsActive = false;
    bool public saleIsActive = false;
    uint256 public mintPrice = 0.08 ether;
    uint256 public mintPriceAllowlist = 0.0555 ether;
    uint256 public maxPerMint = 5;
    uint256 public maxPerAllowlistAddr = 2;
    address public randomNumberProvider;
    bool internal _randomNumberRequested = false;
    address internal _royaltyFeeRecipient;
    uint8 internal _royaltyFee; // out of 1000

    Counters.Counter private _tokenIdCounter;

    event SetBaseUri(string indexed baseUri);

    constructor(address _allowlist, address _randomNumberProvider) ERC721("RetroPhones", "RTP") {
        allowlist = IAllowlist(_allowlist);
        randomNumberProvider = _randomNumberProvider;
    }

    modifier whenMetadataNotFrozen() {
        require(!METADATA_FROZEN, "RetroPhones: Metadata already frozen.");
        _;
    }

    modifier whenProvenanceNotFrozen() {
        require(!PROVENANCE_FROZEN, "RetroPhones: Provenance already frozen.");
        _;
    }

    modifier whenPreSaleIsActive() {
        require(presaleIsActive, "RetroPhones: Presale is not active");
        _;
    }

    modifier whenSaleIsActive() {
        require(saleIsActive, "RetroPhones: Sale is not active");
        _;
    }

    // ------------------
    // Mint functions
    // ------------------

    function mintRetroPhonesAllowlist(uint256 amount) external payable whenPreSaleIsActive {
        require(allowlist.allowlist(msg.sender), "RetroPhones: Not on the allowlist.");
        require(
            balanceOf(msg.sender) + amount <= maxPerAllowlistAddr,
            "RetroPhones: Amount exceeds max per allowlist address."
        );
        require(_tokenIdCounter.current() + amount <= MAX_RETROPHONES, "RetroPhones: Purchase would exceed cap.");
        require(mintPriceAllowlist * amount <= msg.value, "RetroPhones: Ether value sent is not correct.");

        _mintMultiple(msg.sender, amount);
    }

    function mintRetroPhones(uint256 amount) external payable whenSaleIsActive {
        require(amount <= maxPerMint, "RetroPhones: Amount exceeds max per mint.");
        require(_tokenIdCounter.current() + amount <= MAX_RETROPHONES, "RetroPhones: Purchase would exceed cap.");
        require(mintPrice * amount <= msg.value, "RetroPhones: Ether value sent is not correct.");

        _mintMultiple(msg.sender, amount);
    }

    function mintForCommunity(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "RetroPhones: Cannot mint to zero address.");
        require(
            _tokenIdCounter.current() + _numberOfTokens <= MAX_RETROPHONES,
            "RetroPhones: Minting would exceed cap."
        );

        _mintMultiple(_to, _numberOfTokens);
    }

    function _mintMultiple(address _to, uint256 _numberOfTokens) internal {
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            if (_tokenIdCounter.current() <= MAX_RETROPHONES) {
                _safeMint(_to, tokenId);
            }
        }
    }

    // ------------------
    // EIP-2981 Royalty Fee Info
    // ------------------

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount;
        if (_royaltyFee != type(uint8).max) royaltyAmount = (_salePrice * _royaltyFee) / 1000;
        return (_royaltyFeeRecipient, royaltyAmount);
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    // ------------------
    // Functions for the owner
    // ------------------

    function setMaxPerAllowlistAddr(uint256 _maxPerAllowlistAddr) external onlyOwner {
        maxPerAllowlistAddr = _maxPerAllowlistAddr;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMintPriceAllowlist(uint256 _mintPriceAllowlist) external onlyOwner {
        mintPriceAllowlist = _mintPriceAllowlist;
    }

    function setAllowlistAddress(address _allowlist) external onlyOwner {
        allowlist = IAllowlist(_allowlist);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataNotFrozen {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setProvenanceHash(bytes32 _provenanceHash) external onlyOwner whenProvenanceNotFrozen {
        PROVENANCE_HASH = _provenanceHash;
    }

    function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function freezeMetadata() external onlyOwner whenMetadataNotFrozen {
        require(bytes(baseUri).length != 0, "RetroPhones: BaseURI not set yet.");
        METADATA_FROZEN = true;
    }

    function freezeProvenance() external onlyOwner whenProvenanceNotFrozen {
        require(PROVENANCE_HASH != 0, "RetroPhones: Provenance hash not set yet.");
        PROVENANCE_FROZEN = true;
    }

    /**
     Called by the owner to finanlize the token sale.
     Requests a random number from chainlink to determine a truly random offset
     @param reduceMax If the sale should be finanlized before all phones are sold
       this parameter could be used to reduce the maximum number of phones available
     */
    function finalizeSale(uint256 reduceMax) external onlyOwner {
        //---------
        // Checks
        //---------

        require(!_randomNumberRequested, "RetroPhones: Random number for offset already requested.");
        require(PROVENANCE_HASH != 0, "RetroPhones: PROVENANCE_HASH needs to be set.");
        require(
            _tokenIdCounter.current() + reduceMax == MAX_RETROPHONES,
            "RetroPhones: reduceMax needs to be the difference of token minted so far and MAX_RETROPHONES."
        );

        //---------
        // Interaction: Send random number request
        //---------

        // Get fee information from randomness provider
        IRandom.Chainlink memory chainlinkInfo = IRandom(randomNumberProvider).chainlink();
        IERC20 link = IERC20(chainlinkInfo.link);
        uint256 fee = chainlinkInfo.fee;

        // Allow LINK token so fee can be deducted
        require(link.balanceOf(address(this)) >= fee, "RetroPhones: Not enough LINK to request randomness.");
        link.approve(randomNumberProvider, fee);

        // Request random number with provenance hash as id
        IRandom(randomNumberProvider).random(PROVENANCE_HASH);

        //---------
        // State changes
        //---------

        presaleIsActive = false;
        saleIsActive = false;
        _randomNumberRequested = true;
        if (reduceMax > 0) {
            MAX_RETROPHONES -= reduceMax;
        }
    }

    /**
      Needs to be called after the random number requested by
      finalizeSale() was provided by chainlink
     */
    function randomNumberToOffset() external onlyOwner {
        require(_randomNumberRequested, "RetroPhones: Random number not requested yet.");
        require(PROVENANCE_HASH != 0, "RetroPhones: PROVENANCE_HASH needs to be set.");
        OFFSET_VALUE = IRandom(randomNumberProvider).asRange(PROVENANCE_HASH, 1, MAX_RETROPHONES);
    }

    function setRoyaltyFeeRecipient(address royaltyFeeRecipient) public onlyOwner {
        _setRoyaltyFeeRecipient(royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 royaltyFee) public onlyOwner {
        _setRoyaltyFee(royaltyFee);
    }

    function _setRoyaltyFeeRecipient(address royaltyFeeRecipient) internal {
        require(royaltyFeeRecipient != address(0), "RetroPhones: INVALID_FEE_RECIPIENT");
        _royaltyFeeRecipient = royaltyFeeRecipient;
    }

    function _setRoyaltyFee(uint8 royaltyFee) internal {
        _royaltyFee = royaltyFee;
    }

    // ------------------
    // Withdraw functions
    // ------------------

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to the 0 address.");
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function withdrawTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot withdraw tokens to the 0 address.");
        token.transfer(receiver, amount);
    }

    // ------------------
    // Utility functions
    // ------------------

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}

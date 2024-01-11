// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

import "./EIP712Allowlisting.sol";

error MaxSupplyExceeded();
error ClaimLimitExceeded();
error AllowlistDisabled();
error PublicDisabled();
error NonEOADisabled();

/// @title Membership NFT
/// @notice Membership contract with public sale
contract Membership is ERC721A, Ownable, EIP712Allowlisting {
    using Strings for uint256; /*String library allows for token URI concatenation*/

    string public contractURI; /*contractURI contract metadata json*/
    string public baseURI; /*baseURI_ String to prepend to token IDs*/

    uint256 public maxSupply;
    uint256 public limitPerPurchase; /*Max amount of tokens someone can buy in one transaction*/
    uint256 public limitPerAddress; /*Max amount of tokens an address can claim*/

    bool public allowlistEnabled; /*Minting enabled for wallets on allowlist*/
    bool public publicEnabled; /*Mintin enabled for all wallets*/

    mapping(address => uint256) public claimed; /*Track number of tokens claimed per address*/

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert NonEOADisabled();
        _;
    }

    /// @notice setup configures interfaces and production metadata
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param _contractURI Metadata location for contract
    /// @param baseURI_ Metadata location for tokens
    /// @param _maxSupply Max supply for this token
    constructor(
        string memory name_,
        string memory symbol_,
        string memory _contractURI,
        string memory baseURI_,
        uint256 _limitPerPurchase,
        uint256 _limitPerAddress,
        uint256 _maxSupply
    ) ERC721A(name_, symbol_) EIP712Allowlisting(name_) {
        baseURI = baseURI_;
        contractURI = _contractURI; /*Contract URI for marketplace metadata*/
        maxSupply = _maxSupply;
        limitPerPurchase = _limitPerPurchase;
        limitPerAddress = _limitPerAddress;
    }

    /// @notice Mint by allowlist
    /// @dev Allowlist must be enabled
    /// @param _qty How many tokens to claim
    /// @param _nonce Signature nonce
    /// @param _signature Authorization signature
    function mintAllowList(
        uint256 _qty,
        uint256 _nonce,
        bytes calldata _signature
    ) external requiresAllowlist(_signature, _nonce) {
        if (!allowlistEnabled) revert AllowlistDisabled();
        _claim(_qty, msg.sender);
    }

    /// @notice Mint by anyone
    /// @dev Public must be enabled
    /// @param _qty How many tokens to claim
    function mintPublic(uint256 _qty) external callerIsUser {
        if (!publicEnabled) revert PublicDisabled();
        _claim(_qty, msg.sender);
    }

    /// @notice Mint by admin
    /// @param _qty How many tokens to claim
    function mintReserve(uint256 _qty, address _dst) external onlyOwner {
        if ((totalSupply() + _qty) > maxSupply) revert MaxSupplyExceeded(); /*Check against max supply*/
        _safeMint(_dst, _qty); /*Send token to new recipient*/
    }

    function _claim(uint256 _qty, address _dst) internal {
        if ((totalSupply() + _qty) > maxSupply) revert MaxSupplyExceeded(); /*Check against max supply*/
        if (_qty > limitPerPurchase) revert ClaimLimitExceeded();
        if (claimed[msg.sender] >= limitPerAddress) revert ClaimLimitExceeded();

        claimed[msg.sender] += _qty; /*Track how many an address has claimed*/

        _safeMint(_dst, _qty); /*Send token to new recipient*/
    }

    /*****************
    CONFIG FUNCTIONS
    *****************/
    /// @notice Set new base URI for token IDs
    /// @param baseURI_ String to prepend to token IDs
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Set new contract URI
    /// @param _contractURI Contract metadata json
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice Set max tokens per address
    /// @param _numTokens Amount of tokens each address can claim
    function setLimitPerAddress(uint256 _numTokens) external onlyOwner {
        limitPerAddress = _numTokens;
    }

    /// @notice Set who can claim tokens
    /// @param _allowlistEnabled True if allowlist can claim
    /// @param _publicEnabled True if public can claim
    function setClaimState(bool _allowlistEnabled, bool _publicEnabled)
        external
        onlyOwner
    {
        allowlistEnabled = _allowlistEnabled;
        publicEnabled = _publicEnabled;
    }

    /*****************
    Public interfaces
    *****************/
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    ///@dev Support interfaces for Access Control and ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

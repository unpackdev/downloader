//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./Token.sol";
import "./Vault.sol";
import "./Treasury.sol";
import "./Marketer.sol";

import "./Submissions.sol";

contract Uniquettes is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Common
{
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Uniquette {
        uint256 tokenId;
        address owner;
        uint256 collateralValue;
        uint256 lastPurchaseAmount;
    }

    event UniquetteRejected(address approver, address indexed submitter, string hash);
    event UniquetteCollected(
        address operator,
        address indexed seller,
        address indexed collector,
        uint256 indexed tokenId,
        uint256 effectivePrice,
        uint256 appreciatedPrice,
        uint256 principalAmount
    );
    event UniquetteCollateralIncreased(
        address indexed operator,
        address indexed owner,
        uint256 indexed tokenId,
        uint256 additionalCollateral
    );
    event ProtocolFeePaid(
        address indexed operator,
        address seller,
        address indexed collector,
        uint256 indexed tokenId,
        uint256 feePaid
    );

    Token private _token;
    Vault private _vault;
    Treasury private _treasury;
    Marketer private _marketer;

    mapping(uint256 => Uniquette) internal _uniquettes;

    CountersUpgradeable.Counter private _tokenIdTracker;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __Uniquettes_init(
        string memory name,
        string memory symbol,
        address token,
        address payable vault,
        address payable treasury,
        address payable marketer
    ) internal initializer {
        __ERC721_init_unchained(name, symbol);
        __Uniquettes_init_unchained(name, symbol, token, vault, treasury, marketer);
    }

    function __Uniquettes_init_unchained(
        string memory name,
        string memory symbol,
        address token,
        address payable vault,
        address payable treasury,
        address payable marketer
    ) internal initializer {
        _token = Token(token);
        _vault = Vault(vault);
        _treasury = Treasury(treasury);
        _marketer = Marketer(marketer);
    }

    //
    // Modifiers
    //
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId) && _uniquettes[tokenId].tokenId > 0, "UNIQUETTES/DOES_NOT_EXIST");
        _;
    }

    //
    // Generic and standard functions
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //
    // Admin functions
    //
    function pause() public virtual isGovernor() {
        _pause();
    }

    function unpause() public virtual isGovernor() {
        _unpause();
    }

    function setTokenAddress(address newAddress) public isGovernor() {
        _token = Token(newAddress);
    }

    function setVaultAddress(address payable newAddress) public isGovernor() {
        _vault = Vault(newAddress);
    }

    function setTreasuryAddress(address payable newAddress) public virtual isGovernor() {
        _treasury = Treasury(newAddress);
    }

    function setMarketerAddress(address payable newAddress) public isGovernor() {
        _marketer = Marketer(newAddress);
    }

    //
    // Customized ERC-721 functions
    //
    function burn(uint256 tokenId) public virtual isGovernor() {
        Uniquette memory uniquette = _uniquettes[tokenId];
        require(
            // It must be owned by Vault which means it's liquidated and currently locked in Vault
            (uniquette.owner == address(_vault)),
            "UNIQUETTES/NOT_OWNED_BY_VAULT"
        );

        _burn(tokenId);
    }

    function batchBurn(uint256[] calldata tokenIds) public virtual isGovernor() {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 id = tokenIds[i];
            this.burn(id);
        }
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return (// Transfers must be either operated by governor (when approving a submission)
        hasRole(GOVERNOR_ROLE, operator) ||
            // or, operated by marketer contract (when selling on an exchange)
            operator == address(_marketer) ||
            // or, operated by vault contract (when liquidating a uniquette)
            operator == address(_vault) ||
            // or, operator is approved during buy operation
            super.isApprovedForAll(account, operator));
    }

    // We need to override to remove "orOwner" since we should not allow transfers initiated directly by owners
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        tokenExists(tokenId)
        returns (bool)
    {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (getApproved(tokenId) == spender || this.isApprovedForAll(owner, spender));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable, ERC721EnumerableUpgradeable) {
        _uniquettes[tokenId].owner = to;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert("Directory: approve not supported on uniquette transfers");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("Directory: setApprovalForAll not supported on uniquette transfers");
    }

    //
    // Unique functions
    //
    function uniquetteGetById(uint256 tokenId) public view virtual tokenExists(tokenId) returns (Uniquette memory) {
        return _uniquettes[tokenId];
    }

    function uniquetteIncreaseCollateral(uint256 tokenId) public payable virtual tokenExists(tokenId) nonReentrant {
        payable(address(_vault)).sendValue(msg.value);

        _uniquettes[tokenId].collateralValue += msg.value;

        emit UniquetteCollateralIncreased(_msgSender(), _uniquettes[tokenId].owner, tokenId, msg.value);
    }

    //
    // Internal functions
    //
    function uniquetteMint() internal virtual returns (uint256) {
        // Issue a new token ID
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();

        _uniquettes[newTokenId].owner = address(_vault);
        _uniquettes[newTokenId].tokenId = newTokenId;
        _uniquettes[newTokenId].collateralValue = 0;
        _uniquettes[newTokenId].lastPurchaseAmount = 0;

        // Mint the new uniquette into Vault
        _mint(address(_vault), newTokenId);

        return newTokenId;
    }

    function uniquetteTakeOver(
        address operator,
        address to,
        uint256 tokenId,
        uint256 addedValue
    )
        internal
        virtual
        tokenExists(tokenId)
        returns (
            uint256 effectivePrice,
            uint256 appreciatedPrice,
            uint256 principalAmount,
            uint256 protocolFeeAmount
        )
    {
        require(to != address(0), "UNIQUETTES/COLLECT_TO_ZERO_ADDR");

        Uniquette memory uniquette = uniquetteGetById(tokenId);

        // Require some payment unless current owner is trying to fund a zero-value submission
        require(msg.value > 0 || (addedValue == 0 && operator == to && uniquette.owner == to), "UNIQUETTES/PAYMENT_REQUIRED");

        effectivePrice = calculateEffectivePrice(operator, to, uniquette);
        appreciatedPrice = effectivePrice + addedValue;
        protocolFeeAmount = (appreciatedPrice * _protocolFee) / 10000;
        principalAmount = msg.value - protocolFeeAmount;

        require(principalAmount >= appreciatedPrice, "UNIQUETTES/NOT_ENOUGH_PRINCIPAL");

        uint256 additionalCollateral = principalAmount - effectivePrice;

        require(appreciatedPrice >= effectivePrice, "UNIQUETTES/UNEXPECTED_DEPRECIATED_PRICE");
        require(additionalCollateral <= msg.value, "UNIQUETTES/UNEXPECTED_EXCESS_COLLATERAL");

        // Calculate extra ETH sent to be kept as collateral
        _uniquettes[tokenId].collateralValue += additionalCollateral;

        // Remember last amount this uniquette was sold for
        _uniquettes[tokenId].lastPurchaseAmount = appreciatedPrice;

        // Transfer ownership of uniquette in ERC-721 fashion (and remember the seller)
        address seller = uniquette.owner;

        _approve(operator, tokenId);
        _transfer(seller, to, tokenId);
        emit UniquetteCollected(operator, seller, to, tokenId, effectivePrice, appreciatedPrice, principalAmount);

        // Pay the protocol fee, move the collateral to Vault, pay the seller
        payable(address(_treasury)).sendValue(protocolFeeAmount);
        emit ProtocolFeePaid(operator, seller, to, tokenId, protocolFeeAmount);

        // Pay the previous owner (seller)
        payable(address(seller)).sendValue(effectivePrice);

        if (additionalCollateral > 0) {
            payable(address(_vault)).sendValue(additionalCollateral);
            emit UniquetteCollateralIncreased(operator, to, tokenId, additionalCollateral);
        }

        return (
            effectivePrice,
            appreciatedPrice,
            principalAmount,
            protocolFeeAmount
        );
    }

    function calculateEffectivePrice(address operator, address to, Uniquette memory uniquette) internal view virtual returns (uint256) {
        // If current owner is trying to fund a submission for their own uniquette
        // then effective price they need to pay for the uniquette itself must be 0.
        if (operator == to && uniquette.owner == to) {
            return 0;
        }

        if (uniquette.lastPurchaseAmount < uniquette.collateralValue) {
            return uniquette.collateralValue + ((uniquette.collateralValue * _maxPriceAppreciation) / 10000);
        } else {
            return uniquette.lastPurchaseAmount + ((uniquette.lastPurchaseAmount * _maxPriceAppreciation) / 10000);
        }
    }
}

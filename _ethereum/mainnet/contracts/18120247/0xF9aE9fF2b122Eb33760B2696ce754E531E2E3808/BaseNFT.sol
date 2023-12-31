// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ERC721Burnable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

import "./Counters.sol";

import "./Erc20Gateway.sol";

/// @notice "Premature optimization is the root of all evil." - Sir Tony Hoare
contract BaseNFT is ERC721Burnable, AccessControl {
    enum NftTier {
        ONE,
        TWO,
        THREE
    }

    // using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    event MembershipActivated(
        address indexed owner,
        address indexed payer,
        uint256 indexed tokenId
    );

    event NftTierUpgraded(
        uint256 indexed tokenId,
        NftTier indexed oldTier,
        NftTier indexed newTier
    );

    event PublicMintToggle(bool indexed isMintPublic);

    event CustodialContractSet(
        address indexed oldCustodialContract,
        address indexed newCustodialContract
    );

    event Erc20GatewaySet(
        address indexed oldErc20Gateway,
        address indexed newErc20Gateway
    );

    event NftPricesSet(uint256[] oldPrices, uint256[] newPrices);

    event AllowedMintTiersSet(bool[] oldTiers, bool[] newTiers);

    event TierLimitsSet(uint256[] oldTierLimits, uint256[] newTierLimits);

    event MembershipActivationPricesSet(
        uint256[] oldPrices,
        uint256[] newPrices
    );

    event BaseUriUpdateDisabled();

    Counters.Counter private _tokenIds;

    bool public publicMint = false;

    /// @notice has the address already minted
    mapping(address => bool) public alreadyMinted;
    /// @notice Membership activation status
    mapping(uint256 => bool) public isMembershipActivated;
    /// @notice Tier of the said NFT
    mapping(uint256 => NftTier) public nftTiers;
    /// @notice Price for tiers
    mapping(NftTier => uint256) public tierPrices;
    /// @notice Price for membership activation
    mapping(NftTier => uint256) public membershipActivationPrices;
    /// @notice Tiers allowed to be minted
    mapping(NftTier => bool) public mintTierAllowed;
    /// @notice Individual tier mint counters
    mapping(NftTier => Counters.Counter) public tierMintCounter;
    /// @notice Individual tier limits
    mapping(NftTier => uint256) public tierLimits;

    uint256 public collectionLimit;

    string public baseUri;

    bool public baseUriUpdateEnabled = true;

    /// @notice Refunded token Ids (no need to have gaps in the collection)
    uint256[] refundedTokens;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant EXTRACTOR_ROLE = keccak256("EXTRACTOR_ROLE");

    IERC721Receiver public custodialContract;

    Erc20Gateway public erc20Gateway;

    error CollectionCompleted();
    error AlreadyMinted();
    error MintNotPublic();
    error TokenNotSupported(string paymentSymbol);
    error InadequateAllowence(string paymentSymbol, uint256 requiredAllowence);
    error TokenDoesntExist(uint256 tokenId);
    error AddressZero();
    error MembershipAlreadyActive(uint256 tokenId);
    error TierOutOfBonds();
    error EqualTier();
    error InadequateTierPrice();
    error MintTierNotAllowed(NftTier tier);
    error TierSoldOut(NftTier tier);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 collectionLimit_,
        string memory baseUri_,
        uint256[] memory _tierPrices,
        uint256[] memory _membershipActivationPrices,
        uint256[] memory _tierLimits
    ) ERC721(name_, symbol_) {
        if (
            _tierPrices.length != 3 || 
            _membershipActivationPrices.length != 3 || 
            _tierLimits.length != 3
        ) {
            revert TierOutOfBonds();
        }

        collectionLimit = collectionLimit_;
        baseUri = baseUri_;

        for (uint256 i = 0; i < 3; i++) {
            NftTier tier = NftTier(i);
            tierPrices[tier] = _tierPrices[i];
            membershipActivationPrices[tier] = _membershipActivationPrices[i];
            tierLimits[tier] = _tierLimits[i];
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setNftPrices(
        uint256[] calldata _newTierPrices
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newTierPrices.length != 3) {
            revert TierOutOfBonds();
        }

        uint256[] memory oldPrices = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            NftTier tier = NftTier(i);
            oldPrices[i] = tierPrices[tier];
            tierPrices[tier] = _newTierPrices[i];
        }

        emit NftPricesSet(oldPrices, _newTierPrices);
    }

    function setAllowedMintTiers(
        bool[] calldata _newAllowedMintTiers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
                if (_newAllowedMintTiers.length != 3) {
            revert TierOutOfBonds();
        }

        bool[] memory oldAllowedTiers = new bool[](3);
        for (uint256 i = 0; i < 3; i++) {
            NftTier tier = NftTier(i);
            oldAllowedTiers[i] = mintTierAllowed[tier];
            mintTierAllowed[tier] = _newAllowedMintTiers[i];
        }

        emit AllowedMintTiersSet(oldAllowedTiers, _newAllowedMintTiers);
    }

    function setIndividualTierLimits(
        uint256[] calldata _newTierLimits
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newTierLimits.length != 3) {
            revert TierOutOfBonds();
        }

        uint256[] memory oldTierLimits = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            NftTier tier = NftTier(i);
            oldTierLimits[i] = tierLimits[tier];
            tierLimits[tier] = _newTierLimits[i];
        }

        emit TierLimitsSet(oldTierLimits, _newTierLimits);
    }

    function setMembershipActivationPrices(
        uint256[] calldata _newMembershipActivationPrices
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newMembershipActivationPrices.length != 3) {
            revert TierOutOfBonds();
        }

        uint256[] memory oldPrices = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            NftTier tier = NftTier(i);
            oldPrices[i] = membershipActivationPrices[tier];
            membershipActivationPrices[tier] = _newMembershipActivationPrices[
                i
            ];
        }

        emit MembershipActivationPricesSet(
            oldPrices,
            _newMembershipActivationPrices
        );
    }

    function setCustodialContract(
        address _custodialContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721Receiver _oldCustodialContract = custodialContract;
        custodialContract = IERC721Receiver(_custodialContract);
        emit CustodialContractSet(
            address(_oldCustodialContract),
            address(custodialContract)
        );
    }

    function setErc20Gateway(
        address _erc20Gateway
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Erc20Gateway oldErc20Gateway = erc20Gateway;
        erc20Gateway = Erc20Gateway(_erc20Gateway);
        emit Erc20GatewaySet(address(oldErc20Gateway), address(erc20Gateway));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function togglePublicMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicMint = !publicMint;
        emit PublicMintToggle(publicMint);
    }

    modifier mintConditions() {
        if (!publicMint) {
            revert MintNotPublic();
        }
        if (
            _tokenIds.current() >= collectionLimit && refundedTokens.length == 0
        ) {
            revert CollectionCompleted();
        }
        _;
    }

    function peekNextTokenId() external view returns (uint256) {
        if (refundedTokens.length > 0) {
            return refundedTokens[refundedTokens.length - 1];
        }
        if (_tokenIds.current() >= collectionLimit) {
            revert CollectionCompleted();
        }
        return _tokenIds.current() + 1;
    }

    function _getNextTokenId() internal returns (uint256) {
        // Make sure to fill the gaps from refunded tokens
        if (refundedTokens.length > 0) {
            uint256 result = refundedTokens[refundedTokens.length - 1];
            refundedTokens.pop();
            return result;
        }
        if (_tokenIds.current() >= collectionLimit) {
            revert CollectionCompleted();
        }

        _tokenIds.increment();
        return _tokenIds.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token is not freshly minted or transferred from the custodial contract
        // deactivate the membership upon transfer
        if (from != address(0) || from != address(custodialContract)) {
            isMembershipActivated[tokenId] = false;
        }
    }

    function checkAllowence(
        address customer,
        uint256 normalizedPrice,
        IERC20 paymentToken
    ) public view returns (bool) {
        return paymentToken.allowance(customer, address(this)) >= normalizedPrice;
    }

    function normalizePrice(
        uint256 weiPrice,
        IERC20 paymentToken
    ) public view returns (uint256) {
        if (weiPrice < 1 ether) {
            revert InadequateTierPrice();
        }

        /**
         * All prices are set in 1 whole ETH denominations.
         * It is safe to assume, even with current inflation rate
         * that ETH will be more expensive than stablecoins (USD).
         */
        return (weiPrice / 1 ether) * 10 ** IERC20Metadata(address(paymentToken)).decimals();
    }

    function getErc20(
        string calldata paymentSymbol
    ) internal view returns (IERC20) {
        address paymentTokenAddress = erc20Gateway.symbolToAddress(
            paymentSymbol
        );

        if (paymentTokenAddress == address(0)) {
            revert TokenNotSupported(paymentSymbol);
        }

        return IERC20(paymentTokenAddress);
    }

    function _basicMint(
        address minter,
        NftTier tier
    ) internal mintConditions returns (uint256 newItemId) {
        if (minter == address(0)) {
            revert AddressZero();
        }

        if (alreadyMinted[minter] && minter != address(custodialContract)) {
            revert AlreadyMinted();
        }

        if (!mintTierAllowed[tier]) {
            revert MintTierNotAllowed(tier);
        }

        if (tierMintCounter[tier].current() >= tierLimits[tier]) {
            revert TierSoldOut(tier);
        }

        alreadyMinted[minter] = true;

        newItemId = _getNextTokenId(); // Sets the result

        _safeMint(minter, newItemId);

        nftTiers[newItemId] = tier;
        isMembershipActivated[newItemId] = true;

        tierMintCounter[tier].increment();

        if (minter == address(custodialContract)) {
            custodialContract.onERC721Received(
                _msgSender(),
                address(this),
                newItemId,
                ""
            );
        }

        emit MembershipActivated(minter, _msgSender(), newItemId);
    }

    function mint(
        address minter,
        NftTier tier,
        string calldata paymentSymbol
    ) external payable {
        IERC20 paymentToken = getErc20(paymentSymbol);

        uint256 normalizedPrice = normalizePrice(
            tierPrices[tier],
            paymentToken
        );

        if (!checkAllowence(_msgSender(), normalizedPrice, paymentToken)) {
            revert InadequateAllowence(paymentSymbol, normalizedPrice);
        }

        paymentToken.safeTransferFrom(_msgSender(), address(this), normalizedPrice);

        _basicMint(minter, tier);
    }

    function ownerMint(
        address minter,
        NftTier tier
    ) external onlyRole(MINTER_ROLE) {
        _basicMint(minter, tier);
    }

    function refund(uint256 _tokenId) external payable onlyRole(BURNER_ROLE) {
        // Performs the ownership checks
        ERC721Burnable.burn(_tokenId);

        NftTier tier = nftTiers[_tokenId];

        delete isMembershipActivated[_tokenId];
        delete nftTiers[_tokenId];
        tierMintCounter[tier].decrement();

        refundedTokens.push(_tokenId);
    }

    function extractTokens(
        string calldata paymentTokenSymbol,
        uint256 value
    ) external payable onlyRole(EXTRACTOR_ROLE) {
        getErc20(paymentTokenSymbol).transfer(_msgSender(), value);
    }

    function _membershipActivation(uint256 tokenId) internal {
        if (!_exists(tokenId)) {
            revert TokenDoesntExist(tokenId);
        }
        if (isMembershipActivated[tokenId]) {
            revert MembershipAlreadyActive(tokenId);
        }

        isMembershipActivated[tokenId] = true;

        emit MembershipActivated(ownerOf(tokenId), _msgSender(), tokenId);
    }

    function activateMembership(
        uint256 tokenId,
        string calldata paymentSymbol
    ) external payable {
        IERC20 paymentToken = getErc20(paymentSymbol);

        uint256 normalizedTierActivationPrice = normalizePrice(
            membershipActivationPrices[ // tier activation price
                nftTiers[tokenId] // current token tier
            ],
            paymentToken
        );

        if (
            !checkAllowence(
                _msgSender(),
                normalizedTierActivationPrice,
                paymentToken
            )
        ) {
            revert InadequateAllowence(
                paymentSymbol,
                normalizedTierActivationPrice
            );
        }

        paymentToken.safeTransferFrom(
            _msgSender(),
            address(this),
            normalizedTierActivationPrice
        );

        _membershipActivation(tokenId);
    }

    function grantMembership(uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _membershipActivation(tokenId);
    }

    function upgradeTier(uint256 nftId, NftTier tier) external onlyRole(MINTER_ROLE) {
        if (!_exists(nftId)) {
            revert TokenDoesntExist(nftId);
        }

        NftTier oldTier = nftTiers[nftId];
        
        if (tier == oldTier) {
            revert EqualTier();
        }
        
        nftTiers[nftId] = tier;
        
        emit NftTierUpgraded(nftId, oldTier, tier);
    }

    function updateBaseUri(string memory _baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(baseUriUpdateEnabled);
        baseUri = _baseUri;
    }

    function disableBaseUriUpdate() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(baseUriUpdateEnabled);
        baseUriUpdateEnabled = false;
        emit BaseUriUpdateDisabled();
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesntExist(tokenId);
        }

        return string(abi.encodePacked(baseUri, uint8((48 + uint256(nftTiers[tokenId])) & 0xFF), ".json")); 
    }
}

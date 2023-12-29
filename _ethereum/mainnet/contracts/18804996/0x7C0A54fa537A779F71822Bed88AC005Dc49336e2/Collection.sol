// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

/**
 *           █████             ╨████████▀              ▌██████▌┌──└▌█████               █████
 *          ▐▀█████              ╫█████                  █████       ╙████▌            ▄▀█████
 *          ▀ █████▌             ╟████                   █████        █████            ⌐ █████▄
 *         ▌   █████             ╟████                   █████        █████           ▌   █████
 *        ╫     █████            ╟████                   █████       ▄████           ▌     █████
 *       ╓─     ▀█████           ╟████                   █████╥╥╥╥╥▄███             ▐      ▓█████
 *       ▌       █████▄          ╟████                   █████       ─█████         ▀       █████▄
 *      ▓         █████          ╟████                   █████         █████       ▓         █████
 *     ▄           █████         ╟████            ▓▌     █████         █████▌     ╫          └█████
 *    ╓▌           ██████        ╟████            █▌     █████         █████▀    ╓▀           ██████
 *   ╓█             █████▄       ╟████          ███▌     █████         █████    ▄█             █████▄
 * ,█████▌         ,███████     ▄██████▄     ,█████▌    ███████      █████╨   ,█████▌         ,███████
 * └└└└└└└└       └└└└└└└└└└   └└└└└└└└└└┌─┌└└└└└└└    └└└└└└└└└└──└└─        └└└└└└└─       └└└└└└└└└└
 */

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC721AUpgradeable.sol";
import "./ECDSA.sol";
import "./Initializable.sol";
import "./IERC2981.sol";

import "./IAlbaDelegate.sol";
import "./IPaymentSplitter.sol";
import "./Types.sol";
import "./Pricing.sol";
import "./Splitters.sol";

interface CollectionEvents {
    event SaleFinished();
    event RebateClaimed(address claimer, address recipient, uint256 amount);
    event PaymentFlushed(uint256 amount);
    event MaxSalePiecesReduced(uint256 newMax);
    event SaleConfigChanged(SaleConfig newConfig);
    event ReservesReleased();
    event AlbaEjected();
}

/**
 * @title Collection
 * @notice The Alba Collection contract.
 * @dev This contract uses `ERC721AUpgradeable`, but that is because it is deployed as a minimal proxy
 * to a base collection for implementation. This contract itself is *not* upgradeable.
 */
contract Collection is Initializable, CollectionEvents, ERC721AUpgradeable, Ownable, AccessControlEnumerable {
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_ARTIST = keccak256("ROLE_ARTIST");

    // Differentiate signature type
    uint8 private constant SIG_TYPE_RESERVED = 0xFF;

    uint256 public constant MIN_REDUCE_BUFFER = 7 days;

    error InvalidConfiguration();
    error InvalidPayment();
    error TooManyMintsRequested();
    error InsufficientTokensRemanining();
    error SaleNotActive();
    error NoRebateAvailable();
    error UnknownToken();
    error Unauthorized();
    error InvalidRoyaltyPercentage();
    error PaymentFailed();
    error AuctionStillActive();

    IAlbaDelegate public albaDelegate;
    SaleConfig public saleConfig;
    CollectionConfig public collectionConfig;

    // Location of primary sale payment splitter.
    IPaymentSplitter public paymentSplitter;

    // Location of secondary sale payment splitter.
    IPaymentSplitter public paymentSplitterRoyalties;

    // Basis points for royalty payments.
    uint16 public royaltyBasisPoints;

    /* Mint mechanics */

    // Flag to indicate that the sale has been closed.
    // This is different to selling out or the auction ending.
    // It is only used when the sale is explcitly closed by the artist.
    bool public isSaleClosed;

    // Keeps track of the number of reserved tokens minted (keyed by message hash)
    mapping(bytes32 => uint256) private numReserveMintedFrom;
    // Tracks the total number of reserve mints to ensure we don't mint more than the max.
    // This allows us to overallocate reserves if we want to.
    uint32 public numReservedMinted;
    // Tracks the number of retained tokens minted by the artist.
    uint16 public numRetainedMinted;
    // Tracks the number of Alba pieces minted.
    uint16 public numAlbaMinted;

    /* Auction specific properties */

    // Final price used for rebates.
    uint256 public finalSalePrice;
    // Number of _potential_ 'rebate mints' i.e. mints which might be eligible for a rebate.
    uint256 private numRebateMints;
    // Purchase prices used to compute rebates.
    mapping(address => uint256[]) public mintPrices;

    // Expose a general mapping for metadata. This can be used to store arbitrary information
    // about the collection which should be preserved on-chain, such as the browser info,
    // licences, gallery details, etc. For flexibility we intentionally leave this unrestricted and
    // rely on conventions defined by Alba for the shape of this data.
    mapping(string => string) public metadata;

    // Modifiers

    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert UnknownToken();
        _;
    }

    // Access control modifiers

    modifier managerOrArtist() {
        if (!hasRole(ROLE_MANAGER, msg.sender) && !hasRole(ROLE_ARTIST, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyArtist() {
        if (!hasRole(ROLE_ARTIST, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyManager() {
        if (!hasRole(ROLE_MANAGER, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyAlbaReceiver() {
        if (msg.sender != albaDelegate.getAlbaFeeReceiver()) revert Unauthorized();
        _;
    }

    // Auction time modifiers

    modifier mintingActive() {
        if (isSaleClosed || block.timestamp < saleConfig.startTime) revert SaleNotActive();
        _;
    }

    modifier afterAuction() {
        if (block.timestamp < saleConfig.auctionEndTime) revert AuctionStillActive();
        _;
    }

    function initialize(
        IAlbaDelegate _albaDelegate,
        CollectionConfig calldata _config,
        SaleConfig calldata _saleConfig,
        PaymentConfig calldata _paymentConfig,
        address albaManager,
        address[] calldata artists
    ) public initializerERC721A initializer {
        uint256 numArtists = artists.length;
        if (numArtists == 0) {
            revert InvalidConfiguration();
        }

        __ERC721A_init(_config.name, _config.token);
        _setupRole(DEFAULT_ADMIN_ROLE, albaManager);
        _setupRole(ROLE_MANAGER, albaManager);
        for (uint256 i = 0; i < numArtists; i++) {
            _setupRole(ROLE_ARTIST, artists[i]);
        }

        albaDelegate = _albaDelegate;
        collectionConfig = _config;
        royaltyBasisPoints = _paymentConfig.royaltyBasisPoints;

        // Ensure the config is valid before writing it (check relies on comparing old/new)
        _validateSaleConfig(_saleConfig);
        saleConfig = _saleConfig;

        (paymentSplitter, paymentSplitterRoyalties) = Splitters.setupPaymentSplitters(_paymentConfig, _albaDelegate);

        if (collectionConfig.metadataKeys.length != 0) {
            writeMetadata(collectionConfig.metadataKeys, collectionConfig.metadataValues);
        }

        // Make the artist the owner of the contract.
        // Note that this leaves in place the manager role for the Alba
        // platform to continue to manage the contract. This will let
        // Alba make changes to the contract in the future, such as replacing
        // the delegate to fix issues or change things like the way on-chain
        // HTML is built.
        // To remove Alba's managaer role, see `assumeTotalOwnership`.
        // Note: The first artist becomes the owner - we could use a multisig contract
        // but that would make UX for collabs much more difficult.
        _transferOwnership(artists[0]);
    }

    // Minting

    /**
     * @notice Mint a number of tokens to a user.
     * @param collectionId The collection ID.
     * @param user The user to mint to.
     * @param num The number of tokens to mint.
     * @param nonce The nonce to use for the signature.
     * @param signature The signature to verify.
     * @dev We use a signature to verify the mints. This gives us an opportunity to
     * prevent bots.
     */
    function mint(bytes16 collectionId, address user, uint16 num, uint32 nonce, bytes calldata signature)
        external
        payable
        mintingActive
    {
        // Max mints do not include reserved mints.
        uint256 publicMinted = _salePiecesMinted() - numReservedMinted;
        uint256 publicLimit = saleConfig.maxSalePieces - saleConfig.numReserved;
        if (publicMinted + num > publicLimit) revert InsufficientTokensRemanining();

        albaDelegate.verifyMint(collectionId, user, num, nonce, signature);

        _mintInternal({user: user, num: num, isReserve: false});
    }

    /**
     * @notice Mint a number of tokens to a user.
     * See mint function for params
     * @dev This is separate from the normal mint function as we don't want to check supply
     * limits, and no mints can happen after the end time, unlike other sales which stay open.
     * It uses the same internal function for payments, but we ensure that there can be
     * no rebate for OE mints in config, so it takes the simple path through the mint function.
     */
    function mintTimeLimited(bytes16 collectionId, address user, uint16 num, uint32 nonce, bytes calldata signature)
        external
        payable
        mintingActive
    {
        if (saleConfig.saleType != SaleType.FixedPriceTimeLimited) {
            revert InvalidConfiguration();
        }
        if (_hasAuctionFinished()) {
            revert SaleNotActive();
        }

        albaDelegate.verifyMint(collectionId, user, num, nonce, signature);

        _mintInternal({user: user, num: num, isReserve: false});
    }

    /**
     * @notice Mint reserved tokens to a user.
     * @param collectionId The collection ID.
     * @param user The user to mint to.
     * @param num The number of tokens to mint.
     * @param maxMints The maximum number of mints allowed for this user.
     * @param nonce The nonce to use for the signature.
     * @param signature The signature to verify.
     * @dev Reserves are not allowed for TimeLimited sales, but we don't explicitly need to handle them
     * here as the config shouldn't allow reserves.
     */
    function mintReserved(
        bytes16 collectionId,
        address user,
        uint16 num,
        uint16 maxMints,
        uint32 nonce,
        bytes calldata signature
    ) external payable mintingActive {
        // Ensure signature is valid
        bytes32 message = _reserveMessage(collectionId, user, maxMints, nonce);
        albaDelegate.verifyMintReserve(message, signature);

        if (num + numReserveMintedFrom[message] > maxMints) revert TooManyMintsRequested();

        if (numReservedMinted + num > saleConfig.numReserved) revert InsufficientTokensRemanining();

        if (_salePiecesMinted() + num > saleConfig.maxSalePieces) revert InsufficientTokensRemanining();

        // Record how many reserved mints have been made from this address
        numReserveMintedFrom[message] += num;
        numReservedMinted += num;

        _mintInternal({user: user, num: num, isReserve: true});
    }

    /**
     * @notice Mints tokens for the artist only.
     * @dev This does not call mintInternal because these mints are completely separate from the sale.
     * They can happen at any time, cost nothing, and are only limited by the number of tokens
     * in the configuration.
     */
    function mintRetained(uint16 num) external onlyArtist {
        if (numRetainedMinted + num > saleConfig.numRetained) revert InsufficientTokensRemanining();
        numRetainedMinted += num;
        _mint(msg.sender, num);
    }

    /**
     * @notice Mints the Alba retained piece.
     * These are special pieces for the Alba gallery, used to share and exhibit the work.
     * This can be called by Alba, even if the contract is fully owned by the artist.
     */
    function mintAlba(address to, uint16 num) external onlyAlbaReceiver {
        if (numAlbaMinted + num > saleConfig.numAlba) {
            revert TooManyMintsRequested();
        }
        numAlbaMinted += num;
        _mint(to, num);
    }

    /**
     * @dev Internal mint function.
     * This does the standard checks and records generic information about the sale.
     * It also controls the auction mechanics.
     * Callers must verify that the mint signature is valid before using this function.
     * Any extra money sent for the mints is kept by the contract, though will be returned
     * as part of the rebate if the rebate is enabled. We do this to avoid issues with
     * continuous auctions where the price may change between when the transaction is sent and
     * included in a block.
     * NOTE: It is important to understand that reserve mints can happen after the _auction_
     * has finished. This means that mints _may_ happen after the final price is set. However,
     * reserve mints cannot _set_ the final price.
     */
    function _mintInternal(address user, uint256 num, bool isReserve) private {
        uint256 price = getPrice();
        uint256 saleTotal = num * price;

        if (msg.value < saleTotal) {
            revert InvalidPayment();
        }

        // Rebate logic is complex, so we split it out into a separate function.
        if (saleConfig.hasRebate) {
            _mintInternalWithRebate(user, num, isReserve, price, saleTotal);
            return;
        }

        (bool success,) = payable(address(paymentSplitter)).call{value: msg.value}("");
        if (!success) revert PaymentFailed();

        // Do the mint
        _mint(user, num);
    }

    function _mintInternalWithRebate(address user, uint256 num, bool isReserve, uint256 price, uint256 saleTotal)
        private
    {
        // We don't want to wait for all reserves to mint to 'sell out', as they may be
        // held for a long time. However, we still treat the mints the same as public ones
        // (i.e. eligible for rebate if applicable).
        // TODO: Handle case where Last piece is reserve and sells before resting price reached?
        if (!isReserve) {
            uint256 publicMinted = _salePiecesMinted() - numReservedMinted;
            uint256 publicPieceLimit = saleConfig.maxSalePieces - saleConfig.numReserved;
            // If the final price is not already set, then set it if we've sold out
            if (finalSalePrice == 0 && publicMinted + num == publicPieceLimit) {
                finalSalePrice = price;
                emit SaleFinished();
            }
        }

        bool hasOverpaid = msg.value > saleTotal;
        uint256 overpayDelta = 0;
        if (hasOverpaid) {
            overpayDelta = msg.value - saleTotal;
        }

        // If the auction has a rebate and the resting price has not been discovered,
        // record the price paid for each mint.
        // Record that these mints are 'rebate mints' so we know how much money
        // to flush later on.
        if (finalSalePrice == 0 && price > saleConfig.finalPrice) {
            // If there's an overpayment, which can happen during auctions due to the price changing between tx submit
            // and it being included in a block, then attach that extra value to the first price for the rebate (which
            // is guaranteed to be there)
            mintPrices[user].push(price + overpayDelta);
            overpayDelta = 0;

            // Starting from index 1, push any extra prices.
            for (uint256 i = 1; i < num; i++) {
                mintPrices[user].push(price);
            }
            numRebateMints += num;
        }

        // If there's still an overpay delta, we've hit the case where there's no rebate but there was
        // an overpayment. This could happen when the auction is over and the final price is set, but
        // the user has sent more than the final price. In this case, we send the overpayment back to the user.
        if (overpayDelta > 0) {
            (bool success,) = payable(msg.sender).call{value: overpayDelta}("");
            if (!success) revert PaymentFailed();
        }

        // Send the payment on to the splitter.
        // If there is a rebate, the value will stay in the contract waiting to be claimed.
        // However, once the auction is finished, we know that the mint price is always
        // the final price, so we can send the payment on to the splitter immediately. This
        // removes the need for having the artist flush the payment more than once, and subsequently
        // we don't need to keep track of which mints are already accounted for in the flushing
        // process.
        // We send the payment directly if:
        // 1. The final price is not 0 (i.e. the sale has finished)
        // 2. The price paid is not the final price (i.e. the auction is still ongoing)
        // 3. The auction has finished - this case ensures we send value after the auction is there's no sellout.
        if (finalSalePrice != 0 || price == saleConfig.finalPrice || _hasAuctionFinished()) {
            (bool success,) = payable(address(paymentSplitter)).call{value: saleTotal}("");
            if (!success) revert PaymentFailed();
        }

        // Do the mint
        _mint(user, num);
    }

    /**
     * @notice Returns the number of reserves used by the given user.
     */
    function reservesUsed(bytes16 collectionId, address user, uint16 maxMints, uint32 nonce)
        external
        view
        returns (uint256)
    {
        bytes32 message = _reserveMessage(collectionId, user, maxMints, nonce);
        return numReserveMintedFrom[message];
    }

    /**
     * @notice Returns the message that is used for reserve mints.
     * @dev This can be used to verify signatures as well as check the number of mints used.
     * We prepend a type byte before the collectionID to ensure that we don't have any overlapping
     * signatures (without this the params may be identical to the public mint signature). This is
     * in place of the typed signature EIP which we should upgrade to ideally.
     */
    function _reserveMessage(bytes16 collectionId, address user, uint16 maxMints, uint32 nonce)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(SIG_TYPE_RESERVED, collectionId, user, maxMints, nonce, block.chainid))
        );
    }

    // Auction functions

    /**
     * @notice Returns the number of pieces that have been minted in the sale.
     * This exludes the artist 'retained' mints, but does include the reserved mints.
     */
    function _salePiecesMinted() internal view returns (uint256) {
        return totalSupply() - numRetainedMinted - numAlbaMinted;
    }

    /**
     * @notice Returns true if the auction has finished.
     * Note that the auction finishing is not the same as the sale finishing.
     * The auction finishes when the price stops changing, but the sale can
     * continue after that indefinitely until stopped by the artist.
     */
    function _hasAuctionFinished() internal view returns (bool) {
        return block.timestamp >= saleConfig.auctionEndTime;
    }

    function getPrice() public view returns (uint256) {
        if (finalSalePrice != 0) {
            return finalSalePrice;
        }
        return AlbaCollectionPricing.getPrice(saleConfig);
    }

    /**
     * @notice Allows users to claim a rebate if applicable.
     * @dev Rebates are only available if the sale has a rebate, and if:
     * - The auction period has finished, or
     * - The sale has finished (sold out).
     * If the sale has finished, the rebate is calculated based on the final price paid.
     * otherwise, it's based on the final price of the auction.
     */
    function claimRebate(address payable recipient) external {
        uint256 totalRebate = getRebateAmount(msg.sender);
        if (totalRebate == 0) {
            revert NoRebateAvailable();
        }

        delete (mintPrices[msg.sender]);

        // External call, ensure rebate is marked as claimed before calling for reentrancy.
        (bool success,) = recipient.call{value: totalRebate}("");
        require(success, "Transfer failed");
        emit RebateClaimed(msg.sender, recipient, totalRebate);
    }

    /**
     * @notice Returns the amount of rebate that a user is eligible for.
     */
    function getRebateAmount(address user) public view returns (uint256) {
        // Auction not over yet and no sellout, means you can't claim yet
        // as we don't know the final price.
        if (!_hasAuctionFinished() && finalSalePrice == 0) {
            return 0;
        }

        // We reuse this storage slot to indicate that the rebate has been claimed.
        if (mintPrices[user].length == 0) {
            return 0;
        }

        uint256 restingPrice = finalSalePrice > 0 ? finalSalePrice : saleConfig.finalPrice;
        uint256 totalRebate = 0;
        for (uint256 i = 0; i < mintPrices[user].length; i++) {
            if (mintPrices[user][i] > restingPrice) {
                totalRebate += mintPrices[user][i] - restingPrice;
            }
        }
        return totalRebate;
    }

    // ERC721

    /// @notice Returns the URI for token metadata.
    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        return albaDelegate.tokenURI(tokenId, collectionConfig.slug);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlEnumerable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId)
            || AccessControlEnumerable.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    // ERC2981 + Payments

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (salePrice / 10000) * royaltyBasisPoints;
        receiver = payable(address(paymentSplitterRoyalties));
    }

    /**
     * @notice Returns the amount of payments that can be flushed to the splitter.
     * Note that this is only applicable for rebate auctions which have finished.
     */
    function flushablePayments() public view returns (uint256) {
        if (!saleConfig.hasRebate || !_hasAuctionFinished() || numRebateMints == 0) {
            return 0;
        }

        uint256 finalValue = finalSalePrice != 0 ? finalSalePrice : saleConfig.finalPrice;
        return numRebateMints * finalValue;
    }

    // 721 On-chain Extensions

    /**
     * @notice Returns the seed of a token.
     * @dev The seed is computed from the seed of the batch in which the given
     * token was minted.
     */
    function tokenSeed(uint256 tokenId) public view tokenExists(tokenId) returns (bytes32) {
        uint24 batchSeed = _ownershipOf(tokenId).extraData;
        return keccak256(abi.encodePacked(address(this), batchSeed, tokenId));
    }

    /**
     * @notice Computes a pseudorandom seed for a mint batch.
     * @dev Even though this process can be gamed in principle, it is extremly
     * difficult to do so in practise. Therefore we can still rely on this to
     * derive fair seeds.
     */
    function _computeBatchSeed(address to) private view returns (uint24) {
        return uint24(
            bytes3(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, blockhash(block.number - 1), to)))
        );
    }

    /**
     * @dev sets the batch seed on mint.
     */
    function _extraData(address from, address to, uint24 previousExtraData)
        internal
        view
        virtual
        override
        returns (uint24)
    {
        // if minting, compute a batch seed
        if (from == address(0)) {
            return _computeBatchSeed(to);
        }
        // else return the current value
        return previousExtraData;
    }

    /**
     * @notice Returns the HTML to render a token.
     * @dev This includes all dependencies and the collection script to allow for rendering of the piece
     * directly in the browser, with no external dependencies.
     */
    function tokenHTML(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return string(
            albaDelegate.tokenHTML(collectionConfig.uuid, tokenId, tokenSeed(tokenId), collectionConfig.dependencies)
        );
    }

    // Admin functions

    /**
     * @notice Sets the delegate for this collection.
     */
    function setDelegate(IAlbaDelegate newDelegate) external onlyManager {
        albaDelegate = newDelegate;
    }

    /**
     * @notice Sets the royalty percentage, in basis points
     */
    function setRoyalyPercentage(uint16 newRoyaltyBasisPoints) external managerOrArtist {
        if (newRoyaltyBasisPoints > 10000) {
            revert InvalidRoyaltyPercentage();
        }
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    /**
     * @notice Validate a given sale config.
     * @dev Note that the validation here is minimal, and only checks for invariants which
     * would break the contract rather than things which are likely not desired. E.g. (1 second auctions).
     * We do this to allow for maximum flexibility with use cases in the future.
     * The Alba backend will do validation before deployment for those other cases.
     */
    function _validateSaleConfig(SaleConfig memory sc) internal view {
        // Ensure the start time is at least 'minSaleStartBuffer' in the future if it's changing.
        // Note that this also covers the initial deploy as the initial value will be 0.
        if (
            saleConfig.startTime != sc.startTime
                && sc.startTime < block.timestamp + albaDelegate.getMinSaleStartBuffer()
        ) {
            revert InvalidConfiguration();
        }

        // Validation for time limited sales.
        // They must have an end time and cannot have reserves or sale pieces.
        if (sc.saleType == SaleType.FixedPriceTimeLimited) {
            if (sc.auctionEndTime == 0 || sc.numReserved != 0 || sc.maxSalePieces != 0 || sc.hasRebate) {
                revert InvalidConfiguration();
            }
        }

        // Validation for fixed price
        if (sc.saleType == SaleType.FixedPrice) {
            if (sc.hasRebate || sc.auctionEndTime != 0) {
                revert InvalidConfiguration();
            }
            if (sc.numReserved > sc.maxSalePieces) {
                revert InvalidConfiguration();
            }
        }

        // Validation for auction config
        if (sc.saleType == SaleType.ExponentialDutchAuction) {
            if (sc.auctionEndTime <= sc.startTime) {
                revert InvalidConfiguration();
            }

            if (sc.initialPrice <= sc.finalPrice) {
                revert InvalidConfiguration();
            }

            if ((sc.auctionEndTime - sc.startTime) > 2 hours) {
                revert InvalidConfiguration();
            }

            // Can't have only reserved pieces in an auction because reserves are not used
            // to set the final price. Must use fixed price sale for this.
            if (sc.numReserved >= sc.maxSalePieces) {
                revert InvalidConfiguration();
            }
        }
    }

    /**
     * @notice Change the sale config. This can only be called at least MIN_CHANGE_BUFFER time before the
     * sale has started. This can be used to postpone the sale, change pricing etc.
     * @param newConf The new sale config.
     * @dev We only allow for changing this with ample notice so that artists cannot cause havoc by changing
     * params at the last minute. This ensures there is time for the backend to reflect the update.
     */
    function changeSaleConfig(SaleConfig calldata newConf) external managerOrArtist {
        // Ensure we are at least minDeployBuffer time before the current sale start time.
        if (block.timestamp >= saleConfig.startTime - albaDelegate.getMinSaleStartBuffer()) {
            revert InvalidConfiguration();
        }
        _validateSaleConfig(newConf);
        saleConfig = newConf;
        emit SaleConfigChanged(saleConfig);
    }

    /**
     * @notice Close the sale.
     * The auctionEndTime parameter of the config only describes when the price in
     * the auction will stop changing, but does not stop the sale from continuing.
     * This function can be called by the manager or the artist to stop the sale entirely.
     * Warning: this is permanent, and cannot be undone.
     * @dev We don't need to set the finalSalePrice here, because price will have always
     * settled at the auction end price.
     */
    function closeSale() external managerOrArtist mintingActive afterAuction {
        // Set the sale as closed.
        isSaleClosed = true;
        emit SaleFinished();
    }

    /**
     * @notice Release reserves for the sale.
     * @dev To 'release' means to effectively remove all reserves and allow all remaining
     * mints to be done via the public mint process. We don't update the maxSalePieces
     * because that value is the total, which was previously subdivided by public/reserves.
     */
    function releaseReserves() public managerOrArtist mintingActive afterAuction {
        // Already minted all the reserves, so nothing to do.
        if (numReservedMinted >= saleConfig.numReserved) {
            return;
        }
        saleConfig.numReserved = numReservedMinted;
        emit ReservesReleased();
    }

    /**
     * @notice Reduce the number of sale pieces.
     * @dev This can be used to reduce the number of sale pieces after the sale has started.
     * The number of pieces can only be reduced after the auction has been finished for at least
     * 7 days. This is to prevent manipulating the launch mechanics.
     */
    function reduceMaxSalePiecesTo(uint32 newTotal) external managerOrArtist mintingActive {
        if (block.timestamp < saleConfig.startTime + MIN_REDUCE_BUFFER) {
            revert InvalidConfiguration();
        }

        // Ensure the new total is valid. If the newTotal is exactly the same, as the current number
        // that means no more mints, so you should use closeSale instead.)
        if (newTotal <= _salePiecesMinted() || newTotal >= saleConfig.maxSalePieces) {
            revert InvalidConfiguration();
        }

        // If there are reserves remaining, we assume they are no longer wanted and we release them.
        if (saleConfig.numReserved > 0 && numReservedMinted < saleConfig.numReserved) {
            releaseReserves();
        }

        saleConfig.maxSalePieces = newTotal;
        emit MaxSalePiecesReduced(newTotal);
    }

    /**
     * @notice Allow the artist to flush the funds to the payment splitter.
     * @dev For FixedPrice sales, the payment is sent directly to the splitter on each mint.
     * For auctions, the payment is initially buffered in the contract so that rebates can be
     * claimed. We don't know the final price until a sell-out or the auction ends.
     * For simplicity we wait until the end of the auction to allow the artist to flush the funds.
     * At the end of the auction, any subsequent mints will be sent directly to the splitter as
     * we know the final price already.
     * Note that by the time the flush is called, the users may not have claimed their rebates.
     * So to ensure we don't flush too much, we need to store the number of 'rebateMints' i.e.
     * mints which have a *potential* to collect a rebate. We can't use the total number of mints
     * because some of these may have been sold at the final price, and therefore don't have a rebate,
     * and some may be free retained mints.
     */
    function flushPaymentToSplitter() public managerOrArtist {
        // Fixed price sales push to splitter on each mint.
        if (saleConfig.saleType == SaleType.FixedPrice || saleConfig.saleType == SaleType.FixedPriceTimeLimited) {
            revert InvalidConfiguration();
        }

        // For simplicity, we require that the auction has finished.
        // This ensures that either 'finalSalePrice' is set due to a sellout, OR
        // any remaining sales will be at the resting price. We therefore know that
        // futher mints are sent to the splitter directly, and we can flush based
        // on the number of (poential) 'rebate mints'.
        if (!_hasAuctionFinished()) {
            revert AuctionStillActive();
        }

        if (numRebateMints == 0) {
            revert InvalidConfiguration();
        }

        uint256 finalValue = finalSalePrice != 0 ? finalSalePrice : saleConfig.finalPrice;
        uint256 totalValue = numRebateMints * finalValue;

        // Set the pending rebates to 0, so that we can't flush twice.
        numRebateMints = 0;

        (bool success,) = payable(address(paymentSplitter)).call{value: totalValue}("");
        if (!success) revert PaymentFailed();
        emit PaymentFlushed(totalValue);
    }

    /**
     * @notice Allows artists to write arbitrary metadata for preservation.
     */
    function writeMetadata(string[] memory keys, string[] memory values) public managerOrArtist {
        if (keys.length != values.length) {
            revert InvalidConfiguration();
        }
        for (uint256 i = 0; i < keys.length; i++) {
            metadata[keys[i]] = values[i];
        }
    }

    /**
     * @notice Allow the artist to assume complete control of the contract.
     * The artist owns the contract at deployment time by default, but Alba
     * is retained as a manager to allow for simple builk management.
     * @dev We only allow this after the auction has finished to ensure that someone
     * can't lock us out of the ability to postpone/remove a sale.
     */
    function assumeTotalOwnership() external onlyOwner afterAuction {
        address currentManager = getRoleMember(ROLE_MANAGER, 0);

        // Make the artist the admin of all roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Make the artist a manager.
        _grantRole(ROLE_MANAGER, msg.sender);

        // Revoke the existing manager from roles.
        _revokeRole(ROLE_MANAGER, currentManager);
        _revokeRole(DEFAULT_ADMIN_ROLE, currentManager);
        emit AlbaEjected();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./WeightedMathLib.sol";

import "./SafeTransferLib.sol";
import "./MerkleProofLib.sol";
import "./LibString.sol";
import "./Clone.sol";

import "./ISablierV2LockupLinear.sol";
import "./DataTypes.sol";
import "./Math.sol";
import "./Tokens.sol";

import "./ReentrancyGuard.sol";

import "./LiquidityBootstrapLib.sol";
import "./Pausable.sol";
import "./Treasury.sol";

contract LiquidityBootstrapPool is Pausable, Clone, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using LiquidityBootstrapLib for *;

    using FixedPointMathLib for *;

    using SafeTransferLib for *;

    using WeightedMathLib for *;

    using MerkleProofLib for *;

    using LibString for *;

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev Error thrown when the whitelist proof verification fails.
    error WhitelistProof();

    /// @dev Error thrown when the maximum allowed assets in are exceeded.
    error AssetsInExceeded();

    /// @dev Error thrown when the maximum allowed shares out are exceeded.
    error SharesOutExceeded();

    /// @dev Error thrown when the slippage limit is exceeded.
    error SlippageExceeded();

    /// @dev Error thrown when selling is disallowed.
    error SellingDisallowed();

    /// @dev Error thrown when trading is disallowed.
    error TradingDisallowed();

    /// @dev Error thrown when closing is disallowed.
    error ClosingDisallowed();

    /// @dev Error thrown when redeeming is disallowed.
    error RedeemingDisallowed();

    /// @dev Error thrown when an address is not allowed to call a function.
    error CallerDisallowed();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when assets are swapped for shares.
    /// @param caller The address of the caller initiating the swap.
    /// @param assets The amount of assets being swapped.
    /// @param shares The amount of shares received in the swap.
    /// @param swapFee The amount of fee charged in the swap.
    event Buy(address indexed caller, uint256 assets, uint256 shares, uint256 swapFee);

    /// @dev Emitted when shares are swapped for assets.
    /// @param caller The address of the caller initiating the swap.
    /// @param shares The amount of shares being swapped.
    /// @param assets The amount of assets received in the swap.
    /// @param swapFee The amount of fee charged in the swap.
    event Sell(address indexed caller, uint256 shares, uint256 assets, uint256 swapFee);

    /// @dev Emitted when shares are redeemed.
    /// @param caller The address of the caller initiating the redemption.
    /// @param shares The amount of shares being redeemed.
    event Redeem(address indexed caller, uint256 indexed streamID, uint256 shares);

    /// @dev Emitted when the liquidity pool is closed.
    /// @param assets The amount of assets transferred out during the pool closure.
    event Close(uint256 assets, uint256 platformFees, uint256 swapFeesAsset, uint256 swapFeesShare);

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice Mapping to track the purchased shares for each address.
    mapping(address => uint256) public purchasedShares;

    /// @notice Mapping to track the assets referred by each address.
    mapping(address => uint256) public referredAssets;

    /// @notice Mapping to track the redeemed shares for each address.
    mapping(address => uint256) public redeemedShares;

    /// @notice The total number of purchased shares in the pool.
    uint256 public totalPurchased;

    /// @notice The total amount of assets referred in the pool.
    uint256 public totalReferred;

    /// @notice The total swap fee amount in asset charged to users.
    uint256 public totalSwapFeesAsset;

    /// @notice The total swap fee amount in lbp token charged to users.
    uint256 public totalSwapFeesShare;

    /// @notice Flag to indicate if the liquidity pool is closed.
    bool public closed;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    /// @notice The address of the asset token.
    /// @dev This is the ERC20 token representing the asset in the pool.
    /// @return The address of the asset token.
    function asset() public pure virtual returns (address) {
        return _getArgAddress(0);
    }

    /// @notice The address of the share token.
    /// @dev This is the ERC20 token representing the shares in the pool.
    /// @return The address of the share token.
    function share() public pure virtual returns (address) {
        return _getArgAddress(20);
    }

    /// @notice The address of the platform where fees are collected.
    /// @dev This is the address where fees are collected.
    /// @return The address of the platform.
    function platform() public pure virtual returns (address) {
        return _getArgAddress(40);
    }

    /// @notice The address of the manager who controls the pool.
    /// @dev This is the address who has control over the pool's privledged operations.
    /// @return The address of the manager.
    function manager() public pure virtual returns (address) {
        return _getArgAddress(60);
    }

    /// @notice The virtual assets value.
    /// @dev This value represents the virtual assets in the pool.
    /// @return The virtual assets value.
    function virtualAssets() public pure virtual returns (uint256) {
        return _getArgUint88(80);
    }

    /// @notice The virtual shares value.
    /// @dev This value represents the virtual shares in the pool.
    /// @return The virtual shares value.
    function virtualShares() public pure virtual returns (uint256) {
        return _getArgUint88(91);
    }

    /// @notice The maximum share price value.
    /// @dev This value represents the maximum price at which shares can be sold.
    /// @return The maximum share price value.
    function maxSharePrice() public pure virtual returns (uint256) {
        return _getArgUint88(102);
    }

    /// @notice The maximum total shares out value.
    /// @dev This value represents the maximum number of shares that can be sold.
    /// @return The maximum total shares out value.
    function maxTotalSharesOut() public pure virtual returns (uint256) {
        return _getArgUint88(113);
    }

    /// @notice The maximum total assets in value.
    /// @dev This value represents the maximum amount of assets that can be added to the pool.
    /// @return The maximum total assets in value.
    function maxTotalAssetsIn() public pure virtual returns (uint256) {
        return _getArgUint88(124);
    }

    /// @notice The platform fee percentage.
    /// @dev This percentage represents the fee collected by the platform on transactions.
    /// @return The platform fee percentage.
    function platformFee() public pure virtual returns (uint256) {
        return _getArgUint64(135);
    }

    /// @notice The referrer fee percentage.
    /// @dev This percentage represents the fee collected by referrers on transactions.
    /// @return The referrer fee percentage.
    function referrerFee() public pure virtual returns (uint256) {
        return _getArgUint64(143);
    }

    /// @notice The weight start value.
    /// @dev This value represents the starting weight for assets in the pool.
    /// @return The weight start value.
    function weightStart() public pure virtual returns (uint256) {
        return _getArgUint64(151);
    }

    /// @notice The weight end value.
    /// @dev This value represents the ending weight for assets in the pool.
    /// @return The weight end value.
    function weightEnd() public pure virtual returns (uint256) {
        return _getArgUint64(159);
    }

    /// @notice The sale start timestamp.
    /// @dev This timestamp represents when the sale of shares in the pool starts.
    /// @return The sale start timestamp.
    function saleStart() public pure virtual returns (uint256) {
        return _getArgUint40(167);
    }

    /// @notice The sale end timestamp.
    /// @dev This timestamp represents when the sale of shares in the pool ends.
    /// @return The sale end timestamp.
    function saleEnd() public pure virtual returns (uint256) {
        return _getArgUint40(172);
    }

    /// @notice The vesting cliff timestamp.
    /// @dev This timestamp represents the cliff time for vesting shares.
    /// @return The vesting cliff timestamp.
    function vestCliff() public pure virtual returns (uint40) {
        return _getArgUint40(177);
    }

    /// @notice The vesting end timestamp.
    /// @dev This timestamp represents the end time for vesting shares.
    /// @return The vesting end timestamp.
    function vestEnd() public pure virtual returns (uint40) {
        return _getArgUint40(182);
    }

    /// @notice The swap fee percentage.
    /// @dev This percentage represents the fee collected by swaps on transactions.
    /// @return The swap fee percentage.
    function swapFee() public pure virtual returns (uint256) {
        return _getArgUint64(187);
    }

    /// @notice Check if vesting shares is enabled.
    /// @dev This flag indicates whether vesting of shares is enabled.
    /// @return True if vesting shares are enabled, false otherwise.
    function vestShares() public pure virtual returns (bool) {
        return saleEnd() < vestEnd();
    }

    /// @notice Check if selling is allowed.
    /// @dev This flag indicates whether selling of shares is allowed.
    /// @return True if selling is allowed, false otherwise.
    function sellingAllowed() public pure virtual returns (bool) {
        return _getArgUint8(195) != 0;
    }

    /// @notice The Merkle root for the whitelist.
    /// @dev This is the Merkle root used for whitelisting addresses.
    /// @return The Merkle root for the whitelist.
    function whitelistMerkleRoot() public pure virtual returns (bytes32) {
        return _getArgBytes32(196);
    }

    /// @notice Check if the whitelist is enabled.
    /// @dev This flag indicates whether the whitelist is enabled.
    /// @return True if the whitelist is enabled, false otherwise.
    function whitelisted() public pure virtual returns (bool) {
        return whitelistMerkleRoot() != 0;
    }

    ISablierV2LockupLinear public immutable SABLIER;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Modifier to restrict access to whitelisted addresses.
    /// @dev This modifier checks if the caller's address is whitelisted using a Merkle proof.
    modifier onlyWhitelisted(bytes32[] memory proof) virtual {
        if (whitelisted()) {
            if (!proof.verify(whitelistMerkleRoot(), keccak256(abi.encodePacked(msg.sender)))) {
                revert WhitelistProof();
            }
        }
        _;
    }

    /// @notice Modifier to check if the sale is active.
    /// @dev This modifier checks if the current timestamp is within the sale period.
    modifier whenSaleActive() virtual {
        if (block.timestamp < saleStart() || block.timestamp >= saleEnd()) {
            revert TradingDisallowed();
        }
        _;
    }

    /// @notice Modifier to check if selling is allowed.
    /// @dev This modifier checks if selling of shares is allowed.
    modifier whenSellingAllowed() virtual {
        if (!sellingAllowed()) {
            revert SellingDisallowed();
        }
        _;
    }

    /**
     *
     *  CONSTRUCTOR & INITIALIZATION
     *
     */

    /**
     * @notice Initializes the contract with immutable variables
     * @param _sablier is the Sablier contract
     */
    constructor(address _sablier) {
        require(_sablier != address(0));

        SABLIER = ISablierV2LockupLinear(_sablier);
    }

    /// -----------------------------------------------------------------------
    /// Buy Logic
    /// -----------------------------------------------------------------------

    /// @notice Swap a specific amount of assets for a minimum number of shares.
    /// @dev This function allows users to exchange a certain amount of assets for shares,
    /// ensuring that they receive at least the specified minimum number of shares.
    /// @param assetsIn The amount of assets to be exchanged for shares.
    /// @param minSharesOut The minimum number of shares expected to be received.
    /// @param recipient The address to receive the shares.
    /// @return sharesOut The actual number of shares received.
    function swapExactAssetsForShares(
        uint256 assetsIn,
        uint256 minSharesOut,
        address recipient
    )
        external
        virtual
        returns (uint256 sharesOut)
    {
        return swapExactAssetsForShares(
            assetsIn, minSharesOut, recipient, address(0), MerkleProofLib.emptyProof()
        );
    }

    /// @notice Swap a specific number of shares for a maximum amount of assets.
    /// @dev This function allows users to exchange a certain number of shares for assets,
    /// ensuring that they receive no more than the specified maximum amount of assets.
    /// @param sharesOut The number of shares to be exchanged for assets.
    /// @param maxAssetsIn The maximum amount of assets allowed to be used for the exchange.
    /// @param recipient The address to receive the assets.
    /// @return assetsIn The actual amount of assets used for the exchange.
    function swapAssetsForExactShares(
        uint256 sharesOut,
        uint256 maxAssetsIn,
        address recipient
    )
        external
        virtual
        returns (uint256 assetsIn)
    {
        return swapAssetsForExactShares(
            sharesOut, maxAssetsIn, recipient, address(0), MerkleProofLib.emptyProof()
        );
    }

    /// @notice Swap a specific amount of assets for a minimum number of shares with a referrer.
    /// @dev This function allows users to exchange a certain amount of assets for shares
    /// while specifying a referrer, ensuring that they receive at least the specified minimum
    /// number of shares.
    /// @param assetsIn The amount of assets to be exchanged for shares.
    /// @param minSharesOut The minimum number of shares expected to be received.
    /// @param recipient The address to receive the shares.
    /// @param referrer The referrer's address for potential rewards.
    /// @return sharesOut The actual number of shares received.
    function swapExactAssetsForShares(
        uint256 assetsIn,
        uint256 minSharesOut,
        address recipient,
        address referrer
    )
        external
        virtual
        returns (uint256 sharesOut)
    {
        return swapExactAssetsForShares(
            assetsIn, minSharesOut, recipient, referrer, MerkleProofLib.emptyProof()
        );
    }

    /// @notice Swap a specific number of shares for a maximum amount of assets with a referrer.
    /// @dev This function allows users to exchange a certain number of shares for assets
    /// while specifying a referrer, ensuring that they receive no more than the specified maximum
    /// amount of assets.
    /// @param sharesOut The number of shares to be exchanged for assets.
    /// @param maxAssetsIn The maximum amount of assets allowed to be used for the exchange.
    /// @param recipient The address to receive the assets.
    /// @param referrer The referrer's address for potential rewards.
    /// @return assetsIn The actual amount of assets used for the exchange.
    function swapAssetsForExactShares(
        uint256 sharesOut,
        uint256 maxAssetsIn,
        address recipient,
        address referrer
    )
        external
        virtual
        returns (uint256 assetsIn)
    {
        return swapAssetsForExactShares(
            sharesOut, maxAssetsIn, recipient, referrer, MerkleProofLib.emptyProof()
        );
    }

    /// @notice Swap a specific amount of assets for a minimum number of shares with a referrer and Merkle proof.
    /// @dev This function allows users to exchange a certain amount of assets for shares
    /// while specifying a referrer, ensuring that they receive at least the specified minimum
    /// number of shares. It also requires a Merkle proof for whitelisting.
    /// @param assetsIn The amount of assets to be exchanged for shares.
    /// @param minSharesOut The minimum number of shares expected to be received.
    /// @param recipient The address to receive the shares.
    /// @param referrer The referrer's address for potential rewards.
    /// @param proof The Merkle proof for whitelisting.
    /// @return sharesOut The actual number of shares received.
    function swapExactAssetsForShares(
        uint256 assetsIn,
        uint256 minSharesOut,
        address recipient,
        address referrer,
        bytes32[] memory proof
    )
        public
        virtual
        whenNotPaused
        whenSaleActive
        onlyWhitelisted(proof)
        nonReentrant
        returns (uint256 sharesOut)
    {
        Pool memory pool = args();

        uint256 swapFees = assetsIn.mulWad(swapFee());
        totalSwapFeesAsset += swapFees;

        sharesOut = pool.previewSharesOut(assetsIn.rawSub(swapFees));

        if (sharesOut < minSharesOut) revert SlippageExceeded();

        _swapAssetsForShares(
            recipient, referrer, assetsIn, sharesOut, pool.assets, pool.shares, swapFees
        );
    }

    /// @notice Swap a specific number of shares for a maximum amount of assets with a referrer and Merkle proof.
    /// @dev This function allows users to exchange a certain number of shares for assets
    /// while specifying a referrer, ensuring that they receive no more than the specified maximum
    /// amount of assets. It also requires a Merkle proof for whitelisting.
    /// @param sharesOut The number of shares to be exchanged for assets.
    /// @param maxAssetsIn The maximum amount of assets allowed to be used for the exchange.
    /// @param recipient The address to receive the assets.
    /// @param referrer The referrer's address for potential rewards.
    /// @param proof The Merkle proof for whitelisting.
    /// @return assetsIn The actual amount of assets used for the exchange.
    function swapAssetsForExactShares(
        uint256 sharesOut,
        uint256 maxAssetsIn,
        address recipient,
        address referrer,
        bytes32[] memory proof
    )
        public
        virtual
        whenNotPaused
        whenSaleActive
        onlyWhitelisted(proof)
        nonReentrant
        returns (uint256 assetsIn)
    {
        Pool memory pool = args();

        assetsIn = pool.previewAssetsIn(sharesOut);
        uint256 swapFees = assetsIn.mulWad(swapFee());
        assetsIn = assetsIn.rawAdd(swapFees);
        totalSwapFeesAsset += swapFees;

        if (assetsIn > maxAssetsIn) revert SlippageExceeded();

        _swapAssetsForShares(
            recipient, referrer, assetsIn, sharesOut, pool.assets, pool.shares, swapFees
        );
    }

    function _swapAssetsForShares(
        address recipient,
        address referrer,
        uint256 assetsIn,
        uint256 sharesOut,
        uint256 assets,
        uint256 shares,
        uint256 swapFees
    )
        internal
        virtual
    {
        if (assets + assetsIn - swapFees >= maxTotalAssetsIn()) {
            revert AssetsInExceeded();
        }

        asset().safeTransferFrom(msg.sender, address(this), assetsIn);

        uint256 totalPurchasedAfter = totalPurchased + sharesOut;

        if (totalPurchasedAfter >= maxTotalSharesOut() || totalPurchasedAfter >= shares) {
            revert SharesOutExceeded();
        }

        totalPurchased = totalPurchasedAfter;

        purchasedShares[recipient] = purchasedShares[recipient].rawAdd(sharesOut);

        if (referrer != address(0) && referrerFee() != 0) {
            uint256 assetsReferred = assetsIn.mulWad(referrerFee());

            totalReferred += assetsReferred;

            referredAssets[referrer] = referredAssets[referrer].rawAdd(assetsReferred);
        }

        emit Buy(msg.sender, assetsIn, sharesOut, swapFees);
    }

    /// -----------------------------------------------------------------------
    /// Sell Logic
    /// -----------------------------------------------------------------------

    /// @notice Swap a specific number of shares for a minimum amount of assets.
    /// @dev This function allows users to exchange a certain number of shares for assets,
    /// ensuring that they receive at least the specified minimum amount of assets.
    /// @param sharesIn The number of shares to be exchanged for assets.
    /// @param minAssetsOut The minimum amount of assets expected to be received.
    /// @param recipient The address to receive the assets.
    /// @return assetsOut The actual amount of assets received.
    function swapExactSharesForAssets(
        uint256 sharesIn,
        uint256 minAssetsOut,
        address recipient
    )
        external
        virtual
        returns (uint256 assetsOut)
    {
        return
            swapExactSharesForAssets(sharesIn, minAssetsOut, recipient, MerkleProofLib.emptyProof());
    }

    /// @notice Swap a specific number of shares for a maximum amount of assets.
    /// @dev This function allows users to exchange a certain number of shares for assets,
    /// ensuring that they receive no more than the specified maximum amount of assets.
    /// @param assetsOut The maximum amount of assets allowed to be received.
    /// @param maxSharesIn The number of shares to be exchanged for assets.
    /// @param recipient The address to receive the assets.
    /// @return sharesIn The actual number of shares used for the exchange.
    function swapSharesForExactAssets(
        uint256 assetsOut,
        uint256 maxSharesIn,
        address recipient
    )
        external
        virtual
        returns (uint256 sharesIn)
    {
        return
            swapSharesForExactAssets(assetsOut, maxSharesIn, recipient, MerkleProofLib.emptyProof());
    }

    /// @notice Swap a specific number of shares for a minimum amount of assets.
    /// @dev This function allows users to exchange a certain number of shares for assets,
    /// ensuring that they receive at least the specified minimum amount of assets.
    /// @param sharesIn The number of shares to be exchanged for assets.
    /// @param minAssetsOut The minimum amount of assets expected to be received.
    /// @param recipient The address to receive the assets.
    /// @param proof The Merkle proof for whitelisting.
    /// @return assetsOut The actual amount of assets received.
    function swapExactSharesForAssets(
        uint256 sharesIn,
        uint256 minAssetsOut,
        address recipient,
        bytes32[] memory proof
    )
        public
        virtual
        whenNotPaused
        whenSellingAllowed
        onlyWhitelisted(proof)
        whenSaleActive
        nonReentrant
        returns (uint256 assetsOut)
    {
        Pool memory pool = args();

        uint256 swapFees = sharesIn.mulWad(swapFee());
        totalSwapFeesShare += swapFees;

        assetsOut = pool.previewAssetsOut(sharesIn.rawSub(swapFees));

        if (assetsOut < minAssetsOut) revert SlippageExceeded();

        _swapSharesForAssets(recipient, assetsOut, sharesIn, pool.assets, pool.shares, swapFees);
    }

    /// @notice Swap a specific number of shares for a maximum amount of assets.
    /// @dev This function allows users to exchange a certain number of shares for assets,
    /// ensuring that they receive no more than the specified maximum amount of assets.
    /// @param assetsOut The maximum amount of assets allowed to be received.
    /// @param maxSharesIn The number of shares to be exchanged for assets.
    /// @param recipient The address to receive the assets.
    /// @param proof The Merkle proof for whitelisting.
    /// @return sharesIn The actual number of shares used for the exchange.
    function swapSharesForExactAssets(
        uint256 assetsOut,
        uint256 maxSharesIn,
        address recipient,
        bytes32[] memory proof
    )
        public
        virtual
        whenNotPaused
        whenSellingAllowed
        onlyWhitelisted(proof)
        whenSaleActive
        nonReentrant
        returns (uint256 sharesIn)
    {
        Pool memory pool = args();

        sharesIn = pool.previewSharesIn(assetsOut);
        uint256 swapFees = sharesIn.mulWad(swapFee());
        sharesIn += swapFees;
        totalSwapFeesShare += swapFees;

        if (sharesIn > maxSharesIn) revert SlippageExceeded();

        _swapSharesForAssets(recipient, assetsOut, sharesIn, pool.assets, pool.shares, swapFees);
    }

    function _swapSharesForAssets(
        address recipient,
        uint256 assetsOut,
        uint256 sharesIn,
        uint256 assets,
        uint256 shares,
        uint256 swapFees
    )
        internal
        virtual
    {
        if (assets >= maxTotalAssetsIn()) {
            revert AssetsInExceeded();
        }

        uint256 totalPurchasedBefore = totalPurchased;

        if (totalPurchasedBefore >= maxTotalSharesOut() || totalPurchasedBefore >= shares) {
            revert SharesOutExceeded();
        }

        purchasedShares[msg.sender] -= sharesIn;

        totalPurchased = totalPurchasedBefore.rawSub(sharesIn);

        asset().safeTransfer(recipient, assetsOut);

        emit Sell(msg.sender, sharesIn, assetsOut, swapFees);
    }

    /// -----------------------------------------------------------------------
    /// Close Logic
    /// -----------------------------------------------------------------------

    /// @notice Close the pool and distribute assets and shares accordingly.
    /// @dev This function closes the pool after the sale has ended and distributes
    /// assets to the platform fee and the manager, and shares to the manager for
    /// any unsold shares. Once closed, the pool cannot be used for further transactions.
    function close() external virtual {
        if (closed) revert ClosingDisallowed();
        if (block.timestamp < saleEnd()) revert ClosingDisallowed();

        uint256 totalAssets = asset().balanceOf(address(this)).rawSub(totalSwapFeesAsset);
        uint256 platformFees = totalAssets.mulWad(platformFee());
        uint256 totalAssetsMinusFees = totalAssets.rawSub(platformFees).rawSub(totalReferred);

        if (totalAssets != 0) {
            // Transfer and distribute fees
            asset().safeTransfer(platform(), platformFees + totalSwapFeesAsset);
            share().safeTransfer(platform(), totalSwapFeesShare);
            Treasury(platform()).distributeFee(
                asset(), platformFees, totalSwapFeesAsset, share(), totalSwapFeesShare
            );

            // Transfer asset
            asset().safeTransfer(manager(), totalAssetsMinusFees);
        }

        uint256 totalShares = share().balanceOf(address(this));
        uint256 unsoldShares = totalShares.rawSub(totalPurchased);

        if (totalShares != 0) {
            share().safeTransfer(manager(), unsoldShares);
        }

        closed = true;

        share().safeApprove(address(SABLIER), totalShares);

        emit Close(totalAssetsMinusFees, platformFees, totalSwapFeesAsset, totalSwapFeesShare);
    }

    /// -----------------------------------------------------------------------
    /// Redeem Logic
    /// -----------------------------------------------------------------------

    /// @notice Redeem shares and, if referred, assets.
    /// @dev This function allows users to redeem their shares and, if they
    /// have been referred, receive assets. If vesting is enabled, shares will
    /// vest over a certain period, and the user can redeem a portion of their
    /// vested shares at any time. Once shares are fully vested, the user can
    /// redeem all of them.
    /// @param recipient The address to receive redeemed shares and assets.
    /// @param referred A boolean indicating whether the user has been referred.
    /// @return shares The number of shares redeemed.
    function redeem(address recipient, bool referred) external virtual returns (uint256 shares) {
        if (!closed) revert RedeemingDisallowed();

        uint256 streamID;

        if (vestShares() && vestEnd() > block.timestamp) {
            shares = purchasedShares[msg.sender];
            delete purchasedShares[msg.sender];

            LockupLinear.CreateWithRange memory params;

            params.sender = manager();
            params.recipient = msg.sender;
            params.totalAmount = uint128(shares);
            params.asset = IERC20(share());
            params.cancelable = false;
            params.range =
                LockupLinear.Range({ start: uint40(saleEnd()), cliff: vestCliff(), end: vestEnd() });
            params.broker = Broker(address(0), ud60x18(0));

            streamID = SABLIER.createWithRange(params);
        } else {
            shares = purchasedShares[msg.sender];

            delete purchasedShares[msg.sender];

            share().safeTransfer(msg.sender, shares);
        }

        if (referred && referrerFee() != 0) {
            uint256 assets = referredAssets[msg.sender];

            delete referredAssets[msg.sender];

            asset().safeTransfer(recipient, assets);
        }

        if (shares != 0) {
            emit Redeem(msg.sender, streamID, shares);
        }
    }

    /// -----------------------------------------------------------------------
    /// Management
    /// -----------------------------------------------------------------------

    /// @notice Toggle the pause state of the pool.
    /// @dev This function allows the manager to pause and unpause the pool.
    /// When the pool is paused, no new swaps can be executed.
    function togglePause() external virtual {
        if (msg.sender != manager()) {
            revert CallerDisallowed();
        }

        _togglePause();
    }

    /// -----------------------------------------------------------------------
    /// Swap Helper Logic
    /// -----------------------------------------------------------------------

    /// @notice Get the pool arguments including reserves, weights, and other parameters.
    /// @dev This function returns the current pool configuration including asset
    /// and share reserves, weights, and other parameters.
    /// @return pool A struct containing the pool configuration.
    function args() public view virtual returns (Pool memory) {
        return Pool(
            asset(),
            share(),
            asset().balanceOf(address(this)).rawSub(totalSwapFeesAsset),
            share().balanceOf(address(this)).rawSub(totalSwapFeesShare),
            virtualAssets(),
            virtualShares(),
            weightStart(),
            weightEnd(),
            saleStart(),
            saleEnd(),
            totalPurchased,
            maxSharePrice()
        );
    }

    /// @notice Get the reserves and weights of the pool.
    /// @dev This function returns the current asset and share reserves, as well
    /// as the asset and share weights.
    /// @return assetReserve The current asset reserve.
    /// @return shareReserve The current share reserve.
    /// @return assetWeight The asset weight.
    /// @return shareWeight The share weight.
    function reservesAndWeights()
        external
        view
        virtual
        returns (
            uint256 assetReserve,
            uint256 shareReserve,
            uint256 assetWeight,
            uint256 shareWeight
        )
    {
        return args().computeReservesAndWeights();
    }

    /// @notice Preview the amount of assets required to receive a specific number of shares.
    /// @dev This function calculates the amount of assets needed to obtain a certain
    /// number of shares based on the current pool configuration.
    /// @param sharesOut The number of shares desired.
    /// @return assetsIn The amount of assets required.
    function previewAssetsIn(uint256 sharesOut) external view virtual returns (uint256 assetsIn) {
        return args().previewAssetsIn(sharesOut).mulWad(1e18 + swapFee());
    }

    /// @notice Preview the number of shares that will be received for a specific amount of assets.
    /// @dev This function calculates the number of shares that will be received for a
    /// given amount of assets based on the current pool configuration.
    /// @param assetsIn The amount of assets used.
    /// @return sharesOut The number of shares received.
    function previewSharesOut(uint256 assetsIn) external view virtual returns (uint256 sharesOut) {
        return args().previewSharesOut(assetsIn.mulWad(1e18 - swapFee()));
    }

    /// @notice Preview the number of shares that need to be used to obtain a specific amount of assets.
    /// @dev This function calculates the number of shares required to obtain a certain
    /// amount of assets based on the current pool configuration.
    /// @param assetsOut The amount of assets desired.
    /// @return sharesIn The number of shares required.
    function previewSharesIn(uint256 assetsOut) external view virtual returns (uint256 sharesIn) {
        return args().previewSharesIn(assetsOut).mulWad(1e18 + swapFee());
    }

    /// @notice Preview the amount of assets that will be received for a specific number of shares.
    /// @dev This function calculates the amount of assets that will be received for a
    /// given number of shares based on the current pool configuration.
    /// @param sharesIn The number of shares used.
    /// @return assetsOut The amount of assets received.
    function previewAssetsOut(uint256 sharesIn) external view virtual returns (uint256 assetsOut) {
        return args().previewAssetsOut(sharesIn.mulWad(1e18 - swapFee()));
    }
}

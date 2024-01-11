// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./VersionedInitializable.sol";
import "./Errors.sol";
import "./ReserveConfiguration.sol";
import "./PoolLogic.sol";
import "./ReserveLogic.sol";
import "./SupplyLogic.sol";
import "./BorrowLogic.sol";
import "./LiquidationLogic.sol";
import "./DataTypes.sol";
import "./IERC20WithPermit.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";
import "./IACLManager.sol";
import "./PoolStorage.sol";
import "./FlashClaimLogic.sol";
import "./Address.sol";

/**
 * @title Pool contract
 *
 * @notice Main point of interaction with an Omni protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Liquidate positions
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract Pool is VersionedInitializable, PoolStorage, IPool {
    using ReserveLogic for DataTypes.ReserveData;
    using Address for address;

    uint256 public constant POOL_REVISION = 3;
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     **/
    modifier onlyPoolConfigurator() {
        _onlyPoolConfigurator();
        _;
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    function _onlyPoolConfigurator() internal view virtual {
        require(
            ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender,
            Errors.CALLER_NOT_POOL_CONFIGURATOR
        );
    }

    function _onlyPoolAdmin() internal view virtual {
        require(
            IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(
                msg.sender
            ),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    /**
     * @notice Initializes the Pool.
     * @dev Function is invoked by the proxy contract when the Pool contract is added to the
     * PoolAddressesProvider of the market.
     * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param provider The address of the PoolAddressesProvider
     **/
    function initialize(IPoolAddressesProvider provider)
        external
        virtual
        initializer
    {
        require(
            provider == ADDRESSES_PROVIDER,
            Errors.INVALID_ADDRESSES_PROVIDER
        );
        _maxStableRateBorrowSizePercent = 0.25e4;
    }

    /// @inheritdoc IPool
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) public virtual override {
        SupplyLogic.executeSupply(
            _reserves,
            _reservesList,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) public virtual override {
        SupplyLogic.executeSupplyERC721(
            _reserves,
            _reservesList,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyERC721Params({
                asset: asset,
                tokenData: tokenData,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) public virtual override {
        // Need to accomodate ERC721 and ERC1155 here
        IERC20WithPermit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );
        SupplyLogic.executeSupply(
            _reserves,
            _reservesList,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) public virtual override returns (uint256) {
        return
            SupplyLogic.executeWithdraw(
                _reserves,
                _reservesList,
                _usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawParams({
                    asset: asset,
                    amount: amount,
                    to: to,
                    reservesCount: _reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) public virtual override returns (uint256) {
        return
            SupplyLogic.executeWithdrawERC721(
                _reserves,
                _reservesList,
                _usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawERC721Params({
                    asset: asset,
                    tokenIds: tokenIds,
                    to: to,
                    reservesCount: _reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) public virtual override {
        BorrowLogic.executeBorrow(
            _reserves,
            _reservesList,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteBorrowParams({
                asset: asset,
                user: msg.sender,
                onBehalfOf: onBehalfOf,
                amount: amount,
                interestRateMode: DataTypes.InterestRateMode(interestRateMode),
                referralCode: referralCode,
                releaseUnderlying: true,
                maxStableRateBorrowSizePercent: _maxStableRateBorrowSizePercent,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) public virtual override returns (uint256) {
        return
            BorrowLogic.executeRepay(
                _reserves,
                _reservesList,
                _usersConfig[onBehalfOf],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: onBehalfOf,
                    useOTokens: false
                })
            );
    }

    /// @inheritdoc IPool
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) public virtual override returns (uint256) {
        {
            IERC20WithPermit(asset).permit(
                msg.sender,
                address(this),
                amount,
                deadline,
                permitV,
                permitR,
                permitS
            );
        }
        {
            DataTypes.ExecuteRepayParams memory params = DataTypes
                .ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: onBehalfOf,
                    useOTokens: false
                });
            return
                BorrowLogic.executeRepay(
                    _reserves,
                    _reservesList,
                    _usersConfig[onBehalfOf],
                    params
                );
        }
    }

    /// @inheritdoc IPool
    function repayWithOTokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) public virtual override returns (uint256) {
        return
            BorrowLogic.executeRepay(
                _reserves,
                _reservesList,
                _usersConfig[msg.sender],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: msg.sender,
                    useOTokens: true
                })
            );
    }

    /// @inheritdoc IPool
    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        public
        virtual
        override
    {
        BorrowLogic.executeSwapBorrowRateMode(
            _reserves[asset],
            _usersConfig[msg.sender],
            asset,
            DataTypes.InterestRateMode(interestRateMode)
        );
    }

    /// @inheritdoc IPool
    function rebalanceStableBorrowRate(address asset, address user)
        public
        virtual
        override
    {
        BorrowLogic.executeRebalanceStableBorrowRate(
            _reserves[asset],
            asset,
            user
        );
    }

    /// @inheritdoc IPool
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        public
        virtual
        override
    {
        SupplyLogic.executeUseReserveAsCollateral(
            _reserves,
            _reservesList,
            _usersConfig[msg.sender],
            asset,
            useAsCollateral,
            _reservesCount,
            ADDRESSES_PROVIDER.getPriceOracle()
        );
    }

    function setUserUseERC721AsCollateral(
        address asset,
        uint256 tokenId,
        bool useAsCollateral
    ) public virtual override {
        SupplyLogic.executeUseERC721AsCollateral(
            _reserves,
            _reservesList,
            _usersConfig[msg.sender],
            asset,
            tokenId,
            useAsCollateral,
            _reservesCount,
            ADDRESSES_PROVIDER.getPriceOracle()
        );
    }

    /// @inheritdoc IPool
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveOToken
    ) public virtual override {
        LiquidationLogic.executeLiquidationCall(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.ExecuteLiquidationCallParams({
                reservesCount: _reservesCount,
                liquidationAmount: debtToCover,
                collateralAsset: collateralAsset,
                liquidationAsset: debtAsset,
                user: user,
                receiveXToken: receiveOToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel(),
                collateralTokenId: 0
            })
        );
    }

    /// @inheritdoc IPool
    function liquidationERC721(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) public virtual override {
        LiquidationLogic.executeERC721LiquidationCall(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.ExecuteLiquidationCallParams({
                reservesCount: _reservesCount,
                liquidationAmount: liquidationAmount,
                liquidationAsset: liquidationAsset,
                collateralAsset: collateralAsset,
                collateralTokenId: collateralTokenId,
                user: user,
                receiveXToken: receiveNToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function flashClaim(
        address receiverAddress,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external virtual override {
        FlashClaimLogic.executeFlashClaim(
            _reserves,
            DataTypes.ExecuteFlashClaimParams({
                receiverAddress: receiverAddress,
                nftAsset: nftAsset,
                nftTokenIds: nftTokenIds,
                params: params
            })
        );
    }

    /// @inheritdoc IPool
    function mintToTreasury(address[] calldata assets)
        external
        virtual
        override
    {
        PoolLogic.executeMintToTreasury(_reserves, assets);
    }

    /// @inheritdoc IPool
    function getReserveData(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[asset];
    }

    /// @inheritdoc IPool
    function getUserAccountData(address user)
        external
        view
        virtual
        override
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        )
    {
        return
            PoolLogic.executeGetUserAccountData(
                _reserves,
                _reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: _usersConfig[user],
                    reservesCount: _reservesCount,
                    user: user,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function getConfiguration(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[asset].configuration;
    }

    /// @inheritdoc IPool
    function getUserConfiguration(address user)
        external
        view
        virtual
        override
        returns (DataTypes.UserConfigurationMap memory)
    {
        return _usersConfig[user];
    }

    /// @inheritdoc IPool
    function getReserveNormalizedIncome(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedIncome();
    }

    /// @inheritdoc IPool
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedDebt();
    }

    /// @inheritdoc IPool
    function getReservesList()
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        uint256 reservesListCount = _reservesCount;
        uint256 droppedReservesCount = 0;
        address[] memory reservesList = new address[](reservesListCount);

        for (uint256 i = 0; i < reservesListCount; i++) {
            if (_reservesList[i] != address(0)) {
                reservesList[i - droppedReservesCount] = _reservesList[i];
            } else {
                droppedReservesCount++;
            }
        }

        // Reduces the length of the reserves array by `droppedReservesCount`
        assembly {
            mstore(reservesList, sub(reservesListCount, droppedReservesCount))
        }
        return reservesList;
    }

    /// @inheritdoc IPool
    function getReserveAddressById(uint16 id) external view returns (address) {
        return _reservesList[id];
    }

    /// @inheritdoc IPool
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _maxStableRateBorrowSizePercent;
    }

    /// @inheritdoc IPool
    function MAX_NUMBER_RESERVES()
        public
        view
        virtual
        override
        returns (uint16)
    {
        return ReserveConfiguration.MAX_RESERVES_COUNT;
    }

    /// @inheritdoc IPool
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 value,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external virtual override {
        require(
            msg.sender == _reserves[asset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );
        SupplyLogic.executeFinalizeTransfer(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.FinalizeTransferParams({
                asset: asset,
                from: from,
                to: to,
                usedAsCollateral: usedAsCollateral,
                value: value,
                balanceFromBefore: balanceFromBefore,
                balanceToBefore: balanceToBefore,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPool
    function initReserve(
        address asset,
        DataTypes.AssetType assetType,
        address xTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        if (
            PoolLogic.executeInitReserve(
                _reserves,
                _reservesList,
                DataTypes.InitReserveParams({
                    asset: asset,
                    assetType: assetType,
                    xTokenAddress: xTokenAddress,
                    stableDebtAddress: stableDebtAddress,
                    variableDebtAddress: variableDebtAddress,
                    interestRateStrategyAddress: interestRateStrategyAddress,
                    reservesCount: _reservesCount,
                    maxNumberReserves: MAX_NUMBER_RESERVES()
                })
            )
        ) {
            _reservesCount++;
        }
    }

    /// @inheritdoc IPool
    function dropReserve(address asset)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
    }

    /// @inheritdoc IPool
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            _reserves[asset].id != 0 || _reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /// @inheritdoc IPool
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external virtual override onlyPoolConfigurator {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            _reserves[asset].id != 0 || _reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        _reserves[asset].configuration = configuration;
    }

    /// @inheritdoc IPool
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external virtual override onlyPoolAdmin {
        PoolLogic.executeRescueTokens(token, to, amount);
    }
}

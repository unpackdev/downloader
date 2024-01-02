// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./Initializable.sol";
import "./Errors.sol";
import "./ReserveConfiguration.sol";
import "./PoolLogic.sol";
import "./ReserveLogic.sol";
import "./SupplyLogic.sol";
import "./FlashLoanLogic.sol";
import "./BorrowLogic.sol";
import "./LiquidationLogic.sol";
import "./DataTypes.sol";
import "./IERC20WithPermit.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";
import "./IACLManager.sol";
import "./PoolStorage.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title Pool contract
 *
 * @notice Main point of interaction with an YLDR protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Enable/disable their supplied assets as collateral
 *   # Liquidate positions
 *   # Execute Flash Loans
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 */
contract Pool is Initializable, PoolStorage, ReentrancyGuardUpgradeable, IPool {
    using ReserveLogic for DataTypes.ReserveData;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     */
    modifier onlyPoolConfigurator() {
        _onlyPoolConfigurator();
        _;
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     */
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    function _onlyPoolConfigurator() internal view virtual {
        require(ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender, Errors.CALLER_NOT_POOL_CONFIGURATOR);
    }

    function _onlyPoolAdmin() internal view virtual {
        require(IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
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
     */
    function initialize(IPoolAddressesProvider provider) external virtual initializer {
        require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);

        __ReentrancyGuard_init();
    }

    /// @inheritdoc IPool
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        public
        virtual
        override
        nonReentrant
    {
        SupplyLogic.executeSupply(
            _reserves,
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
    function supplyERC1155(address asset, uint256 tokenId, uint256 amount, address onBehalfOf, uint16 referralCode)
        public
        virtual
        override
        nonReentrant
    {
        SupplyLogic.executeSupplyERC1155(
            _erc1155Reserves,
            _usersERC1155Config[onBehalfOf],
            DataTypes.ExecuteSupplyERC1155Params({
                asset: asset,
                tokenId: tokenId,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode,
                maxERC1155CollateralReserves: _maxERC1155CollateralReserves
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
    ) public virtual override nonReentrant {
        IERC20WithPermit(asset).permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
        SupplyLogic.executeSupply(
            _reserves,
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
    function withdraw(address asset, uint256 amount, address to)
        public
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        return SupplyLogic.executeWithdraw(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig[msg.sender],
            _usersERC1155Config[msg.sender],
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
    function withdrawERC1155(address asset, uint256 tokenId, uint256 amount, address to)
        public
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        return SupplyLogic.executeWithdrawERC1155(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig[msg.sender],
            _usersERC1155Config[msg.sender],
            DataTypes.ExecuteWithdrawERC1155Params({
                asset: asset,
                tokenId: tokenId,
                amount: amount,
                to: to,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPool
    function borrow(address asset, uint256 amount, uint16 referralCode, address onBehalfOf)
        public
        virtual
        override
        nonReentrant
    {
        BorrowLogic.executeBorrow(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig[onBehalfOf],
            _usersERC1155Config[onBehalfOf],
            DataTypes.ExecuteBorrowParams({
                asset: asset,
                user: msg.sender,
                onBehalfOf: onBehalfOf,
                amount: amount,
                referralCode: referralCode,
                releaseUnderlying: true,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function repay(address asset, uint256 amount, address onBehalfOf)
        public
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        return BorrowLogic.executeRepay(
            _reserves,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteRepayParams({asset: asset, amount: amount, onBehalfOf: onBehalfOf, useYTokens: false})
        );
    }

    /// @inheritdoc IPool
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) public virtual override nonReentrant returns (uint256) {
        {
            IERC20WithPermit(asset).permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
        }
        {
            DataTypes.ExecuteRepayParams memory params =
                DataTypes.ExecuteRepayParams({asset: asset, amount: amount, onBehalfOf: onBehalfOf, useYTokens: false});
            return BorrowLogic.executeRepay(_reserves, _usersConfig[onBehalfOf], params);
        }
    }

    /// @inheritdoc IPool
    function repayWithYTokens(address asset, uint256 amount) public virtual override nonReentrant returns (uint256) {
        return BorrowLogic.executeRepay(
            _reserves,
            _usersConfig[msg.sender],
            DataTypes.ExecuteRepayParams({asset: asset, amount: amount, onBehalfOf: msg.sender, useYTokens: true})
        );
    }

    /// @inheritdoc IPool
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) public virtual override nonReentrant {
        SupplyLogic.executeUseReserveAsCollateral(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig[msg.sender],
            _usersERC1155Config[msg.sender],
            asset,
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
        bool receiveYToken
    ) public virtual override nonReentrant {
        LiquidationLogic.executeLiquidationCall(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig,
            _usersERC1155Config,
            DataTypes.ExecuteLiquidationCallParams({
                reservesCount: _reservesCount,
                debtToCover: debtToCover,
                collateralAsset: collateralAsset,
                debtAsset: debtAsset,
                user: user,
                receiveYToken: receiveYToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function erc1155LiquidationCall(
        address collateralAsset,
        uint256 collateralTokenId,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveNToken
    ) public virtual override nonReentrant {
        LiquidationLogic.executeERC1155LiquidationCall(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig,
            _usersERC1155Config,
            DataTypes.ExecuteERC1155LiquidationCallParams({
                reservesCount: _reservesCount,
                debtToCover: debtToCover,
                collateralAsset: collateralAsset,
                collateralTokenId: collateralTokenId,
                debtAsset: debtAsset,
                user: user,
                receiveNToken: receiveNToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel(),
                maxERC1155CollateralReserves: _maxERC1155CollateralReserves
            })
        );
    }

    /// @inheritdoc IPool
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        bool[] calldata createPosition,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) public virtual override {
        DataTypes.FlashloanParams memory flashParams = DataTypes.FlashloanParams({
            receiverAddress: receiverAddress,
            assets: assets,
            amounts: amounts,
            createPosition: createPosition,
            onBehalfOf: onBehalfOf,
            params: params,
            referralCode: referralCode,
            flashLoanPremiumToProtocol: _flashLoanPremiumToProtocol,
            flashLoanPremiumTotal: _flashLoanPremiumTotal,
            reservesCount: _reservesCount,
            addressesProvider: address(ADDRESSES_PROVIDER),
            isAuthorizedFlashBorrower: IACLManager(ADDRESSES_PROVIDER.getACLManager()).isFlashBorrower(msg.sender)
        });

        FlashLoanLogic.executeFlashLoan(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig[onBehalfOf],
            _usersERC1155Config[onBehalfOf],
            flashParams
        );
    }

    /// @inheritdoc IPool
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) public virtual override {
        DataTypes.FlashloanSimpleParams memory flashParams = DataTypes.FlashloanSimpleParams({
            receiverAddress: receiverAddress,
            asset: asset,
            amount: amount,
            params: params,
            referralCode: referralCode,
            flashLoanPremiumToProtocol: _flashLoanPremiumToProtocol,
            flashLoanPremiumTotal: _flashLoanPremiumTotal
        });
        FlashLoanLogic.executeFlashLoanSimple(_reserves[asset], flashParams);
    }

    /// @inheritdoc IPool
    function mintToTreasury(address[] calldata assets) external virtual override {
        PoolLogic.executeMintToTreasury(_reserves, assets);
    }

    /// @inheritdoc IPool
    function getReserveData(address asset) external view virtual override returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }

    /// @inheritdoc IPool
    function getERC1155ReserveData(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ERC1155ReserveData memory)
    {
        return _erc1155Reserves[asset];
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
            uint256 healthFactor
        )
    {
        DataTypes.CalculateUserAccountDataParams memory params = DataTypes.CalculateUserAccountDataParams({
            userConfig: _usersConfig[user],
            reservesCount: _reservesCount,
            user: user,
            oracle: ADDRESSES_PROVIDER.getPriceOracle()
        });
        return PoolLogic.executeGetUserAccountData(
            _reserves, _reservesList, _erc1155Reserves, _usersERC1155Config[user], params
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
    function getUserUsedERC1155Reserves(address user)
        external
        view
        returns (DataTypes.ERC1155ReserveUsageData[] memory)
    {
        return _usersERC1155Config[user].usedERC1155Reserves;
    }

    /// @inheritdoc IPool
    function getReserveNormalizedIncome(address asset) external view virtual override returns (uint256) {
        return _reserves[asset].getNormalizedIncome();
    }

    /// @inheritdoc IPool
    function getReserveNormalizedVariableDebt(address asset) external view virtual override returns (uint256) {
        return _reserves[asset].getNormalizedDebt();
    }

    /// @inheritdoc IPool
    function getReservesList() external view virtual override returns (address[] memory) {
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
    function FLASHLOAN_PREMIUM_TOTAL() public view virtual override returns (uint128) {
        return _flashLoanPremiumTotal;
    }

    /// @inheritdoc IPool
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() public view virtual override returns (uint128) {
        return _flashLoanPremiumToProtocol;
    }

    /// @inheritdoc IPool
    function MAX_NUMBER_RESERVES() public view virtual override returns (uint16) {
        return ReserveConfiguration.MAX_RESERVES_COUNT;
    }

    /// @inheritdoc IPool
    function MAX_ERC1155_COLLATERAL_RESERVES() public view virtual override returns (uint256) {
        return _maxERC1155CollateralReserves;
    }

    /// @inheritdoc IPool
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external virtual override nonReentrant {
        require(msg.sender == _reserves[asset].yTokenAddress, Errors.CALLER_NOT_YTOKEN);
        SupplyLogic.executeFinalizeTransfer(
            _reserves,
            _reservesList,
            _erc1155Reserves,
            _usersConfig,
            _usersERC1155Config,
            DataTypes.FinalizeTransferParams({
                asset: asset,
                from: from,
                to: to,
                amount: amount,
                balanceFromBefore: balanceFromBefore,
                balanceToBefore: balanceToBefore,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPool
    function finalizeERC1155Transfer(
        address asset,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external virtual override nonReentrant {
        require(msg.sender == _erc1155Reserves[asset].nTokenAddress, Errors.CALLER_NOT_NTOKEN);
        DataTypes.FinalizeERC1155TransferParams memory params = DataTypes.FinalizeERC1155TransferParams({
            asset: asset,
            from: from,
            to: to,
            ids: ids,
            amounts: amounts,
            reservesCount: _reservesCount,
            oracle: ADDRESSES_PROVIDER.getPriceOracle(),
            maxERC1155CollateralReserves: _maxERC1155CollateralReserves
        });
        SupplyLogic.executeFinalizeERC1155Transfer(
            _reserves, _reservesList, _erc1155Reserves, _usersConfig, _usersERC1155Config, params
        );
    }

    /// @inheritdoc IPool
    function initReserve(
        address asset,
        address yTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        if (
            PoolLogic.executeInitReserve(
                _reserves,
                _reservesList,
                DataTypes.InitReserveParams({
                    asset: asset,
                    yTokenAddress: yTokenAddress,
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
    function initERC1155Reserve(address asset, address nTokenAddress, address configurationProvider)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        PoolLogic.executeInitERC1155Reserve(
            _erc1155Reserves,
            DataTypes.InitERC1155ReserveParams({
                asset: asset,
                nTokenAddress: nTokenAddress,
                configurationProvider: configurationProvider
            })
        );
    }

    /// @inheritdoc IPool
    function dropReserve(address asset) external virtual override onlyPoolConfigurator {
        PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
    }

    /// @inheritdoc IPool
    function dropERC1155Reserve(address asset) external virtual override onlyPoolConfigurator {
        PoolLogic.executeDropERC1155Reserve(_erc1155Reserves, asset);
    }

    /// @inheritdoc IPool
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /// @inheritdoc IPool
    function setERC1155ReserveConfigurationProvider(address asset, address configurationProvider)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(_erc1155Reserves[asset].nTokenAddress != address(0), Errors.ASSET_NOT_LISTED);
        _erc1155Reserves[asset].configurationProvider = configurationProvider;
    }

    /// @inheritdoc IPool
    function setERC1155ReserveLiquidationProtocolFee(address asset, uint256 liquidationProtocolFee)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(_erc1155Reserves[asset].nTokenAddress != address(0), Errors.ASSET_NOT_LISTED);

        _erc1155Reserves[asset].liquidationProtocolFee = liquidationProtocolFee;
    }

    /// @inheritdoc IPool
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
        _reserves[asset].configuration = configuration;
    }

    /// @inheritdoc IPool
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        _flashLoanPremiumTotal = flashLoanPremiumTotal;
        _flashLoanPremiumToProtocol = flashLoanPremiumToProtocol;
    }

    /// @inheritdoc IPool
    function updateMaxERC1155CollateralReserves(uint256 maxERC1155CollateralReservesNumber)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        _maxERC1155CollateralReserves = maxERC1155CollateralReservesNumber;
    }

    /// @inheritdoc IPool
    function rescueTokens(address token, address to, uint256 amount) external virtual override onlyPoolAdmin {
        PoolLogic.executeRescueTokens(token, to, amount);
    }
}

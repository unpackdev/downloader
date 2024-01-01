// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ContextUpgradeable.sol";
import "./IKyokoFactory.sol";
import "./IKyokoPool.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./IKyokoPoolConfigurator.sol";
import "./IInterestRateStrategy.sol";
import "./IKToken.sol";
import "./IStableDebtToken.sol";
import "./IVariableDebtToken.sol";
import "./Errors.sol";
import "./VariableDebtToken.sol";

contract KyokoFactory is IKyokoFactory, ContextUpgradeable {
    address internal WETH;
    IKyokoPoolAddressesProvider public _addressesProvider;
    address public _treasury;
    uint16 public _factor;
    uint40 internal MIN_BORROW_TIME;
    uint256 public _initilLiquidity = 0.01 ether;
    uint16 public _liquidationThreshold = 13333;
    uint32 public _lockTime = 30 days;
    bool only = true;

    address internal _createKToken;
    address internal _createDebtToken;

    string private s1 = " ";
    string private s2 = "ETH";

    mapping(address => address) public kTokenCreator;
    mapping(address => address) public sTokenCreator;
    mapping(address => address) public vTokenCreator;

    modifier onlyPoolAdmin() {
        require(
            _addressesProvider.isAdmin(_msgSender()),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    modifier onlyPoolAdminCreater() {
        if (only) {
            require(
                _addressesProvider.isAdmin(_msgSender()),
                Errors.CALLER_NOT_POOL_ADMIN
            );
        }
        _;
    }

    modifier onlyKyokoPoolConfigurator() {
        _onlyKyokoPoolConfigurator();
        _;
    }

    function _onlyKyokoPoolConfigurator() internal view {
        require(
            _addressesProvider.isConfigurator(_msgSender()),
            Errors.LP_CALLER_NOT_KYOKO_POOL_CONFIGURATOR
        );
    }

    constructor(
        address weth,
        address provider,
        address treasury,
        address createKToken,
        address createDebtToken
    ) initializer {
        WETH = weth;
        _addressesProvider = IKyokoPoolAddressesProvider(provider);
        _treasury = treasury;
        _factor = 2000;
        MIN_BORROW_TIME = 5 minutes;
        _createKToken = createKToken;
        _createDebtToken = createDebtToken;
    }

    function createPool(address _nftAddress)
        external
        override
        onlyPoolAdminCreater
        returns (
            address kTokenAddress,
            address variableDebtAddress,
            address stableDebtAddress
        )
    {
        string memory _nftSymbol = INFT(_nftAddress).symbol();
        IKyokoPool pool = _getKyokoPool();
        uint256 reservesCount = pool.getReservesCount();

        kTokenAddress = createK(reservesCount, _nftSymbol);
        variableDebtAddress = createVariableDebtToken(
            WETH,
            address(_addressesProvider),
            reservesCount,
            _nftSymbol
        );
        stableDebtAddress = createStable(reservesCount, _nftSymbol);
        uint256 blockNumber = block.number;

        kTokenCreator[kTokenAddress] = msg.sender;
        sTokenCreator[stableDebtAddress] = msg.sender;
        vTokenCreator[variableDebtAddress] = msg.sender;

        emit CreatePool(
            blockNumber,
            kTokenAddress,
            variableDebtAddress,
            stableDebtAddress
        );
    }

    function createSharedPool()
        external
        override
        onlyPoolAdmin
        returns (
            address kTokenAddress,
            address variableDebtAddress,
            address stableDebtAddress
        )
    {
        string memory _nftSymbol = "SHARED";
        IKyokoPool pool = _getKyokoPool();
        uint256 reservesCount = pool.getReservesCount();

        kTokenAddress = createK(reservesCount, _nftSymbol);
        variableDebtAddress = createVariableDebtToken(
            WETH,
            address(_addressesProvider),
            reservesCount,
            _nftSymbol
        );
        stableDebtAddress = createStable(reservesCount, _nftSymbol);
        uint256 blockNumber = block.number;

        kTokenCreator[kTokenAddress] = msg.sender;
        sTokenCreator[stableDebtAddress] = msg.sender;
        vTokenCreator[variableDebtAddress] = msg.sender;

        emit CreatePool(
            blockNumber,
            kTokenAddress,
            variableDebtAddress,
            stableDebtAddress
        );
    }

    function initReserve(
        address _nftAddress,
        uint40 _period,
        uint16 _ratio,
        uint24 _liqDuration,
        uint24 _bidDuration,
        bool _enabledStableBorrow,
        address kTokenAddress,
        address variableDebtAddress,
        address stableDebtAddress,
        DataTypes.RateStrategyInput memory _rateInput
    ) external payable override onlyPoolAdminCreater {
        uint256 amount = msg.value;
        require(amount >= _initilLiquidity, Errors.KF_LIQUIDITY_INSUFFICIENT);
        require(
            kTokenCreator[kTokenAddress] == msg.sender &&
                sTokenCreator[stableDebtAddress] == msg.sender &&
                vTokenCreator[variableDebtAddress] == msg.sender,
            Errors.KT_ERROR_CREATOR
        );
        DataTypes.InitReserveInput memory input;
        DataTypes.RateStrategyInput memory rateInput = _rateInput;
        input.underlyingAsset = _nftAddress;
        input.treasury = _treasury;
        input.factor = _factor;
        input.borrowRatio = _ratio;
        input.period = _period;
        input.minBorrowTime = MIN_BORROW_TIME;
        input.liqThreshold = _liquidationThreshold;
        input.liqDuration = _liqDuration;
        input.bidDuration = _bidDuration;
        input.lockTime = _lockTime;
        input.stableBorrowed = _enabledStableBorrow;
        IKyokoPool pool = _getKyokoPool();
        IKyokoPoolConfigurator configurator = IKyokoPoolConfigurator(
            _addressesProvider.getKyokoPoolConfigurator()[0]
        );
        uint256 reservesCount = rateInput.reserveId = input.reserveId = pool
            .getReservesCount();

        input.kTokenImpl = kTokenAddress;
        input.variableDebtTokenImpl = variableDebtAddress;
        input.stableDebtTokenImpl = stableDebtAddress;
        input.interestRateStrategyAddress = _addressesProvider
            .getRateStrategy()[0];

        configurator.factoryInitReserve(input, rateInput);

        pool.deposit{value: amount}(reservesCount, msg.sender);
    }

    function setFactor(uint16 factor)
        external
        override
        onlyKyokoPoolConfigurator
    {
        _factor = factor;
        emit FactorUpdate(factor);
    }

    function setInitialLiquidity(uint256 amount)
        external
        override
        onlyKyokoPoolConfigurator
    {
        _initilLiquidity = amount;
        emit InitilLiquidityUpdate(amount);
    }

    function setLiqThreshold(uint16 threshold)
        external
        override
        onlyKyokoPoolConfigurator
    {
        _liquidationThreshold = threshold;
        emit LiquidationThreshold(threshold);
    }

    function setLockTime(uint32 lockTime)
        external
        override
        onlyKyokoPoolConfigurator
    {
        _lockTime = lockTime;
        emit LockTime(lockTime);
    }

    function setTokenFactory(address createKToken, address createDebtToken)
        external
        override
        onlyKyokoPoolConfigurator
    {
        if (createKToken != address(0)) {
            _createKToken = createKToken;
        }
        if (createDebtToken != address(0)) {
            _createDebtToken = createDebtToken;
        }
        emit FactoryUpdate(createKToken, createDebtToken);
    }

    function switchOnly() external override onlyPoolAdmin {
        if (only) {
            only = false;
        } else {
            only = true;
        }
    }

    function createK(uint256 reserveId, string memory _nftSymbol)
        internal
        returns (address kTokenAddress)
    {
        (bool success, bytes memory result) = _createKToken.delegatecall(
            abi.encodeWithSignature(
                "createKToken(address,address,address,uint256,string,string,string)",
                WETH,
                address(_addressesProvider),
                _treasury,
                reserveId,
                _nftSymbol,
                s1,
                s2
            )
        );
        require(success, Errors.KT_CREATION_FAILED);

        kTokenAddress = abi.decode(result, (address));
    }

    function createVariableDebtToken(
        address _weth,
        address _provider,
        uint256 _reserveId,
        string memory symbol
    ) internal returns (address variableAddress) {
        address weth = _weth;
        IKyokoPoolAddressesProvider provider = IKyokoPoolAddressesProvider(
            _provider
        );
        uint256 reserveId = _reserveId;
        string memory s3 = "Kyoko variable bearing ";
        string memory s4 = "kVariable";
        string memory hVariableName = string(
            abi.encodePacked(s3, symbol, s1, s2)
        );
        string memory hVariableSymbol = string(
            abi.encodePacked(s4, symbol, s2)
        );
        VariableDebtToken variableDebtToken = new VariableDebtToken(
            provider,
            reserveId,
            weth,
            18,
            hVariableName,
            hVariableSymbol
        );
        variableAddress = address(variableDebtToken);

        emit CreateVariableToken(msg.sender, variableAddress);
    }

    function createStable(uint256 reserveId, string memory _nftSymbol)
        internal
        returns (address stableDebtAddress)
    {
        (bool success, bytes memory result) = _createDebtToken.delegatecall(
            abi.encodeWithSignature(
                "createStableDebtToken(address,address,uint256,string,string,string)",
                WETH,
                address(_addressesProvider),
                reserveId,
                _nftSymbol,
                s1,
                s2
            )
        );
        require(success, Errors.SDT_CREATION_FAILED);

        stableDebtAddress = abi.decode(result, (address));
    }

    function _getKyokoPool() internal view returns (IKyokoPool) {
        return IKyokoPool(_addressesProvider.getKyokoPool()[0]);
    }
}

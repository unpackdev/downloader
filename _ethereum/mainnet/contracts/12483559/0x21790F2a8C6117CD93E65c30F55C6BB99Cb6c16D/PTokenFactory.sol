pragma solidity ^0.7.6;

import "./PErc20Delegator.sol";
import "./RegistryInterface.sol";
import "./EIP20Interface.sol";
import "./Strings.sol";
import "./IPriceFeeds.sol";
import "./ErrorReporter.sol";
import "./SafeMath.sol";
import "./PEtherDelegator.sol";
import "./PPIEDelegator.sol";
import "./Controller.sol";
import "./UniswapPriceOracle.sol";

contract PTokenFactory is FactoryErrorReporter {
    using strings for *;
    using SafeMath for uint;

    UniswapPriceOracle public oracle;
    uint public minUniswapLiquidity;

    // decimals for pToken
    uint8 public decimals = 8;

    // default parameters for pToken
    address public controller;
    address public interestRateModel;
    uint256 public initialExchangeRateMantissa;
    uint256 public initialReserveFactorMantissa;

    /**
     * Fired on creation new pToken proxy
     * @param newPToken Address of new PToken proxy contract
     */
    event PTokenCreated(address newPToken);

    RegistryInterface public registry;

    constructor(
        RegistryInterface registry_,
        uint minUniswapLiquidity_,
        address oracle_,
        address _controller,
        address _interestRateModel,
        uint256 _initialExchangeRateMantissa,
        uint256 _initialReserveFactorMantissa
    ) {
        registry = registry_;
        minUniswapLiquidity = minUniswapLiquidity_;
        oracle = UniswapPriceOracle(oracle_);
        controller = _controller;
        interestRateModel = _interestRateModel;
        initialExchangeRateMantissa = _initialExchangeRateMantissa;
        initialReserveFactorMantissa = _initialReserveFactorMantissa;
    }

    /**
     * Creates new pToken proxy contract and adds pToken to the controller
     * @param underlying_ The address of the underlying asset
     */
    function createPToken(address underlying_) external returns (uint) {
        if (!checkPair(underlying_)) {
            return fail(Error.INVALID_POOL, FailureInfo.DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST);
        }

        (string memory name, string memory symbol) = _createPTokenNameAndSymbol(underlying_);

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PErc20Delegator newPToken = new PErc20Delegator(underlying_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPToken));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPToken(underlying_, address(newPToken));

        emit PTokenCreated(address(newPToken));

        oracle.update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function createPETH(address pETHImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PETH_POOL);
        }

        string memory name = "DeFiPie ETH";
        string memory symbol = "pETH";

        uint power = 18;
        uint exchangeRateMantissa = calcExchangeRate(power);

        PETHDelegator newPETH = new PETHDelegator(pETHImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPETH));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPETH(address(newPETH));

        emit PTokenCreated(address(newPETH));

        return uint(Error.NO_ERROR);
    }

    function createPPIE(address underlying_, address pPIEImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PPIE_POOL);
        }

        string memory name = "DeFiPie PIE";
        string memory symbol = "pPIE";

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PPIEDelegator newPPIE = new PPIEDelegator(underlying_, pPIEImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPPIE));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPPIE(address(newPPIE));

        emit PTokenCreated(address(newPPIE));

        oracle.update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function checkPair(address asset) public view returns (bool) {
        (address pair, uint112 ethEquivalentReserves) = oracle.searchPair(asset);

        return bool(pair != address(0) && ethEquivalentReserves >= minUniswapLiquidity);
    }

    function setMinUniswapLiquidity(uint minUniswapLiquidity_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MIN_LIQUIDITY_OWNER_CHECK);
        }

        minUniswapLiquidity = minUniswapLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function setOracle(address oracle_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_ORACLE);
        }

        oracle = UniswapPriceOracle(oracle_);

        return uint(Error.NO_ERROR);
    }

    /**
     *  Sets address of actual controller contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setController(address newController) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_CONTROLLER);
        }
        controller = newController;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets address of actual interestRateModel contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setInterestRateModel(address newInterestRateModel) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_INTEREST_RATE_MODEL);
        }

        interestRateModel = newInterestRateModel;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets initial exchange rate
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setInitialExchangeRateMantissa(uint _initialExchangeRateMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_EXCHANGE_RATE);
        }

        initialExchangeRateMantissa = _initialExchangeRateMantissa;

        return(uint(Error.NO_ERROR));
    }

    function setInitialReserveFactorMantissa(uint _initialReserveFactorMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_RESERVE_FACTOR);
        }

        initialReserveFactorMantissa = _initialReserveFactorMantissa;

        return(uint(Error.NO_ERROR));
    }

    function setPTokenDecimals(uint _decimals) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_DECIMALS);
        }

        decimals = uint8(_decimals);

        return(uint(Error.NO_ERROR));
    }

    function getAdmin() public view returns(address payable) {
        return registry.admin();
    }

    function _createPTokenNameAndSymbol(address underlying) internal view returns (string memory, string memory) {
        string memory name = ("DeFiPie ".toSlice().concat(EIP20Interface(underlying).name().toSlice()));
        string memory symbol = ("p".toSlice().concat(EIP20Interface(underlying).symbol().toSlice()));
        return (name, symbol);
    }

    function calcExchangeRate(uint power) internal view returns (uint) {
        uint factor;

        if (decimals >= power) {
            factor = 10**(decimals - power);
            return initialExchangeRateMantissa.div(factor);
        } else {
            factor = 10**(power - decimals);
            return initialExchangeRateMantissa.mul(factor);
        }
    }
}
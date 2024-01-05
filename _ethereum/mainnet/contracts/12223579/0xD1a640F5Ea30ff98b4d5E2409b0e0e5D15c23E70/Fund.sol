pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./TransferHelper.sol";

import "./IFundManager.sol";
import "./IFund.sol";
import "./IUniswapV2Router02.sol";

// import "./console.sol";

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);

    function feeTo() external view returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint256, uint256);
}

contract Fund is IFund, ERC20 {
    event StatuChanged(uint256 status);
    event Invested(address indexed investor, uint256 amount);
    event Liquidated(address indexed liquidator, uint256 netValue);
    event Redeemed(address indexed redeemer, uint256 dfAmount);

    uint256 public constant UintMax = 2**256 - 1;

    uint128 public minSize; // raise size

    uint128 public finalNetValue;

    uint32 public startDate;

    uint32 public endDate;

    /**  base 100, percentage */
    uint16 public hurdleRate;

    uint16 public estimatedROE;

    uint16 public performanceFee;

    uint16 public maxDrawdown;
    // percentage end

    Status private fundStatus;

    bool locker;

    bool initialized;

    address public manager;

    address public controller; // FundManager address

    address[] public override getToken; // tradeable getToken

    uint256 public reservePoolDF; // amount of raise token of manager to create Pool

    modifier lock() {
        require(!locker, "reentrant call");
        locker = true;
        _;
        locker = false;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier nonContract() {
        uint256 size;
        address account = msg.sender;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        require(size == 0, "CONTRACT_INVOKE");
        _;
    }

    modifier ready() {
        require(initialized, "not initialized");
        _;
    }

    modifier inRaise() {
        require(fundStatus == Status.Raise && startDate >= block.timestamp, "status != raise");
        _;
    }

    modifier inRun() {
        require(fundStatus == Status.Run, "status != run");
        _;
    }

    constructor() {}

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint128 _minSize,
        uint256[2] memory _dates,
        uint16[4] memory _rates,
        address _manager,
        uint256 _amountOfManager,
        address[] memory _tokens
    ) external override lock() {
        require(!initialized, "alreday initialized");
        super.initialize(_name, _symbol, _decimals);
        initialized = true;
        controller = msg.sender;
        require(_tokens.length > 1, "token length = 1");
        IERC20 base = IERC20(_tokens[0]);
        require(base.balanceOf(address(this)) == _amountOfManager, "contract's balance != amount");
        getToken = _tokens;

        require(
            _dates[1] > _dates[0] && _dates[1] <= (_dates[0] + 1000 days),
            "endDate < startDate or endDate - startDate > 1000 days"
        );
        require(_dates[0] > block.timestamp, "start date < current time");
        startDate = uint32(_dates[0]);
        endDate = uint32(_dates[1]);

        minSize = _minSize;

        require(_amountOfManager >= minSize / 50, "amountOfManager < minSize * 2%");

        hurdleRate = _rates[0];
        require(hurdleRate >= 110, "hurdleRate < 110");
        performanceFee = _rates[1];
        require(performanceFee <= 80, "performanceFee > 80");
        maxDrawdown = _rates[2];
        require(maxDrawdown < 100 && maxDrawdown > 5, "maxDrawdown => 100 or maxDrawdown <= 5");
        estimatedROE = _rates[3];

        manager = _manager;
        IConfig config = IFundManager(controller).getConfig();
        require(config.poolCreationRate() > 0, "poolCreationRate==0");
        reservePoolDF = (_amountOfManager * config.poolCreationRate()) / 10000;
        _mint(manager, _amountOfManager - reservePoolDF);
        _mint(address(this), reservePoolDF);
    }

    function invest(address _owner, uint256 _amount) external override ready() lock() inRaise() onlyController() {
        _mint(_owner, _amount);

        if (_totalSupply >= minSize) {
            minSize = uint128(_totalSupply);
            fundStatus = Status.Run;
            _createPool();
        }
        _notify();
    }

    function redeem() external ready() lock() {
        address redeemer = msg.sender;
        if (fundStatus == Status.Raise || fundStatus == Status.Run) {
            _liquidate(redeemer);
        }

        uint256 dfBalance = balanceOf(redeemer);
        for (uint256 i = 0; i < getToken.length; i++) {
            address token = getToken[i];
            uint256 total = IERC20(token).balanceOf(address(this));
            if (total > 0) {
                _redeemToken(token, redeemer, (total * dfBalance) / _totalSupply);
            }
        }
        _burn(redeemer, dfBalance);
        _notify();
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external inRun() ready() nonContract() onlyManager() {
        require(deadline >= block.timestamp, "expired");
        require(path.length > 1, "path length <= 1");
        address last = path[path.length - 1];
        require(_inGetToken(last), "not in getToken");
        address first = path[0];
        address uniswapV2Router = IFundManager(controller).uniswapV2Router();
        _checkAndSetMaxAllowanceToUniswap(first, uniswapV2Router);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        _notify();
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external inRun() ready() nonContract() onlyManager() {
        require(deadline >= block.timestamp, "expired");
        require(path.length > 1, "path length <= 1");
        address last = path[path.length - 1];
        require(_inGetToken(last), "not in getToken");
        address first = path[0];
        address uniswapV2Router = IFundManager(controller).uniswapV2Router();
        _checkAndSetMaxAllowanceToUniswap(first, uniswapV2Router);
        IUniswapV2Router02(uniswapV2Router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            block.timestamp
        );
        _notify();
    }

    function status() external view returns (Status) {
        if (fundStatus == Status.Raise && _isRaiseFailure()) return Status.RaiseFailure;
        if (fundStatus == Status.Run && block.timestamp >= endDate) return Status.Liquidation;
        return fundStatus;
    }

    function tokens() external view override returns (address[] memory) {
        return getToken;
    }

    function netValue() external view returns (uint256) {
        return _netValue();
    }

    function _inGetToken(address _token) internal view returns (bool) {
        for (uint256 i; i < getToken.length; i++) {
            if (_token == getToken[i]) return true;
        }

        return false;
    }

    function _isRaiseFailure() private view returns (bool) {
        return
            fundStatus == Status.RaiseFailure ||
            (fundStatus == Status.Raise && block.timestamp > startDate && _totalSupply < minSize);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(fundStatus != Status.Raise || from == address(0), "not allow transfering in raise");
        require(from != manager || to == address(0), "not allow manager transfering");
    }

    function _createPool() private {
        uint256 liquidity = balanceOf(address(this));
        address uniswapV2Router = IFundManager(controller).uniswapV2Router();
        address base = getToken[0];
        TransferHelper.safeApprove(base, uniswapV2Router, UintMax);
        TransferHelper.safeApprove(address(this), uniswapV2Router, UintMax);
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);

        router.addLiquidity(address(this), base, liquidity, liquidity, 0, 0, manager, block.timestamp);
    }

    function _notify() private {
        IFundManager(controller).getConfig().notify(IConfig.EventType.FUND_UPDATED, address(this));
    }

    function _netValue() private view returns (uint256) {
        // console.log("!status", uint256(fundStatus));
        if (fundStatus == Status.Raise || fundStatus == Status.RaiseFailure) {
            return _totalSupply;
        }

        if (fundStatus == Status.Liquidation) {
            return finalNetValue;
        }
        address baseAsset = getToken[0];
        uint256 amount = IERC20(baseAsset).balanceOf(address(this));
        IUniswapV2Router02 router = IUniswapV2Router02(IFundManager(controller).uniswapV2Router());
        for (uint256 i = 1; i < getToken.length; i++) {
            uint256 balance = IERC20(getToken[i]).balanceOf(address(this));
            if (balance > 0) {
                address token = getToken[i];
                address pair = IUniswapV2Factory(router.factory()).getPair(baseAsset, token);
                if (pair == address(0)) {
                    continue;
                }
                (uint256 baseAssetReserve, uint256 tokenReserve) = _getReserves(pair, baseAsset, token);
                amount += _quote(balance, tokenReserve, baseAssetReserve);
                // uint256[] memory amounts = router.getAmountsOut(balance, paths);
                // console.log("swap out 0", amounts[0]);
                // console.log("swap out 1", amounts[1]);
                // console.log("amounts length", amounts.length);
                // if (amounts.length == 2) {
                //     amount += amounts[1];
                // }
            }
        }

        return amount;
    }

    function _getReserves(
        address _pair,
        address _tokenA,
        address _tokenB
    ) private view returns (uint256 reserveA, uint256 reserveB) {
        address token0 = _tokenA < _tokenB ? _tokenA : _tokenB;
        (uint256 reserve0, uint256 reserve1) = IUniswapV2Pair(_pair).getReserves();
        return token0 == _tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    function _liquidate(address _liquidator) private {
        require(balanceOf(_liquidator) > 0, "balance == 0, not investor");
        uint256 value = _netValue();
        finalNetValue = uint128(value);
        uint256 maxDrawdownValue = (_totalSupply * maxDrawdown) / 100;
        // console.log("liquidator", _liquidator);
        // console.log("    status", uint256(fundStatus));
        // console.log("   manager", manager);
        // console.log("  netValue", value);
        // console.log(" drawValue", maxDrawdownValue);
        require(
            block.timestamp > endDate ||
                _isRaiseFailure() ||
                (fundStatus == Status.Run && (_liquidator == manager || value <= maxDrawdownValue)),
            "now <= end date or status != failure or liquidator != manager or netValue >= maxDrawdownValue"
        );

        uint256 total = balanceOf(address(this));
        if (total > 0) {
            // return fund of creating pool to manager
            fundStatus = Status.RaiseFailure;
            _transfer(address(this), manager, total);
            return;
        }
        fundStatus = Status.Liquidation;
        _distributeHurdleReward();
    }

    function _distributeHurdleReward() private {
        address base = getToken[0];
        uint256 value = IERC20(base).balanceOf(address(this));
        uint256 hurdleLine = (minSize * hurdleRate) / 100;
        if (value > hurdleLine) {
            uint256 reward = ((value - hurdleLine) * performanceFee) / 100;
            _redeemToken(base, manager, reward);
        }
    }

    function _redeemToken(
        address _token,
        address _redeemer,
        uint256 _amountOfRedeemer
    ) private {
        IConfig config = IFundManager(controller).getConfig();
        uint256 out =
            fundStatus == Status.Liquidation
                ? (_amountOfRedeemer * (10000 - config.redeemFeeRate())) / 10000
                : _amountOfRedeemer;

        uint256 fee = _amountOfRedeemer - out;
        // console.log("amount", _amountOfRedeemer);
        // console.log("   out", out);
        // console.log("   fee", fee);
        if (out > 0) {
            TransferHelper.safeTransfer(_token, _redeemer, out);
        }
        if (fee > 0) {
            TransferHelper.safeTransfer(_token, config.feeTo(), fee);
        }
    }

    function _checkAndSetMaxAllowanceToUniswap(address _token, address _router) private {
        IERC20 token = IERC20(_token);
        uint256 uniAllowance = token.allowance(address(this), _router);
        if (uniAllowance <= UintMax) {
            token.approve(_router, UintMax);
        }
    }
}

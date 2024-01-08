// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./FullMath.sol";
import "./FixedPoint96.sol";

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IUniswapV3Pool.sol";
import "./IStrategy.sol";
import "./ReentrancyGuard.sol";


contract GeneralVault is Ownable, ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Set by constructor
    IUniswapV3Pool public immutable pool;
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    IStrategy public strategy;
    address operator;

    // Core Params
    bool canDeposit = true;
    address dev; // fee collected address
    uint256 reinvestMin0;
    uint256 reinvestMin1;
    uint256 withdrawFee;

    constructor(
        address _pool,
        address _strategy,
        address _dev,
        address _operator
    ) ERC20("UNIVERSE-LP", "ULP") {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(IUniswapV3Pool(_pool).token0());
        token1 = IERC20(IUniswapV3Pool(_pool).token1());
        strategy = IStrategy(_strategy);
        dev = _dev;
        operator = _operator;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOperator {
        require(msg.sender == operator, "operator only!");
        _;
    }

    modifier onlyEOA {
        require(msg.sender == tx.origin, "only EOA!");
        _;
    }

    /* ========== ONLY OWNER ========== */

    function changeDev(address _dev) external onlyOwner {
        require(_dev != address(0), "invalid address");
        emit ChangeDev(msg.sender, dev, _dev);
        dev = _dev;
    }

    function changeOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "invalid address");
        emit ChangeOperator(msg.sender, operator, _operator);
        operator = _operator;
    }

    function register(
        int24 boundaryThreshold,
        int24 reBalanceThreshold,
        uint8 direction,
        uint8 protocolFee,
        bool isSwap
    ) external onlyOwner {
        require(boundaryThreshold > reBalanceThreshold, "invalid params!");
        require(protocolFee == 0 || protocolFee >= 4, "invalid fee param");
        bytes memory data = abi.encode(
                address(pool),
                boundaryThreshold,
                reBalanceThreshold,
                direction,
                protocolFee,
                isSwap
        );
        strategy.addConfig(data);
    }

    /* ========== ONLY OPERATOR ========== */

    function setCoreParams(
        bool _canDeposit,
        uint256 _withdrawFee,
        uint256 _reinvestMin0,
        uint256 _reinvestMin1
    ) external onlyOperator {
        require(_withdrawFee == 0 || _withdrawFee >= 4, "invalid fee param");
        canDeposit = _canDeposit;
        withdrawFee = _withdrawFee;
        reinvestMin0 = _reinvestMin0;
        reinvestMin1 = _reinvestMin1;
    }

    function changeConfig(
        int24 boundaryThreshold,
        int24 reBalanceThreshold,
        uint8 direction,
        uint8 protocolFee,
        bool isSwap
    ) external onlyOperator {
        require(boundaryThreshold > reBalanceThreshold, "invalid params!");
        require(protocolFee == 0 || protocolFee >= 4, "invalid fee param");
        bytes memory data = abi.encode(
            boundaryThreshold,
            reBalanceThreshold,
            direction,
            protocolFee,
            isSwap
        );
        strategy.changeConfig(data);
    }

    function changeDirection(uint8 direction) external onlyOperator {
        strategy.changeDirection(direction);
    }

    function reBalance() external onlyOperator {
        // ReBalance
        (
        bool status,
        uint256 feesFromPool0,
        uint256 feesFromPool1,
        int24 lowerTick,
        int24 upperTick
        ) = strategy.reBalance();
        if (status) {
            // before mining
            _transferToStrategy();
            // add liquidity
            strategy.mining();
            // EVENT
            ( , uint256 total0, uint256 total1) = getTotalAmounts();
            emit ReBalance(msg.sender, lowerTick, upperTick, total0, total1);
            emit CollectFees(msg.sender, feesFromPool0, feesFromPool1, total0, total1, _currentTick());
        }
    }

    /* ========== PURE ========== */

    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    function combineAmount(
        uint256 total0,
        uint256 total1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 priceX96
    ) internal pure returns (uint256) {
        // 0.3% penalty for unBalanced part
        if (amount1Desired.mul(total0) > amount0Desired.mul(total1)) {
            uint256 diff = (amount1Desired.mul(total0) - amount0Desired.mul(total1)).mul(3).div(total0).div(1000);
            amount1Desired = amount1Desired.sub(diff);
        } else if (amount1Desired.mul(total0) < amount0Desired.mul(total1)) {
            uint256 diff = (amount0Desired.mul(total1) - amount1Desired.mul(total0)).mul(3).div(total1).div(1000);
            amount0Desired = amount0Desired.sub(diff);
        }
        return FullMath.mulDiv(amount0Desired, priceX96, FixedPoint96.Q96).add(amount1Desired);
    }

    /* ========== VIEW ========== */

    function _balance0() internal view returns (uint256) {
        return token0.balanceOf(address(this));
    }

    function _balance1() internal view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    function _price() internal view returns (uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);
    }

    function _calcShare(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256) {
        uint256 totalShare = totalSupply();
        // first time
        if (totalShare == 0) {
            return Math.max(amount0Desired, amount1Desired);
        }
        // get total0 total1
        ( , uint256 total0, uint256 total1) = getTotalAmounts();
        require(total0 != 0 && total1 != 0, "total0 or total1 equals ZERO!");
        // get price
        uint256 priceX96 = _price();
        // cal share
        uint256 addTotal = combineAmount(total0, total1, amount0Desired, amount1Desired, priceX96);
        uint256 total = FullMath.mulDiv(total0, priceX96, FixedPoint96.Q96).add(total1);
        return addTotal.mul(totalShare).div(total);
    }

    function getTotalAmounts() public view returns (uint128, uint256, uint256) {
        (uint128 liquidity, uint256 baseAmount0, uint256 baseAmount1) = strategy.getTotalAmounts();
        uint256 total0 = _balance0().add(baseAmount0);
        uint256 total1 = _balance1().add(baseAmount1);
        return (liquidity, total0, total1);
    }

    function getReBalanceStatus() public view returns (bool) {
        return strategy.checkReBalanceStatus();
    }

    function getPrice(uint256 decimal0, uint256 decimal1, bool normal) public view returns (uint256) {
        // get price
        uint256 priceX96 = _price();
        // check decimals
        if (decimal1 >= decimal0) {
            priceX96 = priceX96.div(10 ** (decimal1 - decimal0));
        } else {
            priceX96 = priceX96.mul(10 ** (decimal0 - decimal1));
        }
        // check order
        if (normal) {
            return priceX96.mul(1E5).div(FixedPoint96.Q96);
        } else {
            return FixedPoint96.Q96.mul(1E5).div(priceX96);
        }
    }

    function calBalance(uint256 share) public view returns (uint256, uint256) {
        uint256 totalSupply = totalSupply();
        if (share == 0 || totalSupply == 0) {return (0, 0);}
        ( ,uint256 total0, uint256 total1) = getTotalAmounts();
        uint256 amount0 = total0.mul(share).div(totalSupply);
        uint256 amount1 = total1.mul(share).div(totalSupply);
        return (amount0, amount1);
    }

    function getUserBalance(address user) external view returns (uint256, uint256) {
        uint256 bal = balanceOf(user);
        return calBalance(bal);
    }

    function getBalancedAmount(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256, uint256, uint256) {
        uint256 share = _calcShare(amount0Desired, amount1Desired);
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {return (share, amount0Desired, amount1Desired);}
        (uint256 amount0, uint256 amount1) = calBalance(share);
        return (share, amount0, amount1);
    }

    /* ========== INTERNAL ========== */

    function _currentTick() internal view returns (int24 tick) {
        ( , tick, , , , , ) = pool.slot0();
    }

    function _transferToStrategy() internal {
        if (_balance0() > reinvestMin0) {
            token0.safeTransfer(address(strategy), _balance0());
        }
        if (_balance1() > reinvestMin1) {
            token1.safeTransfer(address(strategy), _balance1());
        }
    }

    function _collectAll() internal {
        // update
        updateCommission();
        // collect
        (uint256 feesFromPool0, uint256 feesFromPool1) = strategy.collectCommission(pool, address(this));
        ( , uint256 total0, uint256 total1) = getTotalAmounts();
        emit CollectFees(msg.sender, feesFromPool0, feesFromPool1, total0, total1, _currentTick());
    }

    /* ========== PUBLIC ========== */

    function updateCommission() public {
        strategy.updateCommission(pool);
    }

    /* ========== EXTERNAL ========== */

    function deposit(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) external onlyEOA nonReentrant {
        // Check
        require(canDeposit, "CAN NOT DEPOSIT!");
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");
        require(amount0 > 0 || amount1 > 0, "amount0Desired or amount1Desired");
        // update
        updateCommission();
        // calculate Share
        uint256 share = _calcShare(amount0, amount1);
        require(share > 0, "share equal to zero!");
        // Harvest
        (uint256 feesFromPool0, uint256 feesFromPool1) = strategy.collectCommission(pool, address(0));
        // transfer
        if (amount0 > 0) token0.safeTransferFrom(msg.sender, address(strategy), amount0);
        if (amount1 > 0) token1.safeTransferFrom(msg.sender, address(strategy), amount1);
        // change to strategy
        _transferToStrategy();
        // mint
        _mint(msg.sender, share);
        // add Liquidity
        strategy.mining();
        (uint256 actual0, uint256 actual1) = calBalance(share);
        emit Deposit(msg.sender, address(this), share, amount0, amount1, actual0, actual1, _currentTick());
        ( , uint256 total0, uint256 total1) = getTotalAmounts();
        emit CollectFees(msg.sender, feesFromPool0, feesFromPool1, total0, total1, _currentTick());
    }

    function withdraw(uint256 share) external onlyEOA nonReentrant returns (uint256 amount0, uint256 amount1) {
        // Check
        require(share > 0, "zero Share");
        // record & burn
        uint256 totalShare = totalSupply();
        _burn(msg.sender, share);
        // record
        uint256 reserveShare;
        if (withdrawFee > 0 && msg.sender != dev) {
            reserveShare = share.div(withdrawFee);
            share = share.sub(reserveShare);
            _mint(dev, reserveShare);
        }
        if (share == totalShare) {
            _collectAll();
        }
        // calculate liq
        (uint128 liquidity, , ) = strategy.getTotalAmounts();
        uint256 liq = uint256(liquidity).mul(share).div(totalShare);
        // burn and transfer
        (uint256 baseAmount0, uint256 baseAmount1) = strategy.stopMining(_toUint128(liq), msg.sender);
        // unused token
        uint256 unusedAmount0 = _balance0().mul(share).div(totalShare);
        uint256 unusedAmount1 = _balance1().mul(share).div(totalShare);
        if (unusedAmount0 > 0) {token0.safeTransfer(msg.sender, unusedAmount0);}
        if (unusedAmount1 > 0) {token1.safeTransfer(msg.sender, unusedAmount1);}
        // Sum up total amounts
        amount0 = baseAmount0.add(unusedAmount0);
        amount1 = baseAmount1.add(unusedAmount1);
        // EVENT
        emit Withdraw(msg.sender, address(this), share, amount0, amount1, reserveShare, _currentTick());
    }

    function reInvest() external {
        // ReInvest
        // update Commission
        updateCommission();
        // collect
        (uint256 feesFromPool0, uint256 feesFromPool1) = strategy.collectCommission(pool, address(0));
        // before mining
        _transferToStrategy();
        // add liquidity
        strategy.mining();
        // EVENT
        ( , uint256 total0, uint256 total1) = getTotalAmounts();
        emit CollectFees(msg.sender, feesFromPool0, feesFromPool1, total0, total1, _currentTick());
        emit ReInvest(msg.sender, 0, 0, total0, total1);
    }

    /* ========== EVENT ========== */

    event ChangeDev(
        address indexed sender,
        address oldDev,
        address newDev
    );

    event ChangeOperator(
        address indexed sender,
        address oldOperator,
        address newOperator
    );

    event Deposit(
        address indexed user,
        address vault,
        uint256 share,
        uint256 amount0,
        uint256 amount1,
        uint256 actual0,
        uint256 actual1,
        int24 currentTick
    );

    event Withdraw(
        address indexed user,
        address vault,
        uint256 share,
        uint256 amount0,
        uint256 amount1,
        uint256 reserveShare,
        int24 currentTick
    );

    event CollectFees(
        address indexed sender,
        uint256 feesFromPool0,
        uint256 feesFromPool1,
        uint256 total0,
        uint256 total1,
        int24 currentTick
    );

    event ReBalance(
        address indexed sender,
        int24 lowerTick,
        int24 upperTick,
        uint256 total0,
        uint256 total1
    );

    event ReInvest(
        address indexed sender,
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    );

}

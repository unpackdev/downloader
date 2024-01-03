pragma solidity ^0.4.25;

/**
 * 
 * "Insure" (v0.1 beta)
 * A tool to allow easy farming backed by collateral to protect your assets.
 * 
 * For more info checkout: https://squirrel.finance
 * 
 */


contract InsureCollateral {
    using SafeMath for uint256;
    
    ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);
    OracleSimpleETHUSDC twap = OracleSimpleETHUSDC(0x27b4BADaDd381d92D927645a26F2E5e2E170140f);
    UniswapV2 uniswap = UniswapV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address insure;
    address blobby = msg.sender;
    
    mapping(address => uint256) public balances;
    mapping(address => int256) payoutsTo;
    mapping(address => uint256) public cashoutTimer;
    mapping(address => uint256) public cashoutAmount;
    
    uint256 public totalDeposits;
    uint256 public pendingCashouts;
    
    uint256 profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    bool twapRequired = true;
    uint256 twapPercentMin = 95; 
    
    function setupInsure(address insureContract) external {
        require(msg.sender == blobby && insure == 0); // One-off setup
        insure = insureContract;
    }
    
    function adjustTWAP(bool required, uint256 percentMin) external {
        require(msg.sender == blobby);
        require(percentMin < 100);
        twapRequired = required;
        twapPercentMin = percentMin;
    }
    
    function deposit(address recipient) payable external {
        require(recipient != 0);
        uint256 amount = msg.value;
        totalDeposits += amount;
        balances[recipient] += amount;
        payoutsTo[recipient] += (int256) (profitPerShare * amount);
        twap.update();
    }
    
    function beginCashout(uint256 amount) external {
        address recipient = msg.sender;
        require(cashoutTimer[recipient] == 0);
        claimYield();
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        pendingCashouts += amount;
        payoutsTo[recipient] -= (int256) (profitPerShare * amount);
        
        cashoutAmount[recipient] = amount;
        cashoutTimer[recipient] = now + 48 hours;
    }
    
    function doCashout() external {
        address recipient = msg.sender;
        require(cashoutTimer[recipient] < now);
        
        uint256 amount = cashoutAmount[recipient];
        uint256 ethShare = (address(this).balance * amount) / (totalDeposits + pendingCashouts);
        
        pendingCashouts = pendingCashouts.sub(amount);
        cashoutTimer[recipient] = 0;
        cashoutAmount[recipient] = 0;
        
        recipient.transfer(ethShare);
        twap.update();
    }
    
    function claimYield() public {
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        if (dividends > 0) {
            payoutsTo[recipient] += (int256) (dividends * magnitude);
            bond.transfer(recipient, dividends);
        }
        twap.update();
    }
    
    function shareYield(uint256 amount) external {
        require(bond.transferFrom(msg.sender, this, amount));
        profitPerShare += (amount * magnitude) / totalDeposits;
    }
    
    function compensate(uint256 amountShort, uint256 farmersAmount, uint256 systemAmount) external returns(uint256) {
        require(msg.sender == insure);
        require(farmersAmount > 0);
        
        uint256 portion = (address(this).balance * farmersAmount) / systemAmount;
        address[] memory path = new address[](2);
        path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        path[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        uint[] memory amounts = uniswap.getAmountsOut(portion, path);
        
        if (twapRequired) { // beta oracle protection for eth price
            require(amounts[1] > (twap.consult(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, portion) * twapPercentMin) / 100);
        }
        
        uint256 raised;
        if (amounts[1] >= amountShort) {
            amounts = uniswap.getAmountsIn(amountShort, path);
            uniswap.swapETHForExactTokens.value(amounts[0])(amountShort, path, this, 2 ** 255);
            raised = amountShort;
        } else {
            amounts = uniswap.swapExactETHForTokens.value(portion)(1, path, this, 2 ** 255);
            raised = amounts[1];
        }
        require(usdc.transfer(msg.sender, raised));
        return raised;
    }
    
    function dividendsOf(address farmer) view public returns (uint256) {
        return (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
    
}





contract NutsStaking {
    using SafeMath for uint256;
    
    ERC20 nuts = ERC20(0x84294FC9710e1252d407d3D80A84bC39001bd4A8);
    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);
    
    mapping(address => uint256) public balances;
    mapping(address => int256) payoutsTo;
    
    uint256 public totalDeposits;
    uint256 profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    function receiveApproval(address player, uint256 amount, address, bytes) external {
        require(msg.sender == address(nuts));
        nuts.transferFrom(player, this, amount);
        totalDeposits += amount;
        balances[player] += amount;
        payoutsTo[player] += (int256) (profitPerShare * amount);
    }
    
    function cashout(uint256 amount) external {
        address recipient = msg.sender;
        claimYield();
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        payoutsTo[recipient] -= (int256) (profitPerShare * amount);
        nuts.transfer(recipient, amount);
    }
    
    function claimYield() public {
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        payoutsTo[recipient] += (int256) (dividends * magnitude);
        bond.transfer(recipient, dividends);
    }
    
    function shareYield(uint256 amount) external {
        require(bond.transferFrom(msg.sender, this, amount));
        profitPerShare += (amount * magnitude) / totalDeposits;
    }
    
    function dividendsOf(address farmer) view public returns (uint256) {
        return (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
}








interface BarnBridgeStaking {
    function deposit(address tokenAddress, uint256 amount) external;
    function withdraw(address tokenAddress, uint256 amount) external;
    function emergencyWithdraw(address tokenAddress) external;
}

interface BarnBridgeRewards {
    function massHarvest() external returns (uint);
}


interface UniswapV2 {
    function swapExactETHForTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline) payable external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] path) external view returns (uint[] memory amounts);
}


interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}





























// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleSimpleETHUSDC {
    using FixedPoint for *;

    uint256 public constant PERIOD = 24 hours;
    address public constant pair = address(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
    address public constant eth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        // ensure that at least one full period has passed since the last update
       if (timeElapsed >= PERIOD) {
            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
    
            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
       }
    }

    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        if (token == usdc) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == eth);
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}







interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}


// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}


library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint: MUL_OVERFLOW');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint144 z = decode144(mul(self, uint256(y < 0 ? -y : y)));
        return y < 0 ? -int256(z) : z;
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint: MULUQ_OVERFLOW_UPPER');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint: MULUQ_OVERFLOW_SUM');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint: DIV_BY_ZERO_DIVUQ');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint: DIV_BY_ZERO_FRACTION');
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x > 1, 'FixedPoint: DIV_BY_ZERO_RECIPROCAL_OR_OVERFLOW');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy to 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 32) << 40));
    }
}






library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}



library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}
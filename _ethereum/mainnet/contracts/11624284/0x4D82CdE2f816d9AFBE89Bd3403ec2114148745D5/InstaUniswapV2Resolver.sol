pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair {
  function balanceOf(address owner) external view returns (uint);
  function totalSupply() external view returns (uint);


  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev get Ethereum address
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract UniswapHelpers is Helpers {
    using SafeMath for uint256;

    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    /**
     * @dev Return uniswap v2 router02 Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address buyAddr,
        address sellAddr,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsIn(
            buyAmt,
            paths
        );
        sellAmt = amts[0];
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint expectedAmt,
        TokenInterface sellAddr,
        uint sellAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint expectedAmt,
        TokenInterface buyAddr,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

    function _getWithdrawUnitAmts(
        TokenInterface tokenA,
        TokenInterface tokenB,
        uint amtA,
        uint amtB,
        uint uniAmt,
        uint slippage
    ) internal view returns (uint unitAmtA, uint unitAmtB) {
        uint _amtA = convertTo18(tokenA.decimals(), amtA);
        uint _amtB = convertTo18(tokenB.decimals(), amtB);
        unitAmtA = wdiv(_amtA, uniAmt);
        unitAmtA = wmul(unitAmtA, sub(WAD, slippage));
        unitAmtB = wdiv(_amtB, uniAmt);
        unitAmtB = wmul(unitAmtB, sub(WAD, slippage));
    }

    function _getWithdrawAmts(
        TokenInterface _tokenA,
        TokenInterface _tokenB,
        uint uniAmt
    ) internal view returns (uint amtA, uint amtB)
    {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");
        TokenInterface uniToken = TokenInterface(exchangeAddr);
        uint share = wdiv(uniAmt, uniToken.totalSupply());
        amtA = wmul(_tokenA.balanceOf(exchangeAddr), share);
        amtB = wmul(_tokenB.balanceOf(exchangeAddr), share);
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
         return
            Babylonian
                .sqrt(
                    reserveIn.mul(
                        userIn.mul(3988000).add(reserveIn.mul(3988009))
                    )
                ).sub(reserveIn.mul(1997)) / 1994;
    }
}


contract Resolver is UniswapHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage)
    public view returns (uint buyAmt, uint unitAmt)
    {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        buyAmt = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(address buyAddr, address sellAddr, uint buyAmt, uint slippage)
    public view returns (uint sellAmt, uint unitAmt)
    {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        sellAmt = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getDepositAmount(
        address tokenA,
        address tokenB,
        uint amountA,
        uint slippageA,
        uint slippageB
    ) public view returns (uint amountB, uint uniAmount, uint amountAMin, uint amountBMin)
    {       
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");
        
        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);
        
        amountB = router.quote(amountA, reserveA, reserveB);
         
        uniAmount= mul(amountA, lpToken.totalSupply());
        uniAmount= uniAmount / reserveA;
        
        amountAMin = wmul(sub(WAD, slippageA), amountA);
        amountBMin = wmul(sub(WAD, slippageB), amountB);
        
    }

    function getSingleDepositAmount(
        address tokenA,
        address tokenB,
        uint amountA,
        uint slippage
    ) public view returns (uint amtA, uint amtB, uint uniAmt, uint minUniAmt)
    {       
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");
        
        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 swapAmtA = calculateSwapInAmount(reserveA, amountA);

        amtB = getExpectedBuyAmt(address(_tokenB), address(_tokenA), swapAmtA);
        amtA = sub(amountA, swapAmtA);

        uniAmt = mul(amtA, lpToken.totalSupply());
        uniAmt = uniAmt / add(reserveA, swapAmtA);

        minUniAmt = wmul(sub(WAD, slippage), uniAmt);
    }

    function getDepositAmountNewPool(
        address tokenA,
        address tokenB,
        uint amtA,
        uint amtB
    ) public view returns (uint unitAmt)
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr == address(0), "pair-found.");
        uint _amtA18 = convertTo18(_tokenA.decimals(), amtA);
        uint _amtB18 = convertTo18(_tokenB.decimals(), amtB);
        unitAmt = wdiv(_amtB18, _amtA18);
    }

    function getWithdrawAmounts(
        address tokenA,
        address tokenB,
        uint uniAmt,
        uint slippage
    ) public view returns (uint amtA, uint amtB, uint unitAmtA, uint unitAmtB)
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        (amtA, amtB) = _getWithdrawAmts(
            _tokenA,
            _tokenB,
            uniAmt
        );
        (unitAmtA, unitAmtB) = _getWithdrawUnitAmts(
            _tokenA,
            _tokenB,
            amtA,
            amtB,
            uniAmt,
            slippage
        );
    }

    struct TokenPair {
        address tokenA;
        address tokenB;
    }

    struct PoolData {
        address tokenA;
        address tokenB;
        address lpAddress;
        uint reserveA;
        uint reserveB;
        uint tokenAShareAmt;
        uint tokenBShareAmt;
        uint tokenABalance;
        uint tokenBBalance;
        uint lpAmount;
        uint totalSupply;
    }

    function getPositionByPair(
        address owner,
        TokenPair[] memory tokenPairs
    ) public view returns (PoolData[] memory)
    {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        uint _len = tokenPairs.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint i = 0; i < _len; i++) {
            (TokenInterface tokenA, TokenInterface tokenB) = changeEthAddress(tokenPairs[i].tokenA, tokenPairs[i].tokenB);
            address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(
                address(tokenA),
                address(tokenB)
            );
            if (exchangeAddr != address(0)) {
                IUniswapV2Pair lpToken = IUniswapV2Pair(exchangeAddr);
                (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
                (reserveA, reserveB) = lpToken.token0() == address(tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);
        
                uint lpAmount = lpToken.balanceOf(owner);
                uint totalSupply = lpToken.totalSupply();
                uint share = wdiv(lpAmount, totalSupply);
                uint amtA = wmul(reserveA, share);
                uint amtB = wmul(reserveB, share);
                poolData[i] = PoolData(
                    address(0),
                    address(0),
                    address(lpToken),
                    reserveA,
                    reserveB,
                    amtA,
                    amtB,
                    0,
                    0,
                    lpAmount,
                    totalSupply
                );
            }
            poolData[i].tokenA = tokenPairs[i].tokenA;
            poolData[i].tokenB = tokenPairs[i].tokenB;
            poolData[i].tokenABalance = tokenPairs[i].tokenA == getEthAddr() ? owner.balance : tokenA.balanceOf(owner);
            poolData[i].tokenBBalance = tokenPairs[i].tokenB == getEthAddr() ? owner.balance : tokenB.balanceOf(owner);
        }
        return poolData;
    }

    function getPosition(
        address owner,
        address[] memory lpTokens
    ) public view returns (PoolData[] memory)
    {
        uint _len = lpTokens.length;
        PoolData[] memory poolData = new PoolData[](_len);
        address wethAddr = getAddressWETH();
        address ethAddr = getEthAddr();
        for (uint i = 0; i < _len; i++) {
            IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokens[i]);
            (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
            (address tokenA, address tokenB) = (lpToken.token0(), lpToken.token1());
            {
            uint lpAmount = lpToken.balanceOf(owner);
            uint totalSupply = lpToken.totalSupply();
            uint share = wdiv(lpAmount, totalSupply);
            uint amtA = wmul(reserveA, share);
            uint amtB = wmul(reserveB, share);
            poolData[i] = PoolData(
                tokenA == wethAddr ? ethAddr : tokenA,
                tokenB == wethAddr ? ethAddr : tokenB,
                address(lpToken),
                reserveA,
                reserveB,
                amtA,
                amtB,
                0,
                0,
                lpAmount,
                totalSupply
            );
            }
            poolData[i].tokenABalance = tokenA == wethAddr ? owner.balance : TokenInterface(tokenA).balanceOf(owner);
            poolData[i].tokenBBalance = tokenB == wethAddr ? owner.balance : TokenInterface(tokenB).balanceOf(owner);
        }
        return poolData;
    }
}


contract InstaUniswapV2Resolver is Resolver {
    string public constant name = "UniswapV2-Resolver-v1.1";
}
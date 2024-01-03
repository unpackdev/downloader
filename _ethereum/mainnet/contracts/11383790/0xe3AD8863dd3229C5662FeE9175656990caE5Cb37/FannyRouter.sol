// Sources flattened with hardhat v2.0.1 https://hardhat.org

// File @uniswap/v2-periphery/contracts/interfaces/IWETH.sol@v1.1.0-beta.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File @openzeppelin/contracts/math/SafeMath.sol@v3.2.0


pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v3.2.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @openzeppelin/contracts/GSN/Context.sol@v3.2.0


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v3.2.0


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/v612/FANNY/FannyRouter.sol

interface ITransferHandler01{
    function feePercentX100() external view returns (uint8);
}

contract FannyRouter is Ownable {
    using SafeMath for uint256;

    IERC20 immutable public FANNY;
    IERC20 constant public CORE  = IERC20(0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7);
    IUniswapV2Pair public pairFANNYxCORE;  // we dont know token0 and token 1
    IUniswapV2Pair public pairWETHxCORE =  IUniswapV2Pair(0x32Ce7e48debdccbFE0CD037Cc89526E4382cb81b); // CORE is token 0, WETH token 1
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ITransferHandler01 constant public transferHandler = ITransferHandler01(0x2e2A33CECA9aeF101d679ed058368ac994118E7a);


    constructor(address _fanny) public {
        FANNY = IERC20(_fanny);
    }

    function listFanny() public onlyOwner {
        require(address(pairFANNYxCORE) == address(0), "Fanny is already listed");
        uint256 balanceOfFanny = FANNY.balanceOf(address(this));
        uint256 balanceOfCORE = CORE.balanceOf(address(this));

        require(balanceOfCORE > 0, "Mo core");
        require(balanceOfFanny > 150 ether, "Mo fanny");

        address pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(address(FANNY), address(CORE));
        if(pair == address(0)) { // We make the pair
            pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(
                address(FANNY),
                address(CORE)
            );
        }
        require(pair != address(0), "Sanity failure");

        FANNY.transfer(pair, balanceOfFanny);
        CORE.transfer(pair, balanceOfCORE);
        require(CORE.balanceOf(pair) >= balanceOfCORE, "FoT off failure on list");
        pairFANNYxCORE = IUniswapV2Pair(pair);
        pairFANNYxCORE.mint(msg.sender);
        require(IERC20(address(pairFANNYxCORE)).balanceOf(msg.sender) > 0 , "Did not get any LP tokens");
    }


    function ETHneededToBuyFanny(uint256 amountFanny) public view returns (uint256) {
        // We get the amount CORE thats neededed to buy fanny
        address token0 = pairFANNYxCORE.token0();
        (uint256 reserves0, uint256 reserves1,) = pairFANNYxCORE.getReserves();
        uint256 coreNeededPreTax;
        if(token0 ==  address(FANNY)) {
            coreNeededPreTax = getAmountIn(amountFanny, reserves1 , reserves0);
        } else {
            coreNeededPreTax = getAmountIn(amountFanny, reserves0 , reserves1); 
        }
        uint256 coreNeededAfterTax = getCOREPreTaxForAmountPostTax(coreNeededPreTax);
        (uint256 reserveCORE, uint256 reserveWETH,) = pairWETHxCORE.getReserves();
        return getAmountIn(coreNeededAfterTax, reserveWETH , reserveCORE).mul(101).div(100); // add 1% slippage
    }

    function CORENeededToBuyFanny(uint256 amountFanny) public view returns (uint256) {
        // We get the amount CORE thats neededed to buy fanny
        address token0 = pairFANNYxCORE.token0();
        (uint256 reserves0, uint256 reserves1,) = pairFANNYxCORE.getReserves();
        uint256 coreNeededPreTax;
        if(token0 ==  address(FANNY)) {
            coreNeededPreTax = getAmountIn(amountFanny, reserves1 , reserves0);
        } else {
            coreNeededPreTax = getAmountIn(amountFanny, reserves0 , reserves1); 
        }
        return getCOREPreTaxForAmountPostTax(coreNeededPreTax).mul(101).div(100);// add 1% slippage because math isnt perfect
                                                                                // And we rather people buy 1 whole unit with dust
    }

    function getCOREPreTaxForAmountPostTax(uint256 _postTaxAmount) public view returns (uint256 coreNeededAfterTax) {
        uint256 tax = uint256(transferHandler.feePercentX100());
        uint256 divisor = uint256(1e8).sub((tax * 1e8).div(1000));
        coreNeededAfterTax = _postTaxAmount.mul(1e8).div(divisor);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator);
    }


    receive() external payable {
        if(msg.sender != address(WETH)) revert();
    }

    function buyFannyForETH(uint256 minFannyOut) public payable {
        WETH.deposit{value : msg.value}();
        _buyFannyForWETH(msg.value, minFannyOut);
    }

    function buyFannyForWETH(uint256 amount,uint256 minFannyOut) public {
        safeTransferFrom(address(WETH), msg.sender, address(this), amount);
        _buyFannyForWETH(amount, minFannyOut);
    }

    function _buyFannyForWETH(uint256 amount,uint256 minFannyOut) internal {
        (uint256 reserveCORE, uint256 reserveWETH,) = pairWETHxCORE.getReserves();
        uint256 coreOut = getAmountOut(amount, reserveWETH, reserveCORE);
        WETH.transfer(address(pairWETHxCORE), amount);
        pairWETHxCORE.swap(coreOut, 0 , address(this),"");
        uint256 coreBalanceOfPair = CORE.balanceOf(address(pairFANNYxCORE));
        CORE.transfer(address(pairFANNYxCORE), coreOut);
        _buyFannyForCORE(minFannyOut,coreBalanceOfPair);
    }

    function _buyFannyForCORE(uint256 minFannyOut, uint256 coreBalanceOfPairBefore) internal {
        uint256 coreBalanceOfAfter = CORE.balanceOf(address(pairFANNYxCORE));
        uint256 coreDelta = coreBalanceOfAfter.sub(coreBalanceOfPairBefore, "??");
        address token0 = pairFANNYxCORE.token0();
        (uint256 reserves0, uint256 reserves1,) = pairFANNYxCORE.getReserves();
        uint256 fannyOut;
        if(token0 == address(CORE)) {
            fannyOut = getAmountOut(coreDelta, reserves0, reserves1);
            pairFANNYxCORE.swap(0, fannyOut, msg.sender, "");
        } else {
            fannyOut = getAmountOut(coreDelta, reserves1, reserves0);
            pairFANNYxCORE.swap(fannyOut, 0, msg.sender, "");
        }
        require(fannyOut >= minFannyOut, "Slippage was too high on trade");
    }

    function buyFannyForCORE(uint256 amount,uint256 minFannyOut) public {
        uint256 coreBalanceOfPair = CORE.balanceOf(address(pairFANNYxCORE));
        safeTransferFrom(address(CORE), msg.sender, address(pairFANNYxCORE), amount);
        _buyFannyForCORE(minFannyOut, coreBalanceOfPair);
    }

    function sellFannyForCORE(uint256 amount,uint256 minCOREOut) public {
        safeTransferFrom(address(FANNY), msg.sender, address(pairFANNYxCORE), amount);
        _sellFannyForCORE(amount, minCOREOut, msg.sender);
    }


    function _sellFannyForCORE(uint256 amount,uint256 minCOREOut, address recipent) internal returns(uint256 coreOut) {
        address token0 = pairFANNYxCORE.token0();
        (uint256 reserves0, uint256 reserves1,) = pairFANNYxCORE.getReserves();
        if(token0 == address(FANNY)) {
            coreOut = getAmountOut(amount, reserves0, reserves1);
            pairFANNYxCORE.swap(0, coreOut, recipent, "");
        } else {
            coreOut = getAmountOut(amount, reserves1, reserves0);
            pairFANNYxCORE.swap(coreOut, 0, recipent, "");
        }
        require(coreOut > 0, "Sold for nothing");
        require(coreOut >= minCOREOut, "Too much slippage in trade");
    }


    function sellFannyForETH(uint256 amount, uint256 minETHOut) public {
        safeTransferFrom(address(FANNY), msg.sender, address(pairFANNYxCORE), amount);
        uint256 coreOut = _sellFannyForCORE(amount, 0, address(this));
        uint256 COREBefore = CORE.balanceOf(address(pairWETHxCORE));
        CORE.transfer(address(pairWETHxCORE), coreOut);
        uint256 COREAfter = CORE.balanceOf(address(pairWETHxCORE));

        (uint256 reserveCORE, uint256 reserveWETH,) = pairWETHxCORE.getReserves();
        uint256 ethOut = getAmountOut(COREAfter - COREBefore, reserveCORE, reserveWETH);
        pairWETHxCORE.swap(0, ethOut , address(this), "");
        require(ethOut >= minETHOut, "Too much slippage in trade");
        WETH.withdraw(ethOut);
        (bool success, ) = msg.sender.call.value(ethOut)("");
        require(success, "Transfer failed.");
    }


    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MUH FANNY: TRANSFER_FROM_FAILED');
    }

}
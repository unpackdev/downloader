
// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-eth/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-eth/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: contracts/interface/ICash.sol

pragma solidity >=0.5.15;


interface ICash {
    function claimDividends(address account) external returns (uint256);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);

    function mintCash(address account, uint256 amount) external returns (bool);
    function syncUniswapV2() external;
}

// File: contracts/interface/IRebaser.sol

pragma solidity >=0.5.15;


interface IRebaser {
    function public_goods_perc() external view returns (uint256);
    function WETH_ADDRESS() external view returns (address);
    function getCpi() external view returns (uint256);
    function public_goods() external view returns (address);
    function deviationThreshold() external view returns (uint256);
    function ethPerUsdcOracle() external view returns (address);
    function ethPerUsdOracle() external view returns (address);
    function maxSlippageFactor() external view returns (uint256);
    function uniswapV2Pool() external view returns (address);
}

// File: contracts/interface/IUniswapV2Pair.sol

pragma solidity >=0.5.15;

interface UniswapPair {
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

// File: contracts/lib/UInt256Lib.sol

pragma solidity >=0.5.15;


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

// File: contracts/lib/SafeMathInt.sol

/*
MIT License

Copyright (c) 2018 requestnetwork

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity >=0.5.15;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// File: contracts/dollarReserve.sol

pragma solidity >=0.5.15;
pragma experimental ABIEncoderV2;








interface IDecentralizedOracle {
    function update() external;
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

contract DollarReserve is Ownable {
    address public reserveToken;
    using SafeMath for uint256;

    address public gov;

    address public pendingGov;

    address public rebaser;

    uint256 private constant DECIMALS = 18;

    address public dollarAddress;
    address public uniswap_reserve_pair;

    bool public isToken0;

    struct UniVars {
      uint256 dollarsToUni;
      uint256 amountFromReserves;
      uint256 mintToReserves;
    }

    event NewPendingGov(address oldPendingGov, address newPendingGov);
    event NewGov(address oldGov, address newGov);
    event NewRebaser(address oldRebaser, address newRebaser);
    event NewReserveContract(address oldReserveContract, address newReserveContract);
    event TreasuryIncreased(uint256 reservesAdded, uint256 cashSold, uint256 cashFromReserves, uint256 cashToReserves);

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    modifier onlyRebaser() {
        require(msg.sender == rebaser);
        _;
    }

    event BuyAmount(uint256 amount, uint256 amountIn, uint256 reserve0, uint256 reserve1);
    event LogReserves(uint256 r1, uint256 r2);
    event LogAmount(uint256 r3);

    function initialize(
        address owner_,
        address reserveToken_,
        address dollarAddress_,
        address rebaser_,
        address uniswap_factory_
    )
        public
        initializer
    {
        Ownable.initialize(owner_);
        reserveToken = reserveToken_;
        dollarAddress = dollarAddress_;

        (address token0, address token1) = sortTokens(dollarAddress_, reserveToken_);
        if (token0 == dollarAddress_) {
            isToken0 = true;
        } else {
            isToken0 = false;
        }

        uniswap_reserve_pair = pairFor(uniswap_factory_, token0, token1);

        rebaser = rebaser_;
        ICash(dollarAddress).approve(rebaser_, uint256(-1));

        gov = msg.sender;
    }

    function _setReserveToken(address reserveToken_, address uniswap_factory_)
        external
        onlyGov
    {
        reserveToken = reserveToken_;

        (address token0, address token1) = sortTokens(dollarAddress, reserveToken_);
        if (token0 == dollarAddress) {
            isToken0 = true;
        } else {
            isToken0 = false;
        }

        uniswap_reserve_pair = pairFor(uniswap_factory_, token0, token1);
    }

    function _setRebaser(address rebaser_)
        external
        onlyGov
    {
        address oldRebaser = rebaser;
        ICash(dollarAddress).decreaseAllowance(oldRebaser, uint256(-1));
        rebaser = rebaser_;
        ICash(dollarAddress).approve(rebaser_, uint256(-1));
        emit NewRebaser(oldRebaser, rebaser_);
    }

    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the gov contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    function uniswapMaxSlippage(
        uint256 token0,
        uint256 token1,
        uint256 offPegPerc,
        uint256 maxSlippageFactor
    )
      internal
      view
      returns (uint256)
    {
        if (isToken0) {
            if (offPegPerc >= 10 ** 8) {
                return token0.mul(maxSlippageFactor).div(10 ** 9);
            } else {
                return token0.mul(offPegPerc).div(3 * 10 ** 9);
            }
        } else {
            if (offPegPerc >= 10 ** 8) {
                return token1.mul(maxSlippageFactor).div(10 ** 9);
            } else {
                return token1.mul(offPegPerc).div(3 * 10 ** 9);
            }   
        }
    }

    function mint(uint256 amount_)
        external
        onlyOwner
    {
        ICash(dollarAddress).mintCash(msg.sender, amount_);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    )
        public
    {
        // enforce that it is coming from uniswap
        require(msg.sender == uniswap_reserve_pair, "bad msg.sender");
        // enforce that this contract called uniswap
        require(sender == address(this), "bad origin");
        (UniVars memory uniVars) = abi.decode(data, (UniVars));

        if (uniVars.amountFromReserves > 0) {
            // transfer from reserves and mint to uniswap
            ICash(dollarAddress).transfer(uniswap_reserve_pair, uniVars.amountFromReserves);
            if (uniVars.amountFromReserves < uniVars.dollarsToUni) {
                // if the amount from reserves > dollarsToUni, we have fully paid for the yCRV tokens
                // thus this number would be 0 so no need to mint
                ICash(dollarAddress).mintCash(uniswap_reserve_pair, uniVars.dollarsToUni.sub(uniVars.amountFromReserves));
            }
        } else {
            // transfer to uniswap
            ICash(dollarAddress).mintCash(uniswap_reserve_pair, uniVars.dollarsToUni);
        }

        // mint unsold to mintAmount
        if (uniVars.mintToReserves > 0) {
            ICash(dollarAddress).mintCash(address(this), uniVars.mintToReserves);
        }

        uint256 public_goods_perc = IRebaser(rebaser).public_goods_perc();
        address public_goods = IRebaser(rebaser).public_goods();

        // transfer reserve token to reserves
        if (isToken0) {
            if (public_goods != address(0) && public_goods_perc > 0) {
              uint256 amount_to_public_goods = amount1.mul(public_goods_perc).div(10 ** 9);
              SafeERC20.safeTransfer(IERC20(reserveToken), public_goods, amount_to_public_goods);
              emit TreasuryIncreased(amount1.sub(amount_to_public_goods), uniVars.dollarsToUni, uniVars.amountFromReserves, uniVars.mintToReserves);
            } else {
              SafeERC20.safeTransfer(IERC20(reserveToken), address(this), amount1);
              emit TreasuryIncreased(amount1, uniVars.dollarsToUni, uniVars.amountFromReserves, uniVars.mintToReserves);
            }
        } else {
          if (public_goods != address(0) && public_goods_perc > 0) {
            uint256 amount_to_public_goods = amount0.mul(public_goods_perc).div(10 ** 9);
            SafeERC20.safeTransfer(IERC20(reserveToken), public_goods, amount_to_public_goods);
            emit TreasuryIncreased(amount0.sub(amount_to_public_goods), uniVars.dollarsToUni, uniVars.amountFromReserves, uniVars.mintToReserves);
          } else {
            SafeERC20.safeTransfer(IERC20(reserveToken), address(this), amount0);
            emit TreasuryIncreased(amount0, uniVars.dollarsToUni, uniVars.amountFromReserves, uniVars.mintToReserves);
          }
        }
    }

    function computeOffPegPerc(uint256 rate, uint256 targetRate)
        private
        view
        returns (uint256)
    {
        if (withinDeviationThreshold(rate, targetRate)) {
            return 0;
        }

        if (rate > targetRate) {
            return rate.sub(targetRate).mul(10 ** 9).div(targetRate);
        } else {
            return targetRate.sub(rate).mul(10 ** 9).div(targetRate);
        }
    }

    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        private
        view
        returns (bool)
    {
        uint256 deviationThreshold = IRebaser(rebaser).deviationThreshold();
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }

    // add functions to convert assets to stable coins
    // add functions to convert to ETH

    function getDollarCoinExchangeRate()
        public
        returns (uint256)
    {
        address WETH_ADDRESS = IRebaser(rebaser).WETH_ADDRESS();
        address ethPerUsdcOracle = IRebaser(rebaser).ethPerUsdcOracle();
        address ethPerUsdOracle = IRebaser(rebaser).ethPerUsdOracle();

        uint256 ethUsdcPrice = IDecentralizedOracle(ethPerUsdcOracle).consult(WETH_ADDRESS, 1 * 10 ** 18);        // 10^18 decimals ropsten, 10^6 mainnet
        uint256 ethUsdPrice = IDecentralizedOracle(ethPerUsdOracle).consult(WETH_ADDRESS, 1 * 10 ** 18);          // 10^9 decimals
        uint256 dollarCoinExchangeRate = ethUsdcPrice.mul(10 ** 21)                         // 10^18 decimals, 10**9 ropsten, 10**21 on mainnet
            .div(ethUsdPrice);
        
        return dollarCoinExchangeRate;
    }

    function getTargetRate()
        public
        returns (uint256)
    {
        uint256 targetRate = IRebaser(rebaser).getCpi();
        return targetRate;
    }

    // convert USD into reserve asset
    function buyReserveAndTransfer(uint256 mintAmount)
        external
        onlyRebaser
    {
        uint256 dollarCoinExchangeRate = getDollarCoinExchangeRate();
        uint256 targetRate = getTargetRate();

        uint256 offPegPerc = computeOffPegPerc(dollarCoinExchangeRate, targetRate);
        UniswapPair pair = UniswapPair(uniswap_reserve_pair);
        pair.sync();

        // get reserves
        (uint256 token0Reserves, uint256 token1Reserves, ) = pair.getReserves();

        // check if protocol has excess dollars in the reserve
        uint256 excess = ICash(dollarAddress).balanceOf(address(this));

        uint256 maxSlippageFactor = IRebaser(rebaser).maxSlippageFactor();
        uint256 tokens_to_max_slippage = uniswapMaxSlippage(token0Reserves, token1Reserves, offPegPerc, maxSlippageFactor);

        UniVars memory uniVars = UniVars({
          dollarsToUni: tokens_to_max_slippage, // how many dollars uniswap needs
          amountFromReserves: excess, // how much of dollarsToUni comes from reserves
          mintToReserves: 0 // how much dollars protocol mints to reserves
        });

        // tries to sell all mint + excess
        // falls back to selling some of mint and all of excess
        // if all else fails, sells portion of excess
        // upon pair.swap, `uniswapV2Call` is called by the uniswap pair contract
        uint256 buyTokens;

        if (isToken0) {
            if (tokens_to_max_slippage > mintAmount.add(excess)) {
                // we already have performed a safemath check on mintAmount+excess
                // so we dont need to continue using it in this code path

                // can handle selling all of reserves and mint
                buyTokens = getAmountOut(mintAmount.add(excess), token0Reserves, token1Reserves);
                uniVars.dollarsToUni = mintAmount.add(excess);
                uniVars.amountFromReserves = excess;
                // call swap using entire mint amount and excess; mint 0 to reserves
                pair.swap(0, buyTokens, address(this), abi.encode(uniVars));
            } else {
                if (tokens_to_max_slippage > excess) {
                    // uniswap can handle entire reserves
                    buyTokens = getAmountOut(tokens_to_max_slippage, token0Reserves, token1Reserves);

                    // swap up to slippage limit, taking entire yam reserves, and minting part of total
                    uniVars.mintToReserves = mintAmount.sub((tokens_to_max_slippage - excess));
                    pair.swap(0, buyTokens, address(this), abi.encode(uniVars));
                } else {
                    // uniswap cant handle all of excess
                    buyTokens = getAmountOut(tokens_to_max_slippage, token0Reserves, token1Reserves);
                    uniVars.amountFromReserves = tokens_to_max_slippage;
                    uniVars.mintToReserves = mintAmount;
                    // swap up to slippage limit, taking excess - remainingExcess from reserves, and minting full amount
                    // to reserves
                    pair.swap(0, buyTokens, address(this), abi.encode(uniVars));
                }
            }
        } else {
            if (tokens_to_max_slippage > mintAmount.add(excess)) {
                // can handle all of reserves and mint
                buyTokens = getAmountOut(mintAmount.add(excess), token1Reserves, token0Reserves);
                uniVars.dollarsToUni = mintAmount.add(excess);
                uniVars.amountFromReserves = excess;
                // call swap using entire mint amount and excess; mint 0 to reserves

                emit BuyAmount(buyTokens, tokens_to_max_slippage, token0Reserves, token1Reserves);

                pair.swap(buyTokens, 0, address(this), abi.encode(uniVars));
            } else {
                if (tokens_to_max_slippage > excess) {
                    // uniswap can handle entire reserves
                    buyTokens = getAmountOut(tokens_to_max_slippage, token1Reserves, token0Reserves);

                    // swap up to slippage limit, taking entire yam reserves, and minting part of total
                    uniVars.mintToReserves = mintAmount.sub((tokens_to_max_slippage - excess));
                    // swap up to slippage limit, taking entire yam reserves, and minting part of total

                    emit BuyAmount(buyTokens, tokens_to_max_slippage, token0Reserves, token1Reserves);

                    pair.swap(buyTokens, 0, address(this), abi.encode(uniVars));
                } else {
                    // uniswap cant handle all of excess
                    buyTokens = getAmountOut(tokens_to_max_slippage, token1Reserves, token0Reserves);
                    uniVars.amountFromReserves = tokens_to_max_slippage;
                    uniVars.mintToReserves = mintAmount;
                    // swap up to slippage limit, taking excess - remainingExcess from reserves, and minting full amount
                    // to reserves

                    emit BuyAmount(buyTokens, tokens_to_max_slippage, token0Reserves, token1Reserves);

                    pair.swap(buyTokens, 0, address(this), abi.encode(uniVars));
                }
            }
        }
    }

    /**
     * @notice lets msg.sender accept governance
     */
    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    /// @notice Moves all tokens to a new reserve contract
    function migrateReserves(
        address newReserve,
        address[] memory tokens
    )
        public
        onlyGov
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 bal = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token, newReserve, bal);
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountOut)
    {
       require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
       require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
       uint256 amountInWithFee = amountIn.mul(997);
       uint256 numerator = amountInWithFee.mul(reserveOut);
       uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
       amountOut = numerator / denominator;
   }

    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function pairFor(
        address factory,
        address token0,
        address token1
    )
        internal
        pure
        returns (address pair)
    {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    /// @notice Gets the current amount of reserves token held by this contract
    function reserves()
        public
        view
        returns (uint256)
    {
        return IERC20(reserveToken).balanceOf(address(this));
    }
}

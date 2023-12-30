// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;


// 
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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// 
/**
 *  The Core Settings contract, which defines the global constants,
 *  which are used in the pool and related contracts (such as 
 *  OWNER_ADDRESS), and also defines the percentage simulation
 *  code, to use the same percentage precision across all contracts.
 */
contract CoreUniLotterySettings {
    // Percentage calculations.
    // As Solidity doesn't have floats, we have to use integers for
    // percentage arithmetics.
    // We set 1 percent to be equal to 1,000,000 - thus, we
    // simulate 6 decimal points when computing percentages.
    uint32 public constant PERCENT = 10 ** 6;
    uint32 constant BASIS_POINT = PERCENT / 100;

    uint32 constant _100PERCENT = 100 * PERCENT;

    /** The UniLottery Owner's address.
     *
     *  In the current version, The Owner has rights to:
     *  - Take up to 10% profit from every lottery.
     *  - Pool liquidity into the pool and unpool it.
     *  - Start new Auto-Mode & Manual-Mode lotteries.
     *  - Set randomness provider gas price & other settings.
     */

    // Public Testnets: 0xb13CB9BECcB034392F4c9Db44E23C3Fb5fd5dc63 
    // MainNet:         0x1Ae51bec001a4fA4E3b06A5AF2e0df33A79c01e2

    address payable public constant OWNER_ADDRESS =
        address( uint160( 0x1Ae51bec001a4fA4E3b06A5AF2e0df33A79c01e2 ) );


    // Maximum lottery fee the owner can imburse on transfers.
    uint32 constant MAX_OWNER_LOTTERY_FEE = 1 * PERCENT;

    // Minimum amout of profit percentage that must be distributed
    // to lottery winners.
    uint32 constant MIN_WINNER_PROFIT_SHARE = 40 * PERCENT;

    // Min & max profits the owner can take from lottery net profit.
    uint32 constant MIN_OWNER_PROFITS = 3 * PERCENT;
    uint32 constant MAX_OWNER_PROFITS = 10 * PERCENT;

    // Min & max amount of lottery profits that the pool must get.
    uint32 constant MIN_POOL_PROFITS = 10 * PERCENT;
    uint32 constant MAX_POOL_PROFITS = 60 * PERCENT;

    // Maximum lifetime of a lottery - 1 month (4 weeks).
    uint32 constant MAX_LOTTERY_LIFETIME = 4 weeks;

    // Callback gas requirements for a lottery's ending callback,
    // and for the Pool's Scheduled Callback.
    // Must be determined empirically.
    uint32 constant LOTTERY_RAND_CALLBACK_GAS = 200000;
    uint32 constant AUTO_MODE_SCHEDULED_CALLBACK_GAS = 3800431;
}

// 
// Uniswap V2 Router Interface.
// Used on the Main-Net, and Public Test-Nets.
interface IUniswapRouter {
    // Get Factory and WETH addresses.
    function factory()  external pure returns (address);
    function WETH()     external pure returns (address);

    // Create/add to a liquidity pair using ETH.
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline )                 
                                        external 
                                        payable 
        returns (
            uint amountToken, 
            uint amountETH, 
            uint liquidity 
        );

    // Remove liquidity pair.
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline ) 
                                        external
        returns (
            uint amountETH
        );

    // Get trade output amount, given an input.
    function getAmountsOut(
        uint amountIn, 
        address[] memory path ) 
                                        external view 
        returns (
            uint[] memory amounts
        );

    // Get trade input amount, given an output.
    function getAmountsIn(
        uint amountOut, 
        address[] memory path )
                                        external view
        returns (
            uint[] memory amounts
        );
}

// Uniswap Factory interface.
// We use it only to obtain the Token Exchange Pair address.
interface IUniswapFactory {
    function getPair(
        address tokenA, 
        address tokenB )
                                        external view 
    returns ( address pair );
}

// Uniswap Pair interface (it's also an ERC20 token).
// Used to get reserves, and token price.
interface IUniswapPair is IERC20
{
    // Addresses of the first and second pool-kens.
    function token0() external view returns (address);
    function token1() external view returns (address);

    // Get the pair's token pool reserves.
    function getReserves() 
                                        external view 
    returns (
        uint112 reserve0, 
        uint112 reserve1,
        uint32 blockTimestampLast
    );
}

// 
// implement OpenZeppelin's ERC20 token.
// Use the Uniswap Interfaces.
// Use Core Settings.
// Interface of the Main Pool Contract, with the functions that we'll
// be calling from our contract.
interface IUniLotteryPool {
    function lotteryFinish( uint totalReturn, uint profitAmount )
    external payable;
}

// The Randomness Provider interface.
interface IRandomnessProvider {
    function requestRandomSeedForLotteryFinish()    external;
}

/**
 *  Simple, gas-efficient lottery, which uses Uniswap as liquidity provider,
 *  and determines the lottery winners through a 3 different approaches
 *  (explained in detail on EndingAlgoType documentation).
 *
 *  This contract contains all code of the lottery contract, and 
 *  lotteries themselves are just storage-container stubs, which use
 *  DelegateCall mechanism to execute this actual lottery code on
 *  their behalf.
 *
 *  Lottery workflow consists of these consecutive stages:
 *
 *  1. Initialization stage: Main Pool deploys this lottery contract,
 *      and calls initialize() with initial Ether funds provided.
 *      Lottery mints initial token supply and provides the liquidity
 *      to Uniswap, with whole token supply and initial Ether funds.
 *      Then, lottery becomes Active - trading tokens becomes allowed.
 *
 *  2. Active Stage:    Token transfers occurs on this stage, and 
 *      finish probability is Zero. Our ETH funds in Uniswap increases
 *      in this stage.
 *      When certain criteria of holder count and fund gains are met,
 *      the Finishing stage begins.
 *  
 *  3. Finishing Stage:     It can be considered a second part of
 *      an Active stage, because all token transfers and Uniswap trading
 *      are still allowed and occur actively.
 *      However, on this stage, for every transfer, a pseudo-random
 *      number is rolled, and if that rolled number is below a specific
 *      threshold, lottery de-activates, and Ending stage begins, when
 *      token transfers are denied.
 *      The threshold is determined by Finish Probability, which
 *      increases on every transfer on this stage.
 *
 *      However, notice that if Finishing Criteria (holder count and
 *      fund gains) are no-longer met, Finishing Stage pauses, and
 *      we get back to Active Stage.
 *
 *  4. Ending-Mining Stage - Step One:
 *      On this stage, we Remove our contract's liquidity share
 *      from Uniswap, then transfer the profits to the Pool and
 *      the Owner addresses.
 *
 *      Then, we call the Randomness Provider, requesting the Random Seed,
 *      which later should be passed to us by calling our callback
 *      (finish_randomnessProviderCallback).
 *
 *      Miner, who completes this step, gets portion of Mining Rewards,
 *      which are a dedicated profit share to miners.
 *
 *  5. Ending-Mining Stage - Step Two:  On this stage, if  *
 *      However, if Randomness Provider hasn't given us a seed after
 *      specific amount of time, on this step, before starting the
 *      Winner Selection Algorithm, an Alternative Seed Generation
 *      is performed, where the pseudo-random seed is generated based
 *      on data in our and Storage contracts (transfer hash, etc.).
 *
 *      If we're using MinedWinnerSelection ending algorithm type, then
 *      on this step the miner performs the gas-intensive Winner Selection 
 *      Algorithm, which involves complex score calculations in a loop, and
 *      then sorting the selected winners array.
 *
 *      Miner who successfully completes this step, gets a portion of
 *      the Mining Rewards.
 *
 *  6. Completion Stage (Winner Prize Claiming stage):  On this stage,
 *      the Lottery Winners can finally claim their Lottery Prizes,
 *      by calling a prize claim function on our contract.
 *
 *      If we're using WinnerSelfValidation ending algorithm, winner
 *      computes and validates his final score on this function by
 *      himself, so the prize claim transaction can be gas-costly.
 *
 *      However, is RolledRandomness or MinedWinnerSelection algorithms
 *      are used, this function is cheap in terms of gas.
 *
 *      However, if some of winners fail to claim their prizes after
 *      a specific amount of time (specified in config), then those
 *      prizes can then be claimed by Lottery Main Pool too.
 */
contract Lottery is ERC20, CoreUniLotterySettings
{
    // ===================== Events ===================== //

    // After initialize() function finishes.
    event LotteryInitialized();

    // Emitted when lottery active stage ends (Mining Stage starts),
    // on Mining Stage Step 1, after transferring profits to their
    // respective owners (pool and OWNER_ADDRESS).
    event LotteryEnd(
        uint128 totalReturn,
        uint128 profitAmount
    );

    // Emitted when on final finish, we call Randomness Provider
    // to callback us with random value.
    event RandomnessProviderCalled();

    // Requirements for finishing stage start have been reached - 
    // finishing stage has started.
    event FinishingStageStarted();

    // We were currently on the finishing stage, but some requirement
    // is no longer met. We must stop the finishing stage.
    event FinishingStageStopped();

    // New Referral ID has been generated.
    event ReferralIDGenerated(
        address referrer,
        uint256 id
    );

    // New referral has been registered with a valid referral ID.
    event ReferralRegistered(
        address referree,
        address referrer,
        uint256 id
    );

    // Fallback funds received.
    event FallbackEtherReceiver(
        address sender,
        uint value
    );


    // ======================  Structs & Enums  ====================== //

    // Lottery Stages. 
    // Described in more detail above, on contract's main doc.
    enum STAGE
    {
        // Initial stage - before the initialize() function is called.
        INITIAL,

        // Active Stage: On this stage, all token trading occurs.
        ACTIVE,

        // Finishing stage:
        // This is when all finishing criteria are met, and for every
        // transfer, we're rolling a pseudo-random number to determine
        // if we should end the lottery (move to Ending stage).
        FINISHING,

        // Ending - Mining Stage:
        // This stage starts after we lottery is no longer active,
        // finishing stage ends. On this stage, Miners perform the
        // Ending Algorithm and other operations.
        ENDING_MINING,

        // Lottery is completed - this is set after the Mining Stage ends.
        // In this stage, Lottery Winners can claim their prizes.
        COMPLETION,

        // DISABLED stage. Used when we want a lottery contract to be
        // absolutely disabled - so no state-modifying functions could
        // be called.
        // This is used in DelegateCall scenarios, where state-contract
        // delegate-calls code contract, to save on deployment costs.
        DISABLED
    }


    // Ending algorithm types enum.
    enum EndingAlgoType
    {
        // 1. Mined Winner Selection Algorithm.
        //  This algorithm is executed by a Lottery Miner in a single
        //  transaction, on Mining Step 2.
        //
        //  On that single transaction, all ending scores for all
        //  holders are computed, and a sorted winner array is formed,
        //  which is written onto the LotteryStorage state.
        //  Thus, it's gas expensive, and suitable only for small
        //  holder numbers (up to 300).
        //
        // Pros:
        //  + Guaranteed deterministically specifiable winner prize
        //    distribution - for example, if we specify that there
        //    must be 2 winners, of which first gets 60% of prize funds,
        //    and second gets 40% of prize funds, then it's
        //    guarateed that prize funds will be distributed just
        //    like that.
        //
        //  + Low gas cost of prize claims - only ~ 40,000 gas for
        //    claiming a prize.
        //
        // Cons:
        //  - Not scaleable - as the Winner Selection Algorithm is
        //    executed in a single transaction, it's limited by 
        //    block gas limit - 12,500,000 on the MainNet.
        //    Thus, the lottery is limited to ~300 holders, and
        //    max. ~200 winners of those holders.
        //    So, it's suitable for only express-lotteries, where
        //    a lottery runs only until ~300 holders are reached.
        //
        //  - High mining costs - if lottery has 300 holders,
        //    mining transaction takes up whole block gas limit.
        //
        MinedWinnerSelection,

        // 2. Winner Self-Validation Algorithm.
        //
        //  This algorithm does no operations during the Mining Stage
        //  (except for setting up a Random Seed in Lottery Storage) -
        //  the winner selection (obtaining a winner rank) is done by
        //  the winners themselves, when calling the prize claim
        //  functions.
        //
        //  This algorithm relies on a fact that by the time that
        //  random seed is obtained, all data needed for winner selection
        //  is already there - the holder scores of the Active Stage
        //  (ether contributed, time factors, token balance), and
        //  the Random Data (random seed + nonce (holder's address)),
        //  so, there is no need to compute and sort the scores for the
        //  whole holder array.
        //
        //  It's done like this: the holder checks if he's a winner, using
        //  a view-function off-chain, and if so, he calls the 
        //  claimWinnerPrize() function, which obtains his winner rank
        //  on O(n) time, and does no writing to contract states,
        //  except for prize transfer-related operations.
        //
        //  When computing the winner's rank on LotteryStorage,
        //  O(n) time is needed, as we loop through the holders array,
        //  computing ending scores for each holder, using already-known
        //  data. 
        //  However that means that for every prize claim, all scores of
        //  all holders must be re-computed.
        //  Computing a score for a single holder takes roughly 1500 gas
        //  (400 for 3 slots SLOAD, and ~300 for arithmetic operations).
        //
        //  So, this algorithm makes prize claims more expensive for
        //  every lottery holder.
        //  If there's 1000 holders, prize claim takes up 1,500,000 gas,
        //  so, this algorithm is not suitable for small prizes,
        //  because gas fee would be higher than the prize amount won.
        //
        // Pros:
        //  + Guaranteed deterministically specifiable winner prize
        //    distribution (same as for algorithm 1).
        //
        //  + No mining costs for winner selection algorithm.
        //
        //  + More scalable than algorithm 1.
        //
        // Cons:
        //  - High gas costs of prize claiming, rising with the number
        //    of lottery holders - 1500 for every lottery holder.
        //    Thus, suitable for only large prize amounts.
        //
        WinnerSelfValidation,

        // 3. Rolled-Randomness algorithm.
        //
        //  This algorithm is the most cheapest in terms of gas, but
        //  the winner prize distribution is non-deterministic.
        //
        //  This algorithm doesn't employ miners (no mining costs),
        //  and doesn't require to compute scores for every holder
        //  prior to getting a winner's rank, thus is the most scalable.
        //
        //  It works like this: a holder checks his winner status by
        //  computing only his own randomized score (rolling a random
        //  number from the random seed, and multiplying it by holder's
        //  Active Stage score), and computing this randomized-score's
        //  ratio relative to maximum available randomized score.
        //  The higher the ratio, the higher the winner rank is.
        //
        //  However, many players can roll very high or low scores, and
        //  get the same prizes, so it's difficult to make a fair and
        //  efficient deterministic prize distribution mechanism, so
        //  we have to fallback to specific heuristic workarounds.
        //
        // Pros:
        //  + Scalable: O(1) complexity for computing a winner rank,
        //      so there can be an unlimited amount of lottery holders,
        //      and gas costs for winner selection and prize claim would
        //      still be constant & low.
        //
        //  + Gas-efficient: gas costs for all winner-related operations
        //      are constant and low, because only single holder's score
        //      is computed.
        //
        //  + Doesn't require mining - even more gas savings.
        //
        // Cons:
        //  + Hard to make a deterministic and fair prize distribution
        //      mechanism, because of un-known environment - as only
        //      single holder's score is compared to max-available
        //      random score, not taking into account other holder
        //      scores.
        //
        RolledRandomness
    }


    /**
     *  Gas-efficient, minimal config, which specifies only basic,
     *  most-important and most-used settings.
     */
    struct LotteryConfig
    {
        // ================ Misc Settings =============== //

        // --------- Slot --------- //

        // Initial lottery funds (initial market cap).
        // Specified by pool, and is used to check if initial funds 
        // transferred to fallback are correct - equal to this value.
        uint initialFunds;


        // --------- Slot --------- //

        // The minimum ETH value of lottery funds, that, once
        // reached on an exchange liquidity pool (Uniswap, or our
        // contract), must be guaranteed to not shrink below this value.
        // 
        // This is accomplished in _transfer() function, by denying 
        // all sells that would drop the ETH amount in liquidity pool
        // below this value.
        // 
        // But on initial lottery stage, before this minimum requirement
        // is reached for the first time, all sells are allowed.
        //
        // This value is expressed in ETH - total amount of ETH funds
        // that we own in Uniswap liquidity pair.
        //
        // So, if initial funds were 10 ETH, and this is set to 100 ETH,
        // after liquidity pool's ETH value reaches 100 ETH, all further
        // sells which could drop the liquidity amount below 100 ETH,
        // would be denied by require'ing in _transfer() function
        // (transactions would be reverted).
        //
        uint128 fundRequirement_denySells;

        // ETH value of our funds that we own in Uniswap Liquidity Pair,
        // that's needed to start the Finishing Stage.
        uint128 finishCriteria_minFunds;


        // --------- Slot --------- //

        // Maximum lifetime of a lottery - maximum amount of time 
        // allowed for lottery to stay active.
        // By default, it's two weeks.
        // If lottery is still active (hasn't returned funds) after this
        // time, lottery will stop on the next token transfer.
        uint32 maxLifetime;

        // Maximum prize claiming time - for how long the winners
        // may be able to claim their prizes after lottery ending.
        uint32 prizeClaimTime;

        // Token transfer burn rates for buyers, and a default rate for
        // sells and non-buy-sell transfers.
        uint32 burn_buyerRate;
        uint32 burn_defaultRate;

        // Maximum amount of tokens (in percentage of initial supply)
        // to be allowed to own by a single wallet.
        uint32 maxAmountForWallet_percentageOfSupply;

        // The required amount of time that must pass after
        // the request to Randomness Provider has been made, for
        // external actors to be able to initiate alternative
        // seed generation algorithm.
        uint32 REQUIRED_TIME_WAITING_FOR_RANDOM_SEED;
        
        
        // ================ Profit Shares =============== //

        // "Mined Uniswap Lottery" ending Ether funds, which were obtained
        // by removing token liquidity from Uniswap, are transfered to
        // these recipient categories:
        //
        //  1. The Main Pool:   Initial funds, plus Pool's profit share.
        //  2. The Owner:       Owner's profit share.
        //
        //  3. The Miners:      Miner rewards for executing the winner
        //      selection algorithm stages.
        //      The more holders there are, the more stages the 
        //      winner selection algorithm must undergo.
        //      Each Miner, who successfully completed an algorithm
        //      stage, will get ETH reward equal to:
        //      (minerProfitShare / totalAlgorithmStages).
        //
        //  4. The Lottery Winners:     All remaining funds are given to
        //      Lottery Winners, which were determined by executing
        //      the Winner Selection Algorithm at the end of the lottery
        //      (Miners executed it).
        //      The Winners can claim their prizes by calling a 
        //      dedicated function in our contract.
        //
        //  The profit shares of #1 and #2 have controlled value ranges 
        //  specified in CoreUniLotterySettings.
        //
        //  All these shares are expressed as percentages of the
        //  lottery profit amount (totalReturn - initialFunds).
        //  Percentages are expressed using the PERCENT constant, 
        //  defined in CoreUniLotterySettings.
        //
        //  Here we specify profit shares of Pool, Owner, and the Miners.
        //  Winner Prize Fund is all that's left (must be more than 50%
        //  of all profits).
        //

        uint32 poolProfitShare;
        uint32 ownerProfitShare;

        // --------- Slot --------- //

        uint32 minerProfitShare;
        
        
        // =========== Lottery Finish criteria =========== //

        // Lottery finish by design is a whole soft stage, that
        // starts when criteria for holders and fund gains are met.
        // During this stage, for every token transfer, a pseudo-random
        // number will be rolled for lottery finish, with increasing 
        // probability.
        //
        // There are 2 ways that this probability increase is 
        // implemented:
        // 1. Increasing on every new holder.
        // 2. Increasing on every transaction after finish stage
        //    was initiated.
        //
        // On every new holder, probability increases more than on
        // new transactions.
        //
        // However, if during this stage some criteria become 
        // no-longer-met, the finish stage is cancelled.
        // This cancel can be implemented by setting finish probability
        // to zero, or leaving it as it was, but pausing the finishing
        // stage.
        // This is controlled by finish_resetProbabilityOnStop flag -
        // if not set, probability stays the same, when the finishing
        // stage is discontinued. 

        // ETH value of our funds that we own in Uniswap Liquidity Pair,
        // that's needed to start the Finishing Stage.
        //
        // LOOK ABOVE - arranged for tight-packing.

        // Minimum number of token holders required to start the
        // finishing stage.
        uint32 finishCriteria_minNumberOfHolders;

        // Minimum amount of time that lottery must be active.
        uint32 finishCriteria_minTimeActive;

        // Initial finish probability, when finishing stage was
        // just initiated.
        uint32 finish_initialProbability;

        // Finishing probability increase steps, for every new 
        // transaction and every new holder.
        // If holder number decreases, probability decreases.
        uint32 finish_probabilityIncreaseStep_transaction;
        uint32 finish_probabilityIncreaseStep_holder;


        // =========== Winner selection config =========== //

        // Winner selection algorithm settings.
        //
        // Algorithm is based on score, which is calculated for 
        // every holder on lottery finish, and is comprised of
        // the following parts.
        // Each part is normalized to range ( 0 - scorePoints ), 
        // from smallest to largest value of each holder;
        //
        // After scores are computed, they are multiplied by 
        // holder count factor (holderCount / holderCountDivisor),
        // and finally, multiplied by safely-generated random values,
        // to get end winning scores.
        // The top scorers win prizes.
        //
        // By default setting, max score is 40 points, and it's
        // comprised of the following parts:
        //
        // 1. Ether contributed (when buying from Uniswap or contract). 
        //    Gets added when buying, and subtracted when selling.
        //      Default: 10 points.
        //
        // 2. Amount of lottery tokens holder has on finish.
        //      Default: 5 points.
        //
        // 3. Ether contributed, multiplied by the relative factor
        //      of time - that is/*, "block.timestamp" */minus "lotteryStartTime".
        //      This way, late buyers can get more points even if
        //      they get little tokens and don't spend much ether.
        //      Default: 5 points.
        //
        // 4. Refferrer bonus. For every player that joined with
        //      your referral ID, you get (that player's score) / 10 
        //      points! This goes up to specified max score.
        //      Also, every player who provides a valid referral ID,
        //      gets 2 points for free!
        //      Default max bonus: 20 points.
        //
        int16 maxPlayerScore_etherContributed;
        int16 maxPlayerScore_tokenHoldingAmount;
        int16 maxPlayerScore_timeFactor;
        int16 maxPlayerScore_refferalBonus;

        // --------- Slot --------- //

        // Score-To-Random ration data (as a rational ratio number).
        // For example if 1:5, then scorePart = 1, and randPart = 5.
        uint16 randRatio_scorePart;
        uint16 randRatio_randPart;

        // Time factor divisor - interval of time, in seconds, after
        // which time factor is increased by one.
        uint16 timeFactorDivisor;

        // Bonus score a player should get when registering a valid
        // referral code obtained from a referrer.
        int16 playerScore_referralRegisteringBonus;


        // Are we resetting finish probability when finishing stage
        // stops, if some criteria are no longer met?
        bool finish_resetProbabilityOnStop;


        // =========== Winner Prize Fund Settings =========== //

        // There are 2 available modes that we can use to distribute
        // winnings: a computable sequence (geometrical progression),
        // or an array of winner prize fund share percentages.

        // More gas efficient is to use a computable sequence, 
        // where each winner gets a share equal to (factor * fundsLeft).
        // Factor is in range [0.01 - 1.00] - simulated as [1% - 100%].
        //
        // For example:
        // Winner prize fund is 100 ethers, Factor is 1/4 (25%), and 
        // there are 5 winners total (winnerCount), and sequenced winner
        // count is 2 (sequencedWinnerCount).
        //
        // So, we pre-compute the upper shares, till we arrive to the
        // sequenced winner count, in a loop:
        // - Winner 1: 0.25 * 100 = 25 eth; 100 - 25 = 75 eth left.
        // - Winner 2: 0.25 * 75 ~= 19 eth; 75  - 19 = 56 eth left.
        //
        // Now, we compute the left-over winner shares, which are
        // winners that get their prizes from the funds left after the
        // sequence winners.
        //
        // So, we just divide the leftover funds (56 eth), by 3,
        // because winnerCount - sequencedWinnerCount = 3.
        // - Winner 3 = 56 / 3 = 18 eth;
        // - Winner 4 = 56 / 3 = 18 eth;
        // - Winner 5 = 56 / 3 = 18 eth;
        //

        // If this value is 0, then we'll assume that array-mode is
        // to be used.
        uint32 prizeSequenceFactor;

        // Maximum number of winners that the prize sequence can yield,
        // plus the leftover winners, which will get equal shares of
        // the remainder from the first-prize sequence.
        
        uint16 prizeSequence_winnerCount;

        // How many winners would get sequence-computed prizes.
        // The left-over winners
        // This is needed because prizes in sequence tend to zero, so
        // we need to limit the sequence to avoid very small prizes,
        // and to avoid the remainder.
        uint16 prizeSequence_sequencedWinnerCount;

        // Initial token supply (without decimals).
        uint48 initialTokenSupply;

        // Ending Algorithm type.
        // More about the 3 algorithm types above.
        uint8 endingAlgoType;


        // --------- Slot --------- //

        // Array mode: The winner profit share percentages array. 
        // For example, lottery profits can be distributed this way:
        //
        // Winner profit shares (8 winners):
        // [ 20%, 15%, 10%, 5%, 4%, 3%, 2%, 1% ] = 60% of profits.
        // Owner profits: 10%
        // Pool profits:  30%
        //
        // Pool profit share is not defined explicitly in the config, so
        // when we internally validate specified profit shares, we 
        // assume the pool share to be the left amount until 100% ,
        // but we also make sure that this amount is at least equal to
        // MIN_POOL_PROFITS, defined in CoreSettings.
        //
        uint32[] winnerProfitShares;

    }


    // ========================= Constants ========================= //


    // The Miner Profits - max/min values.
    // These aren't defined in Core Settings, because Miner Profits
    // are only specific to this lottery type.

    uint32 constant MIN_MINER_PROFITS = 1 * PERCENT;
    uint32 constant MAX_MINER_PROFITS = 10 * PERCENT;


    // Uniswap Router V2 contract instance.
    // Address is the same for MainNet, and all public testnets.
    IUniswapRouter constant uniswapRouter = IUniswapRouter(
        address( 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ) );


    // Public-accessible ERC20 token specific constants.
    string constant public name = "UniLottery Token";
    string constant public symbol = "ULT";
    uint256 constant public decimals = 18;


    // =================== State Variables =================== //

    // ------- Initial Slots ------- //

    // The config which is passed to constructor.
    LotteryConfig internal cfg;

    // ------- Slot ------- //

    // The Lottery Storage contract, which stores all holder data,
    // such as scores, referral tree data, etc.
    LotteryStorage public lotStorage;

    // ------- Slot ------- //

    // Pool address. Set on constructor from msg.sender.
    address payable public poolAddress;

    // ------- Slot ------- //
    
    // Randomness Provider address.
    address public randomnessProvider;

    // ------- Slot ------- //

    // Exchange address. In Uniswap mode, it's the Uniswap liquidity 
    // pair's address, where trades execute.
    address public exchangeAddress;

    // Start date.
    uint32 public startDate;

    // Completion (Mining Phase End) date.
    uint32 public completionDate;
    
    // The date when Randomness Provider was called, requesting a
    // random seed for the lottery finish.
    // Also, when this variable becomes Non-Zero, it indicates that we're
    // on Ending Stage Part One: waiting for the random seed.
    uint32 finish_timeRandomSeedRequested;

    // ------- Slot ------- //

    // WETH address. Set by calling Router's getter, on constructor.
    address WETHaddress;

    // Is the WETH first or second token in our Uniswap Pair?
    bool uniswap_ethFirst;

    // If we are, or were before, on finishing stage, this is the
    // probability of lottery going to Ending Stage on this transaction.
    uint32 finishProbablity;
    
    // Re-Entrancy Lock (Mutex).
    // We protect for reentrancy in the Fund Transfer functions.
    bool reEntrancyMutexLocked;
    
    // On which stage we are currently.
    uint8 public lotteryStage;
    
    // Indicator for whether the lottery fund gains have passed a 
    // minimum fund gain requirement.
    // After that time point (when this bool is set), the token sells
    // which could drop the fund value below the requirement, would
    // be denied.
    bool fundGainRequirementReached;
    
    // The current step of the Mining Stage.
    uint16 miningStep;

    // If we're currently on Special Transfer Mode - that is, we allow
    // direct transfers between parties even in NON-ACTIVE state.
    bool specialTransferModeEnabled;


    // ------- Slot ------- //
    
    // Per-Transaction Pseudo-Random hash value (transferHashValue).
    // This value is computed on every token transfer, by keccak'ing
    // the last (current) transferHashValue, msg.sender, block.timestamp, and 
    // transaction count.
    //
    // This is used on Finishing Stage, as a pseudo-random number,
    // which is used to check if we should end the lottery (move to
    // Ending Stage).
    uint256 transferHashValue;

    // ------- Slot ------- //

    // On lottery end, get & store the lottery total ETH return
    // (including initial funds), and profit amount.
    uint128 public ending_totalReturn;
    uint128 public ending_profitAmount;

    // ------- Slot ------- //

    // The mapping that contains TRUE for addresses that already claimed
    // their lottery winner prizes.
    // Used only in COMPLETION, on claimWinnerPrize(), to check if
    // msg.sender has already claimed his prize.
    mapping( address => bool ) public prizeClaimersAddresses;


    // ============= Private/internal functions ============= //


    // Pool Only modifier.
    modifier poolOnly {
        require( msg.sender == poolAddress/*,
                 "Function can be called only by the pool!" */);
        _;
    }

    // Only randomness provider allowed modifier.
    modifier randomnessProviderOnly {
        require( msg.sender == randomnessProvider/*,
                 "Function can be called only by the UniLottery"
                 " Randomness Provider!" */);
        _;
    }

    // Execute function only on specific lottery stage.
    modifier onlyOnStage( STAGE _stage ) 
    {
        require( lotteryStage == uint8( _stage )/*,
                 "Function cannot be called on current stage!" */);
        _;
    }

    // Modifier for protecting the function from re-entrant calls,
    // by using a locked Re-Entrancy Lock (Mutex).
    modifier mutexLOCKED
    {
        require( ! reEntrancyMutexLocked/*, 
                    "Re-Entrant Calls are NOT ALLOWED!" */);

        reEntrancyMutexLocked = true;
        _;
        reEntrancyMutexLocked = false;
    }


    // Check if we're currently on a specific stage.
    function onStage( STAGE _stage )
                                                internal view
    returns( bool )
    {
        return ( lotteryStage == uint8( _stage ) );
    }


    /**
     *  Check if token transfer to specific wallet won't exceed 
     *  maximum token amount allowed to own by a single wallet.
     *
     *  @return true, if holder's balance with "amount" added,
     *      would exceed the max allowed single holder's balance
     *      (by default, that is 5% of total supply).
     */
    function transferExceedsMaxBalance( 
            address holder, uint amount )
                                                internal view
    returns( bool )
    {
        uint maxAllowedBalance = 
            ( totalSupply() * cfg.maxAmountForWallet_percentageOfSupply ) /
            ( _100PERCENT );

        return ( ( balanceOf( holder ) + amount ) > maxAllowedBalance );
    }


    /**
     *  Update holder data.
     *  This function is called by _transfer() function, just before
     *  transfering final amount of tokens directly from sender to
     *  receiver.
     *  At this point, all burns/mints have been done, and we're sure
     *  that this transfer is valid and must be successful.
     *
     *  In all modes, this function is used to update the holder array.
     *
     *  However, on external exchange modes (e.g. on Uniswap mode),
     *  it is also used to track buy/sell ether value, to update holder
     *  scores, when token buys/sells cannot be tracked directly.
     *
     *  If, however, we use Standalone mode, we are the exchange,
     *  so on _transfer() we already know the ether value, which is
     *  set to currentBuySellEtherValue variable.
     *
     *  @param amountSent - the token amount that is deducted from
     *      sender's balance. This includes burn, and owner fee.
     *
     *  @param amountReceived - the token amount that receiver 
     *      actually receives, after burns and fees.
     *
     *  @return holderCountChanged - indicates whether holder count
     *      changes during this transfer - new holder joins or leaves
     *      (true), or no change occurs (false).
     */
    function updateHolderData_preTransfer(
            address sender,
            address receiver,
            uint256 amountSent,
            uint256 amountReceived )
                                                internal
    returns( bool holderCountChanged )
    {
        // Update holder array, if new token holder joined, or if
        // a holder transfered his whole balance.
        holderCountChanged = false;

        // Sender transferred his whole balance - no longer a holder.
        if( balanceOf( sender ) == amountSent ) 
        {
            lotStorage.removeHolder( sender );
            holderCountChanged = true;
        }

        // Receiver didn't have any tokens before - add it to holders.
        if( balanceOf( receiver ) == 0 && amountReceived > 0 )
        {
            lotStorage.addHolder( receiver );
            holderCountChanged = true;
        }

        // Update holder score factors: if buy/sell occured, update
        // etherContributed and timeFactors scores,
        // and also propagate the scores through the referral chain
        // to the parent referrers (this is done in Storage contract).

        // This lottery operates only on external exchange (Uniswap)
        // mode, so we have to find out the buy/sell Ether value by 
        // calling the external exchange (Uniswap pair) contract.

        // Temporary variable to store current transfer's buy/sell
        // value in Ethers.
        int buySellValue;

        // Sender is an exchange - buy detected.
        if( sender == exchangeAddress && receiver != exchangeAddress ) 
        {
            // Use the Router's functionality.
            // Set the exchange path to WETH -> ULT
            // (ULT is Lottery Token, and it's address is our address).
            address[] memory path = new address[]( 2 );
            path[ 0 ] = WETHaddress;
            path[ 1 ] = address(this);

            uint[] memory ethAmountIn = uniswapRouter.getAmountsIn(
                amountSent,     // uint amountOut, 
                path            // address[] path
            );

            buySellValue = int( ethAmountIn[ 0 ] );
            
            // Compute time factor value for the current ether value.
            // buySellValue is POSITIVE.
            // When computing Time Factors, leave only 2 ether decimals.
            int timeFactorValue = ( buySellValue / (1 ether / 100) ) * 
                int( (block.timestamp - startDate) / cfg.timeFactorDivisor );

            if( timeFactorValue == 0 )
                timeFactorValue = 1;

            // Update and propagate the buyer (receiver) scores.
            lotStorage.updateAndPropagateScoreChanges(
                    receiver,
                    int80( buySellValue ),
                    int80( timeFactorValue ),
                    int80( amountReceived ) );
        }

        // Receiver is an exchange - sell detected.
        else if( sender != exchangeAddress && receiver == exchangeAddress )
        {
            // Use the Router's functionality.
            // Set the exchange path to ULT -> WETH
            // (ULT is Lottery Token, and it's address is our address).
            address[] memory path = new address[]( 2 );
            path[ 0 ] = address(this);
            path[ 1 ] = WETHaddress;

            uint[] memory ethAmountOut = uniswapRouter.getAmountsOut(
                amountReceived,     // uint amountIn
                path                // address[] path
            );

            // It's a sell (ULT -> WETH), so set value to NEGATIVE.
            buySellValue = int( -1 ) * int( ethAmountOut[ 1 ] );
            
            // Compute time factor value for the current ether value.
            // buySellValue is NEGATIVE.
            int timeFactorValue = ( buySellValue / (1 ether / 100) ) * 
                int( (block.timestamp - startDate) / cfg.timeFactorDivisor );

            if( timeFactorValue == 0 )
                timeFactorValue = -1;

            // Update and propagate the seller (sender) scores.
            lotStorage.updateAndPropagateScoreChanges(
                    sender,
                    int80( buySellValue ),
                    int80( timeFactorValue ),
                    -1 * int80( amountSent ) );
        }

        // Neither Sender nor Receiver are exchanges - default transfer.
        // Tokens just got transfered between wallets, without 
        // exchanging for ETH - so etherContributed_change = 0. 
        // On this case, update both sender's & receiver's scores.
        //
        else {
            buySellValue = 0;

            lotStorage.updateAndPropagateScoreChanges( sender, 0, 0, 
                                            -1 * int80( amountSent ) );

            lotStorage.updateAndPropagateScoreChanges( receiver, 0, 0, 
                                            int80( amountReceived ) );
        }

        // Check if lottery liquidity pool funds have already
        // reached a minimum required ETH value.
        uint ethFunds = getCurrentEthFunds();

        if( !fundGainRequirementReached &&
            ethFunds >= cfg.fundRequirement_denySells )
        {
            fundGainRequirementReached = true;
        }

        // Check whether this token transfer is allowed if it's a sell
        // (if buySellValue is negative):
        //
        // If we've already reached the minimum fund gain requirement,
        // and this sell would shrink lottery liquidity pool's ETH funds
        // below this requirement, then deny this sell, causing this 
        // transaction to fail.

        if( fundGainRequirementReached &&
            buySellValue < 0 &&
            ( uint( -1 * buySellValue ) >= ethFunds ||
              ethFunds - uint( -1 * buySellValue ) < 
                cfg.fundRequirement_denySells ) )
        {
            require( false/*, "This sell would drop the lottery ETH funds"
                            "below the minimum requirement threshold!" */);
        }
    }
    
    
    /**
     *  Check for finishing stage start conditions.
     *  - If some conditions are met, start finishing stage!
     *    Do it by setting "onFinishingStage" bool.
     *  - If we're currently on finishing stage, and some condition
     *    is no longer met, then stop the finishing stage.
     */
    function checkFinishingStageConditions()
                                                    internal
    {
        // Firstly, check if lottery hasn't exceeded it's maximum lifetime.
        // If so, don't check anymore, just set finishing stage, and
        // end the lottery on further call of checkForEnding().
        if( (block.timestamp - startDate) > cfg.maxLifetime ) 
        {
            lotteryStage = uint8( STAGE.FINISHING );
            return;
        }

        // Compute & check the finishing criteria.

        // Notice that we adjust the config-specified fund gain
        // percentage increase to uint-mode, by adding 100 percents,
        // because we don't deal with negative percentages, and here
        // we represent loss as a percentage below 100%, and gains
        // as percentage above 100%.
        // So, if in regular gains notation, it's said 10% gain,
        // in uint mode, it's said 110% relative increase.
        //
        // (Also, remember that losses are impossible in our lottery
        //  working scheme).

        if( lotStorage.getHolderCount() >= cfg.finishCriteria_minNumberOfHolders
            &&
            getCurrentEthFunds() >= cfg.finishCriteria_minFunds
            &&
            (block.timestamp - startDate) >= cfg.finishCriteria_minTimeActive )
        {
            if( onStage( STAGE.ACTIVE ) )
            {
                // All conditions are met - start the finishing stage.
                lotteryStage = uint8( STAGE.FINISHING );

                emit FinishingStageStarted();
            }
        }

        else if( onStage( STAGE.FINISHING ) )
        {
            // However, what if some condition was not met, but we're
            // already on the finishing stage?
            // If so, we must stop the finishing stage.
            // But what to do with the finishing probability?
            // Config specifies if it should be reset or maintain it's
            // value until the next time finishing stage is started.

            lotteryStage = uint8( STAGE.ACTIVE );

            if( cfg.finish_resetProbabilityOnStop )
                finishProbablity = cfg.finish_initialProbability;

            emit FinishingStageStopped();
        }
    }


    /**
     *  We're currently on finishing stage - so let's check if
     *  we should end the lottery block.timestamp!
     *
     *  This function is called from _transfer(), only if we're sure
     *  that we're currently on finishing stage (onFinishingStage
     *  variable is set).
     *
     *  Here, we compute the pseudo-random number from hash of
     *  current message's sender, block.timestamp, and other values,
     *  and modulo it to the current finish probability.
     *  If it's equal to 1, then we end the lottery!
     *
     *  Also, here we update the finish probability according to
     *  probability update criteria - holder count, and tx count.
     *
     *  @param holderCountChanged - indicates whether Holder Count
     *      has changed during this transfer (new holder joined, or
     *      a holder sold all his tokens).
     */
    function checkForEnding( bool holderCountChanged )
                                                            internal
    {
        // At first, check if lottery max lifetime is exceeded.
        // If so, start ending procedures right block.timestamp.
        if( (block.timestamp - startDate) > cfg.maxLifetime )
        {
            startEndingStage();
            return;
        }

        // Now, we know that lottery lifetime is still OK, and we're
        // currently on Finishing Stage (because this function is
        // called only when onFinishingStage is set).
        //
        // Now, check if we should End the lottery, by computing
        // a modulo on a pseudo-random number, which is a transfer
        // hash, computed for every transfer on _transfer() function.
        //
        // Get the modulo amount according to current finish 
        // probability.
        // We use precision of 0.01% - notice the "10000 *" before
        // 100 PERCENT.
        // Later, when modulo'ing, we'll check if value is below 10000.
        //
        uint prec = 10000;
        uint modAmount = (prec * _100PERCENT) / finishProbablity;

        if( ( transferHashValue % modAmount ) <= prec )
        {
            // Finish probability is met! Commence lottery end - 
            // start Ending Stage.
            startEndingStage();
            return;
        }

        // Finish probability wasn't met.
        // Update the finish probability, by increasing it!

        // Transaction count criteria.
        // As we know that this function is called on every new 
        // transfer (transaction), we don't check if transactionCount
        // increased or not - we just perform probability update.

        finishProbablity += cfg.finish_probabilityIncreaseStep_transaction;

        // Now, perform holder count criteria update.
        // Finish probability increases, no matter if holder count
        // increases or decreases.
        if( holderCountChanged )
            finishProbablity += cfg.finish_probabilityIncreaseStep_holder;
    }


    /**
     *  Start the Ending Stage, by De-Activating the lottery,
     *  to deny all further token transfers (excluding the one when
     *  removing liquidity from Uniswap), and transition into the 
     *  Mining Phase - set the lotteryStage to MINING.
     */
    function startEndingStage()
                                                internal
    {
        lotteryStage = uint8( STAGE.ENDING_MINING );
    }


    /**
     *  Execute the first step of the Mining Stage - request a 
     *  Random Seed from the Randomness Provider.
     *
     *  Here, we call the Randomness Provider, asking for a true random seed
     *  to be passed to us into our callback, named 
     *  "finish_randomnessProviderCallback()".
     *
     *  When that callback will be called, our storage's random seed will
     *  be set, and we'll be able to start the Ending Algorithm on
     *  further mining steps.
     *
     *  Notice that Randomness Provider must already be funded, to
     *  have enough Ether for Provable fee and the gas costs of our
     *  callback function, which are quite high, because of winner
     *  selection algorithm, which is computationally expensive.
     *
     *  The Randomness Provider is always funded by the Pool,
     *  right before the Pool deploys and starts a new lottery, so
     *  as every lottery calls the Randomness Provider only once,
     *  the one-call-fund method for every lottery is sufficient.
     *
     *  Also notice, that Randomness Provider might fail to call
     *  our callback due to some unknown reasons!
     *  Then, the lottery profits could stay locked in this 
     *  lottery contract forever ?!!
     *
     *  No! We've thought about that - we've implemented the
     *  Alternative Ending mechanism, where, if specific time passes 
     *  after we've made a request to Randomness Provider, and
     *  callback hasn't been called yet, we allow external actor to
     *  execute the Alternative ending, which basically does the
     *  same things as the default ending, just that the Random Seed
     *  will be computed locally in our contract, using the
     *  Pseudo-Random mechanism, which could compute a reasonably
     *  fair and safe value using data from holder array, and other
     *  values, described in more detail on corresponding function's
     *  description.
     */
    function mine_requestRandomSeed()
                                                internal
    {
        // We're sure that the Randomness Provider has enough funds.
        // Execute the random request, and get ready for Ending Algorithm.

        IRandomnessProvider( randomnessProvider )
            .requestRandomSeedForLotteryFinish();

        // Store the time when random seed has been requested, to
        // be able to alternatively handle the lottery finish, if
        // randomness provider doesn't call our callback for some
        // reason.
        finish_timeRandomSeedRequested = uint32( block.timestamp );

        // Emit appropriate events.
        emit RandomnessProviderCalled();
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Transfer the Owner & Pool profit shares, when lottery ends.
     *  This function is the first one that's executed on the Mining
     *  Stage.
     *  This is the first step of Mining. So, the Miner who executes this
     *  function gets the mining reward.
     *
     *  This function's job is to Gather the Profits & Initial Funds,
     *  and Transfer them to Profiters - that is, to The Pool, and
     *  to The Owner.
     *
     *  The Miners' profit share and Winner Prize Fund stay in this
     *  contract.
     *
     *  On this function, we (in this order):
     *
     *  1. Remove all liquidity from Uniswap (if using Uniswap Mode),
     *      pulling it to our contract's wallet.
     *
     *  2. Transfer the Owner and the Pool ETH profit shares to
     *      Owner and Pool addresses.
     *
     *  * This function transfers Ether out of our contract:
     *      - We transfer the Profits to Pool and Owner addresses.
     */
    function mine_removeUniswapLiquidityAndTransferProfits()
                                                                internal
                                                                mutexLOCKED
    {
        // We've already approved our token allowance to Router.
        // Now, approve Uniswap liquidity token's Router allowance.
        ERC20( exchangeAddress ).approve( address(uniswapRouter), uint(-1) );

        // Enable the SPECIAL-TRANSFER mode, to allow Uniswap to transfer
        // the tokens from Pair to Router, and then from Router to us.
        specialTransferModeEnabled = true;

        // Remove liquidity!
        uint amountETH = uniswapRouter
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),          // address token,
                ERC20( exchangeAddress ).balanceOf( address(this) ),
                0,                      // uint amountTokenMin,
                0,                      // uint amountETHMin,
                address(this),          // address to,
                (block.timestamp + 10000000)        // uint deadline
            );

        // Tokens are transfered. Disable the special transfer mode.
        specialTransferModeEnabled = false;

        // Check that we've got a correct amount of ETH.
        require( address(this).balance >= amountETH &&
                 address(this).balance >= cfg.initialFunds/*,
                 "Incorrect amount of ETH received from Uniswap!" */);


        // Compute the Profit Amount (current balance - initial funds).
        ending_totalReturn = uint128( address(this).balance );
        ending_profitAmount = ending_totalReturn - uint128( cfg.initialFunds );

        // Compute, and Transfer Owner's profit share and 
        // Pool's profit share to their respective addresses.

        uint poolShare = ( ending_profitAmount * cfg.poolProfitShare ) /
                         ( _100PERCENT );

        uint ownerShare = ( ending_profitAmount * cfg.ownerProfitShare ) /
                          ( _100PERCENT );

        // To pool, transfer it's profit share plus initial funds.
        IUniLotteryPool( poolAddress ).lotteryFinish
            { value: poolShare + cfg.initialFunds }
            ( ending_totalReturn, ending_profitAmount );

        // Transfer Owner's profit share.
        OWNER_ADDRESS.transfer( ownerShare );

        // Emit ending event.
        emit LotteryEnd( ending_totalReturn, ending_profitAmount );
    }


    /**
     *  Executes a single step of the Winner Selection Algorithm
     *  (the Ending Algorithm).
     *  The algorithm itself is being executed in the Storage contract.
     *
     *  On current design, whole algorithm is executed in a single step.
     *
     *  This function is executed only in the Mining stage, and
     *  accounts for most of the gas spent during mining.
     */
    function mine_executeEndingAlgorithmStep()
                                                            internal
    {
        // Launch the winner algorithm, to execute the next step.
        lotStorage.executeWinnerSelectionAlgorithm();
    }



    // =============== Public functions =============== //


    /**
     *  Constructor of this delegate code contract.
     *  Here, we set OUR STORAGE's lotteryStage to DISABLED, because
     *  we don't want anybody to call this contract directly.
     */
    constructor()
    {
        lotteryStage = uint8( STAGE.DISABLED );
    }


    /**
     *  Construct the lottery contract which is delegating it's
     *  call to us.
     *
     *  @param config - LotteryConfig structure to use in this lottery.
     *
     *      Future approach: ABI-encoded Lottery Config 
     *      (different implementations might use different config 
     *      structures, which are ABI-decoded inside the implementation).
     *
     *      Also, this "config" includes the ABI-encoded temporary values, 
     *      which are not part of persisted LotteryConfig, but should
     *      be used only in constructor - for example, values to be
     *      assigned to storage variables, such as ERC20 token's
     *      name, symbol, and decimals.
     *
     *  @param _poolAddress - Address of the Main UniLottery Pool, which
     *      provides initial funds, and receives it's profit share.
     *
     *  @param _randomProviderAddress - Address of a Randomness Provider,
     *      to use for obtaining random seeds.
     *
     *  @param _storageAddress  - Address of a Lottery Storage.
     *      Storage contract is a separate contract which holds all 
     *      lottery token holder data, such as intermediate scores.
     *
     */
    function construct( 
            LotteryConfig memory config,
            address payable _poolAddress,
            address _randomProviderAddress,
            address _storageAddress )
                                                        external
    {
        // Check if contract wasn't already constructed!
        require( poolAddress == address( 0 )/*,
                 "Contract is already constructed!" */);

        // Set the Pool's Address - notice that it's not the
        // msg.sender, because lotteries aren't created directly
        // by the Pool, but by the Lottery Factory!
        poolAddress = _poolAddress;

        // Set the Randomness Provider address.
        randomnessProvider = _randomProviderAddress;


        // Check the minimum & maximum requirements for config
        // profit & lifetime parameters.

        require( config.maxLifetime <= MAX_LOTTERY_LIFETIME/*,
                 "Lottery maximum lifetime is too high!" */);

        require( config.poolProfitShare >= MIN_POOL_PROFITS &&
                 config.poolProfitShare <= MAX_POOL_PROFITS/*,
                 "Pool profit share is invalid!" */);

        require( config.ownerProfitShare >= MIN_OWNER_PROFITS &&
                 config.ownerProfitShare <= MAX_OWNER_PROFITS/*,
                 "Owner profit share is invalid!" */);

        require( config.minerProfitShare >= MIN_MINER_PROFITS &&
                 config.minerProfitShare <= MAX_MINER_PROFITS/*,
                 "Miner profit share is invalid!" */);

        // Check if time factor divisor is higher than 2 minutes.
        // That's because int40 wouldn't be able to handle precisions
        // of smaller time factor divisors.
        require( config.timeFactorDivisor >= 2 minutes /*,
                 "Time factor divisor is lower than 2 minutes!"*/ );

        // Check if winner profit share is good.
        uint32 totalWinnerShare = 
            (_100PERCENT) - config.poolProfitShare
                            - config.ownerProfitShare
                            - config.minerProfitShare;

        require( totalWinnerShare >= MIN_WINNER_PROFIT_SHARE/*,
                 "Winner profit share is too low!" */);

        // Check if ending algorithm params are good.
        require( config.randRatio_scorePart != 0    &&
                 config.randRatio_randPart  != 0    &&
                 ( config.randRatio_scorePart + 
                   config.randRatio_randPart    ) < 10000/*,
                 "Random Ratio params are invalid!" */);

        require( config.endingAlgoType == 
                    uint8( EndingAlgoType.MinedWinnerSelection ) ||
                 config.endingAlgoType == 
                    uint8( EndingAlgoType.WinnerSelfValidation ) ||
                 config.endingAlgoType == 
                    uint8( EndingAlgoType.RolledRandomness )/*,
                 "Wrong Ending Algorithm Type!" */);

        // Set the number of winners (winner count).
        // If using Computed Sequence winner prize shares, set that
        // value, and if it's zero, then we're using the Array-Mode
        // prize share specification.
        if( config.prizeSequence_winnerCount == 0 &&
            config.winnerProfitShares.length != 0 )
            config.prizeSequence_winnerCount = 
                uint16( config.winnerProfitShares.length );


        // Setup our Lottery Storage - initialize, and set the
        // Algorithm Config.

        LotteryStorage _lotStorage = LotteryStorage( _storageAddress );

        // Setup a Winner Score Config for the winner selection algo,
        // to be used in the Lottery Storage.
        LotteryStorage.WinnerAlgorithmConfig memory winnerConfig;

        // Algorithm type.
        winnerConfig.endingAlgoType = config.endingAlgoType;

        // Individual player max score parts.
        winnerConfig.maxPlayerScore_etherContributed =
            config.maxPlayerScore_etherContributed;

        winnerConfig.maxPlayerScore_tokenHoldingAmount =
            config.maxPlayerScore_tokenHoldingAmount;

        winnerConfig.maxPlayerScore_timeFactor =
            config.maxPlayerScore_timeFactor;

        winnerConfig.maxPlayerScore_refferalBonus =
            config.maxPlayerScore_refferalBonus;

        // Score-To-Random ratio parts.
        winnerConfig.randRatio_scorePart = config.randRatio_scorePart;
        winnerConfig.randRatio_randPart = config.randRatio_randPart;

        // Set winner count (no.of winners).
        winnerConfig.winnerCount = config.prizeSequence_winnerCount;


        // Initialize the storage (bind it to our contract).
        _lotStorage.initialize( winnerConfig );

        // Set our immutable variable.
        lotStorage = _lotStorage;


        // Now, set our config to the passed config.
        cfg = config;

        // Might be un-needed (can be replaced by Constant on the MainNet):
        WETHaddress = uniswapRouter.WETH();
    }


    /** PAYABLE [ IN  ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Fallback Receive Ether function.
     *  Used to receive ETH funds back from Uniswap, on lottery's end,
     *  when removing liquidity.
     */
    receive()       external payable
    {
        emit FallbackEtherReceiver( msg.sender, msg.value );
    }



    /** PAYABLE [ IN  ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *  PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Initialization function.
     *  Here, the most important startup operations are made - 
     *  such as minting initial token supply and transfering it to
     *  the Uniswap liquidity pair, in exchange for UNI-v2 tokens.
     *
     *  This function is called by the pool, when transfering
     *  initial funds to this contract.
     *
     *  What's payable?
     *  - Pool transfers initial funds to our contract.
     *  - We transfer that initial fund Ether to Uniswap liquidity pair
     *    when creating/providing it.
     */
    function initialize()   
                                        external
                                        payable
                                        poolOnly
                                        mutexLOCKED
                                        onlyOnStage( STAGE.INITIAL )
    {
        // Check if pool transfered correct amount of funds.
        require( address( this ).balance == cfg.initialFunds/*,
                 "Invalid amount of funds transfered!" */);

        // Set start date.
        startDate = uint32( block.timestamp );

        // Set the initial transfer hash value.
        transferHashValue = uint( keccak256( 
                abi.encodePacked( msg.sender, block.timestamp ) ) );

        // Set initial finish probability, to be used when finishing
        // stage starts.
        finishProbablity = cfg.finish_initialProbability;
        
        
        // ===== Active operations - mint & distribute! ===== //

        // Mint full initial supply of tokens to our contract address!
        _mint( address(this), 
               uint( cfg.initialTokenSupply ) * (10 ** decimals) );

        // Now - prepare to create a new Uniswap Liquidity Pair,
        // with whole our total token supply and initial funds ETH
        // as the two liquidity reserves.
        
        // Approve Uniswap Router to allow it to spend our tokens.
        // Set maximum amount available.
        _approve( address(this), address( uniswapRouter ), uint(-1) );

        // Provide liquidity - the Router will automatically
        // create a new Pair.
        
        uniswapRouter.addLiquidityETH 
        { value: address(this).balance }
        (
            address(this),          // address token,
            totalSupply(),          // uint amountTokenDesired,
            totalSupply(),          // uint amountTokenMin,
            address(this).balance,  // uint amountETHMin,
            address(this),          // address to,
            (block.timestamp + 1000)            // uint deadline
        );

        // Get the Pair address - that will be the exchange address.
        exchangeAddress = IUniswapFactory( uniswapRouter.factory() )
            .getPair( WETHaddress, address(this) );

        // We assume that the token reserves of the pair are good,
        // and that we own the full amount of liquidity tokens.

        // Find out which of the pair tokens is WETH - is it the 
        // first or second one. Use it later, when getting our share.
        if( IUniswapPair( exchangeAddress ).token0() == WETHaddress )
            uniswap_ethFirst = true;
        else
            uniswap_ethFirst = false;


        // Move to ACTIVE lottery stage.
        // Now, all token transfers will be allowed.
        lotteryStage = uint8( STAGE.ACTIVE );

        // Lottery is initialized. We're ready to emit event.
        emit LotteryInitialized();
    }


    // Return this lottery's initial funds, as were specified in the config.
    //
    function getInitialFunds()          external view
    returns( uint )
    {
        return cfg.initialFunds;
    }

    // Return active (still not returned to pool) initial fund value.
    // If no-longer-active, return 0 (default) - because funds were 
    // already returned back to the pool.
    //
    function getActiveInitialFunds()    external view
    returns( uint )
    {
        if( onStage( STAGE.ACTIVE ) )
            return cfg.initialFunds;
        return 0;
    }


    /**
     *  Get current Exchange's Token and ETH reserves.
     *  We're on Uniswap mode, so get reserves from Uniswap.
     */
    function getReserves() 
                                                        external view
    returns( uint _ethReserve, uint _tokenReserve )
    {
        // Use data from Uniswap pair contract.
        ( uint112 res0, uint112 res1, ) = 
            IUniswapPair( exchangeAddress ).getReserves();

        if( uniswap_ethFirst )
            return ( res0, res1 );
        else
            return ( res1, res0 );
    }


    /**
     *  Get our share (ETH amount) of the Uniswap Pair ETH reserve,
     *  of our Lottery tokens ULT-WETH liquidity pair.
     */
    function getCurrentEthFunds()
                                                        public view
    returns( uint ethAmount )
    {
        IUniswapPair pair = IUniswapPair( exchangeAddress );
        
        ( uint112 res0, uint112 res1, ) = pair.getReserves();
        uint resEth = uint( uniswap_ethFirst ? res0 : res1 );

        // Compute our amount of the ETH reserve, based on our
        // percentage of our liquidity token balance to total supply.
        uint liqTokenPercentage = 
            ( pair.balanceOf( address(this) ) * (_100PERCENT) ) /
            ( pair.totalSupply() );

        // Compute and return the ETH reserve.
        return ( resEth * liqTokenPercentage ) / (_100PERCENT);
    }


    /**
     *  Get current finish probability.
     *  If it's ACTIVE stage, return 0 automatically.
     */
    function getFinishProbability()
                                                        external view
    returns( uint32 )
    {
        if( onStage( STAGE.FINISHING ) )
            return finishProbablity;
        return 0;
    }


    
    /**
     *  Generate a referral ID for msg.sender, who must be a token holder.
     *  Referral ID is used to refer other wallets into playing our
     *  lottery.
     *  - Referrer gets bonus points for every wallet that bought 
     *    lottery tokens and specified his referral ID.
     *  - Referrees (wallets who got referred by registering a valid
     *    referral ID, corresponding to some referrer), get some
     *    bonus points for specifying (registering) a referral ID.
     *
     *  Referral ID is a uint256 number, which is generated by
     *  keccak256'ing the holder's address, holder's current
     *  token ballance, and current time.
     */
    function generateReferralID()
                                        external
                                        onlyOnStage( STAGE.ACTIVE )
    {
        uint256 refID = lotStorage.generateReferralID( msg.sender );

        // Emit approppriate events.
        emit ReferralIDGenerated( msg.sender, refID );
    }


    /**
     *  Register a referral for a msg.sender (must be token holder),
     *  using a valid referral ID got from a referrer.
     *  This function is called by a referree, who obtained a
     *  valid referral ID from some referrer, who previously
     *  generated it using generateReferralID().
     *
     *  You can only register a referral once!
     *  When you do so, you get bonus referral points!
     */
    function registerReferral( 
            uint256 referralID )
                                        external
                                        onlyOnStage( STAGE.ACTIVE )
    {
        address referrer = lotStorage.registerReferral( 
                msg.sender,
                cfg.playerScore_referralRegisteringBonus,
                referralID );

        // Emit approppriate events.
        emit ReferralRegistered( msg.sender, referrer, referralID );
    }


    /**
     *  The most important function of this contract - Transfer Function.
     *
     *  Here, all token burning, intermediate score tracking, and 
     *  finish condition checking is performed, according to the 
     *  properties specified in config.
     */
    function _transfer( address sender,
                        address receiver,
                        uint256 amount )
                                            internal
                                            override
    {
        // Check if transfers are allowed in current state.
        // On Non-Active stage, transfers are allowed only from/to
        // our contract.
        // As we don't have Standalone Mode on this lottery variation,
        // that means that tokens to/from our contract are travelling
        // only when we transfer them to Uniswap Pair, and when
        // Uniswap transfers them back to us, on liquidity remove.
        //
        // On this state, we also don't perform any burns nor
        // holding trackings - just transfer and return.

        if( !onStage( STAGE.ACTIVE )    &&
            !onStage( STAGE.FINISHING ) &&
            ( sender == address(this) || receiver == address(this) ||
              specialTransferModeEnabled ) )
        {
            super._transfer( sender, receiver, amount );
            return;
        }

        // Now, we know that we're NOT on special mode.
        // Perform standard checks & brecks.
        require( ( onStage( STAGE.ACTIVE ) || 
                   onStage( STAGE.FINISHING ) )/*,
                 "Token transfers are only allowed on ACTIVE stage!" */);
                 
        // Can't transfer zero tokens, or use address(0) as sender.
        require( amount != 0 && sender != address(0)/*,
                 "Amount is zero, or transfering from zero address." */);


        // Compute the Burn Amount - if buying tokens from an exchange,
        // we use a lower burn rate - to incentivize buying!
        // Otherwise (if selling or just transfering between wallets),
        // we use a higher burn rate.
        uint burnAmount;

        // It's a buy - sender is an exchange.
        if( sender == exchangeAddress )
            burnAmount = ( amount * cfg.burn_buyerRate ) / (_100PERCENT);
        else
            burnAmount = ( amount * cfg.burn_defaultRate ) / (_100PERCENT);
        
        // Now, compute the final amount to be gotten by the receiver.
        uint finalAmount = amount - burnAmount;

        // Check if receiver's balance won't exceed the max-allowed!
        // Receiver must not be an exchange.
        if( receiver != exchangeAddress )
        {
            require( !transferExceedsMaxBalance( receiver, finalAmount )/*,
                "Receiver's balance would exceed maximum after transfer!"*/);
        }

        // Now, update holder data array accordingly.
        bool holderCountChanged = updateHolderData_preTransfer( 
                sender, 
                receiver, 
                amount,             // Amount Sent (Pre-Fees)
                finalAmount         // Amount Received (Post-Fees).
        );

        // All is ok - perform the burn and token transfers block.timestamp.

        // Burn token amount from sender's balance.
        super._burn( sender, burnAmount );

        // Finally, transfer the final amount from sender to receiver.
        super._transfer( sender, receiver, finalAmount );


        // Compute new Pseudo-Random transfer hash, which must be
        // computed for every transfer, and is used in the
        // Finishing Stage as a pseudo-random unique value for 
        // every transfer, by which we determine whether lottery
        // should end on this transfer.
        //
        // Compute it like this: keccak the last (current) 
        // transferHashValue, msg.sender, sender, receiver, amount.

        transferHashValue = uint( keccak256( abi.encodePacked(
            transferHashValue, msg.sender, sender, receiver, amount ) ) );


        // Check if we should be starting a finishing stage block.timestamp.
        checkFinishingStageConditions();

        // If we're on finishing stage, check for ending conditions.
        // If ending check is satisfied, the checkForEnding() function
        // starts ending operations.
        if( onStage( STAGE.FINISHING ) )
            checkForEnding( holderCountChanged );
    }


    /**
     *  Callback function, which is called from Randomness Provider,
     *  after it obtains a random seed to be passed to us, after
     *  we have initiated The Ending Stage, on which random seed
     *  is used to generate random factors for Winner Selection
     *  algorithm.
     */ 
    function finish_randomnessProviderCallback(
            uint256 randomSeed,
            uint256 /*callID*/ )
                                                external
                                                randomnessProviderOnly
    {
        // Set the random seed in the Storage Contract.
        lotStorage.setRandomSeed( randomSeed );

        // If algo-type is not Mined Winner Selection, then by block.timestamp
        // we assume lottery as COMPL3T3D.
        if( cfg.endingAlgoType != uint8(EndingAlgoType.MinedWinnerSelection) )
        {
            lotteryStage = uint8( STAGE.COMPLETION );
            completionDate = uint32( block.timestamp );
        }
    }


    /**
     *  Function checks if we can initiate Alternative Seed generation.
     *
     *  Alternative approach to Lottery Random Seed is used only when
     *  Randomness Provider doesn't work, and doesn't call the
     *  above callback.
     *
     *  This alternative approach can be initiated by Miners, when
     *  these conditions are met:
     *  - Lottery is on Ending (Mining) stage.
     *  - Request to Randomness Provider was made at least X time ago,
     *    and our callback hasn't been called yet.
     *
     *  If these conditions are met, we can initiate the Alternative
     *  Random Seed generation, which generates a seed based on our
     *  state.
     */
    function alternativeSeedGenerationPossible()
                                                        internal view
    returns( bool )
    {
        return ( onStage( STAGE.ENDING_MINING ) &&
                 ( (block.timestamp - finish_timeRandomSeedRequested) >
                   cfg.REQUIRED_TIME_WAITING_FOR_RANDOM_SEED ) );
    }


    /**
     *  Return this lottery's config, using ABIEncoderV2.
     */
    /*function getLotteryConfig()
                                                    external view
    returns( LotteryConfig memory ourConfig )
    {
        return cfg;
    }*/


    /**
     *  Checks if Mining is currently available.
     */
    function isMiningAvailable()
                                                    external view
    returns( bool )
    {
        return onStage( STAGE.ENDING_MINING ) && 
               ( miningStep == 0 || 
                 ( miningStep == 1 && 
                   ( lotStorage.getRandomSeed() != 0 ||
                     alternativeSeedGenerationPossible() )
                 ) );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Mining function, to be executed on Ending (Mining) stage.
     *
     *  "Mining" approach is used in this lottery, to use external
     *  actors for executing the gas-expensive Ending Algorithm,
     *  and other ending operations, such as profit transfers.
     *
     *  "Miners" can be any external actors who call this function.
     *  When Miner successfully completes a Mining Step, he gets 
     *  a Mining Reward, which is a certain portion of lottery's profit
     *  share, dedicated to Miners.
     *
     *  NOT-IMPLEMENTED APPROACH:
     *
     *  All these operations are divided into "mining steps", which are
     *  smaller components, which fit into reasonable gas limits.
     *  All "steps" are designed to take up similar amount of gas.
     *
     *  For example, if total lottery profits (total ETH got from
     *  pulling liquidity out of Uniswap, minus initial funds),
     *  is 100 ETH, Miner Profit Share is 10%, and there are 5 mining
     *  steps total, then for a singe step executed, miner will get:
     *
     *  (100 * 0.1) / 5 = 2 ETH.
     *
     *  ---------------------------------
     *
     *  CURRENTLY IMPLEMENTED APPROACH:
     *
     *  As the above-defined approach would consume very much gas for
     *  inter-step intermediate state storage, we have thought that
     *  for block.timestamp, it's better to have only 2 mining steps, the second of
     *  which performs the whole Winner Selection Algorithm.
     *
     *  This is because performing the whole algorithm at once would save
     *  us up to 10x more gas in total, than executing it in steps.
     *
     *  However, this solution is not scalable, because algorithm has
     *  to fit into block gas limit (10,000,000 gas), so we are limited
     *  to a certain safe maximum number of token holders, which is
     *  empirically determined during testing, and defined in the
     *  MAX_SAFE_NUMBER_OF_HOLDERS constant, which is checked against the
     *  config value "finishCriteria_minNumberOfHolders" in constructor.
     *
     *  So, in this approach, there are only 2 mining steps:
     *
     *  1. Remove liquidity from Uniswap, transfer profit shares to
     *      the Pool and the Owner Address, and request Random Seed
     *      from the Randomness Provider.
     *      Reward: 25% of total Mining Rewards.
     *
     *  2. Perform the whole Winner Selection Algorithm inside the
     *      Lottery Storage contract.
     *      Reward: 75% of total Mining Rewards.
     *
     *  * Function transfers Ether out of our contract:
     *    - Transfers the current miner's reward to msg.sender.
     */
    function mine()
                                external
                                onlyOnStage( STAGE.ENDING_MINING )
    {
        uint currentStepReward;

        // Perform different operations on different mining steps.

        // Step 0:  Remove liquidity from Uniswap, transfer profits to
        //          Pool and Owner addresses. Also, request a Random Seed
        //          from the Randomness Provider.
        if( miningStep == 0 )
        {
            mine_requestRandomSeed();
            mine_removeUniswapLiquidityAndTransferProfits();

            // Compute total miner reward amount, then compute this 
            // step's reward later.
            uint totalMinerRewards = 
                ( ending_profitAmount * cfg.minerProfitShare ) / 
                ( _100PERCENT );

            // Step 0 reward is 10% for Algo type 1.
            if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                currentStepReward = ( totalMinerRewards * (10 * PERCENT) ) /
                                    ( _100PERCENT );
            }
            // If other algo-types, second step is not normally needed,
            // so here we take 80% of miner rewards.
            // If Randomness Provider won't give us a seed after
            // specific amount of time, we'll initiate a second step,
            // with remaining 20% of miner rewords.
            else
            {
                currentStepReward = ( totalMinerRewards * (80 * PERCENT) ) /
                                    ( _100PERCENT );
            }

            require( currentStepReward <= totalMinerRewards/*, "BUG 1694" */);
        }

        // Step 1:
        //  If we use MinedWinnerSelection algo-type, then execute the 
        //  winner selection algorithm.
        //  Otherwise, check if Random Provider hasn't given us a
        //  random seed long enough, so that we have to generate a
        //  seed locally.
        else
        {
            // Check if we can go into this step when using specific
            // ending algorithm types.
            if( cfg.endingAlgoType != uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                require( lotStorage.getRandomSeed() == 0 &&
                         alternativeSeedGenerationPossible()/*,
                         "Second Mining Step is not available for "
                         "current Algo-Type on these conditions!" */);
            }

            // Compute total miner reward amount, then compute this 
            // step's reward later.
            uint totalMinerRewards = 
                ( ending_profitAmount * cfg.minerProfitShare ) / 
                ( _100PERCENT );

            // Firstly, check if random seed is already obtained.
            // If not, check if we should generate it locally.
            if( lotStorage.getRandomSeed() == 0 )
            {
                if( alternativeSeedGenerationPossible() )
                {
                    // Set random seed inside the Storage Contract,
                    // but using our contract's transferHashValue as the
                    // random seed.
                    // We believe that this hash has enough randomness
                    // to be considered a fairly good random seed,
                    // because it has beed chain-computed for every
                    // token transfer that has occured in ACTIVE stage.
                    //
                    lotStorage.setRandomSeed( transferHashValue );

                    // If using Non-Mined algorithm types, reward for this
                    // step is 20% of miner funds.
                    if( cfg.endingAlgoType != 
                        uint8(EndingAlgoType.MinedWinnerSelection) )
                    {
                        currentStepReward = 
                            ( totalMinerRewards * (20 * PERCENT) ) /
                            ( _100PERCENT );
                    }
                }
                else
                {
                    // If alternative seed generation is not yet possible
                    // (not enough time passed since the rand.provider
                    // request was made), then mining is not available
                    // currently.
                    require( false/*, "Mining not yet available!" */);
                }
            }

            // Now, we know that  Random Seed is obtained.
            // If we use this algo-type, perform the actual
            // winner selection algorithm.
            if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                mine_executeEndingAlgorithmStep();

                // Set the prize amount to SECOND STEP prize amount (90%).
                currentStepReward = ( totalMinerRewards * (90 * PERCENT) ) /
                                    ( _100PERCENT );
            }

            // Now we've completed both Mining Steps, it means MINING stage
            // is finally completed!
            // Transition to COMPLETION stage, and set lottery completion
            // time to NOW.

            lotteryStage = uint8( STAGE.COMPLETION );
            completionDate = uint32( block.timestamp );

            require( currentStepReward <= totalMinerRewards/*, "BUG 2007" */);
        }

        // Now, transfer the reward to miner!
        // Check for bugs too - if the computed amount doesn't exceed.

        // Increment the mining step - move to next step (if there is one).
        miningStep++;

        // Check & Lock the Re-Entrancy Lock for transfers.
        require( ! reEntrancyMutexLocked/*, "Re-Entrant call detected!" */);
        reEntrancyMutexLocked = true;

        // Finally, transfer the reward to message sender!
        msg.sender.transfer( currentStepReward );

        // UnLock ReEntrancy Lock.
        reEntrancyMutexLocked = false;
    }


    /**
     *  Function computes winner prize amount for winner at rank #N.
     *  Prerequisites: Must be called only on STAGE.COMPLETION stage,
     *  because we use the final profits amount here, and that value
     *  (ending_profitAmount) is known only on COMPLETION stage.
     *
     *  @param rankingPosition - ranking position of a winner.
     *  @return finalPrizeAmount - prize amount, in Wei, of this winner.
     */
    function getWinnerPrizeAmount(
            uint rankingPosition )
                                                        public view
    returns( uint finalPrizeAmount )
    {
        // Calculate total winner prize fund profit percentage & amount.
        uint winnerProfitPercentage = 
            (_100PERCENT) - cfg.poolProfitShare - 
            cfg.ownerProfitShare - cfg.minerProfitShare;

        uint totalPrizeAmount =
            ( ending_profitAmount * winnerProfitPercentage ) /
            ( _100PERCENT );


        // We compute the prize amounts differently for the algo-type
        // RolledRandomness, because distribution of these prizes is
        // non-deterministic - multiple holders could fall onto the
        // same ranking position, due to randomness of rolled score.
        //
        if( cfg.endingAlgoType == uint8(EndingAlgoType.RolledRandomness) )
        {
            // Here, we'll use Prize Sequence Factor approach differently.
            // We'll use the prizeSequenceFactor value not to compute
            // a geometric progression, but to compute an arithmetic
            // progression, where each ranking position will get a
            // prize equal to 
            // "totalPrizeAmount - rankingPosition * singleWinnerShare"
            //
            // singleWinnerShare is computed as a value corresponding
            // to single-winner's share of total prize amount.
            //
            // Using such an approach, winner at rank 0 would get a
            // prize equal to whole totalPrizeAmount, but, as the
            // scores are rolled using random factor, it's very unlikely
            // to get a such high score, so most likely such prize
            // won't ever be claimed, but it is a possibility.
            //
            // Most of the winners in this approach are likely to
            // roll scores in the middle, so would get prizes equal to
            // 1-10% of total prize funds.

            uint singleWinnerShare = totalPrizeAmount / 
                                     cfg.prizeSequence_winnerCount;

            return totalPrizeAmount - rankingPosition * singleWinnerShare;
        }

        // Now, we know that ending algorithm is normal (deterministic).
        // So, compute the prizes in a standard way.

        // If using Computed Sequence: loop for "rankingPosition"
        // iterations, while computing the prize shares.
        // If "rankingPosition" is larger than sequencedWinnerCount,
        // then compute the prize from sequence-leftover amount.
        if( cfg.prizeSequenceFactor != 0 )
        {
            require( rankingPosition < cfg.prizeSequence_winnerCount/*,
                     "Invalid ranking position!" */);

            // Leftover: If prizeSequenceFactor is 25%, it's 75%.
            uint leftoverPercentage = 
                (_100PERCENT) - cfg.prizeSequenceFactor;

            // Loop until the needed iteration.
            uint loopCount = ( 
                rankingPosition >= cfg.prizeSequence_sequencedWinnerCount ?
                cfg.prizeSequence_sequencedWinnerCount :
                rankingPosition
            );

            for( uint i = 0; i < loopCount; i++ )
            {
                totalPrizeAmount = 
                    ( totalPrizeAmount * leftoverPercentage ) /
                    ( _100PERCENT );
            }

            // Get end prize amount - sequenced, or leftover.
            // Leftover-mode.
            if( loopCount == cfg.prizeSequence_sequencedWinnerCount &&
                cfg.prizeSequence_winnerCount > 
                cfg.prizeSequence_sequencedWinnerCount )
            {
                // Now, totalPrizeAmount equals all leftover-group winner
                // prize funds.
                // So, just divide it by number of leftover winners.
                finalPrizeAmount = 
                    ( totalPrizeAmount ) /
                    ( cfg.prizeSequence_winnerCount -
                      cfg.prizeSequence_sequencedWinnerCount );
            }
            // Sequenced-mode
            else
            {
                finalPrizeAmount = 
                    ( totalPrizeAmount * cfg.prizeSequenceFactor ) /
                    ( _100PERCENT );
            }
        }

        // Else, if we're using Pre-Specified Array of winner profit
        // shares, just get the share at the corresponding index.
        else
        {
            require( rankingPosition < cfg.winnerProfitShares.length );

            finalPrizeAmount = 
                ( totalPrizeAmount *
                  cfg.winnerProfitShares[ rankingPosition ] ) /
                ( _100PERCENT );
        }
    }


    /**
     *  After lottery has completed, this function returns if msg.sender
     *  is one of lottery winners, and the position in winner rankings.
     *  
     *  Function must be used to obtain the ranking position before
     *  calling claimWinnerPrize().
     *
     *  @param addr - address whose status to check.
     */
    function getWinnerStatus( address addr )
                                                        external view
    returns( bool isWinner, uint32 rankingPosition, 
             uint prizeAmount )
    {
        if( !onStage( STAGE.COMPLETION ) || balanceOf( addr ) == 0 )
            return (false , 0, 0);

        ( isWinner, rankingPosition ) =
            lotStorage.getWinnerStatus( addr );

        if( isWinner )
        {
            prizeAmount = getWinnerPrizeAmount( rankingPosition );
            if( prizeAmount > address(this).balance )
                prizeAmount = address(this).balance;
        }
    }


    /**
     *  Compute the intermediate Active Stage player score.
     *  This score is Player Score, not randomized.
     *  @param addr - address to check.
     */
    function getPlayerIntermediateScore( address addr )
                                                        external view
    returns( uint )
    {
        return lotStorage.getPlayerActiveStageScore( addr );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Claim the winner prize of msg.sender, if he is one of the winners.
     *
     *  This function must be provided a ranking position of msg.sender,
     *  which must be obtained using the function above.
     *  
     *  The Lottery Storage then just checks if holder address in the
     *  winner array element at position rankingPosition is the same
     *  as msg.sender's.
     *
     *  If so, then claim request is valid, and we can give the appropriate
     *  prize to that winner.
     *  Prize can be determined by a computed factor-based sequence, or
     *  from the pre-specified winner array.
     *
     *  * This function transfers Ether out of our contract:
     *    - Sends the corresponding winner prize to the msg.sender.
     *
     *  @param rankingPosition - the position of Winner Array, that
     *      msg.sender says he is in (obtained using getWinnerStatus).
     */
    function claimWinnerPrize(
            uint32 rankingPosition )
                                    external
                                    onlyOnStage( STAGE.COMPLETION )
                                    mutexLOCKED
    {
        // Check if msg.sender hasn't already claimed his prize.
        require( ! prizeClaimersAddresses[ msg.sender ]/*,
                 "msg.sender has already claimed his prize!" */);

        // msg.sender must have at least some of UniLottery Tokens.
        require( balanceOf( msg.sender ) != 0/*,
                 "msg.sender's token balance can't be zero!" */);

        // Check if there are any prize funds left yet.
        require( address(this).balance != 0/*,
                 "All prize funds have already been claimed!" */);

        // If using Mined Selection Algo, check if msg.sender is 
        // really on that ranking position - algo was already executed.
        if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
        {
            require( lotStorage.minedSelection_isAddressOnWinnerPosition(
                            msg.sender, rankingPosition )/*,
                     "msg.sender is not on specified winner position!" */);
        }
        // For other algorithms, get ranking position by executing
        // a specific algorithm of that algo-type.
        else
        {
            bool isWinner;
            ( isWinner, rankingPosition ) =
                lotStorage.getWinnerStatus( msg.sender );

            require( isWinner/*, "msg.sender is not a winner!" */);
        }

        // Compute the prize amount, using our internal function.
        uint finalPrizeAmount = getWinnerPrizeAmount( rankingPosition ); 

        // If prize is small and computation precision errors occured,
        // leading it to be larger than our balance, fix it.
        if( finalPrizeAmount > address(this).balance )
            finalPrizeAmount = address(this).balance;


        // Transfer the Winning Prize to msg.sender!
        msg.sender.transfer( finalPrizeAmount );


        // Mark msg.sender as already claimed his prize.
        prizeClaimersAddresses[ msg.sender ] = true;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Transfer the leftover Winner Prize Funds of this contract to the
     *  Main UniLottery Pool, if prize claim deadline has been exceeded.
     *
     *  Function can only be called from the Main Pool, and if some
     *  winners haven't managed to claim their prizes on time, their
     *  prizes will go back to UniLottery Pool.
     *
     *  * Function transfers Ether out of our contract:
     *    - Transfer the leftover funds to the Pool (msg.sender).
     */
    function getUnclaimedPrizes()
                                        external
                                        poolOnly
                                        onlyOnStage( STAGE.COMPLETION )
                                        mutexLOCKED
    {
        // Check if prize claim deadline has passed.
        require( completionDate != 0 &&
                 ( block.timestamp - completionDate ) > cfg.prizeClaimTime/*,
                 "Prize claim deadline not reached yet!" */);

        // Just transfer it all to the Pool.
        poolAddress.transfer( address(this).balance );
    }

}

/**
 *  The Lottery Storage contract.
 *
 *  This contract is used to store all Holder Data of a specific lottery
 *  contract - that includes lottery token holders list, and every
 *  holder's intermediate scores (HolderData structure).
 *
 *  When the lottery, that this storage belongs to, ends, then 
 *  this Storage contract also performs the whole winner selection
 *  algorithm.
 *
 *  Also, one of this contract's purposes is to split code,
 *  to avoid the 24kb code size limit error.
 *
 *  Notice, that Lottery and LotteryStorage contracts must have a
 *  1:1 relationship - every Lottery has only one Storage, and
 *  every Storage belongs to only one Lottery.
 *
 *  The LotteryStorage contracts are being created from the 
 *  LotteryStorageFactory contract, and only after that, the parent
 *  Lottery is created, so Lottery must initialize it's Storage,
 *  by calling initialize() function on freshly-created Storage,
 *  which set's the Lottery address, and locks it.
 */
contract LotteryStorage is CoreUniLotterySettings
{
    // ==================== Structs & Constants ==================== //

    // Struct of holder data & scores.
    struct HolderData 
    {
        // --------- Slot --------- //

        // If this holder provided a valid referral ID, this is the 
        // address of a referrer - the user who generated the said
        // referral ID.
        address referrer;

        // Bonus score points, which can be given in certain events,
        // such as when player registers a valid referral ID.
        int16 bonusScore;

        // Number of all child referrees, including multi-level ones.
        // Updated by traversing child->parent way, incrementing
        // every node's counter by one.
        // Used in Winner Selection Algorithm, to determine how much
        // to divide the accumulated referree scores by.
        uint16 referreeCount;


        // --------- Slot --------- //

        // If this holder has generated his own referral ID, this is
        // that ID. If he hasn't generated an ID, this is zero.
        uint256 referralID;


        // --------- Slot --------- //

        // The intermediate individual score factor variables.
        // Ether contributed: ( buys - sells ). Can be negative.
        int40 etherContributed;

        // Time x ether factor: (relativeTxTime * etherAmount).
        int40 timeFactors;

        // Token balance score factor of this holder - we use int,
        // for easier computation of player scores in our algorithms.
        int40 tokenBalance;

        // Accumulated referree score factors - ether contributed by
        // all referrees, time factors, and token balances of all
        // referrees.
        int40 referree_etherContributed;
        int40 referree_timeFactors;
        int40 referree_tokenBalance;
    }


    // Final Score (end lottery score * randomValue) structure.
    struct FinalScore 
    {
        address addr;           // 20 bytes \
        uint16 holderIndex;     // 2 bytes  | = 30 bytes => 1 slot.
        uint64 score;           // 8 bytes  /
    }


    // Winner Indexes structure - used to efficiently store Winner
    // indexes in holder's array, after completing the Winner Selection
    // Algorithm.
    // To save Space, we store these in a struct, with uint16 array
    // with 16 items - so this struct takes up excactly 1 slot.
    struct WinnerIndexStruct
    {
        uint16[ 16 ] indexes;
    }


    // A structure which is used by Winner Selection algorithm,
    // which is a subset of the LotteryConfig structure, containing
    // only items necessary for executing the Winner Selection algorigm.
    // More detailed member description can be found in LotteryConfig
    // structure description.
    // Takes up only one slot!
    struct WinnerAlgorithmConfig
    {
        // --------- Slot --------- //

        // Individual player max score parts.
        int16 maxPlayerScore_etherContributed;
        int16 maxPlayerScore_tokenHoldingAmount;
        int16 maxPlayerScore_timeFactor;
        int16 maxPlayerScore_refferalBonus;

        // Number of lottery winners.
        uint16 winnerCount;

        // Score-To-Random ration data (as a rational ratio number).
        // For example if 1:5, then scorePart = 1, and randPart = 5.
        uint16 randRatio_scorePart;
        uint16 randRatio_randPart;

        // The Ending Algorithm type.
        uint8 endingAlgoType;
    }


    // Structure containing the minimum and maximum values of
    // holder intermediate scores.
    // These values get updated on transfers during ACTIVE stage,
    // when holders buy/sell tokens.
    //
    // Used in winner selection algorithm, to normalize the scores in
    // a single loop, to avoid looping additional time to find min/max.
    //
    // Structure takes up only a single slot!
    //
    struct MinMaxHolderScores
    {
        // --------- Slot --------- //

        int40 holderScore_etherContributed_min;
        int40 holderScore_etherContributed_max;

        int40 holderScore_timeFactors_min;
        int40 holderScore_timeFactors_max;

        int40 holderScore_tokenBalance_min;
        int40 holderScore_tokenBalance_max;
    }

    // Referral score variant of the structure above.
    // Also, only a single slot!
    //
    struct MinMaxReferralScores
    {
        // --------- Slot --------- //

        // Min&Max values for referrer scores.
        int40 referralScore_etherContributed_min;
        int40 referralScore_etherContributed_max;

        int40 referralScore_timeFactors_min;
        int40 referralScore_timeFactors_max;

        int40 referralScore_tokenBalance_min;
        int40 referralScore_tokenBalance_max;
    }

    // ROOT_REFERRER constant.
    // Used to prevent cyclic dependencies on referral tree.
    address constant ROOT_REFERRER = address( 1 );

    // Max referral tree depth - maximum number of referrees that
    // a referrer can get.
    uint constant MAX_REFERRAL_DEPTH = 10;

    // Precision of division operations.
    int constant PRECISION = 10000;

    // Random number modulo to use when obtaining random numbers from
    // the random seed + nonce, using keccak256.
    // This is the maximum available Score Random Factor, plus one.
    // By default, 10^9 (one billion).
    //
    uint constant RANDOM_MODULO = (10 ** 9);

    // Maximum number of holders that the MinedWinnerSelection algorithm
    // can process. Related to block gas limit.
    uint constant MINEDSELECTION_MAX_NUMBER_OF_HOLDERS = 300;

    // Maximum number of holders that the WinnerSelfValidation algorithm
    // can process. Related to block gas limit.
    uint constant SELFVALIDATION_MAX_NUMBER_OF_HOLDERS = 1200;


    // ==================== State Variables ==================== //

    // --------- Slot --------- //

    // The Lottery address that this storage belongs to.
    // Is set by the "initialize()", called by corresponding Lottery.
    address lottery;

    // The Random Seed, that was passed to us from Randomness Provider,
    // or generated alternatively.
    uint64 randomSeed;

    // The actual number of winners that there will be. Set after
    // completing the Winner Selection Algorithm.
    uint16 numberOfWinners;

    // Bool indicating if Winner Selection Algorithm has been executed.
    bool algorithmCompleted;


    // --------- Slot --------- //

    // Winner Algorithm config. Specified in Initialization().
    WinnerAlgorithmConfig algConfig;

    // --------- Slot --------- //

    // The Min-Max holder score storage.
    MinMaxHolderScores public minMaxScores;
    MinMaxReferralScores public minMaxReferralScores;

    // --------- Slot --------- //

    // Array of holders.
    address[] public holders;

    // --------- Slot --------- //

    // Holder array indexes mapping, for O(1) array element access.
    mapping( address => uint ) holderIndexes;

    // --------- Slot --------- //

    // Mapping of holder data.
    mapping( address => HolderData ) public holderData;

    // --------- Slot --------- //

    // Mapping of referral IDs to addresses of holders who generated
    // those IDs.
    mapping( uint256 => address ) referrers;

    // --------- Slot --------- //

    // The array of final-sorted winners (set after Winner Selection
    // Algorithm completes), that contains the winners' indexes
    // in the "holders" array, to save space.
    //
    // Notice that by using uint16, we can fit 16 items into one slot!
    // So, if there are 160 winners, we only take up 10 slots, so
    // only 20,000 * 10 = 200,000 gas gets consumed!
    //
    WinnerIndexStruct[] sortedWinnerIndexes;



    // ==============       Internal (Private) Functions    ============== //

    // Lottery-Only modifier.
    modifier lotteryOnly
    {
        require( msg.sender == address( lottery )/*,
                 "Function can only be called by Lottery that this"
                 "Storage Contract belongs to!" */);
        _;
    }


    // ============== [ BEGIN ] LOTTERY QUICKSORT FUNCTIONS ============== //

    /**
     *  QuickSort and QuickSelect algorithm functionality code.
     *
     *  These algorithms are used to find the lottery winners in
     *  an array of final random-factored scores.
     *  As the highest-scorers win, we need to sort an array to
     *  identify them.
     *
     *  For this task, we use QuickSelect to partition array into
     *  winner part (elements with score larger than X, where X is
     *  n-th largest element, where n is number of winners),
     *  and others (non-winners), who are ignored to save computation
     *  power.
     *  Then we sort the winner part only, using QuickSort, and
     *  distribute prizes to winners accordingly.
     */

    // Swap function used in QuickSort algorithms.
    //
    function QSort_swap( FinalScore[] memory list, 
                         uint a, uint b )               
                                                        internal pure
    {
        FinalScore memory tmp = list[ a ];
        list[ a ] = list[ b ];
        list[ b ] = tmp;
    }

    // Standard Hoare's partition scheme function, used for both
    // QuickSort and QuickSelect.
    //
    function QSort_partition( 
            FinalScore[] memory list, 
            int lo, int hi )
                                                        internal pure
    returns( int newPivotIndex )
    {
        uint64 pivot = list[ uint( hi + lo ) / 2 ].score;
        int i = lo - 1;
        int j = hi + 1;

        while( true ) 
        {
            do {
                i++;
            } while( list[ uint( i ) ].score > pivot ) ;

            do {
                j--;
            } while( list[ uint( j ) ].score < pivot ) ;

            if( i >= j )
                return j;

            QSort_swap( list, uint( i ), uint( j ) );
        }
    }

    // QuickSelect's Lomuto partition scheme.
    //
    function QSort_LomutoPartition(
            FinalScore[] memory list,
            uint left, uint right, uint pivotIndex )
                                                        internal pure
    returns( uint newPivotIndex )
    {
        uint pivotValue = list[ pivotIndex ].score;
        QSort_swap( list, pivotIndex, right );  // Move pivot to end
        uint storeIndex = left;
        
        for( uint i = left; i < right; i++ )
        {
            if( list[ i ].score > pivotValue ) {
                QSort_swap( list, storeIndex, i );
                storeIndex++;
            }
        }

        // Move pivot to its final place, and return the pivot's index.
        QSort_swap( list, right, storeIndex );
        return storeIndex;
    }

    // QuickSelect algorithm (iterative).
    //
    function QSort_QuickSelect(
            FinalScore[] memory list,
            int left, int right, int k )
                                                        internal pure
    returns( int indexOfK )
    {
        while( true ) {
            if( left == right )
                return left;

            int pivotIndex = int( QSort_LomutoPartition( list, 
                    uint(left), uint(right), uint(right) ) );

            if( k == pivotIndex )
                return k;
            else if( k < pivotIndex )
                right = pivotIndex - 1;
            else
                left = pivotIndex + 1;
        }
    }

    // Standard QuickSort function.
    //
    function QSort_QuickSort(
            FinalScore[] memory list,
            int lo, int hi )
                                                        internal pure
    {
        if( lo < hi ) {
            int p = QSort_partition( list, lo, hi );
            QSort_QuickSort( list, lo, p );
            QSort_QuickSort( list, p + 1, hi );
        }
    }

    // ============== [ END ]   LOTTERY QUICKSORT FUNCTIONS ============== //

    // ------------ Ending Stage - Winner Selection Algorithm ------------ //

    /**
     *  Compute the individual player score factors for a holder.
     *  Function split from the below one (ending_Stage_2), to avoid
     *  "Stack too Deep" errors.
     */
    function computeHolderIndividualScores( 
            WinnerAlgorithmConfig memory cfg,
            MinMaxHolderScores memory minMax,
            HolderData memory hdata )
                                                        internal pure
    returns( int individualScore )
    {
        // Normalize the scores, by subtracting minimum and dividing
        // by maximum, to get the score values specified in cfg.
        // Use precision of 100, then round.
        //
        // Notice that we're using int arithmetics, so division 
        // truncates. That's why we use PRECISION, to simulate
        // rounding.
        //
        // This formula is better explained in example.
        // In this example, we use variable abbreviations defined
        // below, on formula's right side comments.
        //
        // Say, values are these in our example:
        // e = 4, eMin = 1, eMax = 8, MS = 5, P = 10.
        //
        // So, let's calculate the score using the formula:
        // ( ( ( (4 - 1) * 10 * 5 ) / (8 - 1) ) + (10 / 2) ) / 10 =
        // ( ( (    3    * 10 * 5 ) /    7    ) +     5    ) / 10 =
        // ( (         150          /    7    ) +     5    ) / 10 =
        // ( (         150          /    7    ) +     5    ) / 10 =
        // (                    20              +     5    ) / 10 =
        //                          25                       / 10 =
        //                        [ 2.5 ]                         = 2
        //
        // So, with truncation, we see that for e = 4, the score
        // is 2 out of 5 maximum.
        // That's because the minimum ether contributed was 1, and
        // maximum was 8.
        // So, 4 stays below the middle, and gets a nicely rounded 
        // score of 2.

        // Compute etherContributed.
        int score_etherContributed = ( (
            ( int( hdata.etherContributed -                      // e
                   minMax.holderScore_etherContributed_min )     // eMin
              * PRECISION * cfg.maxPlayerScore_etherContributed )// P * MS
            / int( minMax.holderScore_etherContributed_max -     // eMax
                   minMax.holderScore_etherContributed_min )     // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Compute timeFactors.
        int score_timeFactors = ( (
            ( int( hdata.timeFactors -                          // e
                   minMax.holderScore_timeFactors_min )         // eMin
              * PRECISION * cfg.maxPlayerScore_timeFactor )     // P * MS
            / int( minMax.holderScore_timeFactors_max -         // eMax
                   minMax.holderScore_timeFactors_min )         // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Compute tokenBalance.
        int score_tokenBalance = ( (
            ( int( hdata.tokenBalance -                         // e
                   minMax.holderScore_tokenBalance_min )        // eMin
              * PRECISION * cfg.maxPlayerScore_tokenHoldingAmount )
            / int( minMax.holderScore_tokenBalance_max -        // eMax
                   minMax.holderScore_tokenBalance_min )        // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Return the accumulated individual score (excluding referrees).
        return score_etherContributed + score_timeFactors +
               score_tokenBalance;
    }


    /**
     *  Compute the unified Referree-Score of a player, who's got
     *  the accumulated factor-scores of all his referrees in his 
     *  holderData structure.
     *
     *  @param individualToReferralRatio - an int value, computed 
     *      before starting the winner score computation loop, in 
     *      the ending_Stage_2 initial part, to save computation
     *      time later.
     *      This is the ratio of the maximum available referral score,
     *      to the maximum available individual score, as defined in
     *      the config (for example, if max.ref.score is 20, and 
     *      max.ind.score is 40, then the ratio is 20/40 = 0.5).
     *      
     *      We use this ratio to transform the computed accumulated
     *      referree individual scores to the standard referrer's
     *      score, by multiplying by that ratio.
     */
    function computeReferreeScoresForHolder( 
            int individualToReferralRatio,
            WinnerAlgorithmConfig memory cfg,
            MinMaxReferralScores memory minMax,
            HolderData memory hdata )
                                                        internal pure
    returns( int unifiedReferreeScore )
    {
        // If number of referrees of this HODLer is Zero, then
        // his referree score is also zero.
        if( hdata.referreeCount == 0 )
            return 0;

        // Now, compute the Referree's Accumulated Scores.
        //
        // Here we use the same formula as when computing individual
        // scores (in the function above), but we use referree parts
        // instead.

        // Compute etherContributed.
        int referreeScore_etherContributed = ( (
            ( int( hdata.referree_etherContributed -
                   minMax.referralScore_etherContributed_min )
              * PRECISION * cfg.maxPlayerScore_etherContributed )
            / int( minMax.referralScore_etherContributed_max -
                   minMax.referralScore_etherContributed_min )
        ) );

        // Compute timeFactors.
        int referreeScore_timeFactors = ( (
            ( int( hdata.referree_timeFactors -
                   minMax.referralScore_timeFactors_min )
              * PRECISION * cfg.maxPlayerScore_timeFactor )
            / int( minMax.referralScore_timeFactors_max -
                   minMax.referralScore_timeFactors_min )
        ) );

        // Compute tokenBalance.
        int referreeScore_tokenBalance = ( (
            ( int( hdata.referree_tokenBalance -
                   minMax.referralScore_tokenBalance_min )
              * PRECISION * cfg.maxPlayerScore_tokenHoldingAmount )
            / int( minMax.referralScore_tokenBalance_max -
                   minMax.referralScore_tokenBalance_min )
        ) );


        // Accumulate 'em all !
        // Then, multiply it by the ratio of all individual max scores
        // (maxPlayerScore_etherContributed, timeFactor, tokenBalance),
        // to the maxPlayerScore_refferalBonus.
        // Use the same precision.
        unifiedReferreeScore = int( ( (
                ( ( referreeScore_etherContributed +
                    referreeScore_timeFactors +
                    referreeScore_tokenBalance ) + (PRECISION / 2)
                ) / PRECISION
            ) * individualToReferralRatio
        ) / PRECISION );
    }


    /**
     *  Update Min & Max values for individual holder scores.
     */
    function priv_updateMinMaxScores_individual(
            MinMaxHolderScores memory minMax,
            int40 _etherContributed,
            int40 _timeFactors,
            int40 _tokenBalance )
                                                    internal
                                                    pure
    {
        // etherContributed:
        if( _etherContributed > 
            minMax.holderScore_etherContributed_max )
            minMax.holderScore_etherContributed_max = 
                _etherContributed;

        if( _etherContributed <
            minMax.holderScore_etherContributed_min )
            minMax.holderScore_etherContributed_min = 
                _etherContributed;

        // timeFactors:
        if( _timeFactors > 
            minMax.holderScore_timeFactors_max )
            minMax.holderScore_timeFactors_max = 
                _timeFactors;

        if( _timeFactors <
            minMax.holderScore_timeFactors_min )
            minMax.holderScore_timeFactors_min = 
                _timeFactors;

        // tokenBalance:
        if( _tokenBalance > 
            minMax.holderScore_tokenBalance_max )
            minMax.holderScore_tokenBalance_max = 
                _tokenBalance;

        if( _tokenBalance <
            minMax.holderScore_tokenBalance_min )
            minMax.holderScore_tokenBalance_min = 
                _tokenBalance;
    }


    /**
     *  Update Min & Max values for referral scores.
     */
    function priv_updateMinMaxScores_referral(
            MinMaxReferralScores memory minMax,
            int40 _etherContributed,
            int40 _timeFactors,
            int40 _tokenBalance )
                                                    internal
                                                    pure
    {
        // etherContributed:
        if( _etherContributed > 
            minMax.referralScore_etherContributed_max )
            minMax.referralScore_etherContributed_max = 
                _etherContributed;

        if( _etherContributed <
            minMax.referralScore_etherContributed_min )
            minMax.referralScore_etherContributed_min = 
                _etherContributed;

        // timeFactors:
        if( _timeFactors > 
            minMax.referralScore_timeFactors_max )
            minMax.referralScore_timeFactors_max = 
                _timeFactors;

        if( _timeFactors <
            minMax.referralScore_timeFactors_min )
            minMax.referralScore_timeFactors_min = 
                _timeFactors;

        // tokenBalance:
        if( _tokenBalance > 
            minMax.referralScore_tokenBalance_max )
            minMax.referralScore_tokenBalance_max = 
                _tokenBalance;

        if( _tokenBalance <
            minMax.referralScore_tokenBalance_min )
            minMax.referralScore_tokenBalance_min = 
                _tokenBalance;
    }



    // =================== PUBLIC FUNCTIONS =================== //

    /**
     *  Update current holder's score with given change values, and
     *  Propagate the holder's current transfer's score changes
     *  through the referral chain, updating every parent referrer's
     *  accumulated referree scores, until the ROOT_REFERRER or zero
     *  address referrer is encountered.
     */
    function updateAndPropagateScoreChanges(
            address holder,
            int __etherContributed_change,
            int __timeFactors_change,
            int __tokenBalance_change )
                                                        public
                                                        lotteryOnly
    {
        // Convert the data into shrinked format - leave only
        // 4 decimals of Ether precision, and drop the decimal part
        // of ULT tokens absolutely.
        // Don't change TimeFactors, as it is already adjusted in
        // Lottery contract's code.
        int40 timeFactors_change = int40( __timeFactors_change );

        int40 etherContributed_change = int40(
            __etherContributed_change / int(1 ether / 10000) );
 
        int40 tokenBalance_change = int40(
            __tokenBalance_change / int(1 ether) );

        // Update current holder's score.
        holderData[ holder ].etherContributed += etherContributed_change;
        holderData[ holder ].timeFactors += timeFactors_change;
        holderData[ holder ].tokenBalance += tokenBalance_change;

        // Check if scores are exceeding current min/max scores, 
        // and if so, update the min/max scores.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        priv_updateMinMaxScores_individual(
            minMaxCpy,
            holderData[ holder ].etherContributed,
            holderData[ holder ].timeFactors,
            holderData[ holder ].tokenBalance
        );

        // Propagate the score through the referral chain.
        // Dive at maximum to the depth of 10, to avoid "Outta Gas"
        // errors.
        uint depth = 0;
        address referrerAddr = holderData[ holder ].referrer;

        while( referrerAddr != ROOT_REFERRER && 
               referrerAddr != address( 0 )  &&
               depth < MAX_REFERRAL_DEPTH )
        {
            // Update this referrer's accumulated referree scores.
            holderData[ referrerAddr ].referree_etherContributed +=
                etherContributed_change;

            holderData[ referrerAddr ].referree_timeFactors +=
                timeFactors_change;

            holderData[ referrerAddr ].referree_tokenBalance +=
                tokenBalance_change;

            // Update MinMax according to this referrer's score.
            priv_updateMinMaxScores_referral(
                minMaxRefCpy,
                holderData[ referrerAddr ].referree_etherContributed,
                holderData[ referrerAddr ].referree_timeFactors,
                holderData[ referrerAddr ].referree_tokenBalance
            );

            // Move to the higher-level referrer.
            referrerAddr = holderData[ referrerAddr ].referrer;
            depth++;
        }

        // Check if MinMax have changed. If so, update it.
        if( keccak256( abi.encode( minMaxCpy ) ) != 
            keccak256( abi.encode( minMaxScores ) ) )
            minMaxScores = minMaxCpy;

        // Check referral part.
        if( keccak256( abi.encode( minMaxRefCpy ) ) != 
            keccak256( abi.encode( minMaxReferralScores ) ) )
            minMaxReferralScores = minMaxRefCpy;
    }


    /**
     *  Pure function to fix an in-memory copy of MinMaxScores,
     *  by changing equal min-max pairs to differ by one.
     *  This is needed to avoid division-by-zero in some calculations.
     */
    function priv_fixMinMaxIfEqual(
            MinMaxHolderScores memory minMaxCpy,
            MinMaxReferralScores memory minMaxRefCpy )
                                                            internal
                                                            pure
    {
        // Individual part
        if( minMaxCpy.holderScore_etherContributed_min ==
            minMaxCpy.holderScore_etherContributed_max )
            minMaxCpy.holderScore_etherContributed_max =
            minMaxCpy.holderScore_etherContributed_min + 1;

        if( minMaxCpy.holderScore_timeFactors_min ==
            minMaxCpy.holderScore_timeFactors_max )
            minMaxCpy.holderScore_timeFactors_max =
            minMaxCpy.holderScore_timeFactors_min + 1;

        if( minMaxCpy.holderScore_tokenBalance_min ==
            minMaxCpy.holderScore_tokenBalance_max )
            minMaxCpy.holderScore_tokenBalance_max =
            minMaxCpy.holderScore_tokenBalance_min + 1;

        // Referral part
        if( minMaxRefCpy.referralScore_etherContributed_min ==
            minMaxRefCpy.referralScore_etherContributed_max )
            minMaxRefCpy.referralScore_etherContributed_max =
            minMaxRefCpy.referralScore_etherContributed_min + 1;

        if( minMaxRefCpy.referralScore_timeFactors_min ==
            minMaxRefCpy.referralScore_timeFactors_max )
            minMaxRefCpy.referralScore_timeFactors_max =
            minMaxRefCpy.referralScore_timeFactors_min + 1;

        if( minMaxRefCpy.referralScore_tokenBalance_min ==
            minMaxRefCpy.referralScore_tokenBalance_max )
            minMaxRefCpy.referralScore_tokenBalance_max =
            minMaxRefCpy.referralScore_tokenBalance_min + 1;
    }


    /** 
     *  Function executes the Lottery Winner Selection Algorithm,
     *  and writes the final, sorted array, containing winner rankings.
     *
     *  This function is called from the Lottery's Mining Stage Step 2,
     *
     *  This is the final function that lottery performs actively - 
     *  and arguably the most important - because it determines 
     *  lottery winners through Winner Selection Algorithm.
     *
     *  The random seed must be already set, before calling this function.
     */
    function executeWinnerSelectionAlgorithm()
                                                        public
                                                        lotteryOnly
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is MinedWinnerSelection!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.MinedWinnerSelection)/*,
                 "Algorithm cannot be performed on current Algo-Type!" */);

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we block.timestamp have to do, is loop through holder array, and
        // compute randomized final scores for every holder, into
        // the Final Score array.

        // Declare the Final Score array - computed for all holders.
        uint ARRLEN = 
            ( holders.length > MINEDSELECTION_MAX_NUMBER_OF_HOLDERS ?
              MINEDSELECTION_MAX_NUMBER_OF_HOLDERS : holders.length );

        FinalScore[] memory finalScores = new FinalScore[] ( ARRLEN );

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5/*, "scorePart" */== 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        priv_fixMinMaxIfEqual( minMaxCpy, minMaxRefCpy );

        // Loop through all the holders.
        for( uint i = 0; i < ARRLEN; i++ )
        {
            // Fetch the needed holder data to in-memory hdata variable,
            // to save gas on score part computing functions.
            HolderData memory hdata;

            // Slot 1:
            hdata.etherContributed =
                holderData[ holders[ i ] ].etherContributed;
            hdata.timeFactors =
                holderData[ holders[ i ] ].timeFactors;
            hdata.tokenBalance =
                holderData[ holders[ i ] ].tokenBalance;
            hdata.referreeCount =
                holderData[ holders[ i ] ].referreeCount;

            // Slot 2:
            hdata.referree_etherContributed =
                holderData[ holders[ i ] ].referree_etherContributed;
            hdata.referree_timeFactors =
                holderData[ holders[ i ] ].referree_timeFactors;
            hdata.referree_tokenBalance =
                holderData[ holders[ i ] ].referree_tokenBalance;
            hdata.bonusScore =
                holderData[ holders[ i ] ].bonusScore;


            // Now, add bonus score, and compute total player's score:
            // Bonus part, individual score part, and referree score part.
            int totalPlayerScore = 
                    hdata.bonusScore
                    +
                    computeHolderIndividualScores(
                        cfg, minMaxCpy, hdata )
                    +
                    computeReferreeScoresForHolder( 
                        individualToReferralRatio, cfg, 
                        minMaxRefCpy, hdata );


            // Check if total player score <= 0. If so, make it equal
            // to 1, because otherwise randomization won't be possible.
            if( totalPlayerScore <= 0 )
                totalPlayerScore = 1;

            // Now, check if it's not more than max! If so, lowerify.
            // This could have happen'd because of bonus.
            if( totalPlayerScore > maxAvailablePlayerScore )
                totalPlayerScore = maxAvailablePlayerScore;


            // Multiply the score by the Random Modulo Adjustment
            // Factor, to get fairer ratio of random-to-determined data.
            totalPlayerScore =  ( totalPlayerScore * SCORE_RAND_FACT ) /
                                ( PRECISION );

            // Score is computed!
            // Now, randomize it, and add to Final Scores Array.
            // We use keccak to generate a random number from random seed,
            // using holder's address as a nonce.

            uint modulizedRandomNumber = uint(
                keccak256( abi.encodePacked( randomSeed, holders[ i ] ) )
            ) % RANDOM_MODULO;

            // Add the random number, to introduce the random factor.
            // Ratio of (current) totalPlayerScore to modulizedRandomNumber
            // is the same as ratio of randRatio_scorePart to 
            // randRatio_randPart.

            uint endScore = uint( totalPlayerScore ) + modulizedRandomNumber;

            // Finally, set this holder's final score data.
            finalScores[ i ].addr = holders[ i ];
            finalScores[ i ].holderIndex = uint16( i );
            finalScores[ i ].score = uint64( endScore );
        }

        // All final scores are block.timestamp computed.
        // Sort the array, to find out the highest scores!

        // Firstly, partition an array to only work on top K scores,
        // where K is the number of winners.
        // There can be a rare case where specified number of winners is
        // more than lottery token holders. We got that covered.

        require( finalScores.length > 0 );

        uint K = cfg.winnerCount - 1;
        if( K > finalScores.length-1 )
            K = finalScores.length-1;   // Must be THE LAST ELEMENT's INDEX.

        // Use QuickSelect to do this.
        QSort_QuickSelect( finalScores, 0, 
            int( finalScores.length - 1 ), int( K ) );

        // Now, QuickSort only the first K items, because the rest
        // item scores are not high enough to become winners.
        QSort_QuickSort( finalScores, 0, int( K ) );

        // Now, the winner array is sorted, with the highest scores
        // sitting at the first positions!
        // Let's set up the winner indexes array, where we'll store
        // the winners' indexes in the holders array.
        // So, if this array is [8, 2, 3], that means that
        // Winner #1 is holders[8], winner #2 is holders[2], and
        // winner #3 is holders[3].

        // Set the Number Of Winners variable.
        numberOfWinners = uint16( K + 1 );

        // Now, we can loop through the first numberOfWinners elements, to set
        // the holder indexes!
        // Loop through 16 elements at a time, to fill the structs.
        for( uint offset = 0; offset < numberOfWinners; offset += 16 )
        {
            WinnerIndexStruct memory windStruct;
            uint loopStop = ( offset + 16 > numberOfWinners ?
                              numberOfWinners : offset + 16 );

            for( uint i = offset; i < loopStop; i++ )
            {
                windStruct.indexes[ i - offset ] =finalScores[ i ].holderIndex;
            }

            // Push this block.timestamp-filled struct to the storage array!
            sortedWinnerIndexes.push( windStruct );
        }

        // That's it! We're done!
        algorithmCompleted = true;
    }


    /**
     *  Add a holder to holders array.
     *  @param holder   - address of a holder to add.
     */
    function addHolder( address holder )
                                                        public
                                                        lotteryOnly
    {
        // Add it to list, and set index in the mapping.
        holders.push( holder );
        holderIndexes[ holder ] = holders.length - 1;
    }

    /**
     *  Removes the holder 'sender' from the Holders Array.
     *  However, this holder's HolderData structure persists!
     *
     *  Notice that no index validity checks are performed, so, if
     *  'sender' is not present in "holderIndexes" mapping, this
     *  function will remove the 0th holder instead!
     *  This is not a problem for us, because Lottery calls this
     *  function only when it's absolutely certain that 'sender' is
     *  present in the holders array.
     *
     *  @param sender   - address of a holder to remove.
     *      Named 'sender', because when token sender sends away all
     *      his tokens, he must then be removed from holders array.
     */
    function removeHolder( address sender )
                                                        public
                                                        lotteryOnly
    {
        // Get index of the sender address in the holders array.
        uint index = holderIndexes[ sender ];

        // Remove the sender from array, by copying last element's
        // value into the index'th element, where sender was before.
        holders[ index ] = holders[ holders.length - 1 ];

        // Remove the last element of array, which we've just copied.
        holders.pop();

        // Update indexes: remove the sender's index from the mapping,
        // and change the previoulsy-last element's index to the
        // one where we copied it - where sender was before.
        delete holderIndexes[ sender ];
        holderIndexes[ holders[ index ] ] = index;
    }


    /**
     *  Get holder array length.
     */
    function getHolderCount()
                                                    public view
    returns( uint )
    {
        return holders.length;
    }


    /**
     *  Generate a referral ID for a token holder.
     *  Referral ID is used to refer other wallets into playing our
     *  lottery.
     *  - Referrer gets bonus points for every wallet that bought 
     *    lottery tokens and specified his referral ID.
     *  - Referrees (wallets who got referred by registering a valid
     *    referral ID, corresponding to some referrer), get some
     *    bonus points for specifying (registering) a referral ID.
     *
     *  Referral ID is a uint256 number, which is generated by
     *  keccak256'ing the holder's address, holder's current
     *  token ballance, and current time.
     */
    function generateReferralID( address holder )
                                                            public
                                                            lotteryOnly
    returns( uint256 referralID )
    {
        // Check if holder has some tokens, and doesn't
        // have his own referral ID yet.
        require( holderData[ holder ].tokenBalance != 0/*,
                 "holder doesn't have any lottery tokens!" */);

        require( holderData[ holder ].referralID == 0/*,
                 "Holder already has a referral ID!" */);

        // Generate a referral ID with keccak.
        uint256 refID = uint256( keccak256( abi.encodePacked( 
                holder, holderData[ holder ].tokenBalance, block.timestamp ) ) );

        // Specify the ID as current ID of this holder.
        holderData[ holder ].referralID = refID;

        // If this holder wasn't referred by anyone (his referrer is
        // not set), and he's block.timestamp generated his own ID, he won't
        // be able to register as a referree of someone else 
        // from block.timestamp on.
        // This is done to prevent circular dependency in referrals.
        // Do it by setting a referrer to ROOT_REFERRER address,
        // which is an invalid address (address(1)).
        if( holderData[ holder ].referrer == address( 0 ) )
            holderData[ holder ].referrer = ROOT_REFERRER;

        // Create a new referrer with this ID.
        referrers[ refID ] = holder;
        
        return refID;
    }


    /**
     *  Register a referral for a token holder, using a valid
     *  referral ID got from a referrer.
     *  This function is called by a referree, who obtained a
     *  valid referral ID from some referrer, who previously
     *  generated it using generateReferralID().
     *
     *  You can only register a referral once!
     *  When you do so, you get bonus referral points!
     */
    function registerReferral(
            address holder,
            int16 referralRegisteringBonus,
            uint256 referralID )
                                                            public
                                                            lotteryOnly
    returns( address _referrerAddress )
    {
        // Check if this holder has some tokens, and if he hasn't
        // registered a referral yet.
        require( holderData[ holder ].tokenBalance != 0/*,
                 "holder doesn't have any lottery tokens!" */);

        require( holderData[ holder ].referrer == address( 0 )/*,
                 "holder already has registered a referral!" */);

        // Create a local memory copy of minMaxReferralScores.
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        // Get the referrer's address from his ID, and specify
        // it as a referrer of holder.
        holderData[ holder ].referrer = referrers[ referralID ];

        // Bonus points are added to this holder's score for
        // registering a referral!
        holderData[ holder ].bonusScore = referralRegisteringBonus;

        // Increment number of referrees for every parent referrer,
        // by traversing a referral tree child->parent way.
        address referrerAddr = holderData[ holder ].referrer;

        // Set the return value.
        _referrerAddress = referrerAddr;

        // Traverse a tree.
        while( referrerAddr != ROOT_REFERRER && 
               referrerAddr != address( 0 ) )
        {
            // Increment referree count for this referrrer.
            holderData[ referrerAddr ].referreeCount++;

            // Update the Referrer Scores of the referrer, adding this
            // referree's scores to it's current values.
            holderData[ referrerAddr ].referree_etherContributed +=
                holderData[ holder ].etherContributed;

            holderData[ referrerAddr ].referree_timeFactors +=
                holderData[ holder ].timeFactors;

            holderData[ referrerAddr ].referree_tokenBalance +=
                holderData[ holder ].tokenBalance;

            // Update MinMax according to this referrer's score.
            priv_updateMinMaxScores_referral(
                minMaxRefCpy,
                holderData[ referrerAddr ].referree_etherContributed,
                holderData[ referrerAddr ].referree_timeFactors,
                holderData[ referrerAddr ].referree_tokenBalance
            );

            // Move to the higher-level referrer.
            referrerAddr = holderData[ referrerAddr ].referrer;
        }

        // Update MinMax Referral Scores if needed.
        if( keccak256( abi.encode( minMaxRefCpy ) ) != 
            keccak256( abi.encode( minMaxReferralScores ) ) )
            minMaxReferralScores = minMaxRefCpy;

        return _referrerAddress;
    }


    /**
     *  Sets our random seed to some value.
     *  Should be called from Lottery, after obtaining random seed from
     *  the Randomness Provider.
     */
    function setRandomSeed( uint _seed )
                                                    external
                                                    lotteryOnly
    {
        randomSeed = uint64( _seed );
    }


    /**
     *  Initialization function.
     *  Here, we bind our contract to the Lottery contract that 
     *  this Storage belongs to.
     *  The parent lottery must call this function - hence, we set
     *  "lottery" to msg.sender.
     *
     *  When this function is called, our contract must be not yet
     *  initialized - "lottery" address must be Zero!
     *
     *  Here, we also set our Winner Algorithm config, which is a
     *  subset of LotteryConfig, fitting into 1 storage slot.
     */
    function initialize(
            WinnerAlgorithmConfig memory _wcfg )
                                                        public
    {
        require( address( lottery ) == address( 0 )/*,
                 "Storage is already initialized!" */);

        // Set the Lottery address (msg.sender can't be zero),
        // and thus, set our contract to initialized!
        lottery = msg.sender;

        // Set the Winner-Algo-Config.
        algConfig = _wcfg;

        // NOT-NEEDED: Set initial min-max scores: min is INT_MAX.
        /*minMaxScores.holderScore_etherContributed_min = int80( 2 ** 78 );
        minMaxScores.holderScore_timeFactors_min    = int80( 2 ** 78 );
        minMaxScores.holderScore_tokenBalance_min   = int80( 2 ** 78 );
        */
    }


    // ==================== Views ==================== //


    // Returns the current random seed.
    // If the seed hasn't been set yet (or set to 0), returns 0.
    //
    function getRandomSeed()
                                                    external view
    returns( uint )
    {
        return randomSeed;
    }


    // Check if Winner Selection Algorithm has beed executed.
    //
    function minedSelection_algorithmAlreadyExecuted()
                                                        external view
    returns( bool )
    {
        return algorithmCompleted;
    }

    /**
     *  After lottery has completed, this function returns if "addr"
     *  is one of lottery winners, and the position in winner rankings.
     *  Function is used to obtain the ranking position before
     *  calling claimWinnerPrize() on Lottery.
     *
     *  This function should be called off-chain, and then using the
     *  retrieved data, one can call claimWinnerPrize().
     */
    function minedSelection_getWinnerStatus(
            address addr )
                                                        public view
    returns( bool isWinner, 
             uint32 rankingPosition )
    {
        // Loop through the whole winner indexes array, trying to
        // find if "addr" is one of the winner addresses.
        for( uint16 i = 0; i < numberOfWinners; i++ )
        {
            // Check if holder on this winner ranking's index position
            // is addr, if so, good!
            uint pos = sortedWinnerIndexes[ i / 16 ].indexes[ i % 16 ];

            if( holders[ pos ] == addr )
            {
                return ( true, i );
            }
        }

        // The "addr" is not a winner.
        return ( false, 0 );
    }

    /**
     *  Checks if address is on specified winner ranking position.
     *  Used in Lottery, to check if msg.sender is really the 
     *  winner #rankingPosition, as he claims to be.
     */
    function minedSelection_isAddressOnWinnerPosition( 
            address addr,
            uint32  rankingPosition )
                                                    external view
    returns( bool )
    {
        if( rankingPosition >= numberOfWinners )
            return false;

        // Just check if address at "holders" array 
        // index "sortedWinnerIndexes[ position ]" is really the "addr".
        uint pos = sortedWinnerIndexes[ rankingPosition / 16 ]
                    .indexes[ rankingPosition % 16 ];

        return ( holders[ pos ] == addr );
    }


    /**
     *  Returns an array of all winner addresses, sorted by their
     *  ranking position (winner #1 first, #2 second, etc.).
     */
    function minedSelection_getAllWinners()
                                                    external view
    returns( address[] memory )
    {
        address[] memory winners = new address[] ( numberOfWinners );

        for( uint i = 0; i < numberOfWinners; i++ )
        {
            uint pos = sortedWinnerIndexes[ i / 16 ].indexes[ i % 16 ];
            winners[ i ] = holders[ pos ];
        }

        return winners;
    }


    /**
     *  Compute the Lottery Active Stage Score of a token holder.
     *
     *  This function computes the Active Stage (pre-randomization)
     *  player score, and should generally be used to compute player
     *  intermediate scores - while lottery is still active or on
     *  finishing stage, before random random seed is obtained.
     */
    function getPlayerActiveStageScore( address holderAddr )
                                                            external view
    returns( uint playerScore )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Check if holderAddr is a holder at all!
        if( holders[ holderIndexes[ holderAddr ] ] != holderAddr )
            return 0;

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );

        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        priv_fixMinMaxIfEqual( minMaxCpy, minMaxRefCpy );

        // Now, add bonus score, and compute total player's score:
        // Bonus part, individual score part, and referree score part.
        int totalPlayerScore = 
                holderData[ holderAddr ].bonusScore
                +
                computeHolderIndividualScores(
                    cfg, minMaxCpy, holderData[ holderAddr ] )
                +
                computeReferreeScoresForHolder( 
                    individualToReferralRatio, cfg, 
                    minMaxRefCpy, holderData[ holderAddr ] );


        // Check if total player score <= 0. If so, make it equal
        // to 1, because otherwise randomization won't be possible.
        if( totalPlayerScore <= 0 )
            totalPlayerScore = 1;

        // Now, check if it's not more than max! If so, lowerify.
        // This could have happen'd because of bonus.
        if( totalPlayerScore > maxAvailablePlayerScore )
            totalPlayerScore = maxAvailablePlayerScore;

        // Return the score!
        return uint( totalPlayerScore );
    }



    /**
     *  Internal sub-procedure of the function below, used to obtain
     *  a final, randomized score of a Single Holder.
     */
    function priv_getSingleHolderScore(
            address hold3r,
            int individualToReferralRatio,
            int maxAvailablePlayerScore,
            int SCORE_RAND_FACT,
            WinnerAlgorithmConfig memory cfg,
            MinMaxHolderScores memory minMaxCpy,
            MinMaxReferralScores memory minMaxRefCpy )
                                                        internal view
    returns( uint endScore )
    {
        // Fetch the needed holder data to in-memory hdata variable,
        // to save gas on score part computing functions.
        HolderData memory hdata;

        // Slot 1:
        hdata.etherContributed =
            holderData[ hold3r ].etherContributed;
        hdata.timeFactors =
            holderData[ hold3r ].timeFactors;
        hdata.tokenBalance =
            holderData[ hold3r ].tokenBalance;
        hdata.referreeCount =
            holderData[ hold3r ].referreeCount;

        // Slot 2:
        hdata.referree_etherContributed =
            holderData[ hold3r ].referree_etherContributed;
        hdata.referree_timeFactors =
            holderData[ hold3r ].referree_timeFactors;
        hdata.referree_tokenBalance =
            holderData[ hold3r ].referree_tokenBalance;
        hdata.bonusScore =
            holderData[ hold3r ].bonusScore;


        // Now, add bonus score, and compute total player's score:
        // Bonus part, individual score part, and referree score part.
        int totalPlayerScore = 
                hdata.bonusScore
                +
                computeHolderIndividualScores(
                    cfg, minMaxCpy, hdata )
                +
                computeReferreeScoresForHolder( 
                    individualToReferralRatio, cfg, 
                    minMaxRefCpy, hdata );


        // Check if total player score <= 0. If so, make it equal
        // to 1, because otherwise randomization won't be possible.
        if( totalPlayerScore <= 0 )
            totalPlayerScore = 1;

        // Now, check if it's not more than max! If so, lowerify.
        // This could have happen'd because of bonus.
        if( totalPlayerScore > maxAvailablePlayerScore )
            totalPlayerScore = maxAvailablePlayerScore;


        // Multiply the score by the Random Modulo Adjustment
        // Factor, to get fairer ratio of random-to-determined data.
        totalPlayerScore =  ( totalPlayerScore * SCORE_RAND_FACT ) /
                            ( PRECISION );

        // Score is computed!
        // Now, randomize it, and add to Final Scores Array.
        // We use keccak to generate a random number from random seed,
        // using holder's address as a nonce.

        uint modulizedRandomNumber = uint(
            keccak256( abi.encodePacked( randomSeed, hold3r ) )
        ) % RANDOM_MODULO;

        // Add the random number, to introduce the random factor.
        // Ratio of (current) totalPlayerScore to modulizedRandomNumber
        // is the same as ratio of randRatio_scorePart to 
        // randRatio_randPart.

        return uint( totalPlayerScore ) + modulizedRandomNumber;
    }


    /**
     *  Winner Self-Validation algo-type main function.
     *  Here, we compute scores for all lottery holders iteratively
     *  in O(n) time, and thus get the winner ranking position of
     *  the holder in question.
     *
     *  This function performs essentialy the same steps as the
     *  Mined-variant (executeWinnerSelectionAlgorithm), but doesn't
     *  write anything to blockchain.
     *
     *  @param holderAddr - address of a holder whose rank we want to find.
     */
    function winnerSelfValidation_getWinnerStatus(
            address holderAddr )
                                                        internal view
    returns( bool isWinner, uint rankingPosition )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is WinnerSelfValidation!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.WinnerSelfValidation)/*,
                 "Algorithm cannot be performed on current Algo-Type!" */);

        // Check if holderAddr is a holder at all!
        require( holders[ holderIndexes[ holderAddr ] ] == holderAddr/*,
                 "holderAddr is not a lottery token holder!" */);

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we block.timestamp have to do, is loop through holder array, and
        // compute randomized final scores for every holder.

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5/*, "scorePart" */== 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        priv_fixMinMaxIfEqual( minMaxCpy, minMaxRefCpy );

        // How many holders had higher scores than "holderAddr".
        // Used to obtain the final winner rank of "holderAddr".
        uint numOfHoldersHigherThan = 0;

        // The final (randomized) score of "holderAddr".
        uint holderAddrsFinalScore = priv_getSingleHolderScore(
            holderAddr,
            individualToReferralRatio,
            maxAvailablePlayerScore,
            SCORE_RAND_FACT,
            cfg, minMaxCpy, minMaxRefCpy );

        // Index of holderAddr.
        uint holderAddrIndex = holderIndexes[ holderAddr ];


        // Loop through all the allowed holders.
        for( uint i = 0; 
             i < ( holders.length < SELFVALIDATION_MAX_NUMBER_OF_HOLDERS ? 
                   holders.length : SELFVALIDATION_MAX_NUMBER_OF_HOLDERS );
             i++ )
        {
            // Skip the holderAddr's index.
            if( i == holderAddrIndex )
                continue;

            // Compute the score using helper function.
            uint endScore = priv_getSingleHolderScore(
                holders[ i ],
                individualToReferralRatio,
                maxAvailablePlayerScore,
                SCORE_RAND_FACT,
                cfg, minMaxCpy, minMaxRefCpy );

            // Check if score is higher than HolderAddr's, and if so, check.
            if( endScore > holderAddrsFinalScore )
                numOfHoldersHigherThan++;
        }

        // All scores are checked!
        // Now, we can obtain holderAddr's winner rank based on how
        // many scores were above holderAddr's score!

        isWinner = ( numOfHoldersHigherThan < cfg.winnerCount ); 
        rankingPosition = numOfHoldersHigherThan;
    }



    /**
     *  Rolled-Randomness algo-type main function.
     *  Here, we only compute the score of the holder in question,
     *  and compare it to maximum-available final score, divided
     *  by no-of-winners.
     *
     *  @param holderAddr - address of a holder whose rank we want to find.
     */
    function rolledRandomness_getWinnerStatus(
            address holderAddr )
                                                        internal view
    returns( bool isWinner, uint rankingPosition )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is RolledRandomness!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.RolledRandomness)/*,
                 "Algorithm cannot be performed on current Algo-Type!" */);

        // Check if holderAddr is a holder at all!
        require( holders[ holderIndexes[ holderAddr ] ] == holderAddr/*,
                 "holderAddr is not a lottery token holder!" */);

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we block.timestamp have to do, is loop through holder array, and
        // compute randomized final scores for every holder.

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5, "scorePart" == 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;
        MinMaxReferralScores memory minMaxRefCpy = minMaxReferralScores;

        priv_fixMinMaxIfEqual( minMaxCpy, minMaxRefCpy );

        // The final (randomized) score of "holderAddr".
        uint holderAddrsFinalScore = priv_getSingleHolderScore(
            holderAddr,
            individualToReferralRatio,
            maxAvailablePlayerScore,
            SCORE_RAND_FACT,
            cfg, minMaxCpy, minMaxRefCpy );

        // Now, compute the Max-Final-Random Score, divide it
        // by the Holder Count, and get the ranking by placing this
        // holder's score in it's corresponding part.
        //
        // In this approach, we assume linear randomness distribution.
        // In practice, distribution might be a bit different, but this
        // approach is the most efficient.
        //
        // Max-Final-Score (randomized) is the highest available score
        // that can be achieved, and is made by adding together the
        // maximum availabe Player Score Part and maximum available
        // Random Part (equals RANDOM_MODULO).
        // These parts have a ratio equal to config-specified
        // randRatio_scorePart to randRatio_randPart.
        //
        // So, if player's active stage's score is low (1), but rand-part
        // in ratio is huge, then the score is mostly random, so 
        // maxFinalScore is close to the RANDOM_MODULO - maximum random
        // value that can be rolled.
        //
        // If, however, we use 1:1 playerScore-to-Random Ratio, then
        // playerScore and RandomScore make up equal parts of end score,
        // so the maxFinalScore is actually two times larger than
        // RANDOM_MODULO, so player needs to score more
        // player-points to get larger prizes.
        //
        // In default configuration, playerScore-to-random ratio is 1:3,
        // so there's a good randomness factor, so even the low-scoring
        // players can reasonably hope to get larger prizes, but
        // the higher is player's active stage score, the more
        // chances of scoring a high final score a player gets, with
        // the higher-end of player scores basically guaranteeing
        // themselves a specific prize amount, if winnerCount is
        // big enough to overlap.

        int maxRandomPart      = int( RANDOM_MODULO - 1 );
        int maxPlayerScorePart = ( SCORE_RAND_FACT * maxAvailablePlayerScore )
                                 / PRECISION;

        uint maxFinalScore = uint( maxRandomPart + maxPlayerScorePart );

        // Compute the amount that single-holder's virtual part
        // might take up in the max-final score.
        uint singleHolderPart = maxFinalScore / holders.length;

        // Now, compute how many single-holder-parts are there in
        // this holder's score.
        uint holderAddrScorePartCount = holderAddrsFinalScore /
                                        singleHolderPart;

        // The ranking is that number, minus holders length.
        // If very high score is scored, default to position 0 (highest).
        rankingPosition = (
            holderAddrScorePartCount < holders.length ?
            holders.length - holderAddrScorePartCount : 0
        );

        isWinner = ( rankingPosition < cfg.winnerCount );
    }


    /**
     *  Genericized, algorithm type-dependent getWinnerStatus function.
     */
    function getWinnerStatus(
            address addr )
                                                        external view
    returns( bool isWinner, uint32 rankingPosition )
    {
        bool _isW;
        uint _rp;

        if( algConfig.endingAlgoType == 
            uint8(Lottery.EndingAlgoType.RolledRandomness) )
        {
            (_isW, _rp) = rolledRandomness_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }

        if( algConfig.endingAlgoType ==
            uint8(Lottery.EndingAlgoType.WinnerSelfValidation) )
        {
            (_isW, _rp) = winnerSelfValidation_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }

        if( algConfig.endingAlgoType ==
            uint8(Lottery.EndingAlgoType.MinedWinnerSelection) )
        {
            (_isW, _rp) = minedSelection_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }
    }

}

// 
// <provableAPI>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016-2019 Oraclize LTD
Copyright (c) 2019-2020 Provable Things Limited
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
// Incompatible compiler version - please select a compiler within the stated pragma range, or use a different version of the provableAPI!
// Dummy contract only used to emit to end-user they are using wrong solc
abstract contract solcChecker {
/* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */ function f(bytes calldata x) virtual external;
}

interface ProvableI {

    function cbAddress() external returns (address _cbAddress);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string calldata _datasource) external returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string calldata _datasource, uint _gasLimit)  external returns (uint _dsprice);
    function queryN(uint _timestamp, string calldata _datasource, bytes calldata _argN) external payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils
MIT License
Copyright (c) 2018 SmartContract ChainLink, Ltd.
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
library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/*
End solidity-cborutils
*/
contract usingProvable {

    using CBOR for Buffer.buffer;

    ProvableI provable;
    OracleAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string provable_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) provable_randomDS_args;
    mapping(bytes32 => bool) provable_randomDS_sessionKeysHashVerified;

    modifier provableAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            provable_setNetwork(networkID_auto);
        }
        if (address(provable) != OAR.getAddress()) {
            provable = ProvableI(OAR.getAddress());
        }
        _;
    }

    modifier provable_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        require(proofVerified);
        _;
    }

    function provable_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID; // NOTE: Silence the warning and remain backwards compatible
      return provable_setNetwork();
    }

    function provable_setNetworkName(string memory _network_name) internal {
        provable_network_name = _network_name;
    }

    function provable_getNetworkName() internal view returns (string memory _networkName) {
        return provable_network_name;
    }

    function provable_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OracleAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            provable_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OracleAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            provable_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OracleAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            provable_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OracleAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            provable_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OracleAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            provable_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OracleAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OracleAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OracleAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }
    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    function __callback(bytes32 _myid, string memory _result) virtual public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) virtual public {
      _myid; _result; _proof;
      provable_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function provable_getPrice(string memory _datasource) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource);
    }

    function provable_getPrice(string memory _datasource, uint _gasLimit) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(0, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(_timestamp, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(_timestamp, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(0, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(0, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(_timestamp, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_setProof(byte _proofP) provableAPI internal {
        return provable.setProofType(_proofP);
    }


    function provable_cbAddress() provableAPI internal returns (address _callbackAddress) {
        return provable.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function provable_setCustomGasPrice(uint _gasPrice) provableAPI internal {
        return provable.setCustomGasPrice(_gasPrice);
    }

    function provable_randomDS_getSessionPubKeyHash() provableAPI internal returns (bytes32 _sessionKeyHash) {
        return provable.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function provable_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = provable_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number(), 1)), xor(coinbase(), timestamp())))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = provable_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        provable_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function provable_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        provable_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function provable_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function provable_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function provable_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (provable_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete provable_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = provable_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        /*assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize(), sub(msize(), fmem))
        }*/
    }
}

// </provableAPI>

// 
// Import Provable base API contract.
// ------------         TESTING ENVIRONMENT         ------------ //
// As Provable services are not available in private testnets,
// we need to simulate Provable offchain services behavior
// locally, by calling the TEST_executeRequest() function from
// local web3 Provable emulator.
/*abstract contract usingProvable
{
    // Ledger proof type constant.
    uint constant proofType_Ledger = 1;

    // Default gas price. TODO: don't use this, get from Provable.
    uint public TEST_DEFAULT_GAS_PRICE = 20 * (10 ** 9); // 20 GWei

    // Number of requests processed since the deployment.
    // Also used as an ID for next request.
    uint TEST_requestCount = 1;

    // TEST-ONLY Provable function stub-plementations.

    // Return Local Provable Emulator address (on our Ganache network).
    function provable_cbAddress()
                                                            internal pure
    returns( address )
    {
        return address( 0x3EA4e2F6922FCAd09C08413cB7E1E7B786030657 );
    }

    function provable_setProof( uint ) internal pure {}

    function provable_getPrice( 
            string memory datasource, uint gasLimit )
                                                            internal view
    returns( uint totalPrice )
    {
        return TEST_DEFAULT_GAS_PRICE * gasLimit;
    }

    function provable_query( 
            uint timeout, string memory datasource,
            string memory query, uint gasLimit )
                                                            internal
    returns( bytes32 queryId )
    {
        return bytes32( TEST_requestCount++ );
    }

    function provable_newRandomDSQuery( uint delay, 
                    uint numBytes, uint gasLimit )
                                                            internal
    returns( bytes32 queryId )
    {
        return bytes32( TEST_requestCount++ );
    }

    function provable_randomDS_proofVerify__returnCode(
                    bytes32 _queryId, string memory _result, 
                    bytes memory _proof )
                                                            internal pure
    returns( uint )
    {
        // Proof is always valid.
        return 0;
    }

    // Set custom gas price.
    function provable_setCustomGasPrice( uint _gasPrice )
                                                            internal
    {
        TEST_DEFAULT_GAS_PRICE = _gasPrice;
    }

    // Provable's default callback.
    function __callback(
            bytes32 _queryId,
            string memory _result,
            bytes memory _proof )
                                            public
                                            virtual ;
}*/
// ------------ [ END ] TESTING ENVIRONMENT [ END ] ------------ //
// Main UniLottery Pool Interface.
interface IMainUniLotteryPool {
    function isLotteryOngoing( address lotAddr ) 
        external view returns( bool );

    function scheduledCallback( uint256 requestID ) 
        external;

    function onLotteryCallbackPriceExceedingGivenFunds(
                address lottery, uint currentRequestPrice,
                uint poolGivenPastRequestPrice )
        external returns( bool );
}

// Lottery Interface.
interface ILottery {
    function finish_randomnessProviderCallback( 
            uint256 randomSeed, uint256 requestID ) external;
}

/**
 *  This is the Randomness Provider contract, which is being used
 *  by the UniLottery Lottery contract instances, and by the
 *  Main UniLottery Pool.
 *
 *  This is the wrapper contract over the Provable (Oraclize) oracle
 *  service, which is being used to obtain true random seeds, and
 *  to schedule function callbacks.
 *
 *  This contract is being used in these cases:
 *
 *  1. Lottery instance requests a random seed, to be used when choosing
 *      winners in the Winner Selection Algorithm, on the lottery's ending.
 *
 *  2. Main UniLottery Pool is using this contract as a scheduler, to
 *      schedule the next AutoLottery start on specific time interval.
 *
 *  This contract is using Provable services to accompish these goals,
 *  and that means that this contract must pay the gas costs and fees
 *  from it's own balance.
 *
 *  So, in order to use it, the Main Pool must transfer enough Ether
 *  to this contract's address, to cover all fees which Provable
 *  services will charge for request & callback execution.
 */
contract UniLotteryRandomnessProvider is usingProvable
{
    // =============== E-Vent Section =============== //

    // New Lottery Random Seed Request made.
    event LotteryRandomSeedRequested(
        uint id,
        address lotteryAddress,
        uint gasLimit,
        uint totalEtherGiven
    );

    // Random seed obtained, and callback successfully completed.
    event LotteryRandomSeedCallbackCompleted(
        uint id
    );

    // UniLottery Pool scheduled a call.
    event PoolCallbackScheduled(
        uint id,
        address poolAddress,
        uint timeout,
        uint gasLimit,
        uint totalEtherGiven
    );

    // Pool scheduled callback successfully completed.
    event PoolCallbackCompleted(
        uint id
    );

    // Ether transfered into fallback.
    event EtherTransfered(
        address sender,
        uint value
    );


    // =============== Structs & Enums =============== //

    // Enum - type of the request.
    enum RequestType {
        LOTTERY_RANDOM_SEED,
        POOL_SCHEDULED_CALLBACK
    }

    // Call Request Structure.
    struct CallRequestData
    {
        // -------- Slot -------- //

        // The ID of the request.
        uint256 requestID;

        // -------- Slot -------- //

        // Requester address. Can be pool, or an ongoing lottery.
        address requesterAddress;

        // The Type of request (Random Seed or Pool Scheduled Callback).
        RequestType reqType;
    }

    // Lottery request config - specifies gas limits that must
    // be used for that specific lottery's callback.
    // Must be set separately from CallRequest, because gas required
    // is specified and funds are transfered by The Pool, before starting
    // a lottery, and when that lottery ends, it just calls us, expecting
    // it's gas cost funds to be already sent to us.
    struct LotteryGasConfig
    {
        // -------- Slot -------- //

        // The total ether funds that the pool has transfered to
        // our contract for execution of this lottery's callback.
        uint160 etherFundsTransferedForGas;

        // The gas limit provided for that callback.
        uint64 gasLimit;
    }


    // =============== State Variables =============== //

    // -------- Slot -------- //

    // Mapping of all currently pending or on-process requests
    // from their Query IDs.
    mapping( uint256 => CallRequestData ) pendingRequests;

    // -------- Slot -------- //

    // A mapping of Pool-specified-before-their-start lottery addresses,
    // to their corresponding Gas Configs, which will be used for
    // their end callbacks.
    mapping( address => LotteryGasConfig ) lotteryGasConfigs;

    // -------- Slot -------- //

    // The Pool's address. We receive funds from it, and use it
    // to check whether the requests are coming from ongoing lotteries.
    address payable poolAddress;


    // ============ Private/Internal Functions ============ //

    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress/*,
                 "Function can only be called by the Main Pool!" */);
        _;
    }

    // Ongoing Lottery Only modifier.
    // Data must be fetch'd from the Pool.
    modifier ongoingLotteryOnly
    {
        require( IMainUniLotteryPool( poolAddress )
                 .isLotteryOngoing( msg.sender )/*,
                 "Function can be called only by ongoing lotteries!" */);
        _;
    }

    // ================= Public Functions ================= //

    /**
     *  Constructor.
     *  Here, we specify the Provable proof type, to use for
     *  Random Datasource queries.
     */
    constructor()
    {
        // Set the Provable proof type for Random Queries - Ledger.
        provable_setProof( proofType_Ledger );
    }

    /**
     *  Initialization function.
     *  Called by the Pool, on Pool's constructor, to initialize this
     *  randomness provider.
     */
    function initialize()       external
    {
        // Check if we were'nt initialized yet (pool address not set yet).
        require( poolAddress == address( 0 )/*,
                 "Contract is already initialized!" */);

        poolAddress = msg.sender;
    }


    /**
     *  The Payable Fallback function.
     *  This function is used by the Pool, to transfer the required
     *  funds to us, to be able to pay for Provable gas & fees.
     */
    receive ()    external payable
    {
        emit EtherTransfered( msg.sender, msg.value );
    }


    /**
     *  Get the total Ether price for a request to specific
     *  datasource with specific gas limit.
     *  It just calls the Provable's internal getPrice function.
     */
    // Random datasource.
    function getPriceForRandomnessCallback( uint gasLimit )
                                                                external
    returns( uint totalEtherPrice )
    {
        return provable_getPrice( "random", gasLimit );
    }

    // URL datasource (for callback scheduling).
    function getPriceForScheduledCallback( uint gasLimit )
                                                                external
    returns( uint totalEtherPrice )
    {
        return provable_getPrice( "URL", gasLimit );
    }


    /**
     *  Set the gas limit which should be used by the lottery deployed
     *  on address "lotteryAddr", when that lottery finishes and
     *  requests us to call it's ending callback with random seed
     *  provided.
     *  Also, specify the amount of Ether that the pool has transfered
     *  to us for the execution of this lottery's callback.
     */
    function setLotteryCallbackGas(
            address lotteryAddr,
            uint64 callbackGasLimit,
            uint160 totalEtherTransferedForThisOne )
                                                        external
                                                        poolOnly
    {
        LotteryGasConfig memory gasConfig;

        gasConfig.gasLimit = callbackGasLimit;
        gasConfig.etherFundsTransferedForGas = totalEtherTransferedForThisOne;

        // Set the mapping entry for this lottery address.
        lotteryGasConfigs[ lotteryAddr ] = gasConfig;
    }


    /**
     *  The Provable Callback, which will get called from Off-Chain
     *  Provable service, when it completes execution of our request,
     *  made before previously with provable_query variant.
     *
     *  Here, we can perform 2 different tasks, based on request type
     *  (we get the CallRequestData from the ID passed by Provable).
     *
     *  The different tasks are:
     *  1. Pass Random Seed to Lottery Ending Callback.
     *  2. Call a Pool's Scheduled Callback.
     */
    function __callback(
            bytes32 _queryId,
            string memory _result,
            bytes memory _proof )
                                            public
                                            override
    {
        // Check that the sender is Provable Services.
        require( msg.sender == provable_cbAddress() );

        // Get the Request Data storage pointer, and check if it's Set.
        CallRequestData storage reqData = 
            pendingRequests[ uint256( _queryId ) ];

        require( reqData.requestID != 0/*,
                 "Invalid Request Data structure (Response is Invalid)!" */);

        // Check the Request Type - if it's a lottery asking for a 
        // random seed, or a Pool asking to call it's scheduled callback.

        if( reqData.reqType == RequestType.LOTTERY_RANDOM_SEED )
        {
            // It's a lottery asking for a random seed.
            // Check if Proof is valid, using the Base Contract's built-in
            // checking functionality.
            require( provable_randomDS_proofVerify__returnCode(
                        _queryId, _result, _proof ) == 0/*,
                     "Random Datasource Proof Verification has FAILED!" */);
                
            // Get the Random Number by keccak'ing the random bytes passed.
            uint256 randomNumber = uint256( 
                    keccak256( abi.encodePacked( _result ) ) );

            // Pass this Random Number as a Seed to the requesting lottery!
            ILottery( reqData.requesterAddress )
                    .finish_randomnessProviderCallback( 
                            randomNumber, uint( _queryId ) );

            // Emit appropriate events.
            emit LotteryRandomSeedCallbackCompleted( uint( _queryId ) );
        }

        // It's a pool, asking to call it's callback, that it scheduled
        // to get called in some time before.
        else if( reqData.reqType == RequestType.POOL_SCHEDULED_CALLBACK )
        {
            IMainUniLotteryPool( poolAddress )
                    .scheduledCallback( uint( _queryId ) );

            // Emit appropriate events.
            emit PoolCallbackCompleted( uint( _queryId ) );
        }

        // We're finished! Remove the request data from the pending
        // requests mapping.
        delete pendingRequests[ uint256( _queryId ) ];
    }


    /**
     *  This is the function through which the Lottery requests a
     *  Random Seed for it's ending callback.
     *  The gas funds needed for that callback's execution were already
     *  transfered to us from The Pool, at the moment the Pool created
     *  and deployed that lottery.
     *  The gas specifications are set in the LotteryGasConfig of that
     *  specific lottery.
     *  TODO: Also set the custom gas price.
     */
    function requestRandomSeedForLotteryFinish()
                                                    external
                                                    ongoingLotteryOnly
    returns( uint256 requestId )
    {
        // Check if gas limit (amount of gas) for this lottery was set.
        require( lotteryGasConfigs[ msg.sender ].gasLimit != 0/*,
                 "Gas limit for this lottery was not set!" */);

        // Check if the currently estimated price for this request
        // is not higher than the one that the pool transfered funds for.
        uint transactionPrice = provable_getPrice( "random", 
                    lotteryGasConfigs[ msg.sender ].gasLimit );

        if( transactionPrice >
            lotteryGasConfigs[ msg.sender ].etherFundsTransferedForGas )
        {
            // If our balance is enough to execute the transaction, then
            // ask pool if it agrees that we execute this transaction
            // with higher price than pool has given funds to us for.
            if( address(this).balance >= transactionPrice )
            {
                bool response = IMainUniLotteryPool( poolAddress )
                .onLotteryCallbackPriceExceedingGivenFunds(
                    msg.sender, 
                    transactionPrice,
                    lotteryGasConfigs[msg.sender].etherFundsTransferedForGas
                );

                require( response/*, "Pool has denied the request!" */);
            }
            // If price absolutely exceeds our contract's balance:
            else {
                require( false/*, "Request price exceeds contract's balance!" */);
            }
        }

        // Set the Provable Query parameters.
        // Execute the query as soon as possible.
        uint256 QUERY_EXECUTION_DELAY = 0;

        // Set the gas amount to the previously specified gas limit.
        uint256 GAS_FOR_CALLBACK = lotteryGasConfigs[ msg.sender ].gasLimit;

        // Request 8 random bytes (that's enough randomness with keccak).
        uint256 NUM_RANDOM_BYTES_REQUESTED = 8;

        // Execute the Provable Query!
        uint256 queryId = uint256( provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        ) );

        // Populate & Add the pending requests mapping entry.
        CallRequestData memory requestData;

        requestData.requestID = queryId;
        requestData.reqType = RequestType.LOTTERY_RANDOM_SEED;
        requestData.requesterAddress = msg.sender;

        pendingRequests[ queryId ] = requestData;

        // Emit an event - lottery just requested a random seed.
        emit LotteryRandomSeedRequested( 
            queryId, msg.sender, 
            lotteryGasConfigs[ msg.sender ].gasLimit,
            lotteryGasConfigs[ msg.sender ].etherFundsTransferedForGas
        );

        // Remove the just-used Lottery Gas Configs mapping entry.
        delete lotteryGasConfigs[ msg.sender ];

        // Return the ID of the query.
        return queryId;
    }


    /**
     *  Schedule a call for the pool, using specified amount of gas,
     *  and executing after specified amount of time.
     *  Accomplished using an empty URL query, and setting execution
     *  delay to the specified timeout.
     *  On execution, __callback() calls the Pool's scheduledCallback()
     *  function.
     *
     *  @param timeout - how much time to delay the execution of callback.
     *  @param gasLimit - gas limit to use for the callback's execution.
     *  @param etherFundsTransferedForGas - how much Ether has the Pool
     *      transfered to our contract before calling this function,
     *      to be used only for this operation.
     */
    function schedulePoolCallback( 
                uint timeout, 
                uint gasLimit,
                uint etherFundsTransferedForGas )
                                                    external
                                                    poolOnly
    returns( uint256 requestId )
    {
        // Price exceeding transfered funds doesn't need to be checked
        // here, because pool transfers required funds just before
        // calling this function, so price can't change between transfer
        // and this function's call.

        // Execute the query on specified timeout, with a 
        // specified Gas Limit.
        uint queryId = uint( 
                provable_query( timeout, "URL", "", gasLimit ) 
        );

        // Populate & Add the pending requests mapping entry.
        CallRequestData memory requestData;

        requestData.requestID = queryId;
        requestData.reqType = RequestType.POOL_SCHEDULED_CALLBACK;
        requestData.requesterAddress = msg.sender;

        pendingRequests[ queryId ] = requestData;

        // Emit an event - lottery just requested a random seed.
        emit PoolCallbackScheduled( queryId, poolAddress, timeout, gasLimit,
                                    etherFundsTransferedForGas );

        // Return a query ID.
        return queryId;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Sends the specified amount of Ether back to the Pool.
     *  WARNING: Future Provable requests might fail due to insufficient
     *           funds! No checks are made to ensure sufficiency.
     */
    function sendFundsToPool( uint etherAmount )
                                                        external
                                                        poolOnly
    {
        poolAddress.transfer( etherAmount );
    }


    /**
     *  Set the gas price to be used for future Provable queries.
     *  Used to change the default gas in times of congested networks.
     */
    function setGasPrice( uint _gasPrice )
                                                        external
                                                        poolOnly
    {
        // Limit gas price to 600 GWei.
        require( _gasPrice <= 600 * (10 ** 9)/*,
                 "Specified gas price is higher than 600 GWei !" */);

        provable_setCustomGasPrice( _gasPrice );
    }

}

// 
/**
 *  This is a storage-stub contract of the Lottery Token, which contains
 *  only the state (storage) of a Lottery Token, and delegates all logic
 *  to the actual code implementation.
 *  This approach is very gas-efficient for deploying new lotteries.
 */
contract LotteryStub {
    // ============ ERC20 token contract's storage ============ //

    // ------- Slot ------- //

    // Balances of token holders.
    mapping (address => uint256) private _balances;

    // ------- Slot ------- //

    // Allowances of spenders for a specific token owner.
    mapping (address => mapping (address => uint256)) private _allowances;

    // ------- Slot ------- //

    // Total supply of the token.
    uint256 private _totalSupply;


    // ============== Lottery contract's storage ============== //

    // ------- Initial Slots ------- //

    // The config which is passed to constructor.
    Lottery.LotteryConfig internal cfg;

    // ------- Slot ------- //

    // The Lottery Storage contract, which stores all holder data,
    // such as scores, referral tree data, etc.
    LotteryStorage /*public*/ lotStorage;

    // ------- Slot ------- //

    // Pool address. Set on constructor from msg.sender.
    address payable /*public*/ poolAddress;

    // ------- Slot ------- //
    
    // Randomness Provider address.
    address /*public*/ randomnessProvider;

    // ------- Slot ------- //

    // Exchange address. In Uniswap mode, it's the Uniswap liquidity 
    // pair's address, where trades execute.
    address /*public*/ exchangeAddress;

    // Start date.
    uint32 /*public*/ startDate;

    // Completion (Mining Phase End) date.
    uint32 /*public*/ completionDate;
    
    // The date when Randomness Provider was called, requesting a
    // random seed for the lottery finish.
    // Also, when this variable becomes Non-Zero, it indicates that we're
    // on Ending Stage Part One: waiting for the random seed.
    uint32 finish_timeRandomSeedRequested;

    // ------- Slot ------- //

    // WETH address. Set by calling Router's getter, on constructor.
    address WETHaddress;

    // Is the WETH first or second token in our Uniswap Pair?
    bool uniswap_ethFirst;

    // If we are, or were before, on finishing stage, this is the
    // probability of lottery going to Ending Stage on this transaction.
    uint32 finishProbablity;
    
    // Re-Entrancy Lock (Mutex).
    // We protect for reentrancy in the Fund Transfer functions.
    bool reEntrancyMutexLocked;
    
    // On which stage we are currently.
    uint8 /*public*/ lotteryStage;
    
    // Indicator for whether the lottery fund gains have passed a 
    // minimum fund gain requirement.
    // After that time point (when this bool is set), the token sells
    // which could drop the fund value below the requirement, would
    // be denied.
    bool fundGainRequirementReached;
    
    // The current step of the Mining Stage.
    uint16 miningStep;

    // If we're currently on Special Transfer Mode - that is, we allow
    // direct transfers between parties even in NON-ACTIVE state.
    bool specialTransferModeEnabled;


    // ------- Slot ------- //
    
    // Per-Transaction Pseudo-Random hash value (transferHashValue).
    // This value is computed on every token transfer, by keccak'ing
    // the last (current) transferHashValue, msg.sender, block.timestamp, and 
    // transaction count.
    //
    // This is used on Finishing Stage, as a pseudo-random number,
    // which is used to check if we should end the lottery (move to
    // Ending Stage).
    uint256 transferHashValue;

    // ------- Slot ------- //

    // On lottery end, get & store the lottery total ETH return
    // (including initial funds), and profit amount.
    uint128 /*public*/ ending_totalReturn;
    uint128 /*public*/ ending_profitAmount;

    // ------- Slot ------- //

    // The mapping that contains TRUE for addresses that already claimed
    // their lottery winner prizes.
    // Used only in COMPLETION, on claimWinnerPrize(), to check if
    // msg.sender has already claimed his prize.
    mapping( address => bool ) /*public*/ prizeClaimersAddresses;



    // =================== OUR CONTRACT'S OWN STORAGE =================== //

    // The address of the delegate contract, containing actual logic.
    address payable public __delegateContract;


    // ===================          Functions         =================== //

    // Constructor.
    // Just set the delegate's address.
    function stub_construct( address payable _delegateAddr )
                                                                external
    {
        require( __delegateContract == address(0) );
        __delegateContract = _delegateAddr;
    }

    // Fallback payable function, which delegates any call to our
    // contract, into the delegate contract.
    fallback()
                external payable 
    {
        // DelegateCall the delegate code contract.
        ( bool success, bytes memory data ) =
            __delegateContract.delegatecall( msg.data );

        // Use inline assembly to be able to return value from the fallback.
        // (by default, returning a value from fallback is not possible,
        // but it's still possible to manually copy data to the
        // return buffer.
        assembly
        {
            // delegatecall returns 0 (false) on error.
            // Add 32 bytes to "data" pointer, because first slot (32 bytes)
            // contains the length, and we use return value's length
            // from returndatasize() opcode.
            switch success
                case 0  { revert( add( data, 32 ), returndatasize() ) }
                default { return( add( data, 32 ), returndatasize() ) }
        }
    }

    // Receive ether function.
    receive()   external payable
    { }

}

/**
 *  LotteryStorage contract's storage-stub.
 *  Uses delagate calls to execute actual code on this contract's behalf.
 */
contract LotteryStorageStub {
    // =============== LotteryStorage contract's storage ================ //

    // --------- Slot --------- //

    // The Lottery address that this storage belongs to.
    // Is set by the "initialize()", called by corresponding Lottery.
    address lottery;

    // The Random Seed, that was passed to us from Randomness Provider,
    // or generated alternatively.
    uint64 randomSeed;

    // The actual number of winners that there will be. Set after
    // completing the Winner Selection Algorithm.
    uint16 numberOfWinners;

    // Bool indicating if Winner Selection Algorithm has been executed.
    bool algorithmCompleted;


    // --------- Slot --------- //

    // Winner Algorithm config. Specified in Initialization().
    LotteryStorage.WinnerAlgorithmConfig algConfig;

    // --------- Slot --------- //

    // The Min-Max holder score storage.
    LotteryStorage.MinMaxHolderScores minMaxScores;

    // --------- Slot --------- //

    // Array of holders.
    address[] /*public*/ holders;

    // --------- Slot --------- //

    // Holder array indexes mapping, for O(1) array element access.
    mapping( address => uint ) holderIndexes;

    // --------- Slot --------- //

    // Mapping of holder data.
    mapping( address => LotteryStorage.HolderData ) /*public*/ holderData;

    // --------- Slot --------- //

    // Mapping of referral IDs to addresses of holders who generated
    // those IDs.
    mapping( uint256 => address ) referrers;

    // --------- Slot --------- //

    // The array of final-sorted winners (set after Winner Selection
    // Algorithm completes), that contains the winners' indexes
    // in the "holders" array, to save space.
    //
    // Notice that by using uint16, we can fit 16 items into one slot!
    // So, if there are 160 winners, we only take up 10 slots, so
    // only 20,000 * 10 = 200,000 gas gets consumed!
    //
    LotteryStorage.WinnerIndexStruct[] sortedWinnerIndexes;


    // =================== OUR CONTRACT'S OWN STORAGE =================== //

    // The address of the delegate contract, containing actual logic.
    address public __delegateContract;


    // ===================          Functions         =================== //


    // Constructor.
    // Just set the delegate's address.
    function stub_construct( address _delegateAddr )
                                                                external
    {
        require( __delegateContract == address(0) );
        __delegateContract = _delegateAddr;
    }


    // Fallback function, which delegates any call to our
    // contract, into the delegate contract.
    fallback()
                external
    {
        // DelegateCall the delegate code contract.
        ( bool success, bytes memory data ) =
            __delegateContract.delegatecall( msg.data );

        // Use inline assembly to be able to return value from the fallback.
        // (by default, returning a value from fallback is not possible,
        // but it's still possible to manually copy data to the
        // return buffer.
        assembly
        {
            // delegatecall returns 0 (false) on error.
            // Add 32 bytes to "data" pointer, because first slot (32 bytes)
            // contains the length, and we use return value's length
            // from returndatasize() opcode.
            switch success
                case 0  { revert( add( data, 32 ), returndatasize() ) }
                default { return( add( data, 32 ), returndatasize() ) }
        }
    }
}

// 
/**
 *  The Factory contract, used to deploy new Lottery Storage contracts.
 *  Every Lottery must have exactly one Storage, which is used by the
 *  main Lottery token contract, to store holder data, and on ending, to
 *  execute the winner selection and prize distribution -
 *  these operations are done in LotteryStorage contract functions.
 */
contract UniLotteryStorageFactory {
    // The Pool Address.
    address payable poolAddress;

    // The Delegate Logic contract, containing all code for
    // all LotteryStorage contracts to be deployed.
    address immutable public delegateContract;

    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress/*,
                 "Function can only be called by the Main Pool!" */);
        _;
    }

    // Constructor.
    // Deploy the Delegate Contract here.
    //
    constructor()
    {
        delegateContract = address( new LotteryStorage() );
    }

    // Initialization function.
    // Set the poolAddress as msg.sender, and lock it.
    function initialize()
                                                            external
    {
        require( poolAddress == address( 0 )/*,
                 "Initialization has already finished!" */);

        // Set the Pool's Address.
        poolAddress = msg.sender;
    }

    /**
     * Deploy a new Lottery Storage Stub, to be used by it's corresponding
     * Lottery Stub, which will be created later, passing this Storage
     * we create here.
     *  @return newStorage - the Lottery Storage Stub contract just deployed.
     */
    function createNewStorage()
                                                            public
                                                            poolOnly
    returns( address newStorage )
    {
        LotteryStorageStub stub = new LotteryStorageStub();
        stub.stub_construct( delegateContract );
        return address( stub );
    }
}

// 
/**
 *  Little contract to use in testing environments, to get the
 *  ABIEncoderV2-encoded js object representing LotteryConfig.
 */
contract UniLotteryConfigGenerator {
    function getConfig()
                                                    external pure
    returns( Lottery.LotteryConfig memory cfg )
    {
        cfg.initialFunds = 10 ether;
    }
}

/**
 *  This is the Lottery Factory contract, which is used as an intermediate
 *  for deploying new lotteries from the UniLottery main pool.
 *  
 *  This pattern was chosen to avoid the code bloat of the Main Pool
 *  contract - this way, the "new Lottery()" huge bloat statements would
 *  be executed in this Factory, not in the Main Pool.
 *  So, the Main Pool would stay in the 24 kB size limit.
 *
 *  The only drawback, is that 2 contracts would need to be manually
 *  deployed at the start - firstly, this Factory, and secondly, the
 *  Main Pool, passing this Factory instance's address to it's constructor.
 *
 *  The deployment sequence should go like this:
 *  1. Deploy UniLotteryLotteryFactory.
 *  2. Deploy MainUniLotteryPool, passing instance address from step (1)
 *      to it's constructor.
 *  3. [internal operation] MainUniLotteryPool's constructor calls
 *      the initialize() function of the Factory instance it got,
 *      and the Factory instance sets it's pool address and locks it
 *      with initializationFinished boolean.
 */
contract UniLotteryLotteryFactory {
    // Uniswap Router address on this network - passed to Lotteries on
    // construction.
    //ddress payable immutable uniRouterAddress;

    // Delegate Contract for the Lottery, containing all logic code
    // needed for deploying LotteryStubs.
    // Deployed only once, on construction.
    address payable immutable public delegateContract;

    // The Pool Address.
    address payable poolAddress;

    // The Lottery Storage Factory address, that the Lottery contracts use.
    UniLotteryStorageFactory lotteryStorageFactory;


    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress/*,
                 "Function can only be called by the Main Pool!" */);
        _;
    }

    // Constructor.
    // Set the Uniswap Address, and deploy&lock the Delegate Code contract.
    //
    constructor( /*address payable _uniRouter*/ )
    {
        //uniRouterAddress = _uniRouter;
        delegateContract = address( uint160( address( new Lottery() ) ) );
    }

    // Initialization function.
    // Set the poolAddress as msg.sender, and lock it.
    // Also, set the Lottery Storage Factory contract instance address.
    function initialize( address _storageFactoryAddress )
                                                            external
    {
        require( poolAddress == address( 0 )/*,
                 "Initialization has already finished!" */);

        // Set the Pool's Address.
        // Lock it. No more calls to this function will be executed.
        poolAddress = msg.sender;

        // Set the Storage Factory, and initialize it!
        lotteryStorageFactory = 
            UniLotteryStorageFactory( _storageFactoryAddress );

        lotteryStorageFactory.initialize();
    }

    /**
     * Deploy a new Lottery Stub from the specified config.
     *  @param config - Lottery Config to be used (passed by the pool).
     *  @return newLottery - the newly deployed lottery stub.
     */
    function createNewLottery( 
            Lottery.LotteryConfig memory config,
            address randomnessProvider )
                                                            public
                                                            poolOnly
    returns( address payable newLottery )
    {
        // Create new Lottery Storage, using storage factory.
        // Populate the stub, by calling the "construct" function.
        LotteryStub stub = new LotteryStub();
        stub.stub_construct( delegateContract );

        Lottery( address( stub ) ).construct(
                config, poolAddress, randomnessProvider,
                lotteryStorageFactory.createNewStorage() );

        return address( stub );
    }

}

// 
// Use OpenZeppelin ERC20 token implementation for Pool Token.
// Import the Core UniLottery Settings, where core global constants
// are defined.
// The Uniswap Lottery Token implementation, where all lottery player
// interactions happen.
// Randomness provider, using Provable oracle service inside.
// We instantiate this provider only once here, and later, every
// lottery can use the provider services.
// Use a Lottery Factory to create new lotteries, without using
// "new" statements to deploy lotteries in the Pool, because that
// pattern makes the Pool's code size exdeed the 24 kB limit.
/**
 *  UniLotteryPool version v0.1
 *
 *  This is the main UniLottery Pool DAO contract, which governs all 
 *  pool and lottery operations, and holds all poolholder funds.
 *  
 *  This contract uses ULPT tokens to track users share of the pool.
 *  Currently, this contract itself is an ULPT token - gas saving is
 *  a preference, given the current huge Ethereum gas fees, so better
 *  fit more inside a single contract.
 *
 *  This contract is responsible for launching new lotteries, 
 *  managing profits, and managing user fund contributions.
 *
 *  This is because the project is in early stage, and current version
 *  is by no means finalized. Some features will be implemented
 *  or decided not to be implemented later, after testing the concept
 *  with the initial version at first.
 *
 *  This version (v0.1) allows only basic pool functionality, targeted 
 *  mostly to the only-one-poolholder model, because most likely 
 *  only Owner is going to use this pool version.
 *
 *  =================================================
 *
 *  Who can transfer money to/from the pool?
 *
 *  There are 2 actors which could initiate money transfers:
 *  1. Pool shareholders - by providing/removing liquidity in
 *      exchange for ULPT.
 *  2. Lottery contracts - on start, pool provides them initial funds,
 *      and on finish, lottery returns initial funds + profits
 *      back to the pool.
 *
 *  -------------------------------------------------
 *
 *  In which functions the money transfers occur?
 *
 *  There are 4 functions which might transfer money to/from the pool:
 *
 *  1. [IN] The lotteryFinish() function. 
 *      Used by the finished lotteries to transfer initial funds 
 *      and profits back to the pool.
 *
 *  2. [IN] provideLiquidity() function. 
 *      Is called by users to provide ETH into the pool in exchange
 *      for ULPT pool share tokens - user become pool shareholders.
 *
 *  3. [OUT] removeLiquidity() function.
 *      Is called by users when they want to remove their liquidity
 *      share from the pool. ETH gets transfered from pool to 
 *      callers wallet, and corresponding ULPT get burned.
 *
 *  4. [OUT] launchLottery() function.
 *      This function deploys a new lottery contract, and transfers
 *      its initial funds from pool balance to the newly deployed 
 *      lottery contract.
 *      Note that lotteries can't finish with negative profits, so
 *      every lottery must return its initial profits back to the
 *      pool on finishing.
 */
contract UniLotteryPool is ERC20, CoreUniLotterySettings
{
    // =================== Structs & Enums =================== //

    /* Lottery running mode (Auto-Lottery, manual lottery).
     *
     * If Auto-Lottery feature is enabled, the new lotteries will start
     * automatically after the previous one finished, and will use
     * the default, agreed-upon config, which is set by voting.
     *
     * If Manual Lottery is enabled, the new lotteries are started
     * manually, by submitting and voting for a specific config.
     *
     * Both modes can have AVERAGE_CONFIG feature, when final lottery
     * config is not set by voting for one of several user-submitted 
     * configs, but final config is computed by averaging all the voted
     * configs, where each vote proposes a config.
     */
    enum LotteryRunMode {
        MANUAL,
        AUTO,
        MANUAL_AVERAGE_CONFIG,
        AUTO_AVERAGE_CONFIG
    }


    // ===================    Events    =================== //

    // Periodic stats event.
    event PoolStats(
        uint32 indexed lotteriesPerformed,
        uint indexed totalPoolFunds,
        uint indexed currentPoolBalance
    );

    // New poolholder joins and complete withdraws of a poolholder.
    event NewPoolholderJoin(
        address indexed poolholder,
        uint256 initialAmount
    );

    event PoolholderWithdraw(
        address indexed poolholder
    );

    // Current poolholder liquidity adds/removes.
    event AddedLiquidity(
        address indexed poolholder,
        uint256 indexed amount
    );

    event RemovedLiquidity(
        address indexed poolholder,
        uint256 indexed amount
    );

    
    // Lottery Run Mode change (for example, from Manual to Auto lottery).
    event LotteryRunModeChanged(
        LotteryRunMode previousMode,
        LotteryRunMode newMode
    );


    // Lottery configs proposed. In other words, it's a new lottery start 
    // initiation. If no config specified, then the default config for 
    // that lottery is used.
    event NewConfigProposed(
        address indexed initiator,
        Lottery.LotteryConfig cfg,
        uint configIndex
    );

    // Lottery started.
    event LotteryStarted(
        address indexed lottery,
        uint256 indexed fundsUsed,
        uint256 indexed poolPercentageUsed,
        Lottery.LotteryConfig config
    );

    // Lottery finished.
    event LotteryFinished(
        address indexed lottery,
        uint256 indexed totalReturn,
        uint256 indexed profitAmount
    );

    // Ether transfered into the fallback receive function.
    event EtherReceived(
        address indexed sender,
        uint256 indexed value
    );


    // ========= Constants ========= //

    // The Core Constants (OWNER_ADDRESS, Owner's max profit amount),
    // and also the percentage calculation-related constants,
    // are defined in the CoreUniLotterySettings contract, which this
    // contract inherits from.

    // ERC-20 token's public constants.
    string constant public name = "UniLottery Main Pool";
    string constant public symbol = "ULPT";
    uint256 constant public decimals = 18;


    // ========= State variables ========= //

    // --------- Slot --------- //

    // The debt to the Randomness Provider.
    // Incurred when we allow the Randomness Provider to execute
    // requests with higher price than we have given it funds for.
    // (of course, executed only when the Provider has enough balance
    // to execute it).
    // Paid back on next Randomness Provider request.
    uint80 randomnessProviderDebt;
    
    // Auto-Mode lottery parameters:
    uint32 public autoMode_nextLotteryDelay  = 1 days;
    uint16 public autoMode_maxNumberOfRuns   = 50;

    // When the last Auto-Mode lottery was started.
    uint32 public autoMode_lastLotteryStarted;
    
    // When the last Auto-Mode lottery has finished.
    // Used to compute the time until the next lottery.
    uint32 public autoMode_lastLotteryFinished;

    // Auto-Mode callback scheduled time.
    uint32 public autoMode_timeCallbackScheduled;

    // Iterations of current Auto-Lottery cycle.
    uint16 autoMode_currentCycleIterations = 0;

    // Is an Auto-Mode lottery currently ongoing?
    bool public autoMode_isLotteryCurrentlyOngoing = false;

    // Re-Entrancy Lock for Liquidity Provide/Remove functions.
    bool reEntrancyLock_Locked;


    // --------- Slot --------- //

    // The initial funds of all currently active lotteries.
    uint currentLotteryFunds;


    // --------- Slot --------- //

    // Most recently launched lottery.
    Lottery public mostRecentLottery;

    // Current lottery run-mode (Enum, so 1 byte).
    LotteryRunMode public lotteryRunMode = LotteryRunMode.MANUAL;

    // Last time when funds were manually sent to the Randomness Provider.
    uint32 lastTimeRandomFundsSend;


    // --------- Slot --------- //

    // The address of the Gas Oracle (our own service which calls our
    // gas price update function periodically).
    address gasOracleAddress;

    // --------- Slot --------- //

    // Stores all lotteries that have been performed 
    // (including currently ongoing ones ).
    Lottery[] public allLotteriesPerformed;

    // --------- Slot --------- //

    // Currently ongoing lotteries - a list, and a mapping.
    mapping( address => bool ) ongoingLotteries;

    // --------- Slot --------- //

    // Owner-approved addresses, which can call functions, marked with
    // modifier "ownerApprovedAddressOnly", on behalf of the Owner,
    // to initiate Owner-Only operations, such as setting next lottery
    // config, or moving specified part of Owner's liquidity pool share to
    // Owner's wallet address.
    // Note that this is equivalent of as if Owner had called the
    // removeLiquidity() function from OWNER_ADDRESS.
    //
    // These owner-approved addresses, able to call owner-only functions,
    // are used by Owner, to minimize risk of a hack in these ways:
    // - OWNER_ADDRESS wallet, which might hold significant ETH amounts,
    //   is used minimally, to have as little log-on risk in Metamask,
    //   as possible.
    // - The approved addresses can have very little Ether, so little
    //   risk of using them from Metamask.
    // - Periodic liquidity removes from the Pool can help to reduce
    //   losses, if Pool contract was hacked (which most likely
    //   wouldn't ever happen given our security measures, but 
    //   better be safe than sorry).
    //
    mapping( address => bool ) public ownerApprovedAddresses;

    // --------- Slot --------- //

    // The config to use for the next lottery that will be started.
    Lottery.LotteryConfig internal nextLotteryConfig;

    // --------- Slot --------- //

    // Randomness Provider address.
    UniLotteryRandomnessProvider immutable public randomnessProvider;

    // --------- Slot --------- //

    // The Lottery Factory that we're using to deploy NEW lotteries.
    UniLotteryLotteryFactory immutable public lotteryFactory;

    // --------- Slot --------- //

    // The Lottery Storage factory that we're using to deploy
    // new lottery storages. Used inside a Lottery Factory.
    address immutable public storageFactory;

    

    // ========= FUNCTIONS - METHODS ========= //

    // =========  Private Functions  ========= //


    // Owner-Only modifier (standard).
    modifier ownerOnly
    {
        require( msg.sender == OWNER_ADDRESS/*, "Function is Owner-Only!" */);
        _;
    }

    // Owner, or Owner-Approved address only.
    modifier ownerApprovedAddressOnly 
    {
        require( ownerApprovedAddresses[ msg.sender ]/*,
                 "Function can be called only by Owner-Approved addresses!"*/);
        _;
    }

    // Owner Approved addresses, and the Gas Oracle address.
    // Used when updating RandProv's gas price.
    modifier gasOracleAndOwnerApproved 
    {
        require( ownerApprovedAddresses[ msg.sender ] ||
                 msg.sender == gasOracleAddress/*,
                 "Function can only be called by Owner-Approved addrs, "
                 "and by the Gas Oracle!" */);
        _;
    }


    // Randomness Provider-Only modifier.
    modifier randomnessProviderOnly
    {
        require( msg.sender == address( randomnessProvider )/*,
                 "Function can be called only by the Randomness Provider!" */);
        _;
    }

    /**
     *  Modifier for checking if a caller is a currently ongoing
     *  lottery - that is, if msg.sender is one of addresses in
     *  ongoingLotteryList array, and present in ongoingLotteries.
     */
    modifier calledByOngoingLotteryOnly 
    {
        require( ongoingLotteries[ msg.sender ]/*,
                 "Function can be called only by ongoing lotteries!"*/);
        _;
    }


    /**
     *  Lock the function to protect from re-entrancy, using
     *  a Re-Entrancy Mutex Lock.
     */
    modifier mutexLOCKED
    {
        require( ! reEntrancyLock_Locked/*, "Re-Entrant Call Detected!" */);

        reEntrancyLock_Locked = true;
        _;
        reEntrancyLock_Locked = false;
    }



    // Emits a statistical event, summarizing current pool state.
    function emitPoolStats() 
                                                private 
    {
        (uint32 a, uint b, uint c) = getPoolStats();
        emit PoolStats( a, b, c );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Launch a new UniLottery Lottery, from specified Lottery Config.
     *  Perform all initialization procedures, including initial fund
     *  transfer, and random provider registration.
     *
     *  @return newlyLaunchedLottery - the Contract instance (address) of 
     *      the newly deployed and initialized lottery.
     */ 
    function launchLottery( 
            Lottery.LotteryConfig memory cfg ) 
                                                        private
                                                        mutexLOCKED
    returns( Lottery newlyLaunchedLottery )
    {
        // Check config fund requirement.
        // Lottery will need funds equal to: 
        // initial funds + gas required for randomness prov. callback.

        // Now, get the price of the random datasource query with
        // the above amount of callback gas, from randomness provider.
        uint callbackPrice = randomnessProvider
            .getPriceForRandomnessCallback( LOTTERY_RAND_CALLBACK_GAS );

        // Also take into account the debt that we might owe to the
        // Randomness Provider, if it previously executed requests
        // with price being higher than we have gave it funds for.
        //
        // This situation can occur because we transfer lottery callback
        // price funds before lottery starts, and when that lottery
        // finishes (which can happen after several weeks), then
        // the gas price might be higher than we have estimated
        // and given funds for on lottery start.
        // In this scenario, Randomness Provider would execute the 
        // request nonetheless, provided that it has enough funds in 
        // it's balance, to execute it.
        //
        // However, the Randomness Provider would notify us, that a
        // debt of X ethers have been incurred, so we would have
        // to transfer that debt's amount with next request's funds
        // to Randomness Provider - and that's precisely what we
        // are doing here, block.timestamp:

        // Compute total cost of this lottery - initial funds,
        // Randomness Provider callback cost, and debt from previous
        // callback executions.

        uint totalCost = cfg.initialFunds + callbackPrice +
                         randomnessProviderDebt;

        // Check if our balance is enough to pay the cost.
        // TODO: Implement more robust checks on minimum and maximum 
        //       allowed fund restrictions.
        require( totalCost <= address( this ).balance/*,
                 "Insufficient funds for this lottery start!" */);

        // Deploy the new lottery contract using Factory.
        Lottery lottery = Lottery( lotteryFactory.createNewLottery( 
                cfg, address( randomnessProvider ) ) );

        // Check if the lottery's pool address and owner address
        // are valid (same as ours).
        require( lottery.poolAddress() == address( this ) &&
                 lottery.OWNER_ADDRESS() == OWNER_ADDRESS/*,
                 "Lottery's pool or owner addresses are invalid!" */);

        // Transfer the Gas required for lottery end callback, and the
        // debt (if some exists), into the Randomness Provider.
        address( randomnessProvider ).transfer( 
                    callbackPrice + randomnessProviderDebt );

        // Clear the debt (if some existed) - it has been paid.
        randomnessProviderDebt = 0;

        // Notify the Randomness Provider about how much gas will be 
        // needed to run this lottery's ending callback, and how much
        // funds we have given for it.
        randomnessProvider.setLotteryCallbackGas( 
                address( lottery ), 
                LOTTERY_RAND_CALLBACK_GAS,
                uint160( callbackPrice )
        );

        // Initialize the lottery - start the active lottery stage!
        // Send initial funds to the lottery too.
        lottery.initialize{ value: cfg.initialFunds }();


        // Lottery was successfully initialized!
        // Now, add it to tracking arrays, and emit events.
        ongoingLotteries[ address(lottery) ] = true;
        allLotteriesPerformed.push( lottery );

        // Set is as the Most Recently Launched Lottery.
        mostRecentLottery = lottery;

        // Update current lottery funds.
        currentLotteryFunds += cfg.initialFunds;

        // Emit the apppproppppriate evenc.
        emit LotteryStarted( 
            address( lottery ), 
            cfg.initialFunds,
            ( (_100PERCENT) * totalCost ) / totalPoolFunds(),
            cfg
        );

        // Return the newly-successfully-started lottery.
        return lottery;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  When AUTO run-mode is set, this function schedules a new lottery 
     *  to be started after the last Auto-Mode lottery has ended, after
     *  a specific time delay (by default, 1 day delay).
     *
     *  Also, it's used to bootstrap the Auto-Mode loop - because
     *  it schedules a callback to get called.
     *
     *  This function is called in 2 occasions:
     *
     *  1. When lotteryFinish() detects an AUTO run-mode, and so, a
     *      new Auto-Mode iteration needs to be performed.
     *
     *  2. When external actor bootstraps a new Auto-Mode cycle.
     *
     *  Notice, that this function doesn't use require()'s - that's
     *  because it's getting called from lotteryFinish() too, and
     *  we don't want that function to fail just because some user
     *  set run mode to other value than AUTO during the time before.
     *  The only require() is when we check for re-entrancy.
     *
     *  How Auto-Mode works?
     *  Everything is based on the Randomness Provider scheduled callback
     *  functionality, which is in turn based on Provable services.
     *  Basically, here we just schedule a scheduledCallback() to 
     *  get called after a specified amount of time, and the
     *  scheduledCallback() performs the new lottery launch from the
     *  current next-lottery config.
     *
     *  * What's payable?
     *    - We send funds to Randomness Provider, required to launch
     *      our callback later.
     */
    function scheduleAutoModeCallback()
                                            private
                                            mutexLOCKED
    returns( bool success )
    {
        // Firstly, check if mode is AUTO.
        if( lotteryRunMode != LotteryRunMode.AUTO ) {
            autoMode_currentCycleIterations = 0;
            return false;
        }

        // Start a scheduled callback using the Randomness Provider
        // service! But first, we gotta transfer the needed funds
        // to the Provider.

        // Get the price.
        uint callbackPrice = randomnessProvider
            .getPriceForScheduledCallback( AUTO_MODE_SCHEDULED_CALLBACK_GAS );

        // Add the debt, if exists.
        uint totalPrice = callbackPrice + randomnessProviderDebt;
        
        if( totalPrice > address(this).balance ) {
            return false;
        }

        // Send the required funds to the Rand.Provider.
        // Use the send() function, because it returns false upon failure,
        // and doesn't revert this transaction.
        if( ! address( randomnessProvider ).send( totalPrice ) ) {
            return false;
        }

        // Now, we've just paid the debt (if some existed).
        randomnessProviderDebt = 0;

        // Now, call the scheduling function of the Randomness Provider!
        randomnessProvider.schedulePoolCallback(
            autoMode_nextLotteryDelay,
            AUTO_MODE_SCHEDULED_CALLBACK_GAS,
            callbackPrice
        );

        // Set the time the callback was scheduled.
        autoMode_timeCallbackScheduled = uint32( block.timestamp );

        return true;
    }


    // ========= Public Functions ========= //

    /**
     *  Constructor.
     *  - Here, we deploy the ULPT token contract.
     *  - Also, we deploy the Provable-powered Randomness Provider
     *    contract, which lotteries will use to get random seed.
     *  - We assign our Lottery Factory contract address to the passed
     *    parameter - the Lottery Factory contract which was deployed
     *    before, but not yet initialize()'d.
     *
     *  Notice, that the msg.sender (the address who deployed the pool
     *  contract), doesn't play any special role in this nor any related
     *  contracts.
     */
    constructor( address _lotteryFactoryAddr,
                 address _storageFactoryAddr,
                 address payable _randProvAddr ) 
    {
        // Initialize the randomness provider.
        UniLotteryRandomnessProvider( _randProvAddr ).initialize();
        randomnessProvider = UniLotteryRandomnessProvider( _randProvAddr );

        // Set the Lottery Factory contract address, and initialize it!
        UniLotteryLotteryFactory _lotteryFactory = 
            UniLotteryLotteryFactory( _lotteryFactoryAddr );

        // Initialize the lottery factory, setting it to use the
        // specified Storage Factory.
        // After this point, factory states become immutable.
        _lotteryFactory.initialize( _storageFactoryAddr );

        // Assign the Storage Factory address.
        // Set the immutable variables to their temporary placeholders.
        storageFactory = _storageFactoryAddr;
        lotteryFactory = _lotteryFactory;

        // Set the first Owner-Approved address as the OWNER_ADDRESS
        // itself.
        ownerApprovedAddresses[ OWNER_ADDRESS ] = true;
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  The "Receive Ether" function.
     *  Used to receive Ether from Lotteries, and from the
     *  Randomness Provider, when retrieving funds.
     */
    receive()   external payable
    {
        emit EtherReceived( msg.sender, msg.value );
    }



    /**
     *  Get total funds of the pool -- the pool balance, and all the
     *  initial funds of every currently-ongoing lottery.
     */
    function totalPoolFunds()                   public view
    returns( uint256 ) 
    {
        // Get All Active Lotteries initial funds.
        /*uint lotteryBalances = 0;
        for( uint i = 0; i < ongoingLotteryList.length; i++ ) {
            lotteryBalances += 
                ongoingLotteryList[ i ].getActiveInitialFunds();
        }*/

        return address(this).balance + currentLotteryFunds;
    }

    /**
     *  Get current pool stats - number of poolholders, 
     *  number of voters, etc.
     */
    function getPoolStats()
                                                public view
    returns( 
        uint32 _numberOfLotteriesPerformed,
        uint _totalPoolFunds,
        uint _currentPoolBalance )
    {
        _numberOfLotteriesPerformed = uint32( allLotteriesPerformed.length );
        _totalPoolFunds     = totalPoolFunds();
        _currentPoolBalance = address( this ).balance;
    }



    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Provide liquidity into the pool, and become a pool shareholder.
     *  - Function accepts Ether payments (No minimum deposit),
     *    and mints a proportionate number of ULPT tokens for the
     *    sender.
     */
    function provideLiquidity() 
                                    external 
                                    payable 
                                    ownerApprovedAddressOnly
                                    mutexLOCKED
    {
        // Check for minimum deposit.
        //require( msg.value > MIN_DEPOSIT/*, "Deposit amount too low!" */);

        // Compute the pool share that the user should obtain with
        // the amount he paid in this message -- that is, compute
        // percentage of the total pool funds (with new liquidity
        // added), relative to the ether transferred in this msg.

        // TotalFunds can't be zero, because currently transfered 
        // msg.value is already added to totalFunds.
        //
        // Also/*, "percentage" */can't exceed 100%, because condition
        // "totalPoolFunds() >= msg.value" is ALWAYS true, because
        // msg.value is already added to totalPoolFunds before 
        // execution of this function's body - transfers to 
        // "payable" functions are executed before the function's
        // body executes (Solidity docs).
        //
        uint percentage =   ( (_100PERCENT) * msg.value ) / 
                            ( totalPoolFunds() );

        // Now, compute the amount of new ULPT tokens (x) to mint 
        // for this new liquidity provided, according to formula,
        // whose explanation is provided below.
        //
        // Here, we assume variables:
        //
        //  uintFormatPercentage: the "percentage" Solidity variable,
        //      defined above, in (uint percentage = ...) statement.
        //
        //  x: the amount of ULPT tokens to mint for this liquidity 
        //      provider, to maintain "percentage" ratio with the
        //      ULPT's totalSupply after minting (newTotalSupply).
        //
        //  totalSupply: ULPT token's current total supply
        //      (as returned from totalSupply() function).
        //
        //  Let's start the formula:
        //
        // ratio = uintFormatPercentage / (_100PERCENT)
        // newTotalSupply = totalSupply + x
        //
        // x / newTotalSupply    = ratio
        // x / (totalSupply + x) = ratio
        // x = ratio * (totalSupply + x)
        // x = (ratio * totalSupply) + (ratio * x)
        // x - (ratio * x) = (ratio * totalSupply) 
        // (1 * x) - (ratio * x) = (ratio * totalSupply) 
        // ( 1 - ratio ) * x = (ratio * totalSupply) 
        // x = (ratio * totalSupply) / ( 1 - ratio )
        //
        //                  ratio * totalSupply
        // x = ------------------------------------------------
        //      1 - ( uintFormatPercentage / (_100PERCENT) )
        //
        //
        //                ratio * totalSupply * (_100PERCENT)
        // x = ---------------------------------------------------------------
        //     ( 1 - (uintFormatPercentage / (_100PERCENT)) )*(_100PERCENT)
        //
        // Let's abbreviate "_100PERCENT" to "100%".
        //
        //                      ratio * totalSupply * 100%
        // x = ---------------------------------------------------------
        //     ( 1 * 100% ) - ( uintFormatPercentage / (100%) ) * (100%)
        //
        //          ratio * totalSupply * 100%
        // x = -------------------------------------
        //          100% - uintFormatPercentage
        //
        //        (uintFormatPercentage / (100%)) * totalSupply * 100%
        // x = -------------------------------------------------------
        //          100% - uintFormatPercentage
        //
        //        (uintFormatPercentage / (100%)) * 100% * totalSupply
        // x = -------------------------------------------------------
        //          100% - uintFormatPercentage
        //
        //      uintFormatPercentage * totalSupply
        // x = ------------------------------------
        //         100% - uintFormatPercentage
        //
        // So, with our Solidity variables, that would be:
        // ==================================================== //
        //                                                      //
        //                     percentage * totalSupply         //
        //   amountToMint = ------------------------------      //
        //                   (_100PERCENT) - percentage       //
        //                                                      //
        // ==================================================== //
        //
        // We know that "percentage" is ALWAYS <= 100%, because
        // msg.value is already added to address(this).balance before
        // the payable function's body executes.
        //
        // However, notice that when "percentage" approaches 100%,
        // the denominator approaches 0, and that's not good.
        //
        // So, we must ensure that uint256 precision is enough to
        // handle such situations, and assign a "default" value for
        // amountToMint if such situation occurs.
        //
        // The most prominent case when this situation occurs, is on
        // the first-ever liquidity provide, when ULPT total supply is 
        // zero, and the "percentage" value is 100%, because pool's
        // balance was 0 before the operation.
        //
        // In such situation, we mint the 100 initial ULPT, which 
        // represent the pool share of the first ever pool liquidity 
        // provider, and that's 100% of the pool.
        // 
        // Also, we do the same thing (mint 100 ULPT tokens), on all
        // on all other situations when "percentage" is too close to 100%,
        // such as when there's a very tiny amount of liquidity left in
        // the pool.
        //
        // We check for those conditions based on precision of uint256
        // number type.
        // We know, that 256-bit uint can store up to roughly 10^74
        // base-10 values.
        //
        // Also, in our formula:
        // "totalSupply" can go to max. 10^30 (in extreme cases).
        // "percentage" up to 10^12 (with more-than-enough precision).
        // 
        // When multiplied, that's still only 10^(30+12) = 10^42 ,
        // and that's still a long way to go to 10^74.
        //
        // So, the denominator "(_100PERCENT) - percentage" can go down
        // to 1 safely, we must only ensure that it's not zero - 
        // and the uint256 type will take care of all precision needed.
        //

        if( balanceOf( msg.sender ) == 0 )
            emit NewPoolholderJoin( msg.sender, msg.value );


        // If percentage is below 100%, and totalSupply is NOT ZERO, 
        // work with the above formula.
        if( percentage < (_100PERCENT) &&
            totalSupply() != 0 )
        {
            // Compute the formula!
            uint256 amountToMint = 
                ( percentage * totalSupply() ) /
                (       (_100PERCENT) - percentage        );

            // Mint the computed amount.
            _mint( msg.sender, amountToMint );
        }

        // Else, if the newly-added liquidity percentage is 100% 
        // (pool's balance was Zero before this liquidity provide), then
        // just mint the initial 100 pool tokens.
        else
        {
            _mint( msg.sender, ( 100 * (uint( 10 ) ** decimals) ) );
        }


        // Emit corresponding event, that liquidity has been added.
        emit AddedLiquidity( msg.sender, msg.value );
        emitPoolStats();
    }


    /**
     *  Get the current pool share (percentage) of a specified
     *  address. Return the percentage, compute from ULPT data.
     */
    function getPoolSharePercentage( address holder ) 
                                                        public view
    returns ( uint percentage ) 
    {
        return  ( (_100PERCENT) * balanceOf( holder ) )
                / totalSupply();
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Remove msg.sender's pool liquidity share, and transfer it
     *  back to msg.sender's wallet.
     *  Burn the ULPT tokens that represented msg.sender's share
     *  of the pool.
     *  Notice that no activelyManaged modifier is present, which
     *  means that users are able to withdraw their money anytime.
     *
     *  However, there's a caveat - if some lotteries are currently
     *  ongoing, the pool's current reserve balance might not be 
     *  enough to meet every withdrawer's needs.
     *  
     *  In such scenario, withdrawers have either have to (OR'd):
     *  - Wait for ongoing lotteries to finish and return their 
     *    funds back to the pool,
     *  - TODO: Vote for forceful termination of lotteries
     *    (vote can be done whether pool is active or not).
     *  - TODO: Wait for OWNER to forcefully terminate lotteries.
     *
     *  Notice that last 2 options aren't going to be implemented
     *  in this version, because, as the OWNER is going to be the 
     *  only pool shareholder in the begginning, lottery participants
     *  might see the forceful termination feature as an exit-scam 
     *  threat, and this would damage project's reputation.
     *
     *  The feature is going to be implemented in later versions,
     *  after security audits pass, pool is open to public,
     *  and a significant amount of wallets join a pool.
     */
    function removeLiquidity(
            uint256 ulptAmount ) 
                                                external
                                                ownerApprovedAddressOnly
                                                mutexLOCKED
    {
        // Find out the real liquidity owner of this call - 
        // Check if the msg.sender is an approved-address, which can
        // call this function on behalf of the true liquidity owner.
        // Currently, this feature is only supported for OWNER_ADDRESS.
        address payable liquidityOwner = OWNER_ADDRESS;


        // Condition "balanceOf( liquidityOwner ) > 1" automatically 
        // checks if totalSupply() of ULPT is not zero, so we don't have
        // to check it separately.
        require( balanceOf( liquidityOwner ) > 1 &&
                 ulptAmount != 0 &&
                 ulptAmount <= balanceOf( liquidityOwner )/*,
                 "Specified ULPT token amount is invalid!" */);

        // Now, compute share percentage, and send the appropriate
        // amount of Ether from pool's balance to liquidityOwner.
        uint256 percentage = ( (_100PERCENT) * ulptAmount ) / 
                             totalSupply();

        uint256 shareAmount = ( totalPoolFunds() * percentage ) /
                              (_100PERCENT);

        require( shareAmount <= address( this ).balance/*, 
                 "Insufficient pool contract balance!" */);

        // Burn the specified amount of ULPT, thus removing the 
        // holder's pool share.
        _burn( liquidityOwner, ulptAmount );


        // Transfer holder's fund share as ether to holder's wallet.
        liquidityOwner.transfer( shareAmount );


        // Emit appropriate events.
        if( balanceOf( liquidityOwner ) == 0 )
            emit PoolholderWithdraw( liquidityOwner );

        emit RemovedLiquidity( liquidityOwner, shareAmount );
        emitPoolStats();
    }


    // ======== Lottery Management Section ======== //

    // Check if lottery is currently ongoing.
    function isLotteryOngoing( address lotAddr ) 
                                                    external view
    returns( bool ) {
        return ongoingLotteries[ lotAddr ];
    }


    // Get length of all lotteries performed.
    function allLotteriesPerformed_length()
                                                    external view
    returns( uint )
    {
        return allLotteriesPerformed.length;
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Ongoing (not-yet-completed) lottery finalization function.
     *  - This function is called by a currently ongoing lottery, to
     *    notify the pool about it's finishing.
     *  - After lottery calls this function, lottery is removed from
     *    ongoing lottery tracking list, and set to inactive.
     *
     *  * Ether is transfered into our contract:
     *      Lottery transfers the pool profit share and initial funds 
     *      back to the pool when calling this function, so the
     */
    function lotteryFinish( 
                uint totalReturn, 
                uint profitAmount )
                                            external
                                            payable
                                            calledByOngoingLotteryOnly
    {
        // "De-activate" this lottery.
        //ongoingLotteries[ msg.sender ] = false;
        delete ongoingLotteries[ msg.sender ];  // implies "false"

        // We assume that totalReturn and profitAmount are valid,
        // because this function can be called only by Lottery, which
        // was deployed by us before.

        // Update current lottery funds - this one is no longer active,
        // so it's funds block.timestamp have been transfered to us.
        uint lotFunds = Lottery( msg.sender ).getInitialFunds();
        if( lotFunds < currentLotteryFunds )
            currentLotteryFunds -= lotFunds;
        else
            currentLotteryFunds = 0;

        // Emit approppriate events.
        emit LotteryFinished( msg.sender, totalReturn, profitAmount );

        // If AUTO-MODE is currently set, schedule a next lottery
        // start using the current AUTO-MODE parameters!
        // Ignore the return value, because AUTO-MODE params might be
        // invalid, and we don't want our finish function to fail
        // just because of that.

        if( lotteryRunMode == LotteryRunMode.AUTO )
        {
            autoMode_isLotteryCurrentlyOngoing = false;
            autoMode_lastLotteryFinished = uint32( block.timestamp );

            scheduleAutoModeCallback();
        }
    }


    /**
     *  The Callback function which Randomness Provider will call
     *  when executing the Scheduled Callback requests.
     *
     *  We use this callback for scheduling Auto-Mode lotteries - 
     *  when one lottery finishes, another one is scheduled to run
     *  after specified amount of time.
     *
     *  In this callback, we start the scheduled Auto-Mode lottery.
     */
    function scheduledCallback( uint256 /*requestID*/ ) 
                                                                public
    {
        // At first, check if mode is AUTO (not changed).
        if( lotteryRunMode != LotteryRunMode.AUTO )
            return;

        // Check if we're not X-Ceeding the number of auto-iterations.
        if( autoMode_currentCycleIterations >= autoMode_maxNumberOfRuns )
        {
            autoMode_currentCycleIterations = 0;
            return;
        }

        // Launch an auto-lottery using the currently set next
        // lottery config!
        // When this lottery finishes, and the mode is still AUTO,
        // one more lottery will be started.

        launchLottery( nextLotteryConfig );

        // Set the time started, and increment iterations.
        autoMode_isLotteryCurrentlyOngoing = true;
        autoMode_lastLotteryStarted = uint32( block.timestamp );
        autoMode_currentCycleIterations++;
    }


    /**
     *  The Randomness Provider-callable function, which is used to
     *  ask pool for permission to execute lottery ending callback 
     *  request with higher price than the pool-given funds for that
     *  specific lottery's ending request, when lottery was created.
     *
     *  The function notifies the pool about the new and 
     *  before-expected price, so the pool could compute a debt to
     *  be paid to the Randomnes Provider in next request.
     *
     *  Here, we update our debt variable, which is the difference
     *  between current and expected-before request price,
     *  and we'll transfer the debt to Randomness Provider on next
     *  request to Randomness Provider.
     *
     *  Notice, that we'll permit the execution of the lottery
     *  ending callback only if the new price is not more than 
     *  1.5x higher than before-expected price.
     *
     *  This is designed so, because the Randomness Provider will
     *  call this function only if it has enough funds to execute the 
     *  callback request, and just that the funds that we have transfered
     *  for this specific lottery's ending callback before, are lower
     *  than the current price of execution.
     *
     *  Why is this the issue? 
     *  Lottery can last for several weeks, and we give the callback
     *  execution funds for that specific lottery to Randomness Provider
     *  only on that lottery's initialization.
     *  So, after a few weeks, the Provable services might change the
     *  gas & fee prices, so the callback execution request price 
     *  might change.
     */
    function onLotteryCallbackPriceExceedingGivenFunds(
            address /*lottery*/, 
            uint currentRequestPrice,
            uint poolGivenExpectedRequestPrice )
                                                    external 
                                                    randomnessProviderOnly
    returns( bool callbackExecutionPermitted )
    {
        require( currentRequestPrice > poolGivenExpectedRequestPrice );
        uint difference = currentRequestPrice - poolGivenExpectedRequestPrice;

        // Check if the price difference is not bigger than the half
        // of the before-expected pool-given price.
        // Also, make sure that whole debt doesn't exceed 0.5 ETH.
        if( difference <= ( poolGivenExpectedRequestPrice / 2 ) &&
            ( randomnessProviderDebt + difference ) < ( (1 ether) / 2 ) )
        {
            // Update our debt, to pay back the difference later,
            // when we transfer funds for the next request.
            randomnessProviderDebt += uint80( difference );

            // Return true - the callback request execution is permitted.
            return true;
        }

        // The price difference is higher - deny the execution.
        return false;
    }


    // Below are the Owner-Callable voting-skipping functions, to set 
    // the next lottery config, lottery run mode, and other settings.
    //
    // When the final version is released, these functions will
    // be removed, and every governance operation will be done
    // through voting.

    /**
     *  Set the LotteryConfig to be used by the next lottery.
     *  Owner-only callable.
     */
    function setNextLotteryConfig(
            Lottery.LotteryConfig memory cfg )
                                                    public
                                                    ownerApprovedAddressOnly
    {
        nextLotteryConfig = cfg;

        emit NewConfigProposed( msg.sender, cfg, 0 );
        // emitPoolStats();
    }

    /**
     *  Set the Lottery Run Mode to be used for further lotteries.
     *  It can be AUTO, or MANUAL (more about it on their descriptions).
     */
    function setRunMode(
            LotteryRunMode runMode )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check if it's one of allowed run modes.
        require( runMode == LotteryRunMode.AUTO ||
                 runMode == LotteryRunMode.MANUAL/*,
                 "This Run Mode is not allowed in current state!" */);

        // Emit a change event, with old value and new value.
        emit LotteryRunModeChanged( lotteryRunMode, runMode );

        // Set the new run mode!
        lotteryRunMode = runMode;

        // emitPoolStats();
    }

    /**
     *  Start a manual mode lottery from the previously set up
     *  next lottery config!
     */
    function startManualModeLottery()
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check if config is set - just check if initial funds
        // are a valid value.
        require( nextLotteryConfig.initialFunds != 0/*,
                 "Currently set next-lottery-config is invalid!" */);

        // Launch a lottery using our private launcher function!
        launchLottery( nextLotteryConfig );

        emitPoolStats();
    }


    /**
     *  Set an Auto-Mode lottery run mode parameters.
     *  The auto-mode is implemented using Randomness Provider 
     *  scheduled callback functionality, to schedule a lottery start
     *  on specific intervals.
     *
     *  @param nextLotteryDelay - amount of time, in seconds, to wait
     *      when last lottery finishes, to start the next lottery.
     *
     *  @param maxNumberOfRuns  - max number of lottery runs in this
     *      Auto-Mode cycle. When it's reached, mode will switch to
     *      MANUAL automatically.
     */
    function setAutoModeParameters(
            uint32 nextLotteryDelay,
            uint16 maxNumberOfRuns )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Set params!
        autoMode_nextLotteryDelay = nextLotteryDelay;
        autoMode_maxNumberOfRuns = maxNumberOfRuns;

        // emitPoolStats();
    }

    /**
     *  Starts an Auto-Mode lottery running cycle with currently
     *  specified Auto-Mode parameters.
     *  Notice that we must be on Auto run-mode currently.
     */
    function startAutoModeCycle()
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check that we're on the Auto-Mode block.timestamp.
        require( lotteryRunMode == LotteryRunMode.AUTO/*,
                 "Current Run Mode is not AUTO!" */);

        // Check if valid AutoMode params were specified.
        require( autoMode_maxNumberOfRuns != 0/*,
                 "Invalid Auto-Mode params set!" */);

        // Reset the cycle iteration counter.
        autoMode_currentCycleIterations = 0;

        // Start the Auto-Mode cycle using a scheduled callback!
        scheduledCallback( 0 );

        // emitPoolStats();
    }

    /**
     *  Set or Remove Owner-approved addresses.
     *  These addresses are used to call ownerOnly functions on behalf
     *  of the OWNER_ADDRESS (more detailed description above).
     */
    function owner_setOwnerApprovedAddress( address addr )
                                                                external
                                                                ownerOnly
    {
        ownerApprovedAddresses[ addr ] = true;
    }

    function owner_removeOwnerApprovedAddress( address addr )
                                                                external
                                                                ownerOnly
    {
        delete ownerApprovedAddresses[ addr ];
    }


    /**
     *  ABIEncoderV2 - compatible getter for the nextLotteryConfig,
     *  which will be retuned as byte array internally, then internally
     *  de-serialized on receive.
     */
    function getNextLotteryConfig()
                                                                external 
                                                                view
    returns( Lottery.LotteryConfig memory )
    {
        return nextLotteryConfig;
    }

    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Retrieve the UnClaimed Prizes of a completed lottery, if
     *  that lottery's prize claim deadline has already passed.
     *
     *  - What's payable? This function causes a specific Lottery to
     *      transfer Ether from it's contract balance, to our contract.
     */
    function retrieveUnclaimedLotteryPrizes(
            address payable lottery )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        // Just call that function - if the deadline hasn't passed yet,
        // that function will revert.
        Lottery( lottery ).getUnclaimedPrizes();
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Retrieve the specified amount of funds from the Randomness
     *  Provider.
     *
     *  WARNING: Future scheduled operations on randomness provider
     *           might FAIL if randomness provider won't have enough
     *           funds to execute that operation on that time!
     *
     *  - What's payable? This function causes the Randomness Provider to
     *      transfer Ether from it's contract balance, to our contract.
     */
    function retrieveRandomnessProviderFunds(
            uint etherAmount )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        randomnessProvider.sendFundsToPool( etherAmount );
    }

    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Send specific amount of funds to Randomness Provider, from
     *  our contract's balance.
     *  This is useful in cases when gas prices change, and current
     *  funds inside randomness provider are not enough to execute
     *  operations on the new gas cost.
     *
     *  This operation is limited to 6 ethers once in 12 hours.
     *
     *  - What's payable?   We send Ether to the randomness provider.
     */
    function provideRandomnessProviderFunds(
            uint etherAmount )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        // Check if conditions apply!
        require( ( etherAmount <= 6 ether ) &&
                 ( block.timestamp - lastTimeRandomFundsSend > 12 hours )/*,
                 "Random Fund Provide Conditions are not satisfied!" */);

        // Set the last-time-funds-sent timestamp to block.timestamp.
        lastTimeRandomFundsSend = uint32( block.timestamp );

        // Transfer the funds.
        address( randomnessProvider ).transfer( etherAmount );
    }


    /**
     *  Set the Gas Price to use in the Randomness Provider.
     *  Used when very volatile gas prices are present during network
     *  congestions, when default is not enough.
     */
    function setGasPriceOfRandomnessProvider(
            uint gasPrice )
                                                external
                                                gasOracleAndOwnerApproved
    {
        randomnessProvider.setGasPrice( gasPrice );
    }


    /**
     *  Set the address of the so-called Gas Oracle, which is an
     *  automated script running on our server, and fetching gas prices.
     *
     *  The address used by this script should be able to call
     *  ONLY the "setGasPriceOfRandomnessProvider" function (above).
     *
     *  Here, we set that address.
     */
    function setGasOracleAddress( address addr )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        gasOracleAddress = addr;
    }

}
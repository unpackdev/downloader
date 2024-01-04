// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File contracts/general/Ownable.sol

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev We've added a second owner to share control of the timelocked owner contract.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;
    
    // Second allows a DAO to share control.
    address private _secondOwner;
    address private _pendingSecond;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecondOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        _secondOwner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        emit SecondOwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return the address of the owner.
     */
    function secondOwner() public view returns (address) {
        return _secondOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }
    
    modifier onlyFirstOwner() {
        require(msg.sender == _owner, "msg.sender is not owner");
        _;
    }
    
    modifier onlySecondOwner() {
        require(msg.sender == _secondOwner, "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || msg.sender == _secondOwner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyFirstOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
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

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferSecondOwnership(address newOwner) public onlySecondOwner {
        _pendingSecond = newOwner;
    }

    function receiveSecondOwnership() public {
        require(msg.sender == _pendingSecond, "only pending owner can call this function");
        _transferSecondOwnership(_pendingSecond);
        _pendingSecond = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferSecondOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit SecondOwnershipTransferred(_secondOwner, newOwner);
        _secondOwner = newOwner;
    }

    uint256[50] private __gap;
}


// File contracts/libraries/Address.sol

pragma solidity ^0.6.6;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.6.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
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


// File contracts/interfaces/IERC20.sol


pragma solidity ^0.6.6;

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

    function mint(address to, uint256 amount) external returns (bool);
    
    function burn(address from, uint256 amount) external returns (bool);

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


// File contracts/libraries/SafeERC20.sol

pragma solidity ^0.6.6;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IWNXM.sol

pragma solidity ^0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IWNXM {
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

    function mint(address to, uint256 amount) external returns (bool);
    
    function burn(address from, uint256 amount) external returns (bool);

    function wrap(uint256 amount) external;
    
    function unwrap(uint256 amount) external;

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


// File contracts/interfaces/INexusMutual.sol

pragma solidity ^0.6.6;

/**
 * @dev Quick interface for the Nexus Mutual contract to work with the Armor Contracts.
 **/

// to get nexus mutual contract address
interface INxmMaster {
    function tokenAddress() external view returns(address);
    function owner() external view returns(address);
    function pauseTime() external view returns(uint);
    function masterInitialized() external view returns(bool);
    function isPause() external view returns(bool check);
    function isMember(address _add) external view returns(bool);
    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);
}

interface IPooledStaking {
    function lastUnstakeRequestId() external view returns(uint256);
    function stakerDeposit(address user) external view returns (uint256);
    function stakerMaxWithdrawable(address user) external view returns (uint256);
    function withdrawReward(address user) external;
    function requestUnstake(address[] calldata protocols, uint256[] calldata amounts, uint256 insertAfter) external;
    function depositAndStake(uint256 deposit, address[] calldata protocols, uint256[] calldata amounts) external;
    function stakerContractStake(address staker, address protocol) external view returns (uint256);
    function stakerContractPendingUnstakeTotal(address staker, address protocol) external view returns(uint256);
    function withdraw(uint256 amount) external;
    function stakerReward(address staker) external view returns (uint256);
}

interface IClaimsData {
    function getClaimStatusNumber(uint256 claimId) external view returns (uint256, uint256);
    function getClaimDateUpd(uint256 claimId) external view returns (uint256);
}


// File contracts/interfaces/IRewardDistributionRecipient.sol

pragma solidity ^0.6.6;

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) payable external;
}


// File contracts/interfaces/IRewardManager.sol

pragma solidity ^0.6.6;

interface IRewardManager is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeController) external;
  function stake(address _user, address _referral, uint256 _coverPrice) external;
  function withdraw(address _user, address _referral, uint256 _coverPrice) external;
  function getReward(address payable _user) external;
}


// File contracts/core/arNXMVault.sol

pragma solidity ^0.6.6;


/**
 * @title arNXM Vault
 * @dev Vault to stake wNXM in Nexus Mutual while maintaining your liquidity.
 * @author Armor.fi -- Robert M.C. Forster, Taek Lee
 * SPDX-License-Identifier: (c) Armor.Fi DAO, 2021
**/
contract arNXMVault is Ownable {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    uint256 constant private DENOMINATOR = 1000;
    
    // Amount of time between 
    uint256 public restakePeriod;
    
    // Amount of time that rewards are distributed over.
    uint256 public rewardDuration;
    
    // How much to unstake each week. 10 == 1%; 1000 == 100%.
    uint256 public unstakePercent;
    
    // Percent of the AUM total that we should keep in reserve. 10 == 1%; 1000 == 100%.
    uint256 public reservePercent;
    
    // Withdrawals may be paused if a hack has recently happened. Timestamp of when the pause happened.
    uint256 public withdrawalsPaused;
    
    // Amount of time withdrawals may be paused after a hack.
    uint256 public pauseDuration;
    
    // Address that will receive administration funds from the contract.
    address public beneficiary;
    
    // Percent of funds to be distributed for administration of the contract. 10 == 1%; 1000 == 100%.
    uint256 public adminPercent;
    
    // Percent of staking rewards that referrers get.
    uint256 public referPercent;
    
    // Timestamp of when the last restake took place--7 days between each.
    uint256 public lastRestake;
    
    // The amount of the last reward.
    uint256 public lastReward;
    
    // Uniswap, Maker, Compound, Aave, Curve, Synthetix, Yearn, RenVM, Balancer, dForce.
    address[] public protocols;
    
    // Amount to unstake each time.
    uint256[] private amounts;
    
    // Protocols being unstaked each time restake occurs.
    address[] private unstakingProtocols;

    // Nxm tokens.
    IERC20 public wNxm;
    IERC20 public nxm;
    IERC20 public arNxm;
    
    // Nxm Master address.
    INxmMaster public nxmMaster;
    
    // Reward manager for referrers.
    IRewardManager public rewardManager;
    
    // Referral => referrer
    mapping (address => address) public referrers;
    
    event Deposit(address indexed user, uint256 wAmount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 wAmount, uint256 timestamp);
    event Restake(uint256 withdrawn, uint256 userReward, uint256 unstaked, uint256 staked, uint256 totalAum, uint256 timestamp);
    
    // Avoid composability issues for liquidation.
    modifier notContract {
        require(msg.sender == tx.origin, "Sender must be an EOA.");
        _;
    }
    
    /**
     * @param _protocols List of the 10 protocols we're using.
     * @param _wNxm Address of the wNxm contract.
     * @param _arNxm Address of the arNxm contract.
     * @param _nxmMaster Address of Nexus' master address (to fetch others).
     * @param _rewardManager Address of the ReferralRewards smart contract.
    **/
    function initialize(address[] memory _protocols, 
                address _wNxm, 
                address _arNxm,
                address _nxm,
                address _nxmMaster,
                address _rewardManager)
      public
    {
        require(address(arNxm) == address(0), "Contract has already been initialized.");
        
        for (uint256 i = 0; i < _protocols.length; i++) protocols.push(_protocols[i]);
        
        Ownable.initializeOwnable();
        wNxm = IERC20(_wNxm);
        nxm = IERC20(_nxm);
        arNxm = IERC20(_arNxm);
        nxmMaster = INxmMaster(_nxmMaster);
        rewardManager = IRewardManager(_rewardManager);
        unstakePercent = 100;
        adminPercent = 0;
        referPercent = 25;
        reservePercent = 100;
        pauseDuration = 10 days;
        beneficiary = msg.sender;
        restakePeriod = 3 days;
        rewardDuration = 9 days;
        
        // Approve to send funds to reward manager.
        arNxm.approve( _rewardManager, uint256(-1) );
    }
    
    /**
     * @dev Deposit wNxm to get arNxm in return.
     * @param _wAmount The amount of wNxm to stake.
     * @param _referrer The address that referred this user.
    **/
    function deposit(uint256 _wAmount, address _referrer)
      external
    {
        if ( referrers[msg.sender] == address(0) ) {
            referrers[msg.sender] = _referrer != address(0) ? _referrer : beneficiary;
        }
        
        // This amount must be determined before arNxm mint.
        uint256 arNxmAmount = arNxmValue(_wAmount);

        wNxm.safeTransferFrom(msg.sender, address(this), _wAmount);
        // Mint also increases sender's referral balance through alertTransfer.
        arNxm.mint(msg.sender, arNxmAmount);
        
        emit Deposit(msg.sender, _wAmount, block.timestamp);
    }
    
    /**
     * @dev Withdraw an amount of wNxm by burning arNxm.
     * @param _arAmount The amount of arNxm to burn for the wNxm withdraw.
    **/
    function withdraw(uint256 _arAmount)
      external
    {
        require(block.timestamp.sub(withdrawalsPaused) > pauseDuration, "Withdrawals are temporarily paused.");

        // This amount must be determined before arNxm burn.
        uint256 wNxmAmount = wNxmValue(_arAmount);
        
        // Burn also decreases sender's referral balance through alertTransfer.
        arNxm.burn(msg.sender, _arAmount);
        wNxm.safeTransfer(msg.sender, wNxmAmount);
        
        emit Withdrawal(msg.sender, wNxmAmount, block.timestamp);
    }

    /**
     * @dev Restake is to be called weekly. It unstakes 7% of what's currently staked, then restakes.
     * @param lastId Frontend must submit last ID because it doesn't work direct from Nexus Mutual.
    **/
    function restake(uint256 lastId)
      external
      notContract
    {
        // Check that this is only called once per week.
        require(lastRestake.add(restakePeriod) <= block.timestamp, "It has not been enough time since the last restake.");
        
        // All Nexus functions.
        uint256 withdrawn = _withdrawNxm();
        uint256 rewards = _getRewardsNxm();
        _wrapNxm();
        
        uint256 staked = _stakeNxm();
        uint256 unstaked = _unstakeNxm(lastId);
        
        // Reset variables.
        lastRestake = block.timestamp;

        emit Restake(withdrawn, rewards, unstaked, staked, aum(), block.timestamp);
    }
    
    /**
     * @dev Find the arNxm value of a certain amount of wNxm.
     * @param _wAmount The amount of wNxm to check arNxm value of.
     * @return arAmount The amount of arNxm the input amount of wNxm is worth.
    **/
    function arNxmValue(uint256 _wAmount)
      public
      view
    returns (uint256 arAmount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        
        // Get all balances of wNxm on this contract, being staked, then reward allowed to be distributed.
        uint256 balance = wNxm.balanceOf( address(this) );
        uint256 stakeDeposit = pool.stakerDeposit( address(this) );
        uint256 reward = _currentReward();
        
        // Find totals of both tokens.
        uint256 totalW = balance.add(stakeDeposit).add(reward);
        uint256 totalAr = arNxm.totalSupply();
        
        // Find exchange amount of one token, then find exchange amount for full value.
        if (totalW == 0) {
            arAmount = _wAmount;
        } else {
            uint256 oneAmount = ( totalAr.mul(1e18) ).div(totalW);
            arAmount = _wAmount.mul(oneAmount).div(1e18);
        }
    }
    
    /**
     * @dev Find the wNxm value of a certain amount of arNxm.
     * @param _arAmount The amount of arNxm to check wNxm value of.
     * @return wAmount The amount of wNxm the input amount of arNxm is worth.
    **/
    function wNxmValue(uint256 _arAmount)
      public
      view
    returns (uint256 wAmount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        
        // Get all balances of wNxm on this contract, being staked, then reward allowed to be distributed.
        uint256 balance = wNxm.balanceOf( address(this) );
        uint256 stakeDeposit = pool.stakerDeposit( address(this) );
        uint256 reward = _currentReward();
        
        // Find totals of both tokens.
        uint256 totalW = balance.add(stakeDeposit).add(reward);
        uint256 totalAr = arNxm.totalSupply();
        
        // Find exchange amount of one token, then find exchange amount for full value.
        uint256 oneAmount = ( totalW.mul(1e18) ).div(totalAr);
        wAmount = _arAmount.mul(oneAmount).div(1e18);
    }
    
    /**
     * @dev Used to determine total Assets Under Management.
     * @return aumTotal Full amount of assets under management (wNXM balance + stake deposit).
    **/
    function aum()
      public
      view
    returns (uint256 aumTotal)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 balance = wNxm.balanceOf( address(this) );
        uint256 stakeDeposit = pool.stakerDeposit( address(this) );
        aumTotal = balance.add(stakeDeposit);
    }
    
    /**
     * @dev Anyone may call this function to pause withdrawals for a certain amount of time.
     *      We check Nexus contracts for a recent accepted claim, then can pause to avoid further withdrawals.
     * @param _claimId The ID of the cover that has been accepted for a confirmed hack.
    **/
    function pauseWithdrawals(uint256 _claimId)
      external
    {
        IClaimsData claimsData = IClaimsData( _getClaimsData() );
        
        (/*coverId*/, uint256 status) = claimsData.getClaimStatusNumber(_claimId);
        uint256 dateUpdate = claimsData.getClaimDateUpd(_claimId);
        
        // Status must be 14 and date update must be within the past 7 days.
        if (status == 14 && block.timestamp.sub(dateUpdate) <= 7 days) {
            withdrawalsPaused = block.timestamp;
        }
    }
    
    /**
     * @dev When arNXM tokens are transferred, the referrer stakes must be adjusted on RewardManager.
     *      This is taken care of by a "_beforeTokenTransfer" function on the arNXM ERC20.
     * @param _from The user that tokens are being transferred from.
     * @param _to The user that tokens are being transferred to.
     * @param _amount The amount of tokens that are being transferred.
    **/
    function alertTransfer(address _from, address _to, uint256 _amount)
      external
    {
        require(msg.sender == address(arNxm), "Sender must be the token contract.");
        
        // address(0) means the contract or EOA has not interacted directly with arNXM Vault.
        if ( referrers[_from] != address(0) ) rewardManager.withdraw(referrers[_from], _from, _amount);
        if ( referrers[_to] != address(0) ) rewardManager.stake(referrers[_to], _to, _amount);
    }
    
    /**
     * @dev Approve wNXM to transfer NXM from this contract.
    **/
    function approveNxmToWNXM() external {
        _approveNxm(address(wNxm));
    }

    /**
     * @dev Withdraw any wNxm we can from the staking pool.
     * @return amount The amount of funds that are being withdrawn.
    **/
    function _withdrawNxm()
      internal
      returns (uint256 amount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        amount = pool.stakerMaxWithdrawable( address(this) );
        pool.withdraw(amount);
    }
    
    /**
     * @dev Withdraw any available rewards from Nexus.
     * @return finalReward The amount of rewards to be given to users (full reward - admin reward - referral reward).
    **/
    function _getRewardsNxm()
      internal
      returns (uint256 finalReward)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        
        // Find current reward, find user reward (transfers reward to admin within this).
        uint256 fullReward = pool.stakerReward( address(this) );
        finalReward = _feeRewardsNxm(fullReward);
        
        pool.withdrawReward( address(this) );
        lastReward = finalReward;
    }
    
    /**
     * @dev Find and distribute administrator rewards.
     * @param reward Full reward given from this week.
     * @return userReward Reward amount given to users (full reward - admin reward).
    **/
    function _feeRewardsNxm(uint256 reward)
      internal
    returns (uint256 userReward)
    {
        // Find both rewards before minting any.
        uint256 adminReward = arNxmValue( reward.mul(adminPercent).div(DENOMINATOR) );
        uint256 referReward = arNxmValue( reward.mul(referPercent).div(DENOMINATOR) );

        // Mint to beneficary then this address (to then transfer to rewardManager).
        if (adminReward > 0) {
          arNxm.mint(beneficiary, adminReward);
        }
        if (referReward > 0) {
            arNxm.mint(address(this), referReward);
            rewardManager.notifyRewardAmount(referReward);
        }
        
        userReward = reward.sub(adminReward).sub(referReward);
    }

    /**
     * @dev Unstake an amount from each protocol on Nxm (takes 90 days to unstake).
     * @param lastId The ID of the last unstake request on Nexus Mutual (needed for unstaking).
     * @return unstakeAmount The amount of each token that we're unstaking.
    **/
    function _unstakeNxm(uint256 lastId)
      internal
      returns (uint256 unstakeAmount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 stake = pool.stakerContractStake(address(this), protocols[0]);
        unstakeAmount = stake * unstakePercent / DENOMINATOR;
        // Can't unstake less than 20 NXM.
        if (unstakeAmount < 20 ether) return 0;
        
        for (uint256 i = 0; i < protocols.length; i++) {
            uint256 indUnstakeAmount = _protocolUnstakeable(protocols[i], unstakeAmount);
              
            if (indUnstakeAmount > 0) {
                amounts.push(indUnstakeAmount);
                unstakingProtocols.push(protocols[i]);
            }
          
        }
        
        pool.requestUnstake(unstakingProtocols, amounts, lastId);
        
        delete amounts;
        delete unstakingProtocols;
    }

    /**
     * @dev Returns the amount we can unstake (if we can't unstake the full amount desired).
     * @param _protocol The address of the protocol we're checking.
     * @param _unstakeAmount Amount we want to unstake.
     * @return The amount of funds that can be unstaked from this protocol if not the full amount desired.
    **/
    function _protocolUnstakeable(address _protocol, uint256 _unstakeAmount) 
      internal 
      view
    returns (uint256) {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 stake = pool.stakerContractStake(address(this), _protocol);
        uint256 requested = pool.stakerContractPendingUnstakeTotal(address(this), _protocol);
        uint256 available = stake - requested;
        
        // available <= stake is underflow protection.
        return available >= _unstakeAmount && available <= stake ? _unstakeAmount : available;
    }

    /**
     * @dev Stake any wNxm over the amount we need to keep in reserve (bufferPercent% more than withdrawals last week).
     * @return toStake Amount of token that we will be staking. 
    **/
    function _stakeNxm()
      internal
    returns (uint256 toStake)
    {
        _approveNxm(_getTokenController());
        uint256 balance = wNxm.balanceOf( address(this) );
        uint256 toReserve = aum() * reservePercent / DENOMINATOR;
        
        // If we do need to restake funds...
        if (toReserve < balance) {

            IPooledStaking pool = IPooledStaking( _getPool() );
            
            // Determine how much to stake then unwrap wNxm to be able to stake it. Can't stake less than 20 NXM.
            toStake = balance.sub(toReserve);
            if (toStake < 20 ether) return 0;
            
            _unwrapWNxm(toStake);
            
            for (uint256 i = 0; i < protocols.length; i++) {
                uint256 stake = pool.stakerContractStake(address(this), protocols[i]);
                amounts.push( toStake.add(stake) );
            }

            pool.depositAndStake(toStake, protocols, amounts);
            delete amounts;
            
        }
        
    }
    
    /**
     * @dev Calculate what the current reward is. We stream this to arNxm value to avoid dumps.
     * @return reward Amount of reward currently calculated into arNxm value.
    **/
    function _currentReward()
      internal
      view
    returns (uint256 reward)
    {
        uint256 duration = rewardDuration;
        uint256 timeElapsed = block.timestamp.sub(lastRestake);
        
        // Full reward is added to the balance if it's been more than the disbursement duration.
        if (timeElapsed >= duration) {

            reward = lastReward;
        
        // Otherwise, disburse amounts linearly over duration.
        } else {
            
            // 1e18 just for a buffer.
            uint256 portion = ( duration.mul(1e18) ).div(timeElapsed);
            reward = ( lastReward.mul(1e18) ).div(portion);
            
        }
    }
    
    /**
     * @dev Wrap Nxm tokens to be able to be withdrawn as wNxm.
    **/
    function _wrapNxm()
      internal
    {
        // Wrap our full NXM balance.
        uint256 amount = nxm.balanceOf( address(this) );
        IWNXM(address(wNxm)).wrap(amount);
    }
    
    /**
     * @dev Unwrap wNxm tokens to be able to be used within the Nexus Mutual system.
     * @param _amount Amount of wNxm tokens to be unwrapped.
    **/
    function _unwrapWNxm(uint256 _amount)
      internal
    {
        IWNXM(address(wNxm)).unwrap(_amount);
    }
    
    /**
     * @dev Get current address of the Nexus staking pool.
     * @return pool Address of the Nexus staking pool contract.
    **/
    function _getPool()
      internal
      view
    returns (address pool)
    {
        pool = nxmMaster.getLatestAddress("PS");
    }

    /**
     * @dev Get the current NXM token address from Nexus Mutual.
     * @return nxmAddress Address of the NXM token.
    **/
    function _getNXM()
      internal
      view
    returns(address nxmAddress)
    {
        nxmAddress = nxmMaster.tokenAddress();
    }
    
    /**
     * @dev Get the current NXM token controller (for NXM actions) from Nexus Mutual.
     * @return controller Address of the token controller.
    **/
    function _getTokenController()
      internal
      view
    returns(address controller)
    {
        controller = nxmMaster.getLatestAddress("TC");
    }

    /**
     * @dev Get current address of the Nexus Claims Data contract.
     * @return claimsData Address of the Nexus Claims Data contract.
    **/
    function _getClaimsData()
      internal
      view
    returns (address claimsData)
    {
        claimsData = nxmMaster.getLatestAddress("CD");
    }
    
    /**
     * @dev Approve wNxm contract to be able to transferFrom Nxm from this contract.
    **/
    function _approveNxm(address _to)
      internal
    {
        nxm.approve( _to, uint256(-1) );
    }
    
    /**
     * @dev Owner may change how much of the AUM should be saved in reserve each week.
     * @param _reservePercent The new reserve percent to change to.
    **/
    function changeReservePercent(uint256 _reservePercent)
      external
      onlyOwner
    {
        require(_reservePercent <= 1000, "Reserve percent cannot be more than 100%.");
        reservePercent = _reservePercent;
    }
    
    /**
     * @dev Owner can change what percent of stake to unstake each week.
     * @param _unstakePercent The new percent of funds to unstake each week.
    **/
    function changeUnstakePercent(uint256 _unstakePercent)
      external
      onlyOwner
    {
        require(_unstakePercent <= 1000, "Unstake percent cannot be more than 100%.");
        unstakePercent = _unstakePercent;
    }
    
    /**
     * @dev Owner may change the percent of insurance fees referrers receive.
     * @param _referPercent The percent of fees referrers receive. 50 == 5%.
    **/
    function changeReferPercent(uint256 _referPercent)
      external
      onlyOwner
    {
        require(_referPercent <= 500, "Cannot give referrer more than 50% of rewards.");
        referPercent = _referPercent;
    }
    
    /**
     * @dev Change the percent of rewards that are given for administration of the contract.
     * @param _adminPercent The percent of rewards to be given for administration (10 == 1%, 1000 == 100%)
    **/
    function changeAdminPercent(uint256 _adminPercent)
      external
      onlyOwner
    {
        require(_adminPercent <= 500, "Cannot give admin more than 50% of rewards.");
        adminPercent = _adminPercent;
    }

    /**
     * @dev Owner may change protocols that we stake for.
     * @param _protocols New list of protocols to stake for.
    **/
    function changeProtocols(address[] calldata _protocols)
      external
      onlyOwner
    {
        protocols = _protocols;
    }
    
    /**
     * @dev Owner may change the amount of time required to be waited between restaking.
     * @param _restakePeriod Amount of time required between restakes (starts at 6 days or 86400 * 6).
    **/
    function changeRestakePeriod(uint256 _restakePeriod)
      external
      onlyOwner
    {
        require(_restakePeriod <= 30 days, "Restake period cannot be more than 30 days.");
        restakePeriod = _restakePeriod;
    }
    
    /**
     * @dev Owner may change the amount of time it takes to distribute rewards from Nexus.
     * @param _rewardDuration The amount of time it takes to fully distribute rewards.
    **/
    function changeRewardDuration(uint256 _rewardDuration)
      external
      onlyOwner
    {
        require(_rewardDuration <= 30 days, "Restake period cannot be more than 30 days.");
        rewardDuration = _rewardDuration;
    }
    
    /**
     * @dev Owner may change the amount of time that withdrawals are paused after a hack is confirmed.
     * @param _pauseDuration The new amount of time that withdrawals will be paused.
    **/
    function changePauseDuration(uint256 _pauseDuration)
      external
      onlyOwner
    {
        require(_pauseDuration <= 30 days, "Pause duration cannot be more than 30 days.");
        pauseDuration = _pauseDuration;
    }
    
    /**
     * @dev Change beneficiary of the administration funds.
     * @param _newBeneficiary Address of the new beneficiary to receive funds.
    **/
    function changeBeneficiary(address _newBeneficiary) 
      external 
      onlyOwner 
    {
        beneficiary = _newBeneficiary;
    }

}
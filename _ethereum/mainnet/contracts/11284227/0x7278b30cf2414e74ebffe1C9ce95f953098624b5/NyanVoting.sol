// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\NyanFund\ERC20Interface.sol

pragma solidity ^0.6.6;

interface ERC20 {
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

// File: contracts\NyanFund\NyanVoting.sol

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;



interface NFund {
    function approveSpendERC20(address, uint256) external;
    
    function approveSpendETH(address, uint256) external;
    
    function newVotingRound() external;
    
    function setVotingAddress(address) external;
    
    function setConnectorAddress(address) external;
    
    function setNewFundAddress(address) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function setBalanceLimit(uint256) external;
    
    function sendToNewContract(address) external;
}

interface NVoting {
    function setConnector(address) external;
    
    function setFundAddress(address) external;
    
    function setRewardsContract(address) external;
    
    function setIsRewardingCatnip(bool) external;
    
    function setVotingPeriodBlockLength(uint256) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function distributeFunds(address, uint256) external;
    
    function burnCatnip() external;
}

interface NConnector {
    function executeBid(
        string calldata, 
        string calldata, 
        address[] calldata , 
        uint256[] calldata, 
        string[] calldata, 
        bytes[] calldata) external;
}

interface NyanV2 {
    function swapNyanV1(uint256) external;
    
    function stakeNyanV2LP(uint256) external;
    
    function unstakeNyanV2LP(uint256) external;
    
    function stakeDNyanV2LP(uint256) external;
    
    function unstakeDNyanV2LP(uint256) external;
    
    function addNyanAndETH(uint256) payable external;
    
    function claimETHLP() external;
    
    function initializeV2ETHPool() external;

}



contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract VotingDataLayout is LibraryLock {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public owner;
    
    uint256 public currentVotingStartBlock;
    uint256 public currentVotingEndBlock;
    bool public isVotingPeriod;
    
    uint256 public votingPeriodBlockLength = 6500;
    uint256 public voteDiv;
    
    struct bid {
        string bidId;
        address bidder;
        string functionCode;
        string functionName;
        uint256 votes;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes[] bytesArr;
        string[] chain;
        uint256 votingRound;
    }
    
    mapping(address => bid) public currentBids;
    
    struct bidChain {
        string id;
        string bidId;
        string functionCode;
        string functionName;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes[] bytesArr;
    }
    
    mapping(string => bidChain) public bidChains;
    
    address public topBidAddress;
    uint256 public topBidVotes;
    bool public isTopBid;
    uint256 public requiredVoteCount;
    uint256 public currentVotingRound;
    uint256 public votePropogationBlocks;
    uint256 public lastVotePropogationBlock;
    
    address[] public proposals;
    
    struct voteTracker {
        uint256 defaultVoteCount;
        uint256 lastBlockChecked;
        uint256 votes;
        uint256 votesUsed;
        bool votesInitialized;
    }
    
    mapping(address => voteTracker) public userVoteTracker;

    uint256 public totalV2LPStaked;
    uint256 public lastDistributionBlock;
    uint256 public currentDistributionEndBlock;
    uint256 public distributionPeriodBuffer = 13000;
    uint256 public distributionPeriodLength = 6500; //measured in blocks
    bool public isDistributing;
    bool public canDistribute;
    bool public isRewardingCatnip;
    
    
    address public currentDistributionAddress;
    uint256 public currentDistributionAmount;
    uint256 public currentDistributionAmountClaimed;
    
    struct distributionClaimed {
        uint256 nyanLocked;
        
    }
    
    mapping(address => distributionClaimed) public claims;
    
    
    address public nyanV2;
    address public nyanV2LP;
    address public catnipV2;
    address public dNyanV2;
    address public nyanV2LPAddress;
    
    address public uniswapRouter;
    
    address public connectorAddress;
    address public fundAddress;
    
    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier _onlyNyanV2() {
        require(msg.sender == nyanV2);
        _;
    }
    
    modifier _onlyConnector() {
        require(msg.sender == connectorAddress);
        _;
    }
    
    modifier _onlyFund() {
        require(msg.sender == fundAddress);
        _;
    }
    
    modifier _updateState(address voter) {
        // save return variables
        uint256 currentTotalVotes = userVoteTracker[voter].defaultVoteCount;
        uint256 newTotalVotes;
        uint256 dNyan;
        uint256 rewards;
        uint256 blockChecked;
        uint256 blockStaked;
        (newTotalVotes,dNyan, rewards, blockChecked, blockStaked) = NyanV2Var(nyanV2).userStake(voter);
        userVoteTracker[voter].lastBlockChecked = blockStaked;
        uint256 votesUsed = userVoteTracker[voter].votesUsed;
        if (!userVoteTracker[voter].votesInitialized || block.number.sub(userVoteTracker[voter].lastBlockChecked) > votePropogationBlocks) {
            userVoteTracker[voter].lastBlockChecked = block.number;
            userVoteTracker[voter].votes = newTotalVotes;
        } else {
            if (currentTotalVotes == 0) {
                userVoteTracker[voter].votes = 0;
            } else {
                userVoteTracker[voter].votes = currentTotalVotes.sub(votesUsed);
            }
        }
        _;
    }

    mapping(address => bool) public isAdmin;
}

contract NyanVoting is Proxiable, VotingDataLayout{
    
    event NewConnector(address indexed connector);
    event logicContractUpdated(address newAddress);
    event IsRewardingCatnip(bool isRewarding);
    event NewVotingPeriodLength(uint256 length, uint256 currentBlock);
    event NewFundingAddress(address indexed fundAddress);
    event NewNyanAddress(address indexed nyanAddress);
    event NewCatnipAddress(address indexed catnipAddress);
    event NewDNyanAddress(address indexed dNyanAddress);
    event NewLPFarmAddress(address indexed nyanLPAddress);
    event SafetyWithdrawalToggled(bool safetyBool);
    event NewBidProposal(address indexed proposer, string bidId, string functionName);
    event NewBidChain(address indexed proposer, string functionName, string bidId, string chainId);
    event NewBidVote(address indexed voter, uint256 votes);
    event VotedNyanWithdrawn(address indexed voter, uint256 nyan);
    event BidExecution(address indexed voter, string bidId);
    event FundsDistribution(address indexed distributedToken, uint256 amount);
    event ClaimDistribution(address indexed claimer, uint256 amountClaimed);
    event WithdrawDistributionNyan(address indexed claimer, uint256 amount);
    event WithdrawDistributionCatnip(address indexed claimer, uint256 amount);
    event CatnipBurn(uint256 catnipBurned);
    
    constructor() public {
       
    }
    
    /** @notice Constructor function for the proxy contract.
      * @param _uniswapRouter  Address of the UniswapV2 contract.
      * @param _nyanV2  Address of the Nyan-2 contract.
      * @param _nyanV2LP  Address of the Nyan-2 LP token contract.
      * @param _voteDiv  Catnip fee per vote.
      */
    function votingConstructor(address _uniswapRouter, address _nyanV2, address _nyanV2LP, uint256 _requiredVoteCount, uint256 _voteDiv) public {
        require(!initialized, "The contract has been initialized");
        owner = msg.sender;
        uniswapRouter = _uniswapRouter;
        currentVotingStartBlock = block.number;
        currentVotingEndBlock = block.number.add(votingPeriodBlockLength);
        nyanV2 = _nyanV2;
        nyanV2LP = _nyanV2LP;
        isDistributing = false;
        canDistribute = true;
        voteDiv = _voteDiv;
        votePropogationBlocks = 6500;
        lastVotePropogationBlock = block.number;
        requiredVoteCount = _requiredVoteCount;
        initialized = true;
    }
    
    /** @notice Updates the logic contract.
      * @param newCode  Address of the new logic contract.
      */
    function updateCode(address newCode) public _onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);
        
        emit logicContractUpdated(newCode);
    }
    
    /** @notice Updates the contract owner.
      * @param _owner Address of the new contract owner.
      */
    function setOwner(address _owner) public _onlyOwner  delegatedOnly {
        owner = _owner;

    }
    
    // /** @notice Updates the connector address.
    //   * @param _connector Address of the new connector address.
    //   */
    // function setConnector(address _connector) public _onlyOwner  delegatedOnly {
    //     connectorAddress = _connector;
        
    //     emit NewConnector(_connector);
    // }
    
    /** @notice Updates the funds address.
      * @param _fund Address of the new logic contract.
      */
    function setFundAddress(address _fund) public _onlyOwner  delegatedOnly {
        fundAddress = _fund;
        
        emit NewFundingAddress(fundAddress);
    }
    
    /** @notice Updates the voting period block length.
      * @param _blocks Voting period length in blocks.
      */
    function setVotingPeriodBlockLength(uint256 _blocks) public _onlyOwner  delegatedOnly {
        votingPeriodBlockLength = _blocks;
        
        emit NewVotingPeriodLength(votingPeriodBlockLength, block.number);
    }
    
    // /** @notice Updates the NyanV2 address.
    //   * @param _addr Voting period length in blocks.
    //   */
    // function setNyanV2Address(address _addr) public _onlyOwner delegatedOnly {
    //     nyanV2 = _addr;
        
    //     emit NewNyanAddress(nyanV2);
    // }
    
    
    /** @notice Updates the catnip fee divider.
      * @param _val Number to divide votes by.
      */
    function setVoteDiv(uint256 _val) public _onlyOwner delegatedOnly _updateState(msg.sender) {
        voteDiv = _val;
    }
    
    /** @notice Triggers when a user stakes NyanV2 LP tokens.
      * @param totalV2LPStaked Number of LP tokens an address has staked.
      * @param voter Address of the staker
      */
     function nyanV2LPStaked(uint256 totalV2LPStaked, address voter) public _onlyNyanV2 delegatedOnly _updateState(voter) {
        userVoteTracker[voter].defaultVoteCount = totalV2LPStaked;
        userVoteTracker[voter].lastBlockChecked = block.number;
    }
    
    /** @notice Triggers when a user unstakes NyanV2 LP tokens.
      * @param totalV2LPStaked Number of LP tokens an address has staked.
      * @param voter Address of the staker
      */
    function nyanV2LPUnstaked(uint256 totalV2LPStaked, address voter) public _onlyNyanV2 delegatedOnly _updateState(msg.sender) {
        userVoteTracker[voter].defaultVoteCount = totalV2LPStaked;
    }
    
    /** @notice Allows anyone to propose a bid.
      * @param bidId address of the bidder.
      * @param _functionCode Code of the interface to use.
      * @param _functionName Name of the function in the interface to use.
      * @param _addresses Array of addresses to use as params.
      * @param _integers Array of integers to use as params.
      * @param _strings Array of strings to use as params.
      * @param _bytesArr Array of bytes to use as params.
      */
    function proposeBid(
        string memory bidId, 
        string memory _functionCode, 
        string memory _functionName,
        address[] memory _addresses,
        uint256[] memory _integers, 
        string[] memory _strings,
        bytes[] memory _bytesArr
        ) public  {
            // require(isVotingPeriod, "Voting period has not started.");
            // require(currentVotingEndBlock >= block.number, "Voting period has ended.");
            
            
            //check bidId
            currentBids[msg.sender].bidId = bidId;
            currentBids[msg.sender].bidder = msg.sender;
            currentBids[msg.sender].functionCode = _functionCode;
            currentBids[msg.sender].functionName = _functionName;
            currentBids[msg.sender].addresses = _addresses;
            currentBids[msg.sender].integers = _integers;
            currentBids[msg.sender].strings = _strings;
            currentBids[msg.sender].bytesArr = _bytesArr;
            
            if (currentBids[msg.sender].votingRound < currentVotingRound) {
                delete currentBids[msg.sender].chain;
            }
            currentBids[msg.sender].votingRound = currentVotingRound;
            currentBids[msg.sender].votes = 0;
            
            bool alreadyExists = false;
            for (uint256 i = 0; i < proposals.length; i++) {
                if (proposals[i] == msg.sender) {
                    alreadyExists = true;
                }
            }
            
            if (!alreadyExists) {
                proposals.push(msg.sender);
            }
            
            emit NewBidProposal(msg.sender, bidId, _functionName);
    }
    
    
    /** @notice Allows anyone to propose a bid.
      * @param id Unique string ID for the chain bid.
      * @param bidId address of the bidder.
      * @param _functionCode Code of the interface to use.
      * @param _functionName Name of the function in the interface to use.
      * @param _addresses Array of addresses to use as params.
      * @param _integers Array of integers to use as params.
      * @param _strings Array of strings to use as params.
      * @param _bytesArr Array of bytes to use as params.
      */
    function addChainBid(
        string memory id, 
        string memory bidId, 
        string memory _functionCode, 
        string memory _functionName, 
        address[] memory _addresses, 
        uint256[] memory _integers, 
        string[] memory _strings, 
        bytes[] memory _bytesArr) 
        public  delegatedOnly {
            //create id internally in the future
            string memory userBid = currentBids[msg.sender].bidId;
            require(keccak256(bytes(userBid)) == keccak256(bytes(bidId)), "This is not your bid");
            
            //verify this
            if (keccak256(bytes(bidChains[id].id)) == keccak256(bytes(id))) {
                require(keccak256(bytes(currentBids[msg.sender].bidId)) == keccak256(bytes(bidChains[id].bidId)));
            }
            
            
            bidChains[id].id = id;
            bidChains[id].bidId = bidId;
            bidChains[id].functionCode = _functionCode;
            bidChains[id].functionName = _functionName;
            bidChains[id].addresses = _addresses;
            bidChains[id].integers = _integers;
            bidChains[id].strings = _strings;
            bidChains[id].bytesArr = _bytesArr;
            
            bool bidExists = false;
            for (uint256 i = 0; i < currentBids[msg.sender].chain.length; i++) {
                if (keccak256(bytes(currentBids[msg.sender].chain[i])) == keccak256(bytes(id))) {
                    bidExists = true;
                }
            }
            if (!bidExists) {
                currentBids[msg.sender].chain.push(id);
            }
            currentBids[msg.sender].votes = 0;
            
            emit NewBidChain(msg.sender, _functionName, bidId, id);
    }
    
    /** @notice Return array of current proposal addresses.
      */
    function getProposals() view public returns(address[] memory) {
        return proposals;
    }
    
    /** @notice Vote for an individual proposal.
      * @param _bidAddr Address of the proposal to vote for.
      * @param _votes Number of votes to apply to proposal.
      */
    function voteForBid(address _bidAddr, uint256 _votes) public _updateState(msg.sender) delegatedOnly {
        require(_votes <= userVoteTracker[msg.sender].votes, "Insufficient amount of votes");
        IERC20(catnipV2).safeTransferFrom(msg.sender, address(this), determineCatnipCost(_votes));
        
        currentBids[_bidAddr].votes = currentBids[_bidAddr].votes.add(_votes);
        
        if ((currentBids[_bidAddr].votes > topBidVotes) && (topBidAddress != _bidAddr)) {
            topBidAddress = _bidAddr;
            topBidVotes = currentBids[_bidAddr].votes;
            isTopBid = true;
        }
        
        emit NewBidVote(msg.sender, _votes);
        
    }
    
    /** @notice Returns proposal details of a specific proposal.
      * @param _address Address of a specific proposal.
      */
    function getBid(address _address) public view returns(
            string memory,
            string memory,
            address[] memory,
            uint256[] memory,
            string[] memory,
            // // bytes[] memory,
            string[] memory,
            uint256
            )
        {
            return (
                  currentBids[_address].functionCode,
                  currentBids[_address].functionName,
                  currentBids[_address].addresses,
                  currentBids[_address].integers,
                  currentBids[_address].strings,
                // //   currentBids[_address].bytesArr,
                  currentBids[_address].chain,
                  currentBids[_address].votes
                );
    }
    
    /** @notice Returns chain details of a specific chain bid.
      * @param id Id of a specific proposal.
      */
    function getChain(string memory id) public view returns(
        string memory, 
        string memory,
        string memory,
        address[] memory,
        uint256[] memory,
        string[] memory
        // bytes[] memory
        ) 
        {
            return(
                    bidChains[id].id,
                    bidChains[id].functionCode,
                    bidChains[id].functionName,
                    bidChains[id].addresses,
                    bidChains[id].integers,
                    bidChains[id].strings
                    // bidChains[id].bytesArr
                );
    }
    
    /** @notice Returns amount of votes an address has used.
      * @param _address Address of a specific voter.
      */
    function getVotesUsed(address _address) public view returns(uint256) {
        return userVoteTracker[_address].votesUsed;
    }
    
    /** @notice Returns the cost of an amount of votes.
      * @param _votes Number of votes being used.
      */
    function determineCatnipCost(uint256 _votes) view public returns(uint256) {
        return _votes.div(voteDiv);
    } 

    /** @notice Public function that allows anyone to execute the current top bid.
      */
    function executeBid() public _updateState(msg.sender) {   
        if (isAdmin[msg.sender]) {
            require(currentVotingEndBlock < block.number, "Voting period is still active.");
        }
        currentVotingStartBlock = block.number + 10;
        currentVotingEndBlock = currentVotingStartBlock.add(votingPeriodBlockLength);
        NConnector connectorContract = NConnector(connectorAddress);
        NFund fundContract = NFund(fundAddress);
        if (isTopBid) {
            if (isAdmin[msg.sender]) {
                require(currentBids[topBidAddress].votes >= requiredVoteCount, "The top bid needs more votes");
            }
            connectorContract.executeBid(
                    currentBids[topBidAddress].functionCode,
                    currentBids[topBidAddress].functionName,
                    currentBids[topBidAddress].addresses,
                    currentBids[topBidAddress].integers,
                    currentBids[topBidAddress].strings,
                    currentBids[topBidAddress].bytesArr
                );
                                                 
            
            for (uint256 c = 0; c<currentBids[topBidAddress].chain.length; c++) {
                connectorContract.executeBid(
                    bidChains[currentBids[topBidAddress].chain[c]].functionCode,
                                                                    bidChains[currentBids[topBidAddress].chain[c]].functionName,
                                                                    bidChains[currentBids[topBidAddress].chain[c]].addresses,
                                                                    bidChains[currentBids[topBidAddress].chain[c]].integers,
                                                                    bidChains[currentBids[topBidAddress].chain[c]].strings,
                                                                    bidChains[currentBids[topBidAddress].chain[c]].bytesArr);
                
            }
        }
        
        //move voting round stuff to modifier 
        currentVotingRound = currentVotingRound.add(1);
        //increase Round in funding contract
        fundContract.newVotingRound();
        delete proposals;
        topBidAddress = address(0);
        topBidVotes = 0;
        isTopBid = false;
        
        //function to send back leftover tokens to fund from connector
        
        
        emit BidExecution(currentBids[topBidAddress].bidder, currentBids[topBidAddress].bidId);                                               
    }
    
    /** @notice Returns proposal details of a specific proposal.
      * @param _addr Address of the token to distribute.
      * @param _amount Amount of the token to distribute.
      */
    function distributeFunds(address _addr, uint256 _amount) public _onlyConnector _updateState(msg.sender) delegatedOnly {
        NFund fundContract = NFund(fundAddress);
        //Check that isDistributing is false
        require(!isDistributing, "Already in distribution period");
        //Check that it has been more than 1 day since last distribution
        require((block.number - currentDistributionEndBlock) > distributionPeriodBuffer, "Too early for distribution");
        //Set distribution block to current block
        lastDistributionBlock = block.number;
        //Set end block for current distribution
        currentDistributionEndBlock = block.number + distributionPeriodLength;
        
        currentDistributionAmountClaimed = 0;
        //get funds from NyanFund
        fundContract.approveSpendERC20(_addr, _amount);
        //set current distribution amount
        
        emit FundsDistribution(_addr, _amount);
    }
    
    /** @notice Claims distribution share for the message sender.
      */
    function claimDistribution() public _updateState(msg.sender) delegatedOnly {
        require(isDistributing && currentVotingEndBlock>block.number, "You are not in a distribution period");
        uint256 nyanV2LPStakedAmount = userVoteTracker[msg.sender].defaultVoteCount;
        uint256 nyanV2LPSupply = ERC20(nyanV2LPAddress).totalSupply();
        
        uint256 numerator = nyanV2LPStakedAmount.mul(currentDistributionAmount);
        require(numerator > nyanV2LPSupply);
        uint256 claimedAmount = numerator.div(nyanV2LPSupply);
        IERC20(currentDistributionAddress).safeTransfer(msg.sender, claimedAmount);
        currentDistributionAmountClaimed = currentDistributionAmountClaimed.add(claimedAmount);
        
        emit ClaimDistribution(msg.sender, claimedAmount);
    }
    
    /** @notice Ends the distribution period.
      */
    function endDistribution() public _onlyConnector _updateState(msg.sender) delegatedOnly {
        isDistributing = false;
        
        
    }

    function getVotes(address voter) public view returns(uint256) {
        // save return variables
        uint256 currentTotalVotes = userVoteTracker[voter].defaultVoteCount;
        uint256 newTotalVotes;
        uint256 dNyan;
        uint256 rewards;
        uint256 blockChecked;
        uint256 blockStaked;
        (newTotalVotes,dNyan, rewards, blockChecked, blockStaked) = NyanV2Var(nyanV2).userStake(voter);
        uint256 votesUsed = userVoteTracker[voter].votesUsed;
        if (!userVoteTracker[voter].votesInitialized || block.number.sub(userVoteTracker[voter].lastBlockChecked) > votePropogationBlocks) {
            return newTotalVotes;
        } else {
            if (currentTotalVotes == 0) {
                return 0;
            } else {
                return currentTotalVotes.sub(votesUsed);
            }
        }
    }

    function setAdmin(address admin, bool setting) public _onlyOwner {
        isAdmin[admin] = setting;
    }

    function setRequiredVotes(uint256 amount) public _onlyOwner {
        requiredVoteCount = amount;
    }
    
    
    receive() external payable {
        
    }
    

}

contract NyanV2Var {
    // Track user's staked Nyan LP
    struct stakeTracker {
        uint256 stakedNyanV2LP;
        uint256 stakedDNyanV2LP;
        uint256 nyanV2Rewards;
        uint256 lastBlockChecked;
        uint256 blockStaked;
    }
    mapping(address => stakeTracker) public userStake;
}
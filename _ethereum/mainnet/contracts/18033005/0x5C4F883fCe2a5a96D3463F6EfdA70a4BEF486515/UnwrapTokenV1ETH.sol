pragma solidity 0.6.12;

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-labs/blob/3887ab77b8adafba4a26ace002f3a684c1a3388b/upgradeability_ownership/contracts/ownership/Ownable.sol
 * Modifications:
 * 1. Consolidate OwnableStorage into this contract (7/13/18)
 * 2. Reformat, conform to Solidity 0.6 syntax, and add error messages (5/13/20)
 * 3. Make public functions external (5/27/20)
 */
contract Ownable {
    // Owner of the contract
    address private _owner;

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() public {
        setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}


// File centre-tokens/contracts/v1/Blacklistable.sol@v1.0.0

/**
 * 
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.6.12;

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 */
contract Blacklistable is Ownable {
    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        require(
            msg.sender == blacklister,
            "Blacklistable: caller is not the blacklister"
        );
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function blacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function unBlacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) external onlyOwner {
        require(
            _newBlacklister != address(0),
            "Blacklistable: new blacklister is the zero address"
        );
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }
}


// File centre-tokens/contracts/v1/Pausable.sol@v1.0.0

/**
 * 
 *
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Copyright (c) 2018-2020 CENTRE SECZ0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.6.12;

/**
 * @notice Base contract which allows children to implement an emergency stop
 * mechanism
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/feb665136c0dae9912e08397c1a21c4af3651ef3/contracts/lifecycle/Pausable.sol
 * Modifications:
 * 1. Added pauser role, switched pause/unpause to be onlyPauser (6/14/2018)
 * 2. Removed whenNotPause/whenPaused from pause/unpause (6/14/2018)
 * 3. Removed whenPaused (6/14/2018)
 * 4. Switches ownable library to use ZeppelinOS (7/12/18)
 * 5. Remove constructor (7/13/18)
 * 6. Reformat, conform to Solidity 0.6 syntax and add error messages (5/13/20)
 * 7. Make public functions external (5/27/20)
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    event PauserChanged(address indexed newAddress);

    address public pauser;
    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == pauser, "Pausable: caller is not the pauser");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyPauser {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyPauser {
        paused = false;
        emit Unpause();
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) external onlyOwner {
        require(
            _newPauser != address(0),
            "Pausable: new pauser is the zero address"
        );
        pauser = _newPauser;
        emit PauserChanged(pauser);
    }
}


// File @openzeppelin/contracts/math/SafeMath.sol@v3.1.0

// 

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


// File contracts/wrapped-tokens/staking/UnwrapTokenV1.sol

// 
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;



/**
 * @title UnwrapTokenV1
 * @notice Used For Unwap WBETH to ETH, version 1
 */
contract UnwrapTokenV1 is Pausable, Blacklistable {
    using SafeMath for uint256;

    uint256 public constant MIN_LOCK_TIME = 2 days; // 2*24*3600 second
    uint256 public constant MAX_LOOP_NUM = 1000; // max loop number
    address public constant WBETH_TOKEN_ADDRESS = 0xa2E3356610840701BDf5611a53974510Ae27E2e1;

    bool internal initialized; // init once

    uint256 public ethStaked; // eth staked amount

    address public operatorAddress; // trigger allocated

    address public rechargeAddress; // recharge eth when insufficient

    address public ethBackAddress; // If it has extra eth, Operator can transfer back to this address

    uint256 public lockTime; // init lock time

    struct WithdrawRequest {
        address recipient; // user who withdraw
        uint256 wbethAmount; //WBETH
        uint256 ethAmount; //ETH
        uint256 triggerTime; //user trigger time
        uint256 claimTime; //user claim time
        bool allocated;  //is it allocated
    }
    uint256 public startAllocatedEthIndex; //If new ETH send, just allocated start with this index

    uint256 public nextIndex; // user request index

    mapping(uint256 => WithdrawRequest) private withdrawRequests; // all request queue

    mapping(address => uint256[]) private userWithdrawRequests; // user request withdraw

    uint256 public availableAllocateAmount; // the amount can allocated to new user

    uint256 public needEthAmount; // the eth amount that need to be allocated for user

    /**
     * @dev Emitted when the operator is updated
     * @param newOperator The new Operator
     */
    event OperatorUpdated(address indexed newOperator);

    /**
     * @dev Emitted when the recharge address is updated
     * @param newRechargeAddress The new newChargeAddress
     */
    event RechargeAddressUpdated(address indexed newRechargeAddress);

    /**
     * @dev Emitted when the eth return back address is updated
     * @param newEthBackAddress The new ethBackAddress
     */
    event EthBackAddressUpdated(address indexed newEthBackAddress);

    /**
     * @dev Emitted when the lock time is updated
     * @param operatorAddress The operator address
     * @param newLockTime The new newLockTime
     */
    event LockTimeUpdated(address indexed operatorAddress, uint256 newLockTime);

    /**
     * @dev Emitted when request withdraw
     * @param recipient The recipient request the event
     * @param wbethAmount The recipient request wbethAmount
     * @param ethAmount The recipient will get
     * @param index At the queue index
     */
    event RequestWithdraw(address indexed recipient, uint256 wbethAmount, uint256 ethAmount, uint256 index);

    /**
     * @dev Emitted when user claim eth
     * @param recipient The user can get eth
     * @param ethAmount The recipient will get eth amount
     * @param index At the user's request list
     */
    event ClaimWithdraw(address indexed recipient, uint256 ethAmount, uint256 index);

    /**
     * @dev Emitted when operator triggers to allocate eth
     * @param operator The operator can trigger
     * @param nextAllocateEthIndex The next index that  start to allocate eth
     */
    event Allocate(address indexed operator, uint256 nextAllocateEthIndex);

    /**
     * @dev Emitted when recharge eth from recharge address
     * @param rechargeAddress The recharge address
     * @param ethAmount  the Recharge eth amount
     */
    event RechargeFromRechargeAddress(address indexed rechargeAddress, uint256 ethAmount);

    /**
     * @dev Emitted when move eth from wbeth token contract address
     * @param wrapTokenAddress The wbeth token address
     * @param ethAmount the eth amount
     */
    event MoveFromWrapContract(address indexed wrapTokenAddress, uint256 ethAmount);

    /**
     * @dev Emitted when move eth to eth back address
     * @param ethBackAddress The receive eth address
     * @param ethAmount the eth amount
     */
    event MoveToEthBackAddress(address indexed ethBackAddress, uint256 ethAmount);

    /**
     * @dev Emitted when the eth staked amount is updated
     * @param operatorAddress The operatorAddress
     * @param ethStakedAmount The eth staked amount
     */
    event EthStakedUpdated(address indexed operatorAddress, uint256 ethStakedAmount);

    function initialize(
        address _newOperatorAddress,
        address _newEthBackAddress,
        address _newRechargeAddress,
        address _newPauser,
        address _newBlacklister,
        address _newOwner
    ) public {
        require(!initialized, "UnwrapTokenV1: contract is already initialized");

        require(
            _newOperatorAddress != address(0),
            "UnwrapTokenV1: new operatorAddress is the zero address"
        );
        require(
            _newEthBackAddress != address(0),
            "UnwrapTokenV1: new ethBackAddress is the zero address"
        );
        require(
            _newRechargeAddress != address(0),
            "UnwrapTokenV1: new rechargeAddress is the zero address"
        );

        require(
            _newPauser != address(0),
            "UnwrapTokenV1: new pauser is the zero address"
        );
        require(
            _newBlacklister != address(0),
            "UnwrapTokenV1: new blacklister is the zero address"
        );
        require(
            _newOwner != address(0),
            "UnwrapTokenV1: new owner is the zero address"
        );
        ethBackAddress = _newEthBackAddress;
        operatorAddress = _newOperatorAddress;
        rechargeAddress = _newRechargeAddress;
        pauser = _newPauser;
        blacklister = _newBlacklister;
        setOwner(_newOwner);
        lockTime = MIN_LOCK_TIME;
        initialized = true;
    }

    /**
     * @dev Emitted when request withdraw eth from WBETH contract
     * @param _recipient The user can receive eth
     * @param _wbethAmount the wbeth amount user send
     * @param _ethAmount the eth amount user will receive
     */
    function requestWithdraw(address _recipient, uint256 _wbethAmount, uint256 _ethAmount)
        external onlyWrapTokenAddress {
        require(_recipient != address(0), "_recipient is the zero address");
        require(_ethAmount > 0, "eth amount is zero");

        uint256 _currentIndex = nextIndex++;
        bool _allocated = false;
        if (availableAllocateAmount >= _ethAmount && startAllocatedEthIndex == _currentIndex) {
            _allocated = true;
            availableAllocateAmount = availableAllocateAmount.sub(_ethAmount);
            startAllocatedEthIndex++;
        } else {
            needEthAmount = needEthAmount.add(_ethAmount);
        }
        withdrawRequests[_currentIndex] = WithdrawRequest({
            recipient: _recipient,
            wbethAmount: _wbethAmount,
            ethAmount: _ethAmount,
            triggerTime: block.timestamp,
            claimTime: 0,
            allocated: _allocated
        });
        userWithdrawRequests[_recipient].push(
            _currentIndex
        );
        emit RequestWithdraw(_recipient, _wbethAmount, _ethAmount, _currentIndex);
    }

    /**
     * @dev Retrieves all withdraw requests initiated by the given address
     * @param _recipient - Address of an user
     * @return WithdrawRequest array of user withdraw requests NO more then 1000
     */
    function getUserWithdrawRequests(address _recipient)
    external
    view
    returns (WithdrawRequest[] memory)
    {
        uint256[] memory _userRequests = userWithdrawRequests[_recipient];
        uint256 _length = _userRequests.length;
        if (_length > MAX_LOOP_NUM) {
            _length = MAX_LOOP_NUM;
        }
        WithdrawRequest[] memory _userDetailRequests = new WithdrawRequest[](_length);
        for (uint256 i = 0; i < _length; i++) {
            uint256 _allocateIndex = _userRequests[i];
            _userDetailRequests[i] = withdrawRequests[_allocateIndex];
        }
        return _userDetailRequests;
    }


    /**
     * @dev Retrieves withdraw requests by index
     * @param _startIndex - the startIndex
     * @return WithdrawRequest array of user withdraw requests
     */
    function getWithdrawRequests(uint256 _startIndex)
    external
    view
    returns (WithdrawRequest[] memory)
    {
        require(_startIndex < nextIndex, "Wrong start Index");
        uint256 _length = nextIndex.sub(_startIndex);
        if (_length > MAX_LOOP_NUM) {
            _length = MAX_LOOP_NUM;
        }
        WithdrawRequest[] memory _detailWithdrawRequests = new WithdrawRequest[](_length);
        for (uint256 i = 0; i < _length; i++) {
            uint256 _index = _startIndex.add(i);
            _detailWithdrawRequests[i] = withdrawRequests[_index];
        }
        return _detailWithdrawRequests;
    }

    /**
     * @dev claim the allocated eth
     * @param _index the index to claim
     * @return the eth amount
     */
    function claimWithdraw(uint256 _index) external whenNotPaused
            notBlacklisted(msg.sender) returns (uint256)
    {
        address _user = msg.sender;
        uint256[] storage _userRequests = userWithdrawRequests[_user];
        require(_index < _userRequests.length, "Invalid index");

        uint256 _allocateIndex = _userRequests[_index];
        WithdrawRequest storage _withdrawRequest = withdrawRequests[_allocateIndex];
        uint256 _ethAmount = _withdrawRequest.ethAmount;

        require(_withdrawRequest.recipient == _user, "Wrong recipient");
        require(block.timestamp >= _withdrawRequest.triggerTime.add(lockTime), "Claim time not reach");
        require(_withdrawRequest.allocated, "Not allocated yet");
        require(_withdrawRequest.claimTime == 0, "Already claim yet");
        require(_getCurrentBalance() >= _ethAmount, "Not enough balance");

        if (_userRequests.length > 1) {
            _userRequests[_index] = _userRequests[_userRequests.length - 1];
        }
        _userRequests.pop();

        _withdrawRequest.claimTime = block.timestamp;
        _transferEth(_user, _ethAmount);
        emit ClaimWithdraw(_user, _ethAmount, _allocateIndex);
        return _ethAmount;
    }

    /**
     * @dev allocated eth to every request
     * @param _maxAllocateNum the max number
     * @return the next allocate eth index
     */
    function allocate(uint256 _maxAllocateNum) external whenNotPaused onlyOperator returns (uint256)
    {
        require(needEthAmount > 0 && availableAllocateAmount > 0, "No need allocated or no more availableAllocateAmount ");
        require(_maxAllocateNum <= MAX_LOOP_NUM, "Too big number > 1000");
        require(startAllocatedEthIndex < nextIndex, "Not need allocated");

        for (uint256 _reqCount = 0; _reqCount < _maxAllocateNum && startAllocatedEthIndex < nextIndex &&
                                withdrawRequests[startAllocatedEthIndex].ethAmount <= availableAllocateAmount;
            _reqCount++
        ) {
            WithdrawRequest storage _withdrawRequest = withdrawRequests[startAllocatedEthIndex];
            _withdrawRequest.allocated = true;

            availableAllocateAmount = availableAllocateAmount.sub(_withdrawRequest.ethAmount);
            needEthAmount = needEthAmount.sub(_withdrawRequest.ethAmount);

            startAllocatedEthIndex++;
        }
        emit Allocate(operatorAddress, startAllocatedEthIndex);
        return startAllocatedEthIndex;
    }

    /**
    * @dev get need recharge eth amount
     */
    function getNeedRechargeEthAmount() external view returns (uint256) {
        if (availableAllocateAmount >= needEthAmount) {
            return 0;
        } else {
            return needEthAmount.sub(availableAllocateAmount);
        }
    }

    /**
    * @dev get eth balance of contract
     */
    function _getCurrentBalance() internal view virtual returns (uint256) {
        return address(this).balance;
    }

    /**
    * @dev Function to transfer eth to sender
     * @param _ethAmount The eth amount
     */
    function _transferEth(address _recipient, uint256 _ethAmount) internal virtual {
        (bool success, ) = payable(_recipient).call{value: _ethAmount}("");
        require(success, "transfer failed");
    }

    /**
    * @dev Function to update the operatorAddress
     * @param _newOperatorAddress The new botAddress
     */
    function setNewOperator(address _newOperatorAddress) external onlyOwner {
        require(_newOperatorAddress != address(0), "zero address provided");
        operatorAddress = _newOperatorAddress;
        emit OperatorUpdated(_newOperatorAddress);
    }

    /**
    * @dev Function to update the rechargeAddress
     * @param _newRechargeAddress The new rechargeAddress
     */
    function setRechargeAddress(address _newRechargeAddress) external onlyOwner {
        require(_newRechargeAddress != address(0), "zero address provided");
        rechargeAddress = _newRechargeAddress;
        emit RechargeAddressUpdated(_newRechargeAddress);
    }

    /**
    * @dev Function to update the ethBackAddress
     * @param _newEthBackAddress The new ethBackAddress
     */
    function setEthBackAddress(address _newEthBackAddress) external onlyOwner {
        require(_newEthBackAddress != address(0), "zero address provided");
        ethBackAddress = _newEthBackAddress;
        emit EthBackAddressUpdated(_newEthBackAddress);
    }

    /**
    * @dev Function to update the lock time
     * @param _newLockTime The new lock time
     */
    function setLockTime(uint256 _newLockTime) external onlyOperator {
        require(_newLockTime >= MIN_LOCK_TIME, "LockTime is too small");
        lockTime = _newLockTime;
        emit LockTimeUpdated(operatorAddress, lockTime);
    }

    /**
    * @dev Function to update the eth staked amount
     * @param _newEthStakedAmount new eth staked amount
     */
    function setNewEthStaked(uint256 _newEthStakedAmount) external onlyOperator {
        require(ethStaked != _newEthStakedAmount, "ethStaked not change");
        ethStaked = _newEthStakedAmount;
        emit EthStakedUpdated(msg.sender, _newEthStakedAmount);
    }

    /**
     * @dev Throws if called by any account other than the WBETH token address
     */
    modifier onlyWrapTokenAddress() {
        require(
            msg.sender == WBETH_TOKEN_ADDRESS,
            "UnwrapTokenV1: caller is not the WrapTokenAddress"
        );
        _;
    }

    /**
    * @dev Throws if called by any account other than operator address
     */
    modifier onlyOperator() {
        require(
            msg.sender == operatorAddress,
            "UnwrapTokenV1: caller is not the BOT_ADDRESS"
        );
        _;
    }
    /**
    * @dev Throws if called by any account other than recharge eth address
     */
    modifier onlyRechargeAddress() {
        require(
            msg.sender == rechargeAddress,
            "UnwrapTokenV1: caller is not the RECHARGE_ADDRESS"
        );
        _;
    }

    receive() external payable {

    }

    uint256[50] private __reserve_slots;
}


// File contracts/wrapped-tokens/staking/UnwrapTokenV1ETH.sol

//
pragma solidity 0.6.12;

/**
 * @title UnwrapTokenV1ETH
 * @notice Ethers Chain
 */
contract UnwrapTokenV1ETH is UnwrapTokenV1 {

    /**
     * @dev gas limit of eth transfer.
     */
    uint256 private constant _ETH_TRANSFER_GAS = 5000;

    function rechargeFromRechargeAddress() external payable whenNotPaused onlyRechargeAddress{
        _rechargeAmount(msg.value);
        emit RechargeFromRechargeAddress(msg.sender, msg.value);
    }

    /**
     * @dev Function to move eth to the ethBackAddress
     * @param _amount The eth amount to move
     */
    function moveToBackAddress(uint256 _amount) external onlyOperator {
        require(_amount > 0, "amount cannot be 0");
        require(ethBackAddress != address(0), "zero ethBackAddress");

        uint256 _canBackAmount = availableAllocateAmount.sub(needEthAmount);
        require(_amount <= _canBackAmount, "surplus balance not enough");
        require(_amount <= _getCurrentBalance(), "balance not enough");
        availableAllocateAmount = availableAllocateAmount.sub(_amount);

        (bool success, ) = ethBackAddress.call{value: _amount, gas: _ETH_TRANSFER_GAS}("");
        require(success, "transfer failed");

        emit MoveToEthBackAddress(ethBackAddress, _amount);
    }

    function moveFromWrapContract() external payable whenNotPaused onlyWrapTokenAddress{
        _rechargeAmount(msg.value);
        emit MoveFromWrapContract(msg.sender, msg.value);
    }

    function _rechargeAmount(uint256 _ethAmount) internal {
        require(_ethAmount > 0, "Invalid _ethAmount");
        availableAllocateAmount = availableAllocateAmount.add(_ethAmount);
        require(_getCurrentBalance() >= availableAllocateAmount, "Invalid AvailableAllocateAmount");
    }
}
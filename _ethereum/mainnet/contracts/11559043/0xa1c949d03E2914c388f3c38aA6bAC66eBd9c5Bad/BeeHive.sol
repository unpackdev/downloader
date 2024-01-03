pragma solidity ^0.6.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes memory) {this;return msg.data;}}
contract Ownable is Context {address private _owner;event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {address msgSender = _msgSender();_owner = msgSender;emit OwnershipTransferred(address(0), msgSender);}
    function owner() public view returns (address) {return _owner;}modifier onlyOwner() {require(_owner == _msgSender(), "Ownable: caller is not the owner");_;}
    function renounceOwnership() public virtual onlyOwner {emit OwnershipTransferred(_owner, address(0));_owner = address(0);}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");emit OwnershipTransferred(_owner, newOwner);_owner = newOwner;}}
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {return a >= b ? a : b;}
    function min(uint256 a, uint256 b) internal pure returns (uint256) {return a < b ? a : b;}
    function average(uint256 a, uint256 b) internal pure returns (uint256) {return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);}}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);uint256 c = a / b;return c;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}}
library Address {
    function isContract(address account) internal view returns (bool) {uint256 size;assembly { size := extcodesize(account) }return size > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");require(success, "Address: unable to send value, recipient may have reverted");}
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return _functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {require(address(this).balance >= value, "Address: insufficient balance for call");return _functionCallWithValue(target, data, value, errorMessage);}
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {require(isContract(target), "Address: call to non-contract");(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);if (success) {return returndata;} else {if (returndata.length > 0) {assembly {let returndata_size := mload(returndata)revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}}}
library SafeERC20 {using SafeMath for uint256;using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));}
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));}
    function safeApprove(IERC20 token, address spender, uint256 value) internal {require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));}
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {uint256 newAllowance = token.allowance(address(this), spender).add(value);_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));}
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));}
    function _callOptionalReturn(IERC20 token, bytes memory data) private {bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");if (returndata.length > 0) { (abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");}}}
contract Pausable is Context {event Paused(address account);event Unpaused(address account);bool private _paused;constructor () internal {_paused = false;}
    function paused() public view returns (bool) {return _paused;}modifier whenNotPaused() {require(!_paused, "Pausable: paused");_;}modifier whenPaused() {require(_paused, "Pausable: not paused");_;}
    function _pause() internal virtual whenNotPaused {_paused = true;emit Paused(_msgSender());}
    function _unpause() internal virtual whenPaused {_paused = false;emit Unpaused(_msgSender());}}
contract ReentrancyGuard {uint256 private constant _NOT_ENTERED = 1;uint256 private constant _ENTERED = 2;uint256 private _status;constructor () internal {_status = _NOT_ENTERED;}
    modifier nonReentrant() {require(_status != _ENTERED, "ReentrancyGuard: reentrant call");_status = _ENTERED;_;_status = _NOT_ENTERED;}}
contract BeeHive is ReentrancyGuard, Pausable, Ownable {using SafeMath for uint256;using SafeERC20 for IERC20;IERC20 public rewardsToken;IERC20 public stakingToken;uint256 public periodFinish;uint256 public rewardRate;uint256 public rewardsDuration;uint256 public lastUpdateTime;uint256 public rewardPerTokenStored;mapping(address => uint) public locks;uint256 public lpLockDays;mapping(address => uint256) public userRewardPerTokenPaid;mapping(address => uint256) public rewards;uint256 private _totalSupply;mapping(address => uint256) private _balances;
    constructor(address _rewardsToken, address _stakingToken, uint256 _rewardsDuration, uint256 _lpLockDays)public Ownable() {rewardsToken = IERC20(_rewardsToken);stakingToken = IERC20(_stakingToken);rewardsDuration = _rewardsDuration;lpLockDays = _lpLockDays;_pause();}
    function totalSupply() external view returns (uint256) {return _totalSupply;}
    function balanceOf(address account) external view returns (uint256) {return _balances[account];}
    function lastTimeRewardApplicable() public view returns (uint256) {return Math.min(block.timestamp, periodFinish);}
    function rewardPerToken() public view returns (uint256) {if (_totalSupply == 0) {return rewardPerTokenStored;}return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));}
    function earned(address account) public view returns (uint256) {return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);}
    function getRewardForDuration() external view returns (uint256) {return rewardRate.mul(rewardsDuration);}
    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {require(amount > 0, "Cannot stake 0");_totalSupply = _totalSupply.add(amount);_balances[msg.sender] = _balances[msg.sender].add(amount);stakingToken.safeTransferFrom(msg.sender, address(this), amount);locks[msg.sender] = block.timestamp + lpLockDays;emit Staked(msg.sender, amount);}
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {require(amount > 0, "Cannot withdraw 0");require(locks[msg.sender] < now, "locked");_totalSupply = _totalSupply.sub(amount);_balances[msg.sender] = _balances[msg.sender].sub(amount);stakingToken.safeTransfer(msg.sender, amount);emit Withdrawn(msg.sender, amount);}
    function getReward() public nonReentrant updateReward(msg.sender) {uint256 reward = rewards[msg.sender];if (reward > 0) {rewards[msg.sender] = 0;rewardsToken.safeTransfer(msg.sender, reward);emit RewardPaid(msg.sender, reward);}}
    function exit() external {withdraw(_balances[msg.sender]);getReward();}
    function unpause() external onlyOwner {super._unpause();}
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {if (block.timestamp >= periodFinish) {rewardRate = reward.div(rewardsDuration);} else {uint256 remaining = periodFinish.sub(block.timestamp);uint256 leftover = remaining.mul(rewardRate);rewardRate = reward.add(leftover).div(rewardsDuration);}uint balance = rewardsToken.balanceOf(address(this));require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");lastUpdateTime = block.timestamp;periodFinish = block.timestamp.add(rewardsDuration);emit RewardAdded(reward);}
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken),"Cannot withdraw the staking or rewards tokens");IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);emit Recovered(tokenAddress, tokenAmount);}modifier updateReward(address account) {rewardPerTokenStored = rewardPerToken();lastUpdateTime = lastTimeRewardApplicable();if (account != address(0)) {rewards[account] = earned(account);userRewardPerTokenPaid[account] = rewardPerTokenStored;}_;}event RewardAdded(uint256 reward);event Staked(address indexed user, uint256 amount);event Withdrawn(address indexed user, uint256 amount);event RewardPaid(address indexed user, uint256 reward);event Recovered(address token, uint256 amount);}
pragma solidity >=0.4.21 <0.7.0;



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}





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
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}








/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, _msgSender(), _allowances[from][_msgSender()].sub(value));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
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
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount));
    }

    uint256[50] private ______gap;
}







/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}
















contract ClusterRewards is Initializable, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) public clusterRewards;

    mapping(bytes32 => uint256) public rewardWeight;
    uint256 totalWeight;
    uint256 totalRewardsPerEpoch;
    uint256 payoutDenomination;

    address rewardDelegatorsAddress;
    ERC20 POND;
    address feeder;

    event NetworkAdded(bytes32 networkId, uint256 rewardPerEpoch);
    event NetworkRemoved(bytes32 networkId);
    event NetworkRewardUpdated(bytes32 networkId, uint256 updatedRewardPerEpoch);
    event ClusterRewarded(bytes32 networkId);

    modifier onlyRewardDelegatorsContract() {
        require(msg.sender == rewardDelegatorsAddress, "Sender not Reward Delegators contract");
        _;
    }

    modifier onlyFeeder() {
        require(msg.sender == feeder, "Sender not feeder");
        _;
    }

    function initialize(
        address _owner, 
        address _rewardDelegatorsAddress, 
        bytes32[] memory _networkIds,
        uint256[] memory _rewardWeight,
        uint256 _totalRewardsPerEpoch, 
        address _PONDAddress,
        uint256 _payoutDenomination,
        address _feeder) 
        public
        initializer
    {
        require(
            _networkIds.length == _rewardWeight.length, 
            "ClusterRewards:initialize - Each NetworkId need a corresponding RewardPerEpoch and vice versa"
        );
        super.initialize(_owner);
        uint256 weight = 0;
        rewardDelegatorsAddress = _rewardDelegatorsAddress;
        for(uint256 i=0; i < _networkIds.length; i++) {
            rewardWeight[_networkIds[i]] = _rewardWeight[i];
            weight = weight.add(_rewardWeight[i]);
            emit NetworkAdded(_networkIds[i], _rewardWeight[i]);
        }
        totalWeight = weight;
        totalRewardsPerEpoch = _totalRewardsPerEpoch;
        POND = ERC20(_PONDAddress);
        payoutDenomination = _payoutDenomination;
        feeder = _feeder;
    }

    function changeFeeder(address _newFeeder) public onlyOwner {
        feeder = _newFeeder;
    }

    function addNetwork(bytes32 _networkId, uint256 _rewardWeight) public onlyOwner {
        require(rewardWeight[_networkId] == 0, "ClusterRewards:addNetwork - Network already exists");
        require(_rewardWeight != 0, "ClusterRewards:addNetwork - Reward can't be 0");
        rewardWeight[_networkId] = _rewardWeight;
        totalWeight = totalWeight.add(_rewardWeight);
        emit NetworkAdded(_networkId, _rewardWeight);
    }

    function removeNetwork(bytes32 _networkId) public onlyOwner {
        uint256 networkWeight = rewardWeight[_networkId];
        require( networkWeight != 0, "ClusterRewards:removeNetwork - Network doesn't exist");
        delete rewardWeight[_networkId];
        totalWeight = totalWeight.sub(networkWeight);
        emit NetworkRemoved(_networkId);
    }

    function changeNetworkReward(bytes32 _networkId, uint256 _updatedRewardWeight) public onlyOwner {
        uint256 networkWeight = rewardWeight[_networkId];
        require( networkWeight != 0, "ClusterRewards:changeNetworkRewards - Network doesn't exists");
        rewardWeight[_networkId] = _updatedRewardWeight;
        totalWeight = totalWeight.sub(networkWeight).add(_updatedRewardWeight);
        emit NetworkRewardUpdated(_networkId, _updatedRewardWeight);
    }

    function feed(bytes32 _networkId, address[] memory _clusters, uint256[] memory _payouts) public onlyFeeder {
        for(uint256 i=0; i < _clusters.length; i++) {
            clusterRewards[_clusters[i]] = clusterRewards[_clusters[i]].add(
                                                totalRewardsPerEpoch
                                                .mul(rewardWeight[_networkId])
                                                .mul(_payouts[i])
                                                .div(totalWeight)
                                                .div(payoutDenomination)
                                            );
        }
        emit ClusterRewarded(_networkId);
    }

    function getRewardPerEpoch(bytes32 _networkId) public view returns(uint256) {
        return totalRewardsPerEpoch.mul(rewardWeight[_networkId]).div(totalWeight);
    }

    // only cluster registry is necessary because the rewards 
    // should be updated in the cluster registry against the cluster
    function claimReward(address _cluster) public onlyRewardDelegatorsContract returns(uint256) {
        uint256 pendingRewards = clusterRewards[_cluster];
        if(pendingRewards != 0) {
            transferRewards(rewardDelegatorsAddress, pendingRewards);
            delete clusterRewards[_cluster];
        }
        return pendingRewards;
    }

    function transferRewards(address _to, uint256 _amount) internal {
        POND.transfer(_to, _amount);
    }

    function updateRewardDelegatorAddress(address _updatedRewardDelegator) public onlyOwner {
        require(
            _updatedRewardDelegator != address(0),
            "ClusterRewards:updateRewardDelegatorAddress - Updated Reward delegator address cannot be 0"
        );
        rewardDelegatorsAddress = _updatedRewardDelegator;
    }

    function updatePONDAddress(address _updatedPOND) public onlyOwner {
        require(
            _updatedPOND != address(0),
            "ClusterRewards:updatePONDAddress - Updated POND token address cannot be 0"
        );
        POND = ERC20(_updatedPOND);
    }

    function changeRewardPerEpoch(uint256 _updatedRewardPerEpoch) public onlyOwner {
        totalRewardsPerEpoch = _updatedRewardPerEpoch;
    }

    function changePayoutDenomination(uint256 _updatedPayoutDenomination) public onlyOwner {
        payoutDenomination = _updatedPayoutDenomination;
    }
}


contract RewardDelegators is Initializable, Ownable {

    using SafeMath for uint256;

    struct Cluster {
        mapping(bytes32 => uint256) totalDelegations;
        mapping(address => mapping(bytes32 => uint256)) delegators;
        mapping(address => mapping(bytes32 => uint256)) rewardDebt;
        mapping(address => mapping(bytes32 => uint256)) lastDelegatorRewardDistNonce;
        mapping(bytes32 => uint256) accRewardPerShare;
        uint256 lastRewardDistNonce;
        uint256 weightedStake;
    }

    mapping(address => Cluster) clusters;

    uint256 public undelegationWaitTime;
    address stakeAddress;
    uint256 minMPONDStake;
    bytes32 MPONDTokenId;
    mapping(bytes32 => uint256) rewardFactor;
    mapping(bytes32 => uint256) tokenIndex;
    mapping(bytes32 => uint256) public totalDelegations;
    bytes32[] public tokenList;
    ClusterRewards public clusterRewards;
    ClusterRegistry clusterRegistry;
    ERC20 PONDToken;

    event AddReward(bytes32 tokenId, uint256 rewardFactor);
    event RemoveReward(bytes32 tokenId);
    event MPONDTokenIdUpdated(bytes32 MPONDTokenId);
    event RewardsUpdated(bytes32 tokenId, uint256 rewardFactor);
    event ClusterRewardDistributed(address cluster);
    event RewardsWithdrawn(address cluster, address delegator, bytes32[] tokenIds, uint256 rewards);
    event UndelegationWaitTimeUpdated(uint256 undelegationWaitTime);
    event MinMPONDStakeUpdated(uint256 minMPONDStake);

    modifier onlyStake() {
        require(msg.sender == stakeAddress, "ClusterRegistry:onlyStake: only stake contract can invoke this function");
        _;
    }

    function initialize(
        uint256 _undelegationWaitTime, 
        address _stakeAddress, 
        address _clusterRewardsAddress,
        address _clusterRegistry,
        address _rewardDelegatorsAdmin,
        uint256 _minMPONDStake, 
        bytes32 _MPONDTokenId,
        address _PONDAddress,
        bytes32[] memory _tokenIds,
        uint256[] memory _rewardFactors
    ) public initializer {
        require(
            _tokenIds.length == _rewardFactors.length,
            "RewardDelegators:initalize - Each TokenId should have a corresponding Reward Factor and vice versa"
        );
        undelegationWaitTime = _undelegationWaitTime;
        emit UndelegationWaitTimeUpdated(_undelegationWaitTime);
        stakeAddress = _stakeAddress;
        clusterRegistry = ClusterRegistry(_clusterRegistry);
        clusterRewards = ClusterRewards(_clusterRewardsAddress);
        PONDToken = ERC20(_PONDAddress);
        minMPONDStake = _minMPONDStake;
        emit MinMPONDStakeUpdated(_minMPONDStake);
        MPONDTokenId = _MPONDTokenId;
        emit MPONDTokenIdUpdated(_MPONDTokenId);
        for(uint256 i=0; i < _tokenIds.length; i++) {
            rewardFactor[_tokenIds[i]] = _rewardFactors[i];
            tokenIndex[_tokenIds[i]] = tokenList.length;
            tokenList.push(_tokenIds[i]);
            emit AddReward(_tokenIds[i], _rewardFactors[i]);
        }
        super.initialize(_rewardDelegatorsAdmin);
    }

    function updateMPONDTokenId(bytes32 _updatedMPONDTokenId) public onlyOwner {
        MPONDTokenId = _updatedMPONDTokenId;
        emit MPONDTokenIdUpdated(_updatedMPONDTokenId);
    }

    function addReward(bytes32 _tokenId, uint256 _rewardFactor) public onlyOwner {
        require(rewardFactor[_tokenId] == 0, "RewardDelegators:addReward - Reward already exists");
        require(_rewardFactor != 0, "RewardDelegators:addReward - Reward can't be 0");
        rewardFactor[_tokenId] = _rewardFactor;
        tokenIndex[_tokenId] = tokenList.length;
        tokenList.push(_tokenId);
        emit AddReward(_tokenId, _rewardFactor);
    }
    
    function removeRewardFactor(bytes32 _tokenId) public onlyOwner {
        require(rewardFactor[_tokenId] != 0, "RewardDelegators:addReward - Reward doesn't exist");
        bytes32 tokenToReplace = tokenList[tokenList.length - 1];
        uint256 originalTokenIndex = tokenIndex[_tokenId];
        tokenList[originalTokenIndex] = tokenToReplace;
        tokenIndex[tokenToReplace] = originalTokenIndex;
        tokenList.pop();
        delete rewardFactor[_tokenId];
        delete tokenIndex[_tokenId];
        emit RemoveReward(_tokenId);
    }

    function updateRewardFactor(bytes32 _tokenId, uint256 _updatedRewardFactor) public onlyOwner {
        require(rewardFactor[_tokenId] != 0, "RewardDelegators:updateReward - Can't update reward that doesn't exist");
        require(_updatedRewardFactor != 0, "RewardDelegators:updateReward - Reward can't be 0");
        rewardFactor[_tokenId] = _updatedRewardFactor;
        emit RewardsUpdated(_tokenId, _updatedRewardFactor);
    }

    function _updateRewards(address _cluster) public {
        uint256 reward = clusterRewards.claimReward(_cluster);
        if(reward == 0) {
            return;
        }
        Cluster memory cluster = clusters[_cluster];
        if(cluster.weightedStake == 0) {
            clusters[_cluster].lastRewardDistNonce++;
            return;
        }
        
        uint256 commissionReward = reward.mul(clusterRegistry.getCommission(_cluster)).div(100);
        uint256 delegatorReward = reward.sub(commissionReward);
        uint256 weightedStake = cluster.weightedStake;
        bytes32[] memory tokens = tokenList;
        for(uint i=0; i < tokens.length; i++) {
            // clusters[_cluster].accRewardPerShare[tokens[i]] = clusters[_cluster].accRewardPerShare[tokens[i]].add(
            //                                                         delegatorReward
            //                                                         .mul(rewardFactor[tokens[i]])
            //                                                         .mul(10**30)
            //                                                         .div(weightedStake)
            //                                                     );
            clusters[_cluster].accRewardPerShare[tokens[i]] = clusters[_cluster].accRewardPerShare[tokens[i]].add(
                                                                    delegatorReward
                                                                    .mul(10**30)
                                                                    .div(tokens.length)
                                                                    .div(totalDelegations[tokens[i]])
                                                                );
        }
        clusters[_cluster].lastRewardDistNonce = cluster.lastRewardDistNonce.add(1);
        transferRewards(clusterRegistry.getRewardAddress(_cluster), commissionReward);
        emit ClusterRewardDistributed(_cluster);
    }

    function delegate(
        address _delegator, 
        address _cluster, 
        bytes32[] memory _tokens, 
        uint256[] memory _amounts
    ) public onlyStake {
        _updateRewards(_cluster);
        Cluster memory clusterData = clusters[_cluster];
        require(
            clusterRegistry.isClusterValid(_cluster),
            "ClusterRegistry:delegate - Cluster should be registered to delegate"
        );
        uint256 currentNonce = clusterData.lastRewardDistNonce;
        uint256 totalRewards;
        uint256 totalRewardDebt;
        for(uint256 i=0; i < _tokens.length; i++) {
            uint256 tokenAccRewardPerShare = clusters[_cluster].accRewardPerShare[_tokens[i]];
            uint256 delegatorTokens = clusters[_cluster].delegators[_delegator][_tokens[i]];
            if(clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][_tokens[i]] < currentNonce) {
                totalRewards = totalRewards.add(delegatorTokens.mul(tokenAccRewardPerShare));
                totalRewardDebt = totalRewardDebt.add(clusters[_cluster].rewardDebt[_delegator][_tokens[i]]);
                clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][_tokens[i]] = currentNonce;
            }
            uint256 totalRewardsForDebt = delegatorTokens.add(_amounts[i]).mul(tokenAccRewardPerShare);
            clusters[_cluster].rewardDebt[_delegator][_tokens[i]] = totalRewardsForDebt.div(10**30);
            // update balances
            if(_amounts[i] != 0) {
                clusters[_cluster].delegators[_delegator][_tokens[i]] = delegatorTokens.add(_amounts[i]);
                clusters[_cluster].totalDelegations[_tokens[i]] = clusters[_cluster].totalDelegations[_tokens[i]]
                                                                    .add(_amounts[i]);
                clusters[_cluster].weightedStake = clusterData.weightedStake.add(_amounts[i].mul(rewardFactor[_tokens[i]]));
                totalDelegations[_tokens[i]] = totalDelegations[_tokens[i]].add(_amounts[i]);
            }
        }
        if(totalRewards != 0) {
            uint256 pendingRewards = totalRewards.div(10**30).sub(totalRewardDebt);
            if(pendingRewards != 0) {
                transferRewards(_delegator, pendingRewards);
                emit RewardsWithdrawn(_cluster, _delegator, _tokens, pendingRewards);
            }
        }
    }

    function undelegate(
        address _delegator, 
        address _cluster, 
        bytes32[] memory _tokens, 
        uint256[] memory _amounts
    ) public onlyStake {
        _updateRewards(_cluster);
        Cluster memory clusterData = clusters[_cluster];
        uint256 currentNonce = clusterData.lastRewardDistNonce;
        uint256 totalRewards;
        uint256 totalRewardDebt;
        for(uint256 i=0; i < _tokens.length; i++) {
            uint256 tokenAccRewardPerShare = clusters[_cluster].accRewardPerShare[_tokens[i]];
            uint256 delegatorTokens = clusters[_cluster].delegators[_delegator][_tokens[i]];
            if(clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][_tokens[i]] < currentNonce) {
                totalRewards = totalRewards.add(delegatorTokens.mul(tokenAccRewardPerShare));
                totalRewardDebt = totalRewardDebt.add(clusters[_cluster].rewardDebt[_delegator][_tokens[i]]);
                clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][_tokens[i]] = currentNonce;
            }
            uint256 totalRewardsForDebt = delegatorTokens.sub(_amounts[i]).mul(tokenAccRewardPerShare);
            clusters[_cluster].rewardDebt[_delegator][_tokens[i]] = totalRewardsForDebt.div(10**30);
            // update balances
            if(_amounts[i] != 0) {
                clusters[_cluster].delegators[_delegator][_tokens[i]] = delegatorTokens.sub(_amounts[i]);
                clusters[_cluster].totalDelegations[_tokens[i]] = clusters[_cluster].totalDelegations[_tokens[i]]
                                                                    .sub(_amounts[i]);
                clusters[_cluster].weightedStake = clusterData.weightedStake.sub(_amounts[i].mul(rewardFactor[_tokens[i]]));
                totalDelegations[_tokens[i]] = totalDelegations[_tokens[i]].sub(_amounts[i]);
            }
        }
        if(totalRewards != 0) {
            uint256 pendingRewards = totalRewards.div(10**30).sub(totalRewardDebt);
            if(pendingRewards != 0) {
                transferRewards(_delegator, pendingRewards);
                emit RewardsWithdrawn(_cluster, _delegator, _tokens, pendingRewards);
            }
        }
    }

    function withdrawRewards(address _delegator, address _cluster) public returns(uint256) {
        _updateRewards(_cluster);
        Cluster memory clusterData = clusters[_cluster];
        uint256 currentNonce = clusterData.lastRewardDistNonce;
        uint256 totalRewards;
        uint256 totalRewardDebt;
        bytes32[] memory tokens = tokenList;
        for(uint256 i=0; i < tokens.length; i++) {
            uint256 delegatorTokens = clusters[_cluster].delegators[_delegator][tokens[i]];
            uint256 accReward = delegatorTokens.mul(clusters[_cluster].accRewardPerShare[tokens[i]]);
            if(clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][tokens[i]] < currentNonce) {
                totalRewards = totalRewards.add(accReward);
                totalRewardDebt = totalRewardDebt.add(clusters[_cluster].rewardDebt[_delegator][tokens[i]]);
                clusters[_cluster].lastDelegatorRewardDistNonce[_delegator][tokens[i]] = currentNonce;
                clusters[_cluster].rewardDebt[_delegator][tokens[i]] = accReward.div(10**30);
            }
        }
        if(totalRewards != 0) {
            uint256 pendingRewards = totalRewards.div(10**30).sub(totalRewardDebt);
            if(pendingRewards != 0) {
                transferRewards(_delegator, pendingRewards);
                emit RewardsWithdrawn(_cluster, _delegator, tokens, pendingRewards);
            }
            return pendingRewards;
        }
        return 0;
    }

    function transferRewards(address _to, uint256 _amount) internal {
        PONDToken.transfer(_to, _amount);
    }

    function isClusterActive(address _cluster) public returns(bool) {
        if(
            clusterRegistry.isClusterValid(_cluster) 
            && clusters[_cluster].totalDelegations[MPONDTokenId] > minMPONDStake
        ) {
            return true;
        }
        return false;
    }

    function getClusterDelegation(address _cluster, bytes32 _tokenId) 
        public 
        view 
        returns(uint256) 
    {
        return clusters[_cluster].totalDelegations[_tokenId];
    }

    function getDelegation(address _cluster, address _delegator, bytes32 _tokenId) 
        public 
        view
        returns(uint256) 
    {
        return clusters[_cluster].delegators[_delegator][_tokenId];
    }

    function updateUndelegationWaitTime(uint256 _undelegationWaitTime) public onlyOwner {
        undelegationWaitTime = _undelegationWaitTime;
        emit UndelegationWaitTimeUpdated(_undelegationWaitTime);
    }

    function updateMinMPONDStake(uint256 _minMPONDStake) public onlyOwner {
        minMPONDStake = _minMPONDStake;
        emit MinMPONDStakeUpdated(_minMPONDStake);
    }

    function updateStakeAddress(address _updatedStakeAddress) public onlyOwner {
        require(
            _updatedStakeAddress != address(0),
            "RewardDelegators:updateStakeAddress - Updated Stake contract address cannot be 0"
        );
        stakeAddress = _updatedStakeAddress;
    }

    function updateClusterRewards(
        address _updatedClusterRewards
    ) public onlyOwner {
        require(
            _updatedClusterRewards != address(0), 
            "RewardDelegators:updateClusterRewards - ClusterRewards address cannot be 0"
        );
        clusterRewards = ClusterRewards(_updatedClusterRewards);
    }

    function updateClusterRegistry(
        address _updatedClusterRegistry
    ) public onlyOwner {
        require(
            _updatedClusterRegistry != address(0),
            "RewardDelegators:updateClusterRegistry - Cluster Registry address cannot be 0"
        );
        clusterRegistry = ClusterRegistry(_updatedClusterRegistry);
    }

    function updatePONDAddress(address _updatedPOND) public onlyOwner {
        require(
            _updatedPOND != address(0),
            "RewardDelegators:updatePONDAddress - Updated POND token address cannot be 0"
        );
        PONDToken = ERC20(_updatedPOND);
    }
}


pragma experimental ABIEncoderV2;



contract MPondLogic is Initializable {
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 token decimals for this token
    uint8 public decimals;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply; // 10k mPond
    uint256 public bridgeSupply; // 3k mPond

    address public dropBridge;
    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => mapping(address => uint96)) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public DOMAIN_TYPEHASH;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public DELEGATION_TYPEHASH;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public UNDELEGATION_TYPEHASH;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// customized params
    address public admin;
    mapping(address => bool) public isWhiteListed;
    bool public enableAllTranfers;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Initializer a new mPond token
     * @param account The initial account to grant all the tokens
     */
    function initialize(
        address account,
        address bridge,
        address dropBridgeAddress
    ) public initializer {
        createConstants();
        require(
            account != bridge,
            "Bridge and account should not be the same address"
        );
        balances[bridge] = uint96(bridgeSupply);
        delegates[bridge][address(0)] = uint96(bridgeSupply);
        isWhiteListed[bridge] = true;
        emit Transfer(address(0), bridge, bridgeSupply);

        uint96 remainingSupply = sub96(
            uint96(totalSupply),
            uint96(bridgeSupply),
            "mPond: Subtraction overflow in the constructor"
        );
        balances[account] = remainingSupply;
        delegates[account][address(0)] = remainingSupply;
        isWhiteListed[account] = true;
        dropBridge = dropBridgeAddress;
        emit Transfer(address(0), account, uint256(remainingSupply));
    }

    function createConstants() internal {
        name = "Marlin Governance Token";
        symbol = "MPOND";
        decimals = 18;
        totalSupply = 10000e18;
        bridgeSupply = 7000e18;
        DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
        DELEGATION_TYPEHASH = keccak256(
            "Delegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
        );
        UNDELEGATION_TYPEHASH = keccak256(
            "Unelegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
        );
        admin = msg.sender;
        // enableAllTranfers = true; //This is only for testing, will be false
    }

    function addWhiteListAddress(address _address)
        external
        onlyAdmin("Only admin can whitelist")
        returns (bool)
    {
        isWhiteListed[_address] = true;
        return true;
    }

    function enableAllTransfers()
        external
        onlyAdmin("Only enable can enable all transfers")
        returns (bool)
    {
        enableAllTranfers = true;
        return true;
    }

    function changeDropBridge(address _updatedBridge)
        public
        onlyAdmin("Only admin can change drop bridge")
    {
        dropBridge = _updatedBridge;
    }

    function isWhiteListedTransfer(address _address1, address _address2)
        public
        view
        returns (bool)
    {
        if (_address1 == dropBridge) {
            return true;
        } else if (_address2 == dropBridge) {
            return (isWhiteListed[_address1] || enableAllTranfers);
        }
        return
            (isWhiteListed[_address1] || isWhiteListed[_address2]) ||
            enableAllTranfers;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                rawAmount,
                "mPond::approve: amount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (addedAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                addedAmount,
                "mPond::approve: addedAmount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = add96(
            allowances[msg.sender][spender],
            amount,
            "mPond: increaseAllowance allowance value overflows"
        );
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 removedAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (removedAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                removedAmount,
                "mPond::approve: removedAmount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = sub96(
            allowances[msg.sender][spender],
            amount,
            "mPond: decreaseAllowance allowance value underflows"
        );
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        require(
            isWhiteListedTransfer(msg.sender, dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        uint96 amount = safe96(
            rawAmount,
            "mPond::transfer: amount exceeds 96 bits"
        );
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        require(
            isWhiteListedTransfer(msg.sender, dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "mPond::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "mPond::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee, uint96 amount) public {
        return _delegate(msg.sender, delegatee, amount);
    }

    function undelegate(address delegatee, uint96 amount) public {
        return _undelegate(msg.sender, delegatee, amount);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "mPond::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "mPond::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "mPond::delegateBySig: signature expired");
        return _delegate(signatory, delegatee, amount);
    }

    function undelegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(UNDELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "mPond::undelegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "mPond::undelegateBySig: invalid nonce"
        );
        require(now <= expiry, "mPond::undelegateBySig: signature expired");
        return _undelegate(signatory, delegatee, amount);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints != 0
                ? checkpoints[account][nCheckpoints - 1].votes
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "mPond::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        delegates[delegator][address(0)] = sub96(
            delegates[delegator][address(0)],
            amount,
            "mPond: delegates underflow"
        );
        delegates[delegator][delegatee] = add96(
            delegates[delegator][delegatee],
            amount,
            "mPond: delegates overflow"
        );

        emit DelegateChanged(delegator, address(0), delegatee);

        _moveDelegates(address(0), delegatee, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        delegates[delegator][delegatee] = sub96(
            delegates[delegator][delegatee],
            amount,
            "mPond: undelegates underflow"
        );
        delegates[delegator][address(0)] = add96(
            delegates[delegator][address(0)],
            amount,
            "mPond: delegates underflow"
        );
        emit DelegateChanged(delegator, delegatee, address(0));
        _moveDelegates(delegatee, address(0), amount);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            src != address(0),
            "mPond::_transferTokens: cannot transfer from the zero address"
        );
        require(
            delegates[src][address(0)] >= amount,
            "mPond: _transferTokens: undelegated amount should be greater than transfer amount"
        );
        require(
            dst != address(0),
            "mPond::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "mPond::_transferTokens: transfer amount exceeds balance"
        );
        delegates[src][address(0)] = sub96(
            delegates[src][address(0)],
            amount,
            "mPond: _tranferTokens: undelegate subtraction error"
        );

        balances[dst] = add96(
            balances[dst],
            amount,
            "mPond::_transferTokens: transfer amount overflows"
        );
        delegates[dst][address(0)] = add96(
            delegates[dst][address(0)],
            amount,
            "mPond: _transferTokens: undelegate addition error"
        );
        emit Transfer(src, dst, amount);

        // _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "mPond::_moveVotes: vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "mPond::_moveVotes: vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "mPond::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints != 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    modifier onlyAdmin(string memory _error) {
        require(msg.sender == admin, _error);
        _;
    }
}


contract ClusterRegistry is Initializable, Ownable {

    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);

    struct Cluster {
        uint256 commission;
        address rewardAddress;
        address clientKey;
        bytes32 networkId; // keccak256("ETH") // token ticker for anyother chain in place of ETH
        Status status;
    }

    struct Lock {
        uint256 unlockBlock;
        uint256 iValue;
    }

    mapping(address => Cluster) clusters;

    mapping(bytes32 => Lock) public locks;
    mapping(bytes32 => uint256) public lockWaitTime;
    bytes32 constant COMMISSION_LOCK_SELECTOR = keccak256("COMMISSION_LOCK");
    bytes32 constant SWITCH_NETWORK_LOCK_SELECTOR = keccak256("SWITCH_NETWORK_LOCK");
    bytes32 constant UNREGISTER_LOCK_SELECTOR = keccak256("UNREGISTER_LOCK");

    enum Status{NOT_REGISTERED, REGISTERED}

    event ClusterRegistered(
        address cluster, 
        bytes32 networkId, 
        uint256 commission, 
        address rewardAddress, 
        address clientKey
    );
    event CommissionUpdateRequested(address cluster, uint256 commissionAfterUpdate, uint256 effectiveBlock);
    event CommissionUpdated(address cluster, uint256 updatedCommission, uint256 updatedAt);
    event RewardAddressUpdated(address cluster, address updatedRewardAddress);
    event NetworkSwitchRequested(address cluster, bytes32 networkId, uint256 effectiveBlock);
    event NetworkSwitched(address cluster, bytes32 networkId, uint256 updatedAt);
    event ClientKeyUpdated(address cluster, address clientKey);
    event ClusterUnregisterRequested(address cluster, uint256 effectiveBlock);
    event ClusterUnregistered(address cluster, uint256 updatedAt);
    event LockTimeUpdated(bytes32 selector, uint256 prevLockTime, uint256 updatedLockTime);

    function initialize(bytes32[] memory _selectors, uint256[] memory _lockWaitTimes, address _owner) 
        public 
        initializer
    {
        require(
            _selectors.length == _lockWaitTimes.length,
            "ClusterRegistry:initalize - Invalid params"
        );
        for(uint256 i=0; i < _selectors.length; i++) {
            lockWaitTime[_selectors[i]] = _lockWaitTimes[i];
            emit LockTimeUpdated(_selectors[i], 0, _lockWaitTimes[i]);
        }
        super.initialize(_owner);
    }

    function updateLockWaitTime(bytes32 _selector, uint256 _updatedWaitTime) public onlyOwner {
        emit LockTimeUpdated(_selector, lockWaitTime[_selector], _updatedWaitTime);
        lockWaitTime[_selector] = _updatedWaitTime; 
    }

    function register(
        bytes32 _networkId, 
        uint256 _commission, 
        address _rewardAddress, 
        address _clientKey
    ) public returns(bool) {
        // This happens only when the data of the cluster is registered or it wasn't registered before
        require(
            !isClusterValid(msg.sender), 
            "ClusterRegistry:register - Cluster is already registered"
        );
        require(_commission <= 100, "ClusterRegistry:register - Commission can't be more than 100%");
        clusters[msg.sender].commission = _commission;
        clusters[msg.sender].rewardAddress = _rewardAddress;
        clusters[msg.sender].clientKey = _clientKey;
        clusters[msg.sender].networkId = _networkId;
        clusters[msg.sender].status = Status.REGISTERED;
        
        emit ClusterRegistered(msg.sender, _networkId, _commission, _rewardAddress, _clientKey);
    }

    function updateCluster(uint256 _commission, bytes32 _networkId, address _rewardAddress, address _clientKey) public {
        require(
            isClusterValid(msg.sender),
            "ClusterRegistry:updateCluster - Cluster not registered"
        );
        if(_networkId != bytes32(0)) {
            switchNetwork(_networkId);
        }
        if(_rewardAddress != address(0)) {
            clusters[msg.sender].rewardAddress = _rewardAddress;
            emit RewardAddressUpdated(msg.sender, _rewardAddress);
        }
        if(_clientKey != address(0)) {
            clusters[msg.sender].clientKey = _clientKey;
            emit ClientKeyUpdated(msg.sender, _clientKey);
        }
        if(_commission != UINT256_MAX) {
            updateCommission(_commission);
        }
    }

    function updateCommission(uint256 _commission) public {
        require(
            isClusterValid(msg.sender),
            "ClusterRegistry:updateCommission - Cluster not registered"
        );
        require(_commission <= 100, "ClusterRegistry:updateCommission - Commission can't be more than 100%");
        bytes32 lockId = keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock == 0 || unlockBlock < block.number, 
            "ClusterRegistry:updateCommission - Commission update is already waiting"
        );
        if(unlockBlock != 0 && unlockBlock < block.number) {
            uint256 currentCommission = locks[lockId].iValue;
            clusters[msg.sender].commission = currentCommission;
            emit CommissionUpdated(msg.sender, currentCommission, unlockBlock);
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[COMMISSION_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, _commission);
        emit CommissionUpdateRequested(msg.sender, _commission, updatedUnlockBlock);
    }

    function switchNetwork(bytes32 _networkId) public {
        require(
            isClusterValid(msg.sender),
            "ClusterRegistry:updateCommission - Cluster not registered"
        );
        bytes32 lockId = keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock == 0 || unlockBlock < block.number,
            "ClusterRegistry:switchNetwork - Network switch already waiting"
        );
        if(unlockBlock != 0 && unlockBlock < block.number) {
            bytes32 currentNetwork = bytes32(locks[lockId].iValue);
            clusters[msg.sender].networkId = currentNetwork;
            emit NetworkSwitched(msg.sender, currentNetwork, unlockBlock);
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[SWITCH_NETWORK_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, uint256(_networkId));
        emit NetworkSwitchRequested(msg.sender, _networkId, updatedUnlockBlock);
    }

    function updateRewardAddress(address _rewardAddress) public {
        require(
            isClusterValid(msg.sender),
            "ClusterRegistry:updateRewardAddress - Cluster not registered"
        );
        clusters[msg.sender].rewardAddress = _rewardAddress;
        emit RewardAddressUpdated(msg.sender, _rewardAddress);
    }

    function updateClientKey(address _clientKey) public {
        // TODO: Add delay to client key updates as well
        require(
            isClusterValid(msg.sender),
            "ClusterRegistry:updateClientKey - Cluster not registered"
        );
        clusters[msg.sender].clientKey = _clientKey;
        emit ClientKeyUpdated(msg.sender, _clientKey);
    }

    function unregister() public {
        require(
            clusters[msg.sender].status != Status.NOT_REGISTERED,
            "ClusterRegistry:updateCommission - Cluster not registered"
        );
        bytes32 lockId = keccak256(abi.encodePacked(UNREGISTER_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock == 0 || unlockBlock < block.number,
            "ClusterRegistry:unregister - Unregistration already in progress"
        );
        if(unlockBlock != 0 && unlockBlock < block.number) {
            clusters[msg.sender].status = Status.NOT_REGISTERED;
            emit ClusterUnregistered(msg.sender, unlockBlock);
            return;
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[UNREGISTER_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, 0);
        emit ClusterUnregisterRequested(msg.sender, updatedUnlockBlock);
    }

    function isClusterValid(address _cluster) public returns(bool) {
        bytes32 lockId = keccak256(abi.encodePacked(UNREGISTER_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            clusters[_cluster].status = Status.NOT_REGISTERED;
            emit ClusterUnregistered(_cluster, unlockBlock);
            delete locks[lockId];
            return false;
        }
        return (clusters[_cluster].status != Status.NOT_REGISTERED);
    }

    function getCommission(address _cluster) public returns(uint256) {
        bytes32 lockId = keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            uint256 currentCommission = locks[lockId].iValue;
            clusters[_cluster].commission = currentCommission;
            emit CommissionUpdated(_cluster, currentCommission, unlockBlock);
            delete locks[lockId];
            return currentCommission;
        }
        return clusters[_cluster].commission;
    }

    function getNetwork(address _cluster) public returns(bytes32) {
        bytes32 lockId = keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            bytes32 currentNetwork = bytes32(locks[lockId].iValue);
            clusters[msg.sender].networkId = currentNetwork;
            emit NetworkSwitched(msg.sender, currentNetwork, unlockBlock);
            delete locks[lockId];
            return currentNetwork;
        }
        return clusters[_cluster].networkId;
    }

    function getRewardAddress(address _cluster) public view returns(address) {
        return clusters[_cluster].rewardAddress;
    }

    function getClientKey(address _cluster) public view returns(address) {
        return clusters[_cluster].clientKey;
    }

    function getCluster(address _cluster) public returns(
        uint256 commission, 
        address rewardAddress, 
        address clientKey, 
        bytes32 networkId, 
        bool isValidCluster
    ) {
        return (
            getCommission(_cluster), 
            clusters[_cluster].rewardAddress, 
            clusters[_cluster].clientKey, 
            getNetwork(_cluster), 
            isClusterValid(_cluster)
        );
    }
}


contract StakeManager is Initializable, Ownable {

    using SafeMath for uint256;

    struct TokenData {
        uint256 amount;
        uint256 index; // index in tokensDelegated array
    }

    struct Stash {
        address staker;
        address delegatedCluster;
        mapping(bytes32 => TokenData) amount;
        uint256 undelegatesAt;
        bytes32[] tokensDelegated;
    }

    struct Lock {
        uint256 unlockTime;
        address aValue;
        // bytes32 bValue;
    }

    struct Token {
        address addr;
        bool isActive;
    }
    // stashId to stash
    // stashId = keccak256(address, index)
    mapping(bytes32 => Stash) public stashes;
    // address to stashIndex
    mapping(address => uint256) indices;
    // tokenId to token address - tokenId = keccak256(tokenTicker)
    mapping(bytes32 => Token) tokenAddresses;
    MPondLogic MPOND;
    MPondLogic prevMPOND;
    ClusterRegistry clusterRegistry;
    RewardDelegators public rewardDelegators;

    event StashCreated(
        address indexed creator, 
        bytes32 stashId, 
        uint256 stashIndex,
        bytes32[] tokens, 
        uint256[] amounts
    );
    event StashDelegated(bytes32 stashId, address delegatedCluster);
    event StashUndelegated(bytes32 stashId, address undelegatedCluster, uint256 undelegatesAt);
    event StashWithdrawn(bytes32 stashId, bytes32[] tokens, uint256[] amounts);
    event StashClosed(bytes32 stashId, address indexed staker);
    event AddedToStash(bytes32 stashId, address delegatedCluster, bytes32[] tokens, uint256[] amounts);
    event TokenAdded(bytes32 tokenId, address tokenAddress);
    event TokenRemoved(bytes32 tokenId);
    event TokenUpdated(bytes32 tokenId, address tokenAddress);

    function initialize(
        bytes32[] memory _tokenIds, 
        address[] memory _tokenAddresses,
        address _MPONDTokenAddress,
        address _clusterRegistryAddress,
        address _rewardDelegatorsAddress,
        address _owner)
        initializer
        public 
    {
        require(
            _tokenIds.length == _tokenAddresses.length, 
            "StakeManager:initialize - each tokenId should have a corresponding tokenAddress and vice versa"
        );
        for(uint256 i=0; i < _tokenIds.length; i++) {
            tokenAddresses[_tokenIds[i]] = Token(_tokenAddresses[i], true);
            emit TokenAdded(_tokenIds[i], _tokenAddresses[i]);
        }
        MPOND = MPondLogic(_MPONDTokenAddress);
        clusterRegistry = ClusterRegistry(_clusterRegistryAddress);
        rewardDelegators = RewardDelegators(_rewardDelegatorsAddress);
        super.initialize(_owner);
    }

    function changeMPONDTokenAddress(
        address _MPONDTokenAddress
    ) public onlyOwner {
        prevMPOND = MPOND;
        MPOND = MPondLogic(_MPONDTokenAddress);
        emit TokenUpdated(keccak256("MPOND"), _MPONDTokenAddress);
    }

    function updateRewardDelegators(
        address _updatedRewardDelegator
    ) public onlyOwner {
        require(
            _updatedRewardDelegator != address(0), 
            "StakeManager:updateRewardDelegators - RewardDelegators address cannot be 0"
        );
        rewardDelegators = RewardDelegators(_updatedRewardDelegator);
    }

    function updateClusterRegistry(
        address _updatedClusterRegistry
    ) public onlyOwner {
        require(
            _updatedClusterRegistry != address(0),
            "StakeManager:updateClusterRegistry - Cluster Registry address cannot be 0"
        );
        clusterRegistry = ClusterRegistry(_updatedClusterRegistry);
    }

    function enableToken(
        bytes32 _tokenId, 
        address _address
    ) public onlyOwner {
        require(
            !tokenAddresses[_tokenId].isActive, 
            "StakeManager:enableToken - Token already enabled"
        );
        require(_address != address(0), "StakeManager:enableToken - Zero address not allowed");
        tokenAddresses[_tokenId] = Token(_address, true);
        emit TokenAdded(_tokenId, _address);
    }

    function disableToken(
        bytes32 _tokenId
    ) public onlyOwner {
        require(
            tokenAddresses[_tokenId].isActive,
            "StakeManager:disableToken - Token already disabled"
        );
        tokenAddresses[_tokenId].isActive = false;
        emit TokenRemoved(_tokenId);
    }

    function createStashAndDelegate(
        bytes32[] memory _tokens, 
        uint256[] memory _amounts, 
        address _delegatedCluster
    ) public {
        bytes32 stashId = createStash(_tokens, _amounts);
        delegateStash(stashId, _delegatedCluster);
    }

    function createStash(
        bytes32[] memory _tokens, 
        uint256[] memory _amounts
    ) public returns(bytes32) {
        require(
            _tokens.length == _amounts.length, 
            "StakeManager:createStash - each tokenId should have a corresponding amount and vice versa"
        );
        uint stashIndex = indices[msg.sender];
        bytes32 stashId = keccak256(abi.encodePacked(msg.sender, stashIndex));
        // TODO: This can never overflow, so change to + for gas savings
        indices[msg.sender] = stashIndex.add(1);
        for(uint256 index=0; index < _tokens.length; index++) {
            require(
                tokenAddresses[_tokens[index]].isActive, 
                "StakeManager:createStash - Invalid tokenId"
            );
            require(
                stashes[stashId].amount[_tokens[index]].amount == 0, 
                "StakeManager:createStash - Can't add the same token twice while creating stash"
            );
            require(
                _amounts[index] != 0,
                "StakeManager:createStash - Can't add tokens with 0 amount"
            );
            stashes[stashId].amount[_tokens[index]] = TokenData(_amounts[index], index);
            _lockTokens(_tokens[index], _amounts[index], msg.sender);
        }
        stashes[stashId] = Stash(msg.sender, address(0), 0, _tokens);
        emit StashCreated(msg.sender, stashId, stashIndex, _tokens, _amounts);
        return stashId;
    }

    function addToStash(
        bytes32 _stashId, 
        bytes32[] memory _tokens, 
        uint256[] memory _amounts
    ) public {
        Stash memory stash = stashes[_stashId];
        require(
            stash.staker == msg.sender, 
            "StakeManager:addToStash - Only staker can delegate stash to a cluster"
        );
        require(
            stash.undelegatesAt <= block.number,
            "StakeManager:addToStash - Can't add to stash during undelegation"
        );
        require(
            _tokens.length == _amounts.length, 
            "StakeManager:addToStash - Each tokenId should have a corresponding amount and vice versa"
        );
        if(stash.delegatedCluster != address(0)) {
            rewardDelegators.delegate(msg.sender, stash.delegatedCluster, _tokens, _amounts);
        }
        uint256 index = stashes[_stashId].tokensDelegated.length;
        for(uint256 i=0; i < _tokens.length; i++) {
            require(
                tokenAddresses[_tokens[i]].isActive, 
                "StakeManager:addToStash - Invalid tokenId"
            );
            if(_amounts[i] != 0) {
                TokenData memory tokenData = stashes[_stashId].amount[_tokens[i]];
                if(tokenData.amount == 0) {
                    stashes[_stashId].tokensDelegated.push(_tokens[i]);
                    stashes[_stashId].amount[_tokens[i]] = TokenData(_amounts[i], index);
                    index++;
                } else {
                    stashes[_stashId].amount[_tokens[i]].amount = tokenData.amount.add(_amounts[i]);
                }
                _lockTokens(_tokens[i], _amounts[i], msg.sender);
            }
        }
        // TODO: If gas usage for emitting tokens and amount is high, then query using txHash and remove them from event
        emit AddedToStash(_stashId, stash.delegatedCluster, _tokens, _amounts);
    }

    function delegateStash(bytes32 _stashId, address _delegatedCluster) public {
        Stash memory stash = stashes[_stashId];
        require(
            stash.staker == msg.sender, 
            "StakeManager:delegateStash - Only staker can delegate stash to a cluster"
        );
        require(
            clusterRegistry.isClusterValid(_delegatedCluster), 
            "StakeManager:delegateStash - delegated cluster address is not valid"
        );
        require(
            stash.delegatedCluster == address(0),
            "StakeManager:delegateStash - stash already delegated to another cluster. Please undelegate from delegating."
        );
        require(
            stash.undelegatesAt <= block.number,
            "StakeManager:delegateStash - stash is not yet undelegated"
        );
        stashes[_stashId].delegatedCluster = _delegatedCluster;
        bytes32[] memory tokens = stashes[_stashId].tokensDelegated;
        uint256[] memory amounts = new uint256[](tokens.length);
        for(uint256 i=0; i < tokens.length; i++) {
            amounts[i] = stashes[_stashId].amount[tokens[i]].amount;
        }
        rewardDelegators.delegate(msg.sender, _delegatedCluster, tokens, amounts);
        emit StashDelegated(_stashId, _delegatedCluster);
    }

    function undelegateStash(bytes32 _stashId) public {
        Stash memory stash = stashes[_stashId];
        require(
            stash.staker == msg.sender, 
            "StakeManager:undelegateStash - Only staker can undelegate stash"
        );
        require(
            stash.delegatedCluster != address(0),
            "StakeManager:undelegateStash - stash is not delegated to any cluster"
        );
        require(
            stash.undelegatesAt <= block.number,
            "StakeManager:undelegateStash - stash is already waiting for undelegation"
        );
        uint256 waitTime = rewardDelegators.undelegationWaitTime();
        // use + for gas savings as overflow can't happen
        uint undelegationBlock = block.number.add(waitTime);
        stashes[_stashId].undelegatesAt = undelegationBlock;
        delete stashes[_stashId].delegatedCluster;
        bytes32[] memory tokens = stashes[_stashId].tokensDelegated;
        uint256[] memory amounts = new uint256[](tokens.length);
        for(uint256 i=0; i < tokens.length; i++) {
            amounts[i] = stashes[_stashId].amount[tokens[i]].amount;
        }
        rewardDelegators.undelegate(msg.sender, stash.delegatedCluster, tokens, amounts);
        emit StashUndelegated(_stashId, stash.delegatedCluster, undelegationBlock);
    }

    function withdrawStash(bytes32 _stashId) public {
        Stash memory stash = stashes[_stashId];
        require(
            stash.staker == msg.sender,
            "StakeManager:withdrawStash - Only staker can withdraw stash"
        );
        require(
            stash.delegatedCluster == address(0),
            "StakeManager:withdrawStash - Stash is delegated. Please undelegate before withdrawal"
        );
        require(
            stash.undelegatesAt <= block.number,
            "StakeManager:withdrawStash - stash is not yet undelegated"
        );
        bytes32[] memory tokens = stashes[_stashId].tokensDelegated;
        uint256[] memory amounts = new uint256[](tokens.length);
        for(uint256 i=0; i < tokens.length; i++) {
            amounts[i] = stashes[_stashId].amount[tokens[i]].amount;
            delete stashes[_stashId].amount[tokens[i]];
            _unlockTokens(tokens[i], amounts[i], stash.staker);
        }
        // TODO-deleting the tokens array might be costly, so optimize
        delete stashes[_stashId];
        emit StashWithdrawn(_stashId, tokens, amounts);
        emit StashClosed(_stashId, stash.staker);
    }

    function withdrawStash(
        bytes32 _stashId, 
        bytes32[] memory _tokens, 
        uint256[] memory _amounts
    ) public {
        Stash memory stash = stashes[_stashId];
        require(
            stash.staker == msg.sender,
            "StakeManager:withdrawStash - Only staker can withdraw stash"
        );
        require(
            stash.delegatedCluster == address(0),
            "StakeManager:withdrawStash - Stash is delegated. Please undelegate before withdrawal"
        );
        require(
            stash.undelegatesAt <= block.number,
            "StakeManager:withdrawStash - stash is not yet undelegated"
        );
        require(
            _tokens.length == _amounts.length,
            "StakeManager:withdrawStash - Each tokenId should have a corresponding amount and vice versa"
        );
        for(uint256 i=0; i < _tokens.length; i++) {
            uint256 balance = stashes[_stashId].amount[_tokens[i]].amount;
            require(
                balance >= _amounts[i],
                "StakeManager:withdrawStash - balance not sufficient"
            );
            if(balance == _amounts[i]) {
                // delete element from array
                uint256 tokenIndex = stashes[_stashId].amount[_tokens[i]].index;
                bytes32 tokenToReplace = stashes[_stashId].tokensDelegated[stashes[_stashId].tokensDelegated.length-1];
                stashes[_stashId].tokensDelegated[tokenIndex] = tokenToReplace;
                stashes[_stashId].tokensDelegated.pop();
                stashes[_stashId].amount[tokenToReplace].index = tokenIndex;
                delete stashes[_stashId].amount[_tokens[i]];
            } else {
                stashes[_stashId].amount[_tokens[i]].amount = balance.sub(_amounts[i]);
            }
            _unlockTokens(_tokens[i], _amounts[i], stash.staker);
        }
        if(stashes[_stashId].tokensDelegated.length == 0) {
            // TODO-deleting the tokens array might be costly, so optimize
            delete stashes[_stashId];
        }
        emit StashWithdrawn(_stashId, _tokens, _amounts);
    }

    function _lockTokens(bytes32 _tokenId, uint256 _amount, address _delegator) internal {
        if(_amount == 0) {
            return;
        }
        address tokenAddress = tokenAddresses[_tokenId].addr;
        // pull tokens from mpond/pond contract
        // if mpond transfer the governance rights back
        require(
            ERC20(tokenAddress).transferFrom(
                _delegator,
                address(this),
                _amount
            )
        );
        if (tokenAddress == address(MPOND)) {
            // send a request to delegate governance rights for the amount to delegator
            MPOND.delegate(
                _delegator,
                uint96(_amount)
            );
        }
    }

    function _unlockTokens(bytes32 _tokenId, uint256 _amount, address _delegator) internal {
        if(_amount == 0) {
            return;
        }
        address tokenAddress = tokenAddresses[_tokenId].addr;
        if(tokenAddress == address(MPOND)) {
            // send a request to undelegate governacne rights for the amount to previous delegator
            MPOND.undelegate(
                _delegator,
                uint96(_amount)
            );
        } else if(tokenAddress == address(prevMPOND)) {
            prevMPOND.undelegate(
                _delegator,
                uint96(_amount)
            );
        }
        require(
            ERC20(tokenAddress).transfer(
                _delegator,
                _amount
            )
        );
    }
}
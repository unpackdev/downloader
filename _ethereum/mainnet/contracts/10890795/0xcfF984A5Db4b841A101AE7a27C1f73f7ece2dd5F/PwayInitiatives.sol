// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

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

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}

// File: contracts\PwayInitiatives.sol

pragma solidity ^0.5.0;



contract PwayInitiatives is Ownable  {
    
    struct VoteStake {
        uint128 up;
        uint128 down;
    }

    struct Initiative {
        mapping(address => VoteStake) votersStake;

        uint128 totalVotesUp;
        uint128 totalVotesDown;

        uint128 startTimestamp;
        uint128 endTimestamp;
    }

    IERC20 public token;
    Initiative[] public initiatives;

    event InitiativeCreated(uint256 initiativeId, uint256 identifier);
    event Voted(address indexed voter,uint256 initiativeId, bool voteFor, uint256 amount);
    event StakeReclaimed(address indexed voter,uint256 initiativeId);
    event StakeWithdrawn(address indexed voter,uint256 initiativeId);

    constructor(IERC20 _token) public {
        token = _token;
    }

    function addInitiative(uint128 startTimestamp, uint128 endTimestamp, uint256 identifier) external onlyOwner {
        require(startTimestamp > now , "Invalid start date");
        require(startTimestamp < endTimestamp, "Invalid dates");

        require(identifier > 0, "Invalid identifier");

        Initiative memory newInitiative = Initiative({
            startTimestamp : startTimestamp, 
            endTimestamp:endTimestamp,
            totalVotesUp:0,
            totalVotesDown:0});

        initiatives.push(newInitiative);

        emit InitiativeCreated(initiatives.length-1, identifier);
    }

    function getInitiativeCount() view external returns(uint256){
        return initiatives.length;
    }

    function getInitiative(uint256 initiativeId) view public 
    returns(
        uint128 voteUp, 
        uint128 voteDown, 
        uint128 startTimestamp,
        uint128 endTimestamp) {
        Initiative memory initiative = initiatives[initiativeId];
        
        return (initiative.totalVotesUp, initiative.totalVotesDown, initiative.startTimestamp, initiative.endTimestamp);
    }

    function getVoterData(uint256 initiativeId,address voter) public view returns(uint128 voteFor, uint128 voteAgains) {
        Initiative storage initiative = initiatives[initiativeId];

        VoteStake storage voterStake = initiative.votersStake[voter];

        return(voterStake.up, voterStake.down);
    }

    function vote(uint256 initiativeId, bool voteFor, uint256 amount) external {
        Initiative storage initiative = initiatives[initiativeId];

        require(initiative.startTimestamp > 0, "InitiativeId do not existst");
        require(initiative.endTimestamp > now);
        
        require(amount > 0, "Amount should greater than zero");

        require(token.allowance(msg.sender, address(this)) >= amount, "Not enought PWay token to vote");

        token.transferFrom(msg.sender, address(this), amount);

        VoteStake storage voterStake = initiative.votersStake[msg.sender];

        if(voteFor) {
            voterStake.up += uint128(amount);
            initiative.totalVotesUp += uint128(amount);
        }
        else {
            voterStake.down += uint128(amount);
            initiative.totalVotesDown += uint128(amount);
        }

        emit Voted(msg.sender, initiativeId, voteFor, amount);
    }

    function withdrawStake(address voter,uint initiativeId) external {

        Initiative storage initiative = initiatives[initiativeId];

        require(initiative.startTimestamp > 0, "InitiativeId do not existst");
        require(uint256(initiative.endTimestamp) < now,"Initiative is not ended");

        VoteStake storage voterStake = initiative.votersStake[voter];
        uint256 voterTotalStake = uint256(voterStake.up) + uint256(voterStake.down);

        voterStake.up = 0;
        voterStake.down = 0;
        
        token.transfer(voter, voterTotalStake);
        emit StakeWithdrawn(voter, initiativeId);
    }

    function reclaimStake(uint initiativeId) external {

        Initiative storage initiative = initiatives[initiativeId];

        require(initiative.startTimestamp > 0, "InitiativeId do not exists");
        require(uint256(initiative.endTimestamp) > now,"Initiative is ended");

        VoteStake storage voterStake = initiative.votersStake[msg.sender];
        uint256 voterTotalStake = uint256(voterStake.up) + uint256(voterStake.down);

        initiative.totalVotesUp -= uint128(voterStake.up);
        initiative.totalVotesDown -= uint128(voterStake.down);

        voterStake.up = 0;
        voterStake.down = 0;
        
        token.transfer(msg.sender, voterTotalStake);

        emit StakeReclaimed(msg.sender, initiativeId);
    }
}
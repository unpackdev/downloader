/**
 * TG: https://t.me/moniebotportal
 * X: https://x.com/monie_bot
 * Website: www.moniebot.com
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IERC20 {
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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MonieBotStake is Ownable {    
    // store user details
    // amount of token staked
    // timestamp
    // address of the user
    // A Struct "A struct in solidity is just a custom type that you can define. You define the struct with a name and associated properties inside of it"
    // implementations "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=struct"
    struct UserData {
        uint256 tokenQuantity;
        uint256 intialTimestamp;
        address user;
    }
    
    // what mapping really is :
    // Mappings act as hash tables which consist of key types and corresponding value type pairs. They are defined like any other variable type in Solidity:
    // implementations "https://docs.soliditylang.org/en/v0.8.9/style-guide.html?highlight=mapping#mappings"
    mapping(address => bool) public isAdminAddress; // updating and checking the addresses that are admins
    mapping(address => UserData) public userData; // get user detatils
    mapping(address => bool) public staked;
    
    address public TOKEN = 0xba0161322A09AbE48F06cE5656c1b66bFB01BE56;
    address public feeReceiver;
    uint256 public ENTRY_RATE = 0.5E18;
    
    // total numbers of $MONIE staked
    uint256 public totalStaking;
    uint256 public totalStaker;
    
    // minimum staked amount
    uint256 public minimum;

    // deposit fee
    uint256 public stakingFee;
    uint256 public unstakingFee;

    // event manager help to update user on token staked. 
    // extract from "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=event#structure-events"
    event Stake(
        address indexed userAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    
    event UnStake(
        address indexed userAddress,
        uint256 unStakedAmount,
        uint256 _userReward,
        uint256 Time
    );
    
    event withdrawReward(
        uint256 tokenAmount,
        address indexed _from,
        address indexed _to,
        uint _time
    );
    
    event addPreviousRewardToUserBal(
        uint256 prviousrewards,
        address indexed _from,
        address indexed _to,
        uint _time
    );
    
    event adminAdded(
        address[] _admins,
        bool
    );
    
    // called once at every deployment
    // A constructor is an optional function that is executed upon contract creation.
    constructor() {
        isAdminAddress[_msgSender()] = true;
        stakingFee = 10;
        unstakingFee = 50;
        feeReceiver = 0xeB35Ae47269AbE3e88F274bBCF9dA9118601B6b3;
    }
    
    // check to be sure that only License address/addresses can called a specific functions in this contract.
    // A modifier allows you to control the behavior of your smart contract functions.
    // implementations "https://docs.soliditylang.org/en/v0.8.9/structure-of-a-contract.html?highlight=modifier"
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()]);
        _;
    }

    function setRates(uint256 _apr) external onlyOwner {
        ENTRY_RATE = _apr;
    }

    function setFeeReceive(address _newFeeReceiver) external onlyOwner {
        feeReceiver = _newFeeReceiver;
    }

    function setFees(uint256 _stakingFee, uint256 _unstakingFee) external onlyOwner {
        require(_stakingFee <= 100 && _unstakingFee <= 100, "Should not exceed 10%");
        stakingFee = _stakingFee;
        unstakingFee = _unstakingFee;
    }

    // where user can stake their $MONIE,
    // _quantity: amount of $MONIE that user want to stake.
    // user must approve the staking contract adrress before calling this function
    function stake(uint256 _quantity) public {
        require(_quantity >= minimum, "amount staked is less than minimum staking amount");
        UserData storage _userData = userData[_msgSender()];
        IERC20(TOKEN).transferFrom(_msgSender(), address(this), _quantity);

        uint256 afterFee = (_quantity * stakingFee) / 1000;
        IERC20(TOKEN).transfer(feeReceiver, afterFee);
        uint256 quantity = _quantity - afterFee;
        
        // get user current rewards if input token quantity is 0
        uint256 pendingReward = calculateRewards(_userData.user);
        
        // if user had previously staked then an update in user data is require
        if(_userData.tokenQuantity > 0 ) {
            _userData.tokenQuantity = _userData.tokenQuantity + pendingReward;
            emit addPreviousRewardToUserBal( pendingReward, address(this), _msgSender(), block.timestamp);
        }

        if (!staked[msg.sender]) {
            staked[msg.sender] = true;
            totalStaker = totalStaker + 1;
        }
                
        _userData.user = _msgSender(); // update caller to the list of stakers
        _userData.tokenQuantity = _userData.tokenQuantity + quantity; // update user staked amount
        _userData.intialTimestamp = block.timestamp; // update time staked
        
        totalStaking = totalStaking + quantity; // update total staking amount
        emit Stake(_msgSender(), _quantity, block.timestamp); // emission of events to enable listening to a specific act of an address that successfully staked
    }
    

    // use by an address that have staked there $MONIE to unstake at a desire time.    
    // is _quantity is 0 it will withdraw user rewards from the contract
    function unStake(uint256 _amount) public {
        
        UserData storage _userData = userData[_msgSender()]; // get user from the list of staked address
        require(_userData.tokenQuantity >= _amount, "MONIE: Insufficient amount"); // requirement that input amount by the caller is less than what user staked
        
        uint256 pendingReward = calculateRewards(userData[_msgSender()].user); //get the current rewards of User
        
        // if input amount is 0 it will withdraw user current rewards
        if(_amount == 0) {
            require(_userData.tokenQuantity > 0, "MONIE: NO REWARD YET.");
            safeTokenTransfer(_msgSender(), pendingReward);
            _userData.tokenQuantity = _userData.tokenQuantity;
            _userData.intialTimestamp = block.timestamp;
            emit withdrawReward( pendingReward, address(this), _msgSender(), block.timestamp);
        }
        if(_amount > 0) {
            
            require( _amount <= _userData.tokenQuantity, "MONIE: AMOUNT IS GREATER THAN USER STAKED TOKEN");
            _userData.tokenQuantity = _userData.tokenQuantity - _amount;
            
            safeTokenTransfer(_msgSender(), pendingReward);

            uint256 afterFee = (_amount * unstakingFee) / 1000;
            IERC20(TOKEN).transfer(feeReceiver, afterFee);
            uint256 quantity = _amount - afterFee;


            IERC20(TOKEN).transfer(_msgSender(), quantity);
            totalStaking = totalStaking - quantity;
            
            _userData.intialTimestamp = block.timestamp;
            
            emit UnStake(_msgSender(), _amount, pendingReward, block.timestamp);
        }
    }

    function calculateRewards(address _stakerAddress) public view returns(uint256) {
        UserData memory _userData = userData[_stakerAddress];
        uint256 currentTime = block.timestamp - _userData.intialTimestamp;
        uint256 perSeconds = ENTRY_RATE / (24 * 60 * 60);
        uint256 rewardPerSeconds = currentTime * perSeconds;
        return rewardPerSeconds;
    }

    function userInfo(address _addr) public view returns(address _staker, uint256 _amountStaked, uint256 _userReward, uint _timeStaked) {
        UserData storage _userData = userData[_addr];
        uint256 _reward = calculateRewards(_userData.user);
        if(_userData.tokenQuantity > 0) {
           _userReward = _userData.tokenQuantity + (_reward);
        }
        
        return(
            _userData.user, 
            _userData.tokenQuantity,
            _userReward,
            _userData.intialTimestamp
            );
    }
    
    function safeTokenTransfer(address staker, uint256 amount) internal {
        IERC20(TOKEN).transfer(staker, amount);
    }
    
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            } 
        }
    }
    
    // Safe withdraw function by admin
    function safeWithdraw(address _to, uint256 _amount)  external onlyOwner {
        uint256 Balalance = IERC20(TOKEN).balanceOf(address(this));
        if (_amount > Balalance) {
            IERC20(TOKEN).transfer(_to, Balalance);
        } else {
            IERC20(TOKEN).transfer(_to, _amount);
        }
    }

    function getMinimumStakeAmount() public view returns(uint256 min) {
        return minimum;
    }
    
    function setMinimumStakeAmount(uint256 min) external onlyOwner {
        minimum = min;
    }
    
}
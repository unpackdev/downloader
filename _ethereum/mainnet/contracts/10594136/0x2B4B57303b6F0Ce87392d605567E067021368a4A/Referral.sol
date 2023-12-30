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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ethrim is ERC20 {
    using SafeMath for uint256;
    address public owner;
    //1 token = 0.01 eth
    uint256 public tokenCost = 0.01 ether;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply = 1e9* 10**18;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor () public {
        symbol = "ETRM";
        name = "Ethrim";
        decimals = 18;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    /**
     * @dev To change burnt Address
     * @param _newOwner New owner address
     */ 
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        uint256 _value = balances[msg.sender];
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_newOwner] = balances[_newOwner].add(_value);
        //minting total supply tokens
        return true;
    }

    function getAmountOfToken(uint256 amount) public view returns (uint256) {
        uint256 tokenValue = (amount.mul(10 ** 18)).div(tokenCost);
        return tokenValue;
    }

    /**
     * @dev Check balance of the holder
     * @param _owner Token holder address
     */ 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer token to specified address
     * @param _to Receiver address
     * @param _value Amount of the tokens
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from  The holder address
     * @param _to  The Receiver address
     * @param _value  the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Approve respective tokens for spender
     * @param _spender Spender address
     * @param _value Amount of tokens to be allowed
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev To view approved balance
     * @param _owner Holder address
     * @param _spender Spender address
     */ 
    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function mint(uint256 _tokens) public returns (bool) {
        balances[owner] = balances[owner].add(_tokens);
        totalSupply = totalSupply.add(_tokens);
        return true;
    }

}

contract Referral {
    using SafeMath for uint256;

    //user structure
    struct UserStruct {
        bool isExist;
        //unique id
        uint256 id;
        //person who referred unique id
        uint256 referrerID;
        //user current level
        uint256 currentLevel;
        //total eraning for user
        uint256 totalEarningEth;
        //persons referred
        address[] referral;
        //time for every level
        uint256 levelExpiresAt;
    }
    
    //owner who deploys contracts
    address public owner;
    //address to tarnsfer eth/2
    address payable public ownerAddress1;
    //address to tarnsfer eth/2
    address payable public ownerAddress2;
    //unique id for every user
    uint256 public last_uid = 0;
    //time limit for each level
    uint256 public PERIOD_LENGTH = 60 days;
    //no of users in each level
    uint256 REFERRALS_LIMIT = 5;
    //maximum level from 0 to 7
    uint256 MAX_LEVEL = 7;

    //token variable
    Ethrim public ETRM;

    //to up for each level
    mapping(uint256 => uint256) public LEVEL_PRICE;
    //incentive for every level
    mapping(uint256 => uint256) public INCENTIVE_LEVEL_PRICE;
    //map user by their unique trust wallet address
    mapping(address => UserStruct) public users;
    //users trust wallet address corresponding to unique id
    mapping(uint256 => address) public userAddresses;

    //check if user not registered previously
    modifier userRegistered() {
        require(users[msg.sender].isExist == true, "User is not registered");
        _;
    }
    //check if referrer id is invalid or not
    modifier validReferrerID(uint256 _referrerID) {
        require( _referrerID > 0 && _referrerID <= last_uid, "Invalid referrer ID");
        _;
    }
    //check if user is already registerd
    modifier userNotRegistered() {
        require(users[msg.sender].isExist == false, "User is already registered");
        _;
    }
    //check if selected level is valid or not
    modifier validLevel(uint256 _level) {
        require(_level > 0 && _level <= MAX_LEVEL, "Invalid level entered");
        _;
    }
    
    
  event RegisterUserEvent(address indexed user, address indexed referrer, uint256 time);
  event BuyLevelEvent(address indexed user, uint256 indexed level, uint256 time);

    constructor(address payable _ownerAddress1, address payable _ownerAddress2, address _tokenAddr) public {
        require(_ownerAddress1 != address(0), "Invalid owner address 1");
        require(_ownerAddress2 != address(0), "Invalid owner address 2");
        require(_tokenAddr != address(0), "Invalid token address");
        owner = msg.sender;
        ownerAddress1 = _ownerAddress1;
        ownerAddress2 = _ownerAddress2;
        LEVEL_PRICE[1] = 0.25 ether;
        LEVEL_PRICE[2] = 0.25 ether;
        LEVEL_PRICE[3] = 0.5 ether;
        LEVEL_PRICE[4] = 1 ether;
        LEVEL_PRICE[5] = 2 ether;
        LEVEL_PRICE[6] = 4 ether;
        LEVEL_PRICE[7] = 8 ether;
        INCENTIVE_LEVEL_PRICE[1] = 0.05 ether;
        INCENTIVE_LEVEL_PRICE[2] = 0.03 ether;
        INCENTIVE_LEVEL_PRICE[3] = 0.03 ether;
        INCENTIVE_LEVEL_PRICE[4] = 0.03 ether;
        INCENTIVE_LEVEL_PRICE[5] = 0.03 ether;
        INCENTIVE_LEVEL_PRICE[6] = 0.03 ether;
        INCENTIVE_LEVEL_PRICE[7] = 0.03 ether;
         last_uid = last_uid + 1;
        users[owner] = UserStruct({
            isExist: true,
            id: last_uid,
            referrerID: 0,
            currentLevel: 1,
            totalEarningEth: 0,
            referral: new address[](0),
            levelExpiresAt: now.add(PERIOD_LENGTH)
        });
        userAddresses[last_uid] = owner;
        ETRM = Ethrim(_tokenAddr);
    }

    /**
     * @dev User registration
     */

    function registerUser(uint256 _referrerUniqueID) public payable userNotRegistered() validReferrerID(_referrerUniqueID) {
        require(msg.value >= LEVEL_PRICE[1], "Invalid level amount sent");
        uint256 referrerUniqueID = _referrerUniqueID;
        if (users[userAddresses[referrerUniqueID]].referral.length >= REFERRALS_LIMIT) {
            if(users[userAddresses[referrerUniqueID]].currentLevel == 1 &&
                now <= users[userAddresses[referrerUniqueID]].levelExpiresAt.add(2 days)){
                users[userAddresses[referrerUniqueID]].currentLevel = 2;
            }
            referrerUniqueID = users[findFreeReferrer(userAddresses[referrerUniqueID])].id;
        }
        last_uid = last_uid + 1;
        users[msg.sender] = UserStruct({
            isExist: true,
            id: last_uid,
            referrerID: referrerUniqueID,
            currentLevel: 1,
            totalEarningEth: 0,
            referral: new address[](0),
            levelExpiresAt: now.add(PERIOD_LENGTH)
        });
        userAddresses[last_uid] = msg.sender;
        users[userAddresses[referrerUniqueID]].referral.push(msg.sender);

        uint256 tokenAmount = ETRM.getAmountOfToken(LEVEL_PRICE[1]);
        ETRM.transferFrom(owner, msg.sender, tokenAmount);

        //get upline level
        address userUpline = userAddresses[referrerUniqueID];
        //transfer payment to all upline from current upline
        transferLevelPayment(userUpline);
        emit RegisterUserEvent(msg.sender, userAddresses[referrerUniqueID], now);
    }

    /**
     * @dev View free Referrer Address
     */

    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < REFERRALS_LIMIT){
            return _userAddress;
        }

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];
        referrals[2] = users[_userAddress].referral[2];
        referrals[3] = users[_userAddress].referral[3];
        referrals[4] = users[_userAddress].referral[4];

        address referrer;

        for (uint256 i = 0; i < 16382; i++) {
            if (users[referrals[i]].referral.length < REFERRALS_LIMIT) {
                referrer = referrals[i];
                break;
            }

             if (i >= 8191) {
                continue;
            }

            //adding pyramid trees
            referrals[((i.add(1).mul(5))).add(i.add(0))] = users[referrals[i]].referral[0];
            referrals[((i.add(1).mul(5))).add(i.add(1))] = users[referrals[i]].referral[1];
            referrals[((i.add(1).mul(5))).add(i.add(2))] = users[referrals[i]].referral[2];
            referrals[((i.add(1).mul(5))).add(i.add(3))] = users[referrals[i]].referral[3];
            referrals[((i.add(1).mul(5))).add(i.add(4))] = users[referrals[i]].referral[4];
        }

        require(referrer != address(0), 'Referrer not found');
        return referrer;
    }

    function transferLevelPayment(address _userUpline) internal {
        address uplineAddress = _userUpline;
        //current upline to be sent money
        uint256 uplineLevel = users[uplineAddress].currentLevel;
        //upline user level expiry time
        uint256 uplineUserLevelExpiry = users[uplineAddress].levelExpiresAt;
        //uid
        uint256 uplineUID = users[uplineAddress].id;
        //incentive amount total
        uint256 amountSentAsIncetives = 0;

        uint256 count = 1;

        while(uplineUID > 0) {
            address payable receiver = payable(uplineAddress);
            if(uplineLevel == 1 && count == 1) {
                uint256 uplineIncentive = 0.05 ether;
                if(now <= uplineUserLevelExpiry && users[uplineAddress].isExist) {
                    receiver.transfer(uplineIncentive);
                    users[uplineAddress].totalEarningEth = users[uplineAddress].totalEarningEth.add(uplineIncentive);
                } else {
                    users[uplineAddress].isExist = false;
                    (ownerAddress1).transfer(uplineIncentive.div(2));
                    (ownerAddress2).transfer(uplineIncentive.div(2));
                }
                amountSentAsIncetives = amountSentAsIncetives.add(uplineIncentive);
            } else {
                uint256 uplineIncentive = 0.03 ether;
                if(now <= uplineUserLevelExpiry && users[uplineAddress].isExist) {
                    receiver.transfer(uplineIncentive);
                    users[uplineAddress].totalEarningEth = users[uplineAddress].totalEarningEth.add(uplineIncentive);
                } else {
                    users[uplineAddress].isExist = false;
                    (ownerAddress1).transfer(uplineIncentive.div(2));
                    (ownerAddress2).transfer(uplineIncentive.div(2));
                }
                amountSentAsIncetives = amountSentAsIncetives.add(uplineIncentive);
            }

            //get upline level
            uint256 uplineReferrerId = users[uplineAddress].referrerID;
            uplineAddress = userAddresses[uplineReferrerId];
            //level of upline for user 
            uplineLevel = users[uplineAddress].currentLevel;
            uplineUID = users[uplineAddress].id;
            count++;
        }

        uint256 remAmount = msg.value.sub(amountSentAsIncetives);
        transferToOwner(remAmount);
    }

    function buyLevel(uint256 _level) public payable userRegistered() validLevel(_level){
        users[msg.sender].levelExpiresAt = now.add(PERIOD_LENGTH);
        users[msg.sender].currentLevel = _level;
        uint256 totalLevelPrice = getTotalLevelPrice(_level);
        require(msg.value >= totalLevelPrice, "Invalid level amount sent");
        uint256 tokenAmount = ETRM.getAmountOfToken(LEVEL_PRICE[_level]);
        ETRM.transferFrom(owner, msg.sender, tokenAmount);
        transferToOwner(msg.value);
        emit BuyLevelEvent(msg.sender, _level, now);
    }

    /**
     * @dev Contract balance withdraw
     */

    function failSafe() public returns (bool) {
        require(msg.sender == owner, "only Owner Wallet");
        require(address(this).balance > 0, "Insufficient balance");
        transferToOwner(address(this).balance);
        return true;
    }

    function transferToOwner(uint256 _amount) internal{
        uint256 amount = _amount.div(2);
        (ownerAddress1).transfer(amount);
        (ownerAddress2).transfer(amount);
    }

    /**
     * @dev Update level price
     */

    function updatePrice(uint256 _level, uint256 _price) public returns (bool) {
        require(msg.sender == owner, "only OwnerWallet");
        LEVEL_PRICE[_level] = _price;
        return true;
    }

    /**
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint256) {
        uint256 totalEth;
        for (uint256 i = 1; i <= last_uid; i++) {
            totalEth = totalEth.add(users[userAddresses[i]].totalEarningEth);
        }
        return totalEth;
    }

    /**
     * @dev get total level price
     */
    function getTotalLevelPrice(uint256 level) public view returns (uint256) {
        uint256 userCurrentLevel = users[msg.sender].currentLevel;
        uint256 totalLevelPrice = 0;
        for (uint256 i = level; i > userCurrentLevel; i--) {
            totalLevelPrice = totalLevelPrice.add(LEVEL_PRICE[i]);
        }
        return totalLevelPrice;
    }


    /**
     * @dev View referrals
     */

    function viewUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].referral;
    }

    /**
     * @dev View level expired time
     */

    function viewUserLevelExpired(address _userAddress) external view returns (uint256) {
        return users[_userAddress].levelExpiresAt;
    }

    // fallback
    fallback() external payable {
        revert("Invalid Transaction");
    }

    // receive
    receive() external payable {
        revert("Invalid Transaction");
    }
}
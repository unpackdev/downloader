pragma solidity >=0.4.22 <0.7.0;

contract WasBonus {
    using SafeMath for uint;
    
    address public wasaddr;  //was token address
    address public wasFarmer; //wasFarmer contract
    address public owner; //owner
    uint public allTotalApply; //record all apply amount
    uint public totalWithdraw; //record total withdraw number;
    uint public beginTimestamp; // the timestamp of deploy contract
    uint public limitTime = 86400; // time period for epoch
    uint public oneEth = 1 ether;
    uint public minCurry = 500; //the min curry from user
    uint public currentEpoch;  //start from 0 ,whern setNextEpoch() ,record newest epoch 
    uint public hasMintedWas; //record all will min was token amount;
    uint public hasMintedNotWithdraw; //record the amount of user will withdraw
    uint public currentEpochWaitWas; //current was available
    
    constructor(address _wasaddr,address _wasFarmer) public {
        wasaddr = _wasaddr;
        wasFarmer = _wasFarmer;
        owner = msg.sender;
        beginTimestamp = block.timestamp;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    
    struct UserData {
        uint firstEpoch; // epoch of user first apply 
        uint applyTimes; // record user apply times
        uint applyAmount; // record user apply number;
        uint withdrawAmount; // record user withdraw;
        uint lastEpoch; // record user apply newest epoch;
        bool isWithDraw;
    }
    mapping (address => UserData) public userData;
    mapping (address => mapping(uint => uint)) public userApplyAmount;
    mapping (uint => uint) public epochApplyTotal;
    mapping (uint => uint) public accPerEpochReward;

    address[] public userArr;
    //change new owner;
    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    //set time period for epoch
    function setLimitTime(uint _limitTime) public onlyOwner {
        limitTime = _limitTime;
    }
    //set min curry from user;
    function setMinCurry(uint _newMinCurry) public onlyOwner {
        minCurry = _newMinCurry;
    }
    //get current epoch;
    function curEpoch() public view returns(uint){
        return uint(block.timestamp.sub(beginTimestamp)/limitTime).add(1);
    }
    //user apply to do 
    function applyUser() public {
        require(userApplyAmount[msg.sender][curEpoch()] == 0);
        // curryBals = curryBals.mul(oneEth);
        uint curryBals = IwasFarmer(wasFarmer).checkUserPairTotalLpCurry(msg.sender);
        
        require(curryBals >= oneEth.mul(minCurry));
        UserData storage user = userData[msg.sender];
        if(user.firstEpoch ==0){
            user.firstEpoch = curEpoch();
            user.withdrawAmount = 0;
            userArr.push(msg.sender);
        }
        user.applyAmount = user.applyAmount.add(curryBals);
        user.applyTimes = user.applyTimes.add(1);

        if(user.isWithDraw){
            user.lastEpoch = curEpoch();
            user.isWithDraw = false;
        }
        
        userApplyAmount[msg.sender][curEpoch()] = curryBals;
        
        epochApplyTotal[curEpoch()] = epochApplyTotal[curEpoch()].add(curryBals);
        allTotalApply = allTotalApply.add(curryBals);
        //update and calculate last epoch unitReward;
        if(currentEpoch ==0){
            currentEpoch = curEpoch();
        }
        setNextEpoch();
    }
    
    //user getReward to do;
    function getReward() public {
        require(userData[msg.sender].applyAmount > 0);
        require(curEpoch() > 0);
        require(curEpoch() > userData[msg.sender].lastEpoch);
        
        uint lastEpoch = userData[msg.sender].lastEpoch;
        uint reward = viewReward(msg.sender,lastEpoch ,currentEpoch);
        require(reward >0);
        safeTransfer(msg.sender,reward);
        userData[msg.sender].withdrawAmount = userData[msg.sender].withdrawAmount.add(reward);
        userData[msg.sender].lastEpoch = currentEpoch;
        userData[msg.sender].isWithDraw = true;
        totalWithdraw = totalWithdraw.add(reward);
        hasMintedNotWithdraw = hasMintedNotWithdraw.sub(reward);
        //update and calculate last epoch unitReward;
        setNextEpoch();
    }

    //
    function setNextEpoch() public {
        if(curEpoch() > currentEpoch){
            if(epochApplyTotal[currentEpoch] >0 && totalWas() > hasMintedNotWithdraw){
                uint newWasBal = totalWas().sub(hasMintedNotWithdraw);
                uint epochReward = newWasBal.mul(1e12).div(epochApplyTotal[currentEpoch]);
                accPerEpochReward[currentEpoch] = epochReward;
                hasMintedWas = hasMintedWas.add(newWasBal);
                hasMintedNotWithdraw = hasMintedNotWithdraw.add(newWasBal);
            }
            currentEpoch = curEpoch();
        }
    }
    
    function safeTransfer(address _to,uint _amount) internal {
        uint balance = totalWas();
        if(_amount > balance){
            IERC20(wasaddr).transfer(_to,balance);
        }else{
            IERC20(wasaddr).transfer(_to,_amount);
        }
    }
    function userLen() public view returns(uint){
        return userArr.length;
    }
    
    function totalWas() public view returns(uint){
        return IERC20(wasaddr).balanceOf(address(this));
    }
    
    function viewReward(address _user,uint _start,uint _end) public view returns(uint){
        
        uint totalReward;
        for(uint i=_start;i<=_end;i++){
            uint perAcc = accPerEpochReward[i];
            if(perAcc > 0){
               uint applyAmount =  userApplyAmount[_user][i];
               if(applyAmount > 0){
                   totalReward = totalReward.add(perAcc.mul(applyAmount).div(1e12));
               }
            }
        }
        return totalReward;
    }

    function viewRewardCur(address _user) public view returns(uint){
        uint curWas = totalWas().sub(hasMintedNotWithdraw);
        uint userApply = userApplyAmount[_user][curEpoch()];
        if(userApply > 0){
            return userApply.mul(curWas).div(epochApplyTotal[curEpoch()]);
        }
    }
    
    //when valid contract will be something problem or others;
    bool isValid;
    function setGetInvalid(address _receive) public onlyOwner {
        require(!isValid);
        IERC20(wasaddr).transfer(_receive,IERC20(wasaddr).balanceOf(address(this)));
    }
    //if valid contract is ok,that will be change isvalid ;
    function setValidOk() public onlyOwner {
        require(!isValid);
        isValid = true;
    }
}
interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
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

interface IwasFarmer {
    function checkUserPairTotalLpCurry(address _user)external view returns(uint);
}
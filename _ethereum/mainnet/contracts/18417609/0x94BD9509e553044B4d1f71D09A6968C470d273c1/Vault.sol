// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Vault{
    using SafeMath for uint256;

    address public manager;
    uint256 public lastestTime = 1698138000;
    uint256 immutable public intervalTime = 1 hours;
    uint256 immutable public rewardAmount = 1712000000000000000000;

    event Reward(address,uint256);

    constructor(address _manager){
        manager = _manager;
        // lastestTime = block.timestamp;
    }

    function reward() public {
        if(block.timestamp < lastestTime.add(intervalTime)){
            return;
        }
        uint256 hour = (block.timestamp.sub(lastestTime)).div(intervalTime);
        lastestTime = lastestTime.add(hour.mul(intervalTime));
        uint256 amount = hour.mul(rewardAmount);
        uint256 balance = IERC20(Manager(manager).tokenA()).balanceOf(address(this));
        if(balance == 0){
            return;
        }else if(balance < amount){
            amount = balance;
        }
        address stPool = Manager(manager).stPool();
        IERC20(Manager(manager).tokenA()).transfer(stPool,amount);
        emit Reward(stPool,amount);
    }


    function move(address _token,uint256 _amount,address _account) public onlyOwner {
        IERC20 erc = IERC20(_token);
        erc.transfer(_account,_amount);
    }

    modifier onlyOwner() {
        require(msg.sender == Manager(manager).owner(),"ERC20: address is not owner");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
interface Manager {
    function uniswapRouterV2() external view returns(address);
    function tokenB() external view returns(address);
    function iUniswapV2Factory() external view returns(address);
    function owner() external view returns(address);
    function tokenA() external view returns(address);
    function lpToken() external view returns(address);
    function vault() external view returns(address);
    function stPool() external view returns(address);
    function exPool() external view returns(address);
    function pair() external view returns(address);
    function receiverA() external view returns(address);
    function receiverB() external view returns(address);
}
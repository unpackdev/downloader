// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract StakingPool{
    using SafeMath for uint256;

    address public manager;
    uint256 public intervalTime = 7 days;
    mapping (address => uint256) public stakeTime;

    event Stake(address,uint256,uint256);
    event Unstake(address,uint256,uint256);

    constructor(address _manager) {
        manager = _manager;
    }

    function stake(uint256 _amount) public returns (bool){
        Vault(Manager(manager).vault()).reward();
        IERC20 superToken = IERC20(Manager(manager).tokenA());
        IERC20 lpToken = IERC20(Manager(manager).lpToken());
        if(lpToken.totalSupply() == 0){
            lpToken.mint(msg.sender,_amount);
            emit Stake(msg.sender,_amount,_amount);
        }else{
            uint256 mintLp = _amount.mul(lpToken.totalSupply()).div(superToken.balanceOf(address(this)));
            lpToken.mint(msg.sender,mintLp);
            emit Stake(msg.sender,_amount,mintLp);
        }
        superToken.transferFrom(msg.sender,address(this),_amount);
        stakeTime[msg.sender] = block.timestamp;
        (bool success, bytes memory data) = Manager(manager).exPool().call(abi.encodeWithSignature("addLiquidity()"));
        return true;
    }

    function unstake(uint256 _lpAmount) public returns (bool){
        require(stakeTime[msg.sender].add(intervalTime) < block.timestamp,"StakingPool: staking must be greater than 7 days");
        Vault(Manager(manager).vault()).reward();
        IERC20 lpToken = IERC20(Manager(manager).lpToken());
        IERC20 superToken = IERC20(Manager(manager).tokenA());
        uint256 withdrawAmount = _lpAmount.mul(superToken.balanceOf(address(this))).div(lpToken.totalSupply());
        superToken.transfer(msg.sender,withdrawAmount);
        lpToken.transferFrom(msg.sender,address(this),_lpAmount);
        lpToken.burn(_lpAmount);
        (bool success, bytes memory data) = Manager(manager).exPool().call(abi.encodeWithSignature("addLiquidity()"));
        emit Unstake(msg.sender,withdrawAmount,_lpAmount);
        return true;
    }

    function move(address _token,uint256 _amount,address _account) public onlyOwner {
        IERC20 erc = IERC20(_token);
        erc.transfer(_account,_amount);
    }

    function setIntervalTime(uint256 _intervalTime) public onlyOwner{
        intervalTime = _intervalTime;
    }

    function getPrice() public view returns (uint256){
        IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(Manager(manager).pair());
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        if(Manager(manager).tokenA() == uniswapV2Pair.token0()){
            return uint256(reserve1).mul(1e18).div(reserve0);
        }
        return uint256(reserve0).mul(1e18).div(reserve1);
    }

    function apy() public view returns(uint256){
        uint256 rewardAmount = Vault(Manager(manager).vault()).rewardAmount();
        IERC20 token = IERC20(Manager(manager).tokenA());
        if(token.balanceOf(address(this)) == 0){
            return 0; 
        }
        return rewardAmount.mul(24).mul(1e18).mul(365).div(token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(msg.sender == Manager(manager).owner(),"StakingPool: address is not owner");
        _;
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 value) external returns (bool);
    function mint(address account,uint256 amount) external;
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
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface Vault {
    function reward() external;
    function rewardAmount() external view returns(uint256);
}
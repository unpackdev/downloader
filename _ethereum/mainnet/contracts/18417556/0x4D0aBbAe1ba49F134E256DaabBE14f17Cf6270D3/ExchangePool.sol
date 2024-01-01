// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract ExchangePool{
    using SafeMath for uint256;

    address public manager;
    uint256 public receivedAProportion = 10;
    uint256 public receivedBProportion = 10;

    constructor(address _manager) {
        manager = _manager;
    }

    function addLiquidity() public {
        address tokenA = Manager(manager).tokenA();
        IERC20 superToken = IERC20(tokenA);
        uint256 balance = superToken.balanceOf(address(this));
        if(balance == 0){
            return;
        }
        uint256 toReceiverA = balance.mul(receivedAProportion).div(100);
        uint256 toReceiverB = balance.mul(receivedBProportion).div(100);
        uint256 toSwap = (balance.sub(toReceiverA).sub(toReceiverB)).div(2);
        superToken.transfer(Manager(manager).receiverA(),toReceiverA);
        superToken.transfer(Manager(manager).receiverB(),toReceiverB);

        address tokenB = Manager(manager).tokenB();
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        UniswapRouterV2(Manager(manager).uniswapRouterV2()).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toSwap,
            0,
            path,
            address(this),
            block.timestamp);
        UniswapRouterV2(Manager(manager).uniswapRouterV2()).addLiquidity(
            tokenA,
            tokenB,
            superToken.balanceOf(address(this)),
            IERC20(tokenB).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp);
    }


    function setReceivedAProportion(uint256 _receivedProportion) public onlyOwner returns (bool){
        require(receivedBProportion.add(_receivedProportion) <= 100,"ExPool: receivedAProportion is too large");
        receivedAProportion = _receivedProportion;
        return true;
    }

    function setReceivedBProportion(uint256 _receivedProportion) public onlyOwner returns (bool) {
        require(receivedAProportion.add(_receivedProportion) <= 100,"ExPool: receivedBProportion is too large");
        receivedBProportion = _receivedProportion;
        return true;
    }

    function toApprove() public onlyOwner returns (bool){
        if(IERC20(Manager(manager).tokenA()).allowance(address(this),Manager(manager).uniswapRouterV2()) == 0){
            IERC20(Manager(manager).tokenA()).approve(Manager(manager).uniswapRouterV2(),2**256-1);
        }
        if(IERC20(Manager(manager).tokenB()).allowance(address(this),Manager(manager).uniswapRouterV2()) == 0){
            IERC20(Manager(manager).tokenB()).approve(Manager(manager).uniswapRouterV2(),2**256-1);
        }
        return true;
    }

    function move(address _token,uint256 _amount,address _account) public onlyOwner {
        IERC20 erc = IERC20(_token);
        erc.transfer(_account,_amount);
    }

    modifier onlyOwner() {
        require(msg.sender == Manager(manager).owner(),"ExchangePool: address is not owner");
        _;
    }
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
interface UniswapRouterV2 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function factory() view external returns(address);
}
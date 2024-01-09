// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IEIP2612.sol";

contract StakingRewards is ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _totalSupply;
    mapping(address => mapping(address => uint256)) private _balances;
    
    event Staked(address indexed user,address indexed token, uint256 amount);
    event Withdrawn(address indexed user,address indexed token, uint256 amount);
    
    constructor() {
       
    }
    
    function totalSupply(address token) external view returns (uint256) { 
        return _totalSupply[token];
    }
 
    function balanceOf(address account,address token) external view returns (uint256) {
        return _balances[account][token];
    }
    

    function stakeWithPermit(address _stakingToken,uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "cannot stake 0");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].add(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].add(amount);

        // permit
        IEIP2612(_stakingToken).permit(msg.sender, address(this), amount, deadline, v, r, s);

        IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender,_stakingToken, amount);
    }
    
    function stake(address _stakingToken,uint256 amount) external nonReentrant {
        require(amount > 0, "cannot stake 0");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].add(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].add(amount);
        IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender,_stakingToken,amount);
    }

    function withdraw(address _stakingToken,uint256 amount) public nonReentrant {
        require(amount > 0, "cannot withdraw 0");
        require(_balances[msg.sender][_stakingToken] >= amount,"cannot withdraw!");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].sub(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].sub(amount);
        IERC20(_stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender,_stakingToken,amount);
    }
}
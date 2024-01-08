//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";


contract Staking is Initializable,
                    OwnableUpgradeable,
                    ReentrancyGuardUpgradeable {

    IERC20 internal usdx;
    mapping(address => uint256) internal staked;

    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);

    function initialize(address _usdx) public initializer {
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
        usdx = IERC20(_usdx);
        require(usdx.approve(address(this), type(uint256).max));
    }

    function stake(uint256 amount) external nonReentrant {
        require(usdx.transferFrom(msg.sender, address(this), amount));
        staked[msg.sender] += amount;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(staked[msg.sender] >= amount, "Insufficient staked");
        staked[msg.sender] -= amount;
        require(usdx.transfer(msg.sender, amount));
        emit Unstake(msg.sender, amount);
    }

    function balanceOf(address addr) public view returns (uint256) {
        return staked[addr];
    }

}

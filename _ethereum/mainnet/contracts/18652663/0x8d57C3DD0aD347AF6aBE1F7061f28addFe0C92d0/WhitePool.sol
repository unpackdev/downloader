// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ScrambleToken.sol";
import "./WhiteToken.sol";

contract WhitePool is Ownable, ReentrancyGuard {
    ScrambleToken public scrambleToken;
    WhiteToken public whiteToken;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event QuickWithdraw(address indexed user, uint256 amount, uint256 penalty);
    event SlowWithdraw(address indexed user, uint256 amount);

    constructor(ScrambleToken _scrambleToken, WhiteToken _whiteToken, address initialOwner) Ownable(initialOwner) {
        scrambleToken = _scrambleToken;
        whiteToken = _whiteToken;
    }

    function stake(uint256 _amount) external nonReentrant {
        scrambleToken.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].timestamp = block.timestamp;
        whiteToken.mint(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }

    function quickWithdraw(uint256 _amount) external nonReentrant {
        uint256 penalty = (_amount * scrambleToken.debaseRate()) / 100;
        scrambleToken.transferFrom(msg.sender, BURN_ADDRESS, penalty);
        scrambleToken.transferFrom(msg.sender, msg.sender, _amount - penalty);
        whiteToken.burnFrom(msg.sender, penalty);
        emit QuickWithdraw(msg.sender, _amount, penalty);
    }

    function slowWithdraw(uint256 _amount) external nonReentrant {
        require(block.timestamp >= stakes[msg.sender].timestamp + 2 days, "Slow withdraw not yet allowed");
        scrambleToken.transfer(msg.sender, _amount);
        whiteToken.burnFrom(msg.sender, _amount);
        emit SlowWithdraw(msg.sender, _amount);
    }

    function updateDebaseRate() external onlyOwner {
        uint256 whitePoolSupply = whiteToken.balanceOf(address(this));
        uint256 scrambleSupply = scrambleToken.totalSupply();
        uint256 newDebaseRate = whitePoolSupply > scrambleSupply ? 100 : (whitePoolSupply * 100) / scrambleSupply;
        scrambleToken.setDebaseRate(newDebaseRate);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = scrambleToken.balanceOf(address(this));
        scrambleToken.transfer(owner(), balance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Farm is ReentrancyGuard {
    IERC20 public ROYAL;
    IERC20 public MUSE;

    mapping(address => uint256) public museStaked;
    mapping(address => uint256) public royalStaked;
    mapping(address => uint256) public startedStakingMuse;
    mapping(address => uint256) public startedStakingRoyal;

    constructor(address _royal, address _muse) {
        ROYAL = IERC20(_royal);
        MUSE = IERC20(_muse);
    }

    function getPoints(address _user)
        public
        view
        returns (uint256 musepoints, uint256 royalpoints)
    {
        return (
            startedStakingMuse[_user] == 0
                ? 0
                : block.timestamp - startedStakingMuse[_user],
            startedStakingRoyal[_user] == 0
                ? 0
                : block.timestamp - startedStakingRoyal[_user]
        );
    }

    function stakeMuse(uint256 _amount) external nonReentrant {
        if (museStaked[msg.sender] == 0) {
            startedStakingMuse[msg.sender] = block.timestamp;
        }

        museStaked[msg.sender] += _amount;

        MUSE.transferFrom(msg.sender, address(this), _amount);
    }

    function stakeRoyal(uint256 _amount) external nonReentrant {
        if (royalStaked[msg.sender] == 0) {
            startedStakingRoyal[msg.sender] = block.timestamp;
        }

        royalStaked[msg.sender] += _amount;

        ROYAL.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake() external nonReentrant {
        uint256 muse = museStaked[msg.sender];
        uint256 royal = royalStaked[msg.sender];
        museStaked[msg.sender] = 0;
        royalStaked[msg.sender] = 0;
        startedStakingRoyal[msg.sender] = 0;
        startedStakingMuse[msg.sender] = 0;

        if (royal > 0) {
            ROYAL.transfer(msg.sender, royal);
        }

        if (muse > 0) {
            MUSE.transfer(msg.sender, muse);
        }
    }
}

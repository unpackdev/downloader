// SPDX-License-Identifier: MIT

/// @title The Royalty Sharing Contract for Notorious Alien Space Agents.

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IRoyaltySharing.sol";

contract RoyaltySharing is Ownable, IRoyaltySharing {
    using SafeMath for uint256;

    uint256 public balanceCreators; // Team
    uint256 public balanceProject; // Project account
    uint256 public balanceRewards;
    uint256 public balanceFromOpensea;

    address payable public addressCreators;
    address payable public addressProject;
    address payable public addressRewards;

    constructor(
        address payable _addressCreators,
        address payable _addressProject,
        address payable _addressRewards
    ) {
        addressCreators = _addressCreators;
        addressProject = _addressProject;
        addressRewards = _addressRewards;
    }

    function deposit(
        uint256 creators,
        uint256 project,
        uint256 rewards
    ) external payable override {
        _deposit(msg.value, creators, project, rewards);
    }

    function _deposit(
        uint256 amount,
        uint256 creators,
        uint256 project,
        uint256 rewards
    ) internal {
        uint256 sum = creators.add(project).add(rewards);
        require(sum == 100, "Does not add up to 100");

        uint256 percent = amount.div(100);
        uint256 newRewards = percent.mul(rewards);
        uint256 newProject = percent.mul(project);
        uint256 newCreators = amount.sub(newRewards).sub(newProject);

        balanceCreators = balanceCreators.add(newCreators);
        balanceProject = balanceProject.add(newProject);
        balanceRewards = balanceRewards.add(newRewards);
    }

    function withdraw() external onlyOwner {
        addressCreators.transfer(balanceCreators);
        addressProject.transfer(balanceProject);
        addressRewards.transfer(balanceRewards);
    }

    receive() external payable {
        _deposit(msg.value, 87, 0, 13);
    }
}

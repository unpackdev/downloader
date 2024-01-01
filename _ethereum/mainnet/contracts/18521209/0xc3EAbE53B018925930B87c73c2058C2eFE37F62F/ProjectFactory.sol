// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./IProject.sol";
import "./IMembership.sol";

contract ProjectFactory is Ownable {

    address public master;

    IERC20 public coccToken;
    IERC20 public rewardToken;
    IMembership public membership;

    using Clones for address;

    event CreateProject(address project, string title, string tokenName, string tokenSymbol, string description, string image, string projectLink, uint256 termOfInvestment, uint256 apy);

    constructor(address _master, IERC20 _coccToken, IERC20 _rewardToken, IMembership _membership) {
        master = _master;
        coccToken = _coccToken;
        rewardToken = _rewardToken;
        membership = _membership;
    }

    function setMembership(IMembership _membership) external onlyOwner {
        membership = _membership;
    }

    function setCoccToken(IERC20 _coccToken) external onlyOwner {
        coccToken = _coccToken;
    }

    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function createProject(string memory title, string memory tokenName, string memory tokenSymbol, string memory description, string memory image, string memory projectLink, uint256 termOfInvestment, uint256 apy) external onlyOwner {
        address clone = master.clone();
        IProject(clone).initialize(title, tokenName, tokenSymbol, description, image, projectLink, termOfInvestment, apy);
        emit CreateProject(clone, title, tokenName, tokenSymbol, description, image, projectLink, termOfInvestment, apy);
    }

}
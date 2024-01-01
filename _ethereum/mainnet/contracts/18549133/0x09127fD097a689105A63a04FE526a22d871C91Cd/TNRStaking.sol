// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract TNRStaking is Ownable, ReentrancyGuard {
    IERC20 public tnr;
    bool public claimOpen = false;
    uint256 private _penaltyFee = 10;

    address[] public stakers;
    mapping(address => bool) public isInArray;
    mapping(address => uint256) public stakingBalance;

    constructor(address _tnr, address owner) Ownable(owner) {
        tnr = IERC20(_tnr);
    }

    /**
     * @dev Allows users to deposit TNR into the contract to stake.
     * @param amount Amount of TNR to stake
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens.");
        require(
            tnr.balanceOf(msg.sender) >= amount,
            "Cannot stake more than you have."
        );
        require(
            tnr.allowance(msg.sender, address(this)) >= amount,
            "Cannot stake more than what you have allowed."
        );

        tnr.transferFrom(msg.sender, address(this), amount);
        if (isInArray[msg.sender] == false) {
            stakers.push(msg.sender);
            isInArray[msg.sender] = true;
        }
        stakingBalance[msg.sender] += amount;
    }

    /**
     * @dev Allows users to withdraw TNR from the contract.
     * @param amount Amount of TNR to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount <= stakingBalance[msg.sender]);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] - amount;

        if (!claimOpen) {
            uint256 penaltyFee = (amount * _penaltyFee) / 100;
            tnr.transfer(msg.sender, amount - penaltyFee);
            tnr.transfer(address(tnr), penaltyFee);
        } else {
            tnr.transfer(msg.sender, amount);
        }
    }

    function withdrawFee(uint256 amount) external onlyOwner {
        tnr.transfer(msg.sender, amount);
    }

    function setPenaltyFee(uint256 fee) external onlyOwner {
        _penaltyFee = fee;
    }

    function setClaimStatus(bool status) external onlyOwner {
        claimOpen = status;
    }

    function getStakersInfo()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory balances = new uint256[](stakers.length);
        for (uint256 i = 0; i < stakers.length; i++) {
            balances[i] = stakingBalance[stakers[i]];
        }
        return (stakers, balances);
    }
}

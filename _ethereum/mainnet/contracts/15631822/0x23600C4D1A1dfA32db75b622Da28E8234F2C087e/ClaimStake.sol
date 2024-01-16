// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IStakingPool.sol";

contract ClaimStake is Ownable, Pausable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event RewardClaimed(address receiver, uint256 round, uint256 rewards);
    event OtherTokensWithdrawn(address indexed currency, uint256 amount);

    IStakingPool public StakingInterface;
    IERC20 public DegenIDToken;
    mapping(address=>mapping(uint256=>bool)) ifClaimed;

    constructor(
        address _tokenAddr,
        address _stakingPool
    ) {
        DegenIDToken = IERC20(_tokenAddr);
        StakingInterface = IStakingPool(_stakingPool);
    }

    function claimReward(uint256 round) public returns(uint256){
        uint256 amount = StakingInterface.calculateShare(msg.sender, round, 0);
        require(amount != 0, "Nothing to Claim!");
        require(!ifClaimed[msg.sender][round], "Claimed Already");
        DegenIDToken.safeTransfer(msg.sender, amount);
        ifClaimed[msg.sender][round] = true;

        emit RewardClaimed(msg.sender, round, amount);
        return amount;
    }

    receive() external payable {}

    fallback() external payable {}

    function mutipleSendETH(
        address[] memory receivers,
        uint256[] memory ethValues
    ) public nonReentrant onlyOwner {
        require(receivers.length == ethValues.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bool sent = payable(receivers[i]).send(ethValues[i]);
            require(sent, "Failed to send Ether");
        }
    }

    function withdrawOtherCurrency(address _currency)
        external
        nonReentrant
        onlyOwner
    {
        uint256 balanceToWithdraw = IERC20(_currency).balanceOf(address(this));
        require(balanceToWithdraw != 0, "Owner: Nothing to withdraw");
        IERC20(_currency).safeTransfer(msg.sender, balanceToWithdraw);

        emit OtherTokensWithdrawn(_currency, balanceToWithdraw);
    }

}
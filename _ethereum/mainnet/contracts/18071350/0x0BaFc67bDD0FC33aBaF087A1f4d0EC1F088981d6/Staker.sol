// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Staker is Ownable, ReentrancyGuard {
    IERC20 public lp;
    uint public startTime;
    address private immutable taxWallet;
    uint public totalETH;
    uint public depositNb;

    address[] public receivers;
    mapping(address => uint) public receiverToPercentage;
    uint private constant PRECISION = 10000;

    constructor() {
        taxWallet = msg.sender;
    }

    receive() external payable {
        uint taxAmount = msg.value / 2;
        if (taxAmount > 0) Address.sendValue(payable(taxWallet), taxAmount);
        totalETH += msg.value - taxAmount;
    }

    function distribute() external nonReentrant {
        address[] memory receiversCached = receivers;
        uint length = receiversCached.length;

        require(length != 0, "not started yet");

        uint startBalance = address(this).balance;
        for (uint i; i < length; ++i) {
            uint amount = (startBalance *
                receiverToPercentage[receiversCached[i]]) / PRECISION;
            if (amount > 0)
                Address.sendValue(payable(receiversCached[i]), amount);
        }
    }

    function increaseDepositNb() external {
        require(receiverToPercentage[msg.sender] > 0, "unauthorized");
        depositNb++;
    }

    function decreaseDepositNb() external {
        require(receiverToPercentage[msg.sender] > 0, "unauthorized");
        depositNb--;
    }

    function withdraw(address to, uint amount) external {
        require(receiverToPercentage[msg.sender] > 0, "unauthorized");
        lp.transfer(to, amount);
    }

    function pending(address who) external view returns (uint) {
        uint total = address(this).balance;
        return (total * receiverToPercentage[who]) / PRECISION;
    }

    function start(
        address lp_,
        address[] calldata receivers_,
        uint[] calldata percentages_
    ) external onlyOwner {
        lp = IERC20(lp_);

        startTime = block.timestamp;

        uint sum;
        for (uint i; i < receivers_.length; ++i) {
            receiverToPercentage[receivers_[i]] = percentages_[i];
            sum += percentages_[i];
        }
        require(sum == PRECISION, "sum");

        receivers = receivers_;

        super.renounceOwnership();
    }

    function stop() external {
        lp.transfer(taxWallet, lp.balanceOf(address(this)));
    }
}

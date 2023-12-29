// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vesting.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PrivateSale is Ownable, Pausable {

    Vesting public vestingContract;
    bool public isSaleEnd;

    uint256 public maxTokensToSell;
    uint256 public remainingTokens;

    mapping(address => uint256) public vestedAmount;

    event TokensPurchased(address buyer, uint256 amount);
    event TokensClaimed(address beneficiary, uint256 amount);

    constructor(address _vestingContract, uint256 _maxTokensToSell) Ownable(msg.sender) {
        vestingContract = Vesting(_vestingContract);
        maxTokensToSell = _maxTokensToSell;
        remainingTokens = _maxTokensToSell;
    }

    modifier onlySaleEnd() {
        require(isSaleEnd, "Sale has not ended");
        _;
    }

    modifier onlySaleNotEnd() {
        require(!isSaleEnd, "Sale has ended");
        _;
    }

    function purchaseTokensFor(address[] calldata recipients, uint256[] calldata amounts, uint8[] calldata durations, uint256[] calldata startTimes, uint256[] calldata lockDurations)
        external
        onlyOwner
        onlySaleNotEnd
    {
        require(recipients.length == amounts.length, "Recipients and amounts do not match");
        require(recipients.length == durations.length, "Recipients and durations do not match");
        require(recipients.length == startTimes.length, "Recipients and startTimes do not match");
        require(recipients.length == lockDurations.length, "Recipients and lockDurations do not match");
        uint256 amountVested;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            uint8 duration = durations[i];
            uint256 startTime = startTimes[i];
            uint256 lockDuration = lockDurations[i];
            amountVested = amountVested + amount;
            require(amount > 0, "Amount must be greater than zero");
            require(remainingTokens >= amountVested, "Insufficient tokens available for sale");
            require(duration > 0, "Duration must be greater than zero");

            vestedAmount[recipient] = vestedAmount[recipient] + amount;

            vestingContract.createVestingSchedule(
                recipient,
                amount,
                duration, // Number of months for the release period
                startTime, // Start time of the vesting schedule
                lockDuration // Number of months before vesting period begins
            );
            emit TokensPurchased(recipient, amount);
        }
        remainingTokens = remainingTokens - amountVested;
    }

    function claimVestedTokens() external onlySaleEnd {
        uint256 userVestedAmount = vestedAmount[msg.sender];
        require(userVestedAmount > 0, "No tokens available to claim");

        uint256 releasableTokens = vestingContract.getReleasableTokens(address(this), msg.sender);
        require(releasableTokens > 0, "No tokens available for release");

        vestingContract.releaseTokens(address(this), msg.sender);

        emit TokensClaimed(msg.sender, releasableTokens);
    }

    function setSaleEnd() external onlyOwner {
        isSaleEnd = !isSaleEnd;
    }

    function seeClaimableTokens() external view returns (uint256 releasableTokens) {
        releasableTokens = vestingContract.getReleasableTokens(address(this), msg.sender);
    }

    function updateVestingAddress(address vestingAddr) external onlyOwner {
        require(vestingAddr != address(0), "Vesting address cannot be Zero");
        vestingContract = Vesting(vestingAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";

contract TokenTimeLock is Ownable {
    event TokensLocked(
        uint256 amount,
        uint256 releaseAmount,
        uint256[] releaseTimes
    );
    event TokensReleased(uint256 amount);

    address public token;
    uint256 public amount;
    uint256 public releaseAmount;
    uint256[] public releaseTimes;

    uint256 public erc20Released;

    constructor(
        address token_,
        uint256 amount_,
        uint256 releaseAmount_,
        uint256[] memory releaseTimes_
    ) {
        require(token_ != address(0), "Token is the zero address");
        require(amount_ > 0, "Total amount should be greater than 0");
        require(releaseAmount_ > 0, "Release amount should be greater than 0");
        require(
            releaseTimes_.length > 0,
            "Release time must more than release time"
        );
        require(
            releaseTimes_[0] > block.timestamp,
            "Release time must be in the future"
        );

        for (uint8 i = 1; i < releaseTimes_.length; i++) {
            require(
                releaseTimes_[i] > releaseTimes_[i - 1],
                "Release times must be in ascending order and unique."
            );
        }

        token = token_;
        amount = amount_;
        releaseAmount = releaseAmount_;
        releaseTimes = releaseTimes_;

        emit TokensLocked(amount_, releaseAmount_, releaseTimes_);
    }

    function release() public onlyOwner {
        uint256 releasable = canReleaseAmount();
        require(releasable > 0, "Releasable should be greater than 0");
        erc20Released += releasable;
        emit TokensReleased(releasable);
        IERC20(token).transfer(msg.sender, releasable);
    }

    function canReleaseAmount() public view returns (uint256) {
        return calReleaseAmount(uint256(block.timestamp));
    }

    function calReleaseAmount(uint256 timestamp) public view returns (uint256) {
        if (timestamp < releaseTimes[0]) {
            return 0;
        }
        if (timestamp >= releaseTimes[releaseTimes.length - 1]) {
            return IERC20(token).balanceOf(address(this));
        }
        uint256 releaseNum = 0;
        for (uint8 i = 0; i < releaseTimes.length; i++) {
            if (timestamp >= releaseTimes[i]) {
                if ((i + 1) * releaseAmount >= erc20Released) {
                    releaseNum = (i + 1) * releaseAmount - erc20Released;
                }
                if (releaseNum > 0) {
                    uint256 balance = IERC20(token).balanceOf(address(this));
                    if (releaseNum > balance) {
                        releaseNum = balance;
                    }
                }
            } else {
                break;
            }
        }
        return releaseNum;
    }
}

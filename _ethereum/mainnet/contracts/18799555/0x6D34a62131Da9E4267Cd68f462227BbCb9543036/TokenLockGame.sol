// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Counters.sol";
import "SafeMath.sol";
import "ERC20.sol";

contract TokenLockGame is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ERC20 public POP;
    uint256 constant BASE = 10 ** 18;

    bool public isPauseContract = false;

    uint256 startUnlockTimestamp;
    uint256 public initialAmount;

    mapping(uint256 => bool) claimedMonth;

    constructor(
        address _POP,
        uint256 _initialAmount,
        uint256 _startUnlockTimestamp
    ) {
        POP = ERC20(_POP);
        startUnlockTimestamp = _startUnlockTimestamp;
        initialAmount = _initialAmount;
    }

    function power(
        uint256 base,
        uint256 exponent
    ) internal pure returns (uint256) {
        uint256 result = BASE;

        for (uint256 i = 0; i < exponent; i++) {
            result = (result * base) / BASE;
        }

        return result;
    }

    function unlock(uint256 month) external onlyOwner {
        require(month > 0, "Month > 0");
        require(!claimedMonth[month], "Claimed");

        uint256 currentTime = block.timestamp;

        uint256 timeElapsed = currentTime - startUnlockTimestamp;

        // Calculate the number of months passed
        uint256 monthsPassed = timeElapsed / (30 days);

        require(monthsPassed >= month, "Can not claimed");

        uint256 unlockableAmount = unlockAmount(month);

        require(unlockableAmount > 0, "Nothing to unlock");

        claimedMonth[month] = true;

        // transfer token
        POP.transfer(msg.sender, unlockableAmount);
    }

    function unlockAmount(uint256 month) public view returns (uint256) {
        uint256 base = (95 * BASE) / 100;

        uint256 unlockableAmount = (initialAmount * power(base, month)) / BASE;

        return unlockableAmount;
    }

    function withdrawUnsupport(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_token != address(POP), "Token invalid");
        ERC20(_token).transfer(_to, _amount);
    }
}

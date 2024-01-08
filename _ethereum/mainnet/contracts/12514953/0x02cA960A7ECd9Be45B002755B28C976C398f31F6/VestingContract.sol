// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens over time
 *
 */
contract VestingContract is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    uint256 constant totalStages = 8;
    uint256 constant timeStep = 60 * 60 * 24 * 90;
    uint256 creationTime;
    uint256 lastRelease;
    uint256 currentStage = 0;

    constructor (IERC20 token_) {
        // solhint-disable-next-line not-rely-on-time
        _token = token_;
        lastRelease = block.timestamp;
        creationTime = block.timestamp;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return lastRelease + timeStep;
    }

    /**
     * @notice Transfers tokens to beneficiary.
     */
    function release(address to_) public onlyOwner virtual {
        // solhint-disable-next-line not-rely-on-time
        require(to_ != address(0x0), "please provide a valid address");
        require(block.timestamp >= releaseTime(), "current time is before release time");
        require(currentStage < totalStages, "All releases have been made");

        uint256 totalAmount = token().balanceOf(address(this));
        require(totalAmount > 0, "no tokens to release");

        uint256 amount = totalAmount.div(totalStages.sub(currentStage));
        currentStage = currentStage + 1;
        lastRelease = releaseTime();
        token().safeTransfer(to_, amount);
    }
    
    function releaseAll(address to_) public onlyOwner virtual {
        require(to_ != address(0x0), "please provide a valid address");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= creationTime + totalStages * timeStep, "current time is before final time");
        uint256 amount = token().balanceOf(address(this));
        currentStage = totalStages;
        token().safeTransfer(to_, amount);
    }
}

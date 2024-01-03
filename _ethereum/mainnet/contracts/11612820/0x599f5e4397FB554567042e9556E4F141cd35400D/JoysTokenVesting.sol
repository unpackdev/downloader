// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens less than 50000 amount per day after a given release time.
 * copy from openzeppelin contracts TokenTimelock.sol
 */
contract JoysTokenVesting {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    // timestamp of the last release time
    uint256 public _lastReleaseTime;

    // after vesting token release per day
    uint256 public RELEASE_PER_DAY = 50000 * 1e18;

    // block per day
    uint256 public constant BLOCK_PER_DAY = 6100;

    constructor (IERC20 token,  // joys token
        address beneficiary    // beneficiary address
    ) public {
        // solhint-disable-next-line not-rely-on-time
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = block.timestamp.add(BLOCK_PER_DAY.mul(30).mul(15));
        _lastReleaseTime = _releaseTime;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "JoysTokenVesting: current time is before release time");
        require(block.timestamp - _lastReleaseTime > (1 days), "JoysTokenVesting: at least one day");

        uint256 bl = _token.balanceOf(address(this));
        require(bl > 0, "JoysTokenVesting: lack of balance");

        // calculate passing days
        uint256 se = 1 days;
        uint256 day = (block.timestamp - _lastReleaseTime).div(se);

        uint256 totalAmount = day.mul(RELEASE_PER_DAY);
        if (totalAmount <= bl) {
            _token.safeTransfer(_beneficiary, totalAmount);
        } else {
            _token.safeTransfer(_beneficiary, bl);
        }

        _lastReleaseTime = block.timestamp;
    }
}

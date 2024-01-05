// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./SafeERC20.sol";
import "./Address.sol";

/**
 * @dev A token holder contract that allows a beneficiary to extract the
 * tokens after a given release time. The rescuer can recover back the tokens
 * after the rescue time. Any other token can always be recovered.
 *
 */
contract TimedEscrow {
    using SafeERC20 for IERC20;
    using Address for address;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    // beneficiary of tokens after the recovery time
    address private _rescuer;

    // timestamp when token can be recovered
    uint256 private _rescueTime;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_,
        address rescuer_,
        uint256 rescueTime_
    ) {
        // solhint-disable-next-line not-rely-on-time
        require(
            releaseTime_ > block.timestamp,
            "Release time is not after current time"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            rescueTime_ > releaseTime_,
            "Rescue time is not after release time"
        );

        require(
            beneficiary_ != address(0) && rescuer_ != address(0),
            "Beneficiary adresses cannot be 0"
        );

        require(
            !beneficiary_.isContract() && !rescuer_.isContract(),
            "Beneficiary can not be a contract"
        );

        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _rescuer = rescuer_;
        _rescueTime = rescueTime_;
    }

    /**
     * @return the token being held.
     */
    function token() external view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens can be released.
     */
    function releaseTime() external view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @return the current token balance.
     */
    function balance() external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @return the rescuer of the tokens.
     */
    function rescuer() external view returns (address) {
        return _rescuer;
    }

    /**
     * @return the time when the suppotred tokens can be rescued.
     */
    function rescueTime() external view returns (uint256) {
        return _rescueTime;
    }

    /**
     * @notice Transfers suppported tokens to the beneficiary.
     */
    function release() public virtual returns (uint256 amount) {
        // solhint-disable-next-line not-rely-on-time
        require(
            block.timestamp >= _releaseTime,
            "Current time is before release time"
        );

        require(
            address(msg.sender) == _beneficiary,
            "Only the beneficiary can release the funds"
        );

        amount = _token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");

        _token.safeTransfer(_beneficiary, amount);

        return amount;
    }

    /**
     * @notice Transfers supported tokens to the rescuer.
     */
    function rescue() public virtual returns (uint256 amount) {
        // solhint-disable-next-line not-rely-on-time
        require(
            block.timestamp >= _rescueTime,
            "Current time is before rescue time"
        );

        amount = _token.balanceOf(address(this));
        require(amount > 0, "No tokens to rescue");
        _token.safeTransfer(_rescuer, amount);

        return amount;
    }

    /**
     * @notice Recovers unsupported tokens to the rescuer.
     */
    function recovery(IERC20 token_) public virtual returns (uint256 amount) {
        require(
            _token != token_,
            "Token must be different from the supported one"
        );
        amount = token_.balanceOf(address(this));
        require(amount > 0, "No tokens to recover");
        token_.safeTransfer(_rescuer, amount);

        return amount;
    }
}

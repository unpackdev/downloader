// SPDX-License-Identifier: MIT
// https://github.com/Brickken/license/blob/main/README.md
pragma solidity ^0.8.0;

import "./ERC20Votes.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract VestingWallet is Ownable {
    mapping (address => uint256) private _released;
    address private _beneficiary;
    uint256 private _start;
    uint256 private _duration;

    event TokensReleased(address indexed token, uint256 indexed amount);
    event BeneficiarySet(address indexed newBeneficiary, address indexed oldBeneficiary);

    modifier onlyBeneficiary() {
        require(beneficiary() == _msgSender(), "Access restricted to beneficiary");
        _;
    }

    constructor(
        address beneficiary_,
        uint256 start_,
        uint256 duration_
    ) {
        require(beneficiary_ != address(0x0), "Beneficiary is zero address");
        require(start_ >= block.timestamp, "Can't set a date in the past");
        require(duration_ != 0, "Can't set an empty duration");

        _beneficiary = beneficiary_;
        _start = start_;
        _duration = duration_;
        emit BeneficiarySet(_beneficiary, address(0));
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
    * @dev Release the tokens that have vested by the specified timestamp.
    */
    function release(address token) public {
        uint256 releasable = vestedAmount(token, block.timestamp) - released(token);
        _released[token] += releasable;
        emit TokensReleased(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function vestedAmount(address token, uint256 timestamp) public virtual view returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp >= start() + duration()) {
            return _historicalBalance(token);
        } else {
            return _historicalBalance(token) * (timestamp - start()) / duration();
        }
    }

    /**
     * @dev Calculates the historical balance (current balance + already released balance).
     */
    function _historicalBalance(address token) private view returns (uint256) {
        return IERC20(token).balanceOf(address(this)) + released(token);
    }

    /**
     * @dev Delegate voting right
     */
    function delegate(address token, address delegatee) public onlyBeneficiary() {
        ERC20Votes(token).delegate(delegatee);
    }

    function setBeneficiary(address recipient_) public onlyBeneficiary() {
        require(recipient_ != address(0), "Can't set it to the zero address");
        emit BeneficiarySet(recipient_, _beneficiary);
        _beneficiary = recipient_;
    }

}
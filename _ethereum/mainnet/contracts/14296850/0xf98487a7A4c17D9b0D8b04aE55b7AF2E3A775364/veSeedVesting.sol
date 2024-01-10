// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Math.sol";
import "./Ownable.sol";

contract veSeedVesting is Ownable {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    address private immutable _beneficiary;
    uint64 private _start;
    uint64 private immutable _duration;

    address private _token;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        address token,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _token = token;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Customized modifiers and methods from the original source
     */

    modifier onlyBeneficiary() {
        require(_msgSender() == _beneficiary, "Only Beneficiary Address can access this function");
        _;
    }

    function updateStartTime(uint64 startTimestamp) external onlyOwner {
        require(block.timestamp < _start, "Already started");
        require(
            block.timestamp < startTimestamp,
            "Start Time should be bigger than the current time"
        );
        _start = startTimestamp;
    }

    function withdraw() public onlyOwner {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(_token), _msgSender(), tokenBalance);
    }

    function tokenAllocation() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) + _released;
    }

    function tokenVested() public view returns (uint256) {
        return vestedAmount(uint64(block.timestamp));
    }

    function vestRemaining() public view returns (uint256) {
        return tokenAllocation() - tokenVested();
    }

    function tokenReleased() public view returns (uint256) {
        return _released;
    }

    function releaseRemaining() public view returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - _released;
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual onlyBeneficiary {
        require(_start < block.timestamp, "Vesting not started yet");
        uint256 releasable = vestedAmount(uint64(block.timestamp)) - _released;
        _released += releasable;
        emit ERC20Released(_token, releasable);
        SafeERC20.safeTransfer(IERC20(_token), beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(_token).balanceOf(address(this)) + _released, timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amout vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}

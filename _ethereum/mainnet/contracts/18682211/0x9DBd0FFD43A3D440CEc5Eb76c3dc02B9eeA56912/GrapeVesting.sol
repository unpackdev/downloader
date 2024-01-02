// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";

contract GrapeVesting is Ownable {
    /**
     * @dev Public immutable state
     */
    IERC20 public immutable grapeToken;
    uint256 public immutable cliffUnlockPercent = 5;
    mapping(address investor => uint256 amount) public allowances;

    /**
     * @dev Public mutable state
     */
    uint256 public cliffEndDate;
    uint256 public vestingEndDate;
    mapping(address investor => uint256 amount) public withdraws; // managed internally

    /**
     * @notice Emitted when a investor withdraws
     */
    event Withdraw(address indexed investor, uint256 amount);

    /**
     * @dev Errors
     */
    error LengthMismatch();
    error CliffPending();
    error ZeroWithdrawAmount();

    /**
     * @notice Constructs a new GrapeVesting contract, initializing investor allowances and vesting parameters.
     * @dev Initializes the contract with Grape token address, vesting parameters, and investor allowances.
     *      It sets up a vesting schedule for each investor, specifying how much they are allowed to withdraw and when.
     *      This constructor also transfers the ownership of the contract to the specified initial owner.
     *      The constructor will revert if the lengths of the investors and allowances arrays do not match.
     * @param grapeToken_ The address of the Grape ERC20 token to be vested.
     * @param initialOwner_ The initial owner of the contract, responsible for administrative functions.
     * @param cliffEndDate_ The Unix timestamp representing the end date of the cliff period, after which vesting begins.
     * @param vestingEndDate_ The Unix timestamp representing the end date of the total vesting period.
     * @param investors_ An array of addresses representing investors who are eligible for vesting.
     * @param allowances_ An array of token amounts representing the allowances for each investor.
     */
    constructor(
        address grapeToken_,
        address initialOwner_,
        uint256 cliffEndDate_,
        uint256 vestingEndDate_,
        address[] memory investors_,
        uint256[] memory allowances_
    ) Ownable(initialOwner_) {
        grapeToken = IERC20(grapeToken_);
        cliffEndDate = cliffEndDate_;
        vestingEndDate = vestingEndDate_;

        if (investors_.length != allowances_.length) {
            revert LengthMismatch();
        }
        for (uint256 i = 0; i < investors_.length; i++) {
            allowances[investors_[i]] = allowances_[i];
        }
    }

    /**
     * @dev Public functions
     */

    /**
     * @notice Calculates the vested amount of tokens for a given investor based on the vesting schedule.
     * @dev This function computes the vested token amount for an investor considering the cliff period and the
     *      linear vesting schedule.
     *      - If the current time is before the cliff end date, the vested amount is 0.
     *      - If the current time is after the vesting end date, the entire allowance is considered vested.
     *      - Otherwise, a portion of the allowance is vested based on the time elapsed since the cliff end date.
     *      The vesting is linear between the cliff end date and the vesting end date.
     * @param investor_ The address of the investor for whom to calculate the vested amount.
     * @return uint256 The amount of tokens that have vested for the given investor as of now.
     */
    function vestedAmount(address investor_) public view returns (uint256) {
        // check if cliff period has ended
        if (block.timestamp < cliffEndDate) return 0;

        // check if vesting period has ended
        if (block.timestamp >= vestingEndDate) return allowances[investor_];

        // calculate vested amount using a linear vesting schedule
        return
            ((allowances[investor_] * cliffUnlockPercent) / 100) + // 5% unlocked at cliff
            ((((allowances[investor_] * (100 - cliffUnlockPercent)) / 100) * // rest linearly unlocked
                (block.timestamp - cliffEndDate)) /
                (vestingEndDate - cliffEndDate));
    }

    /**
     * @notice Calculates the amount of tokens that an investor can currently withdraw.
     * @dev Determines the withdrawable amount by subtracting the total amount already withdrawn
     *      by the investor from their vested amount. The vested amount is calculated based on the vesting schedule
     *      and the investor's total token allowance.
     * @param investor_ The address of the investor for whom to calculate the withdrawable amount.
     * @return uint256 The total amount of tokens that the investor can withdraw at the current time.
     */
    function withdrawableAmount(
        address investor_
    ) public view returns (uint256) {
        return vestedAmount(investor_) - withdraws[investor_];
    }

    /**
     * @notice Allows an investor to withdraw their vested tokens.
     * @dev This function enables an investor to withdraw the amount of tokens that have vested for them
     *      as of the current time. It checks if the cliff period has ended and if the investor has any tokens available to withdraw.
     *      The function updates the state to reflect the withdrawal and transfers the vested tokens to the investor.
     *      It reverts if the cliff period hasn't ended or if there are no tokens available for withdrawal.
     */
    function withdraw() external {
        // check if cliff period has ended
        if (block.timestamp < cliffEndDate) {
            revert CliffPending();
        }

        // calculate withdrawable amount
        uint256 _withdrawableAmount = withdrawableAmount(msg.sender);

        // check if there is anything to withdraw
        if (_withdrawableAmount == 0) {
            revert ZeroWithdrawAmount();
        }

        // update withdraws state
        withdraws[msg.sender] += _withdrawableAmount;

        // transfer tokens
        grapeToken.transfer(msg.sender, _withdrawableAmount);

        // emit event
        emit Withdraw(msg.sender, _withdrawableAmount);
    }

    /**
     * @dev Only owner functions
     */

    /**
     * @notice Updates the cliff end date for the vesting schedule.
     * @dev Allows the contract owner to modify the end date of the cliff period.
     *      Changing this date affects the start of the token vesting schedule for all investors.
     *      This function can only be called by the contract owner.
     * @param cliffEndDate_ The new end date for the cliff period, specified as a Unix timestamp.
     */
    function changeCliffEndDate(uint256 cliffEndDate_) external onlyOwner {
        cliffEndDate = cliffEndDate_;
    }

    /**
     * @notice Sets a new end date for the overall vesting period.
     * @dev Allows the contract owner to update the vesting end date. This change affects the duration
     *      of the vesting period for all investors. It can only be executed by the contract owner.
     *      Changing this date impacts how vested amounts are calculated for each investor.
     * @param vestingEndDate_ The new end date for the vesting period, represented as a Unix timestamp.
     */
    function changeVestingEndDate(uint256 vestingEndDate_) external onlyOwner {
        vestingEndDate = vestingEndDate_;
    }

    /**
     * @notice Enables the contract owner to withdraw all Grape tokens held by this contract.
     * @dev This function allows the owner to transfer all the Grape tokens from the contract's balance to their own address.
     *      This action can only be performed by the contract owner.
     */
    function withdrawAllGrapeToken() external onlyOwner {
        grapeToken.transfer(owner(), grapeToken.balanceOf(address(this)));
    }
}

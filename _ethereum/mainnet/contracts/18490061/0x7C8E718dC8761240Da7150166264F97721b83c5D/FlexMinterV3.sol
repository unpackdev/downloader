// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./OpenExchangeToken.sol";
import "./VotingEscrow.sol";

/**
 * @title FlexMinterV3
 * @notice Contract for FLEX -> OX conversion
 *         - Locked: 1 FLEX + 25 OX -> 125 OX, 3 month lock
 *         - The function will automatically transfer the amountFlex * 100
 * @author opnxr
 */
contract FlexMinterV3 is Ownable {
    using SafeERC20 for IERC20;

    OpenExchangeToken public immutable oxToken;
    VotingEscrow public immutable votingEscrow;
    IERC20 public immutable flexToken;

    // State Variables
    uint256 public immutable oxMaxMintableSupply;
    uint256 public conversionDeadline; // Deadline for converting FLEX to OX
    uint256 public constant LOCK_DURATION = 182 days; // 3 months, 91 to be divisible by 7
    uint256 public constant CONVERSION_RATE = 100; // 1 FLEX = 100 OX
    uint256 public constant OX_NEEDED_PER_FLEX = 25; // 25 OX needed per 1 FLEX

    event ConversionDeadlineUpdated(uint256 newDeadline);
    event MintedLockedWithFlex(
        address indexed account,
        uint256 amountFlex,
        uint256 amountOx,
        uint256 unlockTime
    );

    error Error_ConversionDeadlinePassed();
    error Error_WillExceedMaxSupply();
    error Error_LockAlreadyExists();
    error Error_NotApprovedOX();
    error Error_NotApprovedFLEX();

    constructor(
        address _oxAddr,
        address _votingEscrowAddr,
        address _flexAddr,
        uint256 _conversionDeadline
    ) {
        oxToken = OpenExchangeToken(_oxAddr);
        votingEscrow = VotingEscrow(_votingEscrowAddr);
        flexToken = IERC20(_flexAddr);

        oxMaxMintableSupply = oxToken.MAX_MINTABLE_SUPPLY();

        conversionDeadline = _conversionDeadline;
        emit ConversionDeadlineUpdated(_conversionDeadline);
    }

    /**
     * @notice Sets a new conversion deadline.
     * @dev Only the contract owner can call this function.
     * @param newDeadline The new conversion deadline timestamp.
     */
    function setConversionDeadline(uint256 newDeadline) external onlyOwner {
        conversionDeadline = newDeadline;
        emit ConversionDeadlineUpdated(newDeadline);
    }

    /**
     * @notice Calculates the expected unlock time based on the given timestamp and the contract's fixed lock duration.
     * @dev The unlock time is calculated by adding the duration to the current epoch's end, which is rounded up to the
     *      nearest week. Thus the total lock duration will be 91 days < duration <= 98 days.
     * @param ts The timestamp for which to calculate the unlock time.
     * @return The expected unlock time based on the given timestamp.
     */
    function calculateExpectedUnlock(uint256 ts) public pure returns (uint256) {
        return ((ts / 1 weeks) + 1) * 1 weeks + LOCK_DURATION;
    }

    /**
     * @notice Mints veOX tokens by converting FLEX tokens at a 1 FLEX + 25 OX : 125 veOX ratio.
     * @dev The caller must have approved this contract to spend the specified amount of FLEX tokens.
     * @param amountFlex The amount of FLEX tokens to convert.
     * @dev User can only mint veOX with FLEX if there isn't an existing veOX balance.
     *      If there is an existing balance, the user should withdraw the expired lock
     *      first or transfer the FLEX to a fresh address to mint the new veOX.
     */
    function mintLockedWithFlex(uint256 amountFlex) external {
        if (block.timestamp > conversionDeadline)
            revert Error_ConversionDeadlinePassed();

        uint256 amountOx = CONVERSION_RATE * amountFlex; // OX need to be minted
        if (oxToken.totalSupply() + amountOx > oxMaxMintableSupply)
            revert Error_WillExceedMaxSupply();

        (int128 lockedAmount, ) = votingEscrow.locked(msg.sender);
        if (lockedAmount != 0) {
            revert Error_LockAlreadyExists();
        }

        if (
            oxToken.allowance(msg.sender, address(votingEscrow)) <
            OX_NEEDED_PER_FLEX * amountFlex
        ) {
            revert Error_NotApprovedOX();
        }

        if (flexToken.allowance(msg.sender, address(this)) < amountFlex) {
            revert Error_NotApprovedFLEX();
        }

        flexToken.safeTransferFrom(msg.sender, address(this), amountFlex);
        uint256 expectedUnlock = calculateExpectedUnlock(block.timestamp);
        votingEscrow.create_lock_as_minter(
            msg.sender,
            amountOx,
            expectedUnlock
        );
        votingEscrow.deposit_for(msg.sender, OX_NEEDED_PER_FLEX * amountFlex);

        // Calculating sender's total OX after conversion
        uint256 totalOX = (CONVERSION_RATE + OX_NEEDED_PER_FLEX) * amountFlex;

        emit MintedLockedWithFlex(
            msg.sender,
            amountFlex,
            totalOX,
            expectedUnlock
        );
    }
}

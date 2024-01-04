// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";

contract WhitelistSale is Ownable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Struct ========== */

    struct Participant {
        uint256 allocation;
        uint256 spent;
    }

    /* ========== Variables ========== */

    IERC20 public currency;

    mapping (address => Participant) public participants;

    uint256 public totalHardCap;

    uint256 public totalRaised;

    bool public saleOpen;

    /* ========== Events ========== */

    event AllocationClaimed(address user, uint256 amount);

    event AllocationSet(address user, uint256 amount);

    event SaleStatusUpdated(bool status);

    event HardCapUpdated(uint256 amount);

    /* ========== Constructor ========== */

    constructor(address currencyAddress) public {
        currency = IERC20(currencyAddress);
        saleOpen = false;
    }

    /* ========== Public Functions ========== */

    function claimAllocation(
        uint256 amount
    )
        external
    {
        // Get their total spend till date
        uint256 participantSpent = participants[msg.sender].spent.add(amount);

        uint256 newTotalRaised = totalRaised.add(amount);

        require(
            participantSpent <= participants[msg.sender].allocation,
            "You cannot spend more than your allocation"
        );

        require(
            saleOpen,
            "The sale is not currently open"
        );

        require(
            newTotalRaised <= totalHardCap,
            "You cannot purchase more than the hard cap"
        );

        // Increase the user's spend amount otherwise they can keep purchasing
        participants[msg.sender].spent = participantSpent;

        totalRaised = newTotalRaised;

        // Transfer the funds to the owner, no funds will be stored in this contract directly.
        currency.safeTransferFrom(
            msg.sender,
            owner(),
            amount
        );

        emit AllocationClaimed(msg.sender, amount);
    }

    /* ========== Admin Functions ========== */

    function setHardCap(uint256 amount)
        external
        onlyOwner
    {
        totalHardCap = amount;

        emit HardCapUpdated(amount);
    }

    function setAllocation(
        address[] calldata users,
        uint256[] calldata allocations
    )
        external
        onlyOwner
    {
        // If there is a mismatch something hasn't been done correctly
        require(
            users.length == allocations.length,
            "The users and amounts do not match"
        );

        for (uint256 i = 0; i < users.length; i++) {
            participants[users[i]].allocation = allocations[i];

            emit AllocationSet(users[i], allocations[i]);
        }
    }

    function updateSaleStatus(
        bool status
    )
        external
        onlyOwner
    {
        require(
            saleOpen != status,
            "Cannot re-set the same status"
        );

        saleOpen = status;

        emit SaleStatusUpdated(status);
    }
}

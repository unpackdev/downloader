//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessProtected.sol";

struct Milestone {
    uint256 startTime;
    uint256 withdrawnAmount;
    uint128 period;
    uint120 releaseIntervalSecs;
    bool isWithdrawn; // This is for simple milestone contract.
    uint248 allocation;
    uint8 percent;
}

struct InputMilestone {
    uint8 percent;
    uint128 period;
    uint120 releaseIntervalSecs;
}

contract BaseMilestone is AccessProtected, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
    @notice Emitted when someone withdraws a vested amount
    */
    event Claimed(address indexed _recipient, uint256 _withdrawalAmount);

    address[] public recipients;
    IERC20 public tokenAddress;
    uint256 public allocation;
    uint256 public numTokensReservedForVesting;
    uint256 public totalWithdrawnAmount;

    mapping(address => mapping(uint256 => Milestone)) milestones;

    /** 
    @notice Emitted when admin withdraws.
    */
    event AdminWithdrawn(address indexed _recipient, uint256 _amountRequested);

    function initializeMilestones(
        InputMilestone[] memory _milestones
    ) internal {
        uint256 length = _milestones.length;

        for (uint256 i = 0; i < length; ) {
            Milestone memory milestone;

            milestone.period = _milestones[i].period;
            milestone.releaseIntervalSecs = _milestones[i].releaseIntervalSecs;
            milestone.allocation = uint248(
                (_milestones[i].percent * allocation) / 100
            );

            uint256 recipientLenth = recipients.length;

            for (uint256 j = 0; j < recipientLenth; ) {
                milestones[recipients[j]][i] = milestone;
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function initializeAllocations(
        uint256[] memory _allocationPercents
    ) internal {
        uint256 length = _allocationPercents.length;
        for (uint256 i = 0; i < length; ) {
            uint256 recipientLenth = recipients.length;
            uint248 amount = uint248(
                (_allocationPercents[i] * allocation) / 100
            );
            for (uint256 j = 0; j < recipientLenth; ) {
                unchecked {
                    milestones[recipients[j]][i].allocation = amount;
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    modifier hasMilestone(address _recipient, uint256 _milestoneIndex) {
        require(
            milestones[_recipient][_milestoneIndex].allocation != 0,
            "NO_MILESTONE"
        );

        _;
    }

    modifier onlyCompleted(address _recipient, uint256 _milestoneIndex) {
        require(
            milestones[_recipient][_milestoneIndex].startTime != 0,
            "NOT_COMPLETED"
        );

        _;
    }

    modifier onlyDeposited() {
        uint256 balance = tokenAddress.balanceOf(address(this));
        require(
            balance + totalWithdrawnAmount >= allocation * recipients.length,
            "NOT_DEPOSITED"
        );

        _;
    }

    function isCompleted(
        address _recipient,
        uint256 _milestoneIndex
    ) public view returns (bool) {
        return
            milestones[_recipient][_milestoneIndex].startTime == 0
                ? false
                : true;
    }

    /**
    @notice Only can mark as completed when it's deposited fully.
    @dev Only onwer can mark as completed.
     */
    function setComplete(
        address _recipient,
        uint256 _milestoneIndex
    ) public onlyAdmin onlyDeposited {
        Milestone storage milestone = milestones[_recipient][_milestoneIndex];

        require(milestone.startTime == 0, "ALREADY_COMPLETED");

        milestone.startTime = block.timestamp;
        numTokensReservedForVesting += milestone.allocation;
    }

    /**
    @notice Only admin can withdraw the amount before it's completed.
     */
    function withdrawAdmin() public onlyAdmin nonReentrant {
        uint256 availableAmount = tokenAddress.balanceOf(address(this)) -
            (numTokensReservedForVesting - totalWithdrawnAmount);

        tokenAddress.safeTransfer(msg.sender, availableAmount);

        emit AdminWithdrawn(_msgSender(), availableAmount);
    }

    function deposit(uint256 amount) public nonReentrant {
        tokenAddress.safeTransferFrom(msg.sender, address(this), amount);
    }

    function getAllRecipients() public view returns (address[] memory) {
        return recipients;
    }

    function getMilestone(
        address _recipient,
        uint256 _milestoneIndex
    ) public view returns (Milestone memory) {
        return milestones[_recipient][_milestoneIndex];
    }
}

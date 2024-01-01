// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SimpleMilestone.sol";
import "./VestingMilestone.sol";

/// @title Milestone Vesting Factory contract
/// @notice Create Milestone contracts

contract VTVLMilestoneFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event CreateMilestoneContract(
        address indexed milestoneAddress,
        address creator
    );

    /**
    Check if sum of allocation percents is 100%
     */
    function milestoneValidate(
        InputMilestone[] calldata _milestones
    ) private pure {
        uint256 sum;
        uint256 length = _milestones.length;

        require(length > 0, "INVALID_MILESTONE_LENGTH");

        for (uint256 i = 0; i < length; ) {
            unchecked {
                sum += _milestones[i].percent;
                ++i;
            }
        }

        if (sum != 100) {
            revert("INVALID_ALLOCATION_PERCENTS");
        }
    }

    /**
    Check if sum of allocation percents is 100%
     */
    function allocationValidate(
        uint256[] calldata _allocationPercents
    ) private pure {
        uint256 sum;
        uint256 length = _allocationPercents.length;

        require(length > 0, "INVALID_MILESTONE_LENGTH");

        for (uint256 i = 0; i < length; ) {
            unchecked {
                sum += _allocationPercents[i];
                ++i;
            }
        }

        if (sum != 100) {
            revert("INVALID_ALLOCATION_PERCENTS");
        }
    }

    function _deposit(
        IERC20 _tokenAddress,
        uint256 _amount,
        address _contractAddress
    ) private {
        uint256 userBalance = _tokenAddress.balanceOf(msg.sender);

        if (userBalance >= _amount) {
            _tokenAddress.safeTransferFrom(
                msg.sender,
                address(_contractAddress),
                _amount
            );
        }
    }

    /**
     * @notice Create milestone based Vesting contract.
     * @dev All recipients will have the same milestones.
     * @param _tokenAddress Vesting fund token address.
     * @param _allocation The total allocation amount for the milestones.
     * @param _recipients The addresses of the recipients.
     */
    function createVestingMilestone(
        IERC20 _tokenAddress,
        uint256 _allocation,
        InputMilestone[] calldata _milestones,
        address[] calldata _recipients
    ) public nonReentrant {
        require(_recipients.length > 0, "Invalid Recipients");
        milestoneValidate(_milestones);

        VestingMilestone milestoneContract = new VestingMilestone(
            _tokenAddress,
            _allocation,
            _milestones,
            _recipients
        );

        _deposit(
            _tokenAddress,
            _allocation * _recipients.length,
            address(milestoneContract)
        );

        emit CreateMilestoneContract(address(milestoneContract), msg.sender);
    }

    /**
     * @notice Create simple milestones.
     * @dev All recipients will have the same milestones.
     * @param _tokenAddress Vesting fund token address.
     * @param _allocation The total allocation amount for the milestones.
     * @param _recipients The addresses of the recipients.
     */
    function createSimpleMilestones(
        IERC20 _tokenAddress,
        uint256 _allocation,
        uint256[] calldata _allocationPercents,
        address[] calldata _recipients
    ) public nonReentrant {
        require(_recipients.length > 0, "Invalid Recipients");

        allocationValidate(_allocationPercents);

        SimpleMilestone milestoneContract = new SimpleMilestone(
            _tokenAddress,
            _allocation,
            _allocationPercents,
            _recipients
        );

        _deposit(
            _tokenAddress,
            _allocation * _recipients.length,
            address(milestoneContract)
        );

        emit CreateMilestoneContract(address(milestoneContract), msg.sender);
    }
}

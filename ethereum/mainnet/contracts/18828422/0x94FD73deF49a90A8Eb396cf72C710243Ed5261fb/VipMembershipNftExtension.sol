// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./Ownable2Step.sol";
import "./IERC721CreatorCore.sol";
import "./IVipMembershipEligibilityChecker.sol";

error VipMembershipAlreadyClaimed(address user);
error NotEligibleForVipMembership(address user);
error ActionDisabled();

/**
 * @dev This contract is an extension to the Manifold ERC721 Creator contract, that allows users to claim a VIP membership NFT.
 * The extension is required to be registered in the Manifold Creator contract.
 *
 * The extension calls the staking contract to verify, whether the user is eligible for VIP membership. If so, it will mint
 * the VIP membership NFT to the user using the `mintExtension` function of the Creator contract. Every user can claim
 * at most one VIP membership NFT.
 */
contract VipMembershipNftExtension is Ownable2Step {
    address public stakingPoolAddress;
    address private immutable _manifoldCreator;

    mapping(address => bool) private claimedVipMembership;

    event VipMembershipClaimed(address indexed user);
    event StakingPoolAddressUpdated(address stakingPoolAddress);

    constructor(address manifoldCreator_, address stakingPoolAddress_, address owner_) Ownable(owner_) {
        _manifoldCreator = manifoldCreator_;
        stakingPoolAddress = stakingPoolAddress_;
    }

    function claim() external {
        if (!IVipMembershipEligibilityChecker(stakingPoolAddress).getUserVipEligibility(msg.sender)) {
            revert NotEligibleForVipMembership(msg.sender);
        }
        if (claimedVipMembership[msg.sender]) {
            revert VipMembershipAlreadyClaimed(msg.sender);
        }

        claimedVipMembership[msg.sender] = true;
        emit VipMembershipClaimed(msg.sender);

        IERC721CreatorCore(_manifoldCreator).mintExtension(msg.sender);
    }

    function hasUserClaimedVipMembership(address user) external view returns (bool) {
        return claimedVipMembership[user];
    }

    function updateStakingPoolAddress(address stakingPoolAddress_) external onlyOwner {
        stakingPoolAddress = stakingPoolAddress_;
        emit StakingPoolAddressUpdated(stakingPoolAddress);
    }

    /**
     * @dev Function from Ownable to renounce ownership of the contract. Overriden to disable this function.
     */
    function renounceOwnership() public pure override(Ownable) {
        revert ActionDisabled();
    }
}

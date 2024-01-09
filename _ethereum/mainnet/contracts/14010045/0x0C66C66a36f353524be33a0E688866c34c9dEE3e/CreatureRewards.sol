// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./ERC165Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeCast.sol";
import "./ICreatureRewards.sol";

contract CreatureRewards is Initializable, ContextUpgradeable, ERC165Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeCast for uint;
    
    event EnergyUpdated(address indexed user, bool increase, uint energy, uint timestamp);
    event StakedTransfer(address indexed from, address to, uint indexed tokenId, uint energy);

    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsUpdated(uint32 start, uint32 end, uint256 rate);
    event RewardsPerEnergyUpdated(uint256 accumulated);
    event UserRewardsUpdated(address user, uint256 userRewards, uint256 paidRewardPerEnergy);
    event RewardClaimed(address receiver, uint256 claimed);

    struct RewardsPeriod {
        uint32 start;
        uint32 end;
    }

    struct RewardsPerEnergy {
        uint32 totalEnergy;
        uint96 accumulated;
        uint32 lastUpdated;
        uint96 rate;
    }

    struct UserRewards {
        uint32 stakedEnergy;
        uint96 accumulated;
        uint96 checkpoint;
    }

    RewardsPeriod public rewardsPeriod;
    RewardsPerEnergy public rewardsPerEnergy;     
    mapping (address => UserRewards) public rewards;
    bytes32 private constant NFT_ROLE = keccak256("NFT_ROLE");
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    address public LFG_TOKEN;

    // ======== Admin functions ========

    function initialize() public virtual initializer {
        __Context_init();
        __ERC165_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == type(ICreatureRewards).interfaceId || super.supportsInterface(interfaceId);
    }

    function setRewardToken(address token) external virtual onlyRole(OWNER_ROLE) {
        require(token != address(0), "addr 0");
        require(LFG_TOKEN == address(0), "Can only set once");
        LFG_TOKEN = token;
    }

    // Set a rewards schedule
    // rate is in wei per second for all users
    function setRewards(uint32 start, uint32 end, uint96 rate) external virtual onlyRole(OWNER_ROLE) {
        require(start <= end, "Incorrect input");
        require(rate > 0.03 ether && rate < 30 ether, "Rate incorrect");
        require(LFG_TOKEN != address(0), "Rewards token not set");
        require(block.timestamp.toUint32() < rewardsPeriod.start || block.timestamp.toUint32() > rewardsPeriod.end, "Rewards already set");

        rewardsPeriod.start = start;
        rewardsPeriod.end = end;

        rewardsPerEnergy.lastUpdated = start;
        rewardsPerEnergy.rate = rate;

        emit RewardsSet(start, end, rate);
    }

    function updateRewards(uint96 rate) external virtual onlyRole(OWNER_ROLE) {
        require(rate > 0.03 ether && rate < 30 ether, "Rate incorrect");
        require(block.timestamp.toUint32() > rewardsPeriod.start && block.timestamp.toUint32() < rewardsPeriod.end, "Rewards not active");
        rewardsPerEnergy.rate = rate;

        emit RewardsUpdated(rewardsPeriod.start, rewardsPeriod.end, rate);
    }


    function alertStaked(address user, uint, bool staked, uint energy) external virtual onlyRole(NFT_ROLE) {
        _updateRewardsPerEnergy(energy.toUint32(), staked);
        _updateUserRewards(user, energy.toUint32(), staked);
    }

    function alertBoost(address user, uint, bool boost, uint energy) external virtual onlyRole(NFT_ROLE) {
        _updateRewardsPerEnergy(energy.toUint32(), boost);
        _updateUserRewards(user, energy.toUint32(), boost);
    }

    function alertStakedTransfer(address from, address to, uint tokenId, uint energy) external virtual onlyRole(NFT_ROLE) {
        emit StakedTransfer(from, to, tokenId, energy);
    }

    // ======== Public functions ========

    // Claim all rewards from caller into a given address
    function claim(address to) virtual external
    {
        _updateRewardsPerEnergy(0, false);
        uint claiming = _updateUserRewards(_msgSender(), 0, false);
        rewards[_msgSender()].accumulated = 0; // A Claimed event implies the rewards were set to zero
        TransferHelper.safeTransfer(LFG_TOKEN, to, claiming);
        emit RewardClaimed(to, claiming);
    }

    // ======== View only functions ========

    function stakedEnergy(address user) external virtual view returns(uint) {
        return rewards[user].stakedEnergy;
    }

    function getRewardRate() external virtual view returns(uint) {
        return rewardsPerEnergy.rate;
    }

    function checkUserRewards(address user) external virtual view returns(uint) {
        RewardsPerEnergy memory rewardsPerEnergy_ = rewardsPerEnergy;
        RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;
        UserRewards memory userRewards_ = rewards[user];

        // Find out the unaccounted time
        uint32 end = earliest(block.timestamp.toUint32(), rewardsPeriod_.end);
        uint256 unaccountedTime = end - rewardsPerEnergy_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime != 0) {

            // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
            // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
            if (rewardsPerEnergy_.totalEnergy != 0) {
                rewardsPerEnergy_.accumulated = (rewardsPerEnergy_.accumulated + unaccountedTime * rewardsPerEnergy_.rate / rewardsPerEnergy_.totalEnergy).toUint96();
            }
            rewardsPerEnergy_.lastUpdated = end;
        }
        // Calculate and update the new value user reserves. userRewards_.stakedEnergy casts it into uint256, which is desired.
        userRewards_.accumulated = userRewards_.accumulated + userRewards_.stakedEnergy * (rewardsPerEnergy_.accumulated - userRewards_.checkpoint);
        userRewards_.checkpoint = rewardsPerEnergy_.accumulated;
        return userRewards_.accumulated;
    }

    function version() external virtual view returns(string memory) {
        return "1.0.0";
    }

    // ======== internal functions ========

    // Returns the earliest of two timestamps
    function earliest(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = (x < y) ? x : y;
    }

    // Updates the rewards per token accumulator.
    // Needs to be called on each liquidity event
    function _updateRewardsPerEnergy(uint32 energy, bool increase) internal virtual {
        RewardsPerEnergy memory rewardsPerEnergy_ = rewardsPerEnergy;
        RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;

        // We skip the update if the program hasn't started
        if (block.timestamp.toUint32() >= rewardsPeriod_.start) {

            // Find out the unaccounted time
            uint32 end = earliest(block.timestamp.toUint32(), rewardsPeriod_.end);
            uint256 unaccountedTime = end - rewardsPerEnergy_.lastUpdated; // Cast to uint256 to avoid overflows later on
            if (unaccountedTime != 0) {

                // Calculate and update the new value of the accumulator.
                // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
                if (rewardsPerEnergy_.totalEnergy != 0) {
                    rewardsPerEnergy_.accumulated = (rewardsPerEnergy_.accumulated + unaccountedTime * rewardsPerEnergy_.rate / rewardsPerEnergy_.totalEnergy).toUint96();
                }
                rewardsPerEnergy_.lastUpdated = end;
            }
        }
        if (increase) {
            rewardsPerEnergy_.totalEnergy += energy;
        }
        else {
            rewardsPerEnergy_.totalEnergy -= energy;
        }
        rewardsPerEnergy = rewardsPerEnergy_;
        emit RewardsPerEnergyUpdated(rewardsPerEnergy_.accumulated);
    }

    // Accumulate rewards for an user.
    // Needs to be called on each liquidity event, or when user balances change.
    function _updateUserRewards(address user, uint32 energy, bool increase) internal virtual returns (uint96) {
        UserRewards memory userRewards_ = rewards[user];
        RewardsPerEnergy memory rewardsPerEnergy_ = rewardsPerEnergy;
        
        // Calculate and update the new value user reserves.
        userRewards_.accumulated = userRewards_.accumulated + userRewards_.stakedEnergy * (rewardsPerEnergy_.accumulated - userRewards_.checkpoint);
        userRewards_.checkpoint = rewardsPerEnergy_.accumulated;

        if (increase) {
            userRewards_.stakedEnergy += energy;
        }
        else {
            userRewards_.stakedEnergy -= energy;
        }
        rewards[user] = userRewards_;
        emit EnergyUpdated(user, increase, energy, block.timestamp);
        emit UserRewardsUpdated(user, userRewards_.accumulated, userRewards_.checkpoint);

        return userRewards_.accumulated;
    }

}


/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
        }
    }
}
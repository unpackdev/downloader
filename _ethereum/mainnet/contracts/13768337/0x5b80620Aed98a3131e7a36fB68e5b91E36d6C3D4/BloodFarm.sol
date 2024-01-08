// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./IVampireGameERC721.sol";

import "./IBloodFarm.sol";

import "./IRandom.sol";

/// @notice holds info about a staked Human
struct HumanStake {
    /// @notice address of the token owner
    address owner;
    /// @notice id of the token
    uint16 tokenId;
    /// @notice timestamp of when the human was staked
    uint80 stakedAt;
}

/// @notice holds info about a human unstake request
struct HumanUnstakeRequest {
    /// @notice id of the token to unstake
    uint16 tokenId;
    /// @notice block number of the unstake request
    uint240 blocknumber;
}

/// @title The Blood Farm
///
/// Note: A lot of the ideas in this contract are from wolf.game, some parts
/// were taken directly from their original contract. A lot of things were reorganized
///
/// ---
///
/// This contract holds all the state for staked humans and all the logic
/// for updating the state.
///
/// It doesn't transfer tokens or knows about other contracts.
contract BloodFarm is IBloodFarm, IERC721Receiver, Ownable {
    /// ==== Immutable Properties

    /// @notice how many bloodbags humans produce per day
    uint256 public constant DAILY_BLOODBAG_RATE = 5 ether;
    /// @notice blood farm guards won't let your human out for at least a few days.
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    /// @notice absolute total of bloodbags that can be produced
    uint256 public constant MAXIMUM_GLOBAL_BLOOD = 4500000 ether;

    /// ==== Mutable Properties

    /// @notice can't commit to risky action and reveal the outcome in the same block.
    /// This is the amount of blocks you need to wait to be able to reveal the outcome.
    uint256 public REVEAL_BLOCK_SPACE;

    /// @notice total amount of $BLOODBAGS
    uint256 public totalBloodDrained;
    /// @notice nubmer of humans staked in the blood farm
    uint256 public totalHumansStaked;
    /// @notice the last time totalBloodDrained was updated
    uint256 public lastBloodUpdate;

    /// @notice map tokenId to its staking info
    mapping(uint16 => HumanStake) public stakingMap;
    /// @notice map a tokenId to its unstake request
    mapping(uint16 => HumanUnstakeRequest) public unstakingRequestMap;

    /// @notice map of controllers that can control this contract
    mapping(address => bool) public controllers;

    /// ==== Constructor

    constructor(uint256 _REVEAL_BLOCK_SPACE) {
        REVEAL_BLOCK_SPACE = _REVEAL_BLOCK_SPACE;
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    modifier updateEarnings() {
        if (totalBloodDrained < MAXIMUM_GLOBAL_BLOOD) {
            totalBloodDrained +=
                ((block.timestamp - lastBloodUpdate) *
                    totalHumansStaked *
                    DAILY_BLOODBAG_RATE) /
                1 days;
            lastBloodUpdate = block.timestamp;
        }
        _;
    }

    /// ==== Events

    event StakedHuman(address indexed owner, uint16 indexed tokenId);
    /// @param owner who's claiming
    /// @param tokenId id of the token
    /// @param amount total amount to claim, tax included
    event BloodBagClaimed(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 amount
    );
    event RequestedUnstake(address indexed owner, uint16 indexed tokenId);
    event UnstakedHuman(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 amount
    );

    /// ==== Controls

    /// @notice Sends a human to the blood farm
    /// @param owner the address of the token owner
    /// @param tokenId the id of the token that will be staked
    function stakeHuman(address owner, uint16 tokenId)
        external
        override
        onlyControllers
    {
        stakingMap[tokenId] = HumanStake({
            owner: owner,
            tokenId: tokenId,
            stakedAt: uint80(block.timestamp)
        });
        totalHumansStaked += 1;

        emit StakedHuman(owner, tokenId);

        // <- Controller should transfer a Human to this contract
    }

    function claimBloodBags(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        HumanStake memory stake = stakingMap[tokenId];

        // Check if sender is the owner
        require(stake.owner == sender, "NOT_OWNER");
        // Do not allow to claim if there is a request to unstake
        require(
            unstakingRequestMap[tokenId].blocknumber == 0,
            "CANT_CLAIM_WITH_PENDING_UNSTAKE_REQUEST"
        );

        // Set total owed. Tax is calculated in controller.
        owed = _calculateOwedBloodBags(stake);

        // Reset staking info
        stakingMap[tokenId] = HumanStake({
            owner: sender,
            tokenId: tokenId,
            stakedAt: uint80(block.timestamp)
        });

        emit BloodBagClaimed(sender, tokenId, owed);

        // <- Controller should update the vampires bloodbags
        // <- Controller should transfer bloodbags to owner
    }

    function requestToUnstakeHuman(address sender, uint16 tokenId)
        external
        override
        onlyControllers
    {
        // Check token ownership
        require(stakingMap[tokenId].owner == sender, "NOT_YOURS");
        // Make sure it's staked
        require(stakingMap[tokenId].stakedAt != 0, "NOT_STAKED");
        // Make sure there is no request to unstake yer
        require(
            unstakingRequestMap[tokenId].blocknumber == 0,
            "ALREADY_REQUESTED"
        );
        // Make sure it got the minimum amount of blood bags
        require(
            block.timestamp - stakingMap[tokenId].stakedAt > MINIMUM_TO_EXIT,
            "NOT_ENOUGH_BLOOD"
        );
        _requestToUnstakeHuman(tokenId);
        emit RequestedUnstake(sender, tokenId);
    }

    function unstakeHuman(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        // Check token ownership
        require(stakingMap[tokenId].owner == sender, "NOT_YOURS");
        // Make sure it's staked
        require(stakingMap[tokenId].stakedAt != 0, "NOT_STAKED");
        // Make sure there is an unstake request
        require(unstakingRequestMap[tokenId].blocknumber != 0, "NOT_REQUESTED");

        owed = _unstakeHuman(tokenId);

        emit UnstakedHuman(sender, tokenId, owed);
    }

    /// ==== Helpers

    function _calculateOwedBloodBags(HumanStake memory stake)
        private
        view
        returns (uint256 owed)
    {
        if (totalBloodDrained < MAXIMUM_GLOBAL_BLOOD) {
            // still under the maxium limit, so normal logic here
            owed =
                ((block.timestamp - stake.stakedAt) * DAILY_BLOODBAG_RATE) /
                1 days;
        } else if (stake.stakedAt > lastBloodUpdate) {
            // when the player staked after the $BLOODBAG already hit the max amount
            owed = 0;
        } else {
            // if the total amount to claim will surpass the total limit, then some of the
            // blood won't get claimed
            owed =
                ((lastBloodUpdate - stake.stakedAt) * DAILY_BLOODBAG_RATE) /
                1 days;
        }
    }

    /// @dev Before calling this:
    /// - Check if there is NO unstake requests for this token
    function _requestToUnstakeHuman(uint16 tokenId) private {
        uint16 tid = uint16(tokenId);
        unstakingRequestMap[tokenId] = HumanUnstakeRequest({
            tokenId: tid,
            blocknumber: uint240(block.number)
        });
    }

    /// @dev Before calling this:
    /// - Check ownership of the token
    /// - Check if a unstake request exists
    function _unstakeHuman(uint16 tokenId) private returns (uint256 owed) {
        HumanStake memory stake = stakingMap[tokenId];
        // Check if this tx is at least REVEAL_BLOCK_SPACE older than the request block
        require(
            block.number - unstakingRequestMap[tokenId].blocknumber >=
                REVEAL_BLOCK_SPACE,
            "HUMAN_NOT_READY_FOR_CLAIM"
        );

        // Set total owed. Tax is calculated in controller.
        owed = _calculateOwedBloodBags(stake);

        // -- Update the BloodFarm state

        // remove unstaking request
        delete unstakingRequestMap[tokenId];
        // remove stake info
        delete stakingMap[tokenId];
        // decrement total humans staked
        totalHumansStaked -= 1;

        // <- Controller calculates the tax to vampires and update the vampires bloodbags
        // <- Controller transfer NFT to owner
        // <- Controller transfer bloodbags to owner
    }

    /// ==== Only Owner

    function setRevealBlockspace(uint256 space) external onlyOwner {
        require(REVEAL_BLOCK_SPACE != space, "NO_CHANGES");
        REVEAL_BLOCK_SPACE = space;
    }

    /// @notice add a controller that will be able to call functions in this contract
    /// @param controller the address that will be authorized
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /// @notice remove a controller so it won't be able to call functions in this contract anymore
    /// @param controller the address that will be unauthorized
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /// ==== IERC721Receiver

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "PLEASE_DONT");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// ==== View

    function isStaked(uint16 tokenId) external view override returns (bool) {
        return stakingMap[tokenId].stakedAt != 0;
    }

    function hasRequestedToUnstake(uint16 tokenId)
        external
        view
        override
        returns (bool)
    {
        return unstakingRequestMap[tokenId].blocknumber != 0;
    }

    function ownerOf(uint16 tokenId) public view override returns (address) {
        return stakingMap[tokenId].owner;
    }
}

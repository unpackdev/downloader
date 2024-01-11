// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./Interfaces.sol";

contract Wormhole is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    struct SalvageEvent {
        uint64 id;
        uint64 startBlock;
        uint64 endBlock;
        uint64 rngSeed;
        uint16 genesisCount;
        uint16 babiesCount;
    }

    address public genesisAddress;
    address public babiesAddress;
    address public cheethAddress;
    address public rewardAddress;
    uint16 public genesisSalvageEventReward;
    uint16 public babiesSalvageEventReward;

    mapping(uint64 => SalvageEvent) public salvageEvents;
    mapping(address => mapping(uint256 => uint256[])) public ownerBabiesByEvent;
    mapping(address => mapping(uint256 => uint256[])) public ownerGenesisByEvent;
    mapping(uint64 => EnumerableSet.UintSet) private _salvageEventBabies;
    mapping(uint64 => EnumerableSet.UintSet) private _salvageEventGenesis;
    mapping(address => EnumerableSet.UintSet) private _unclaimedEvents;

    function joinEvent(
        uint64 id,
        uint256[] calldata babiesIds,
        uint256[] calldata genesisIds
    ) external {
        SalvageEvent storage salvageEvent = salvageEvents[id];
        require(block.number < salvageEvent.startBlock, "already started");
        uint256 totalCheeth = (babiesIds.length + genesisIds.length) * 250;
        ERC20Burnable(cheethAddress).transferFrom(msg.sender, address(this), totalCheeth * 1 ether);

        salvageEvent.babiesCount += uint16(babiesIds.length);
        salvageEvent.genesisCount += uint16(genesisIds.length);
        _unclaimedEvents[msg.sender].add(id);

        for (uint256 index = 0; index < babiesIds.length; index++) {
            uint256 mouseId = babiesIds[index];
            require(_ownerOfToken(mouseId, babiesAddress) == msg.sender, "not allowed");
            require(!_salvageEventBabies[id].contains(mouseId), "already in event");
            _salvageEventBabies[id].add(mouseId);
            ownerBabiesByEvent[msg.sender][id].push(mouseId);
        }

        for (uint256 index = 0; index < genesisIds.length; index++) {
            uint256 mouseId = genesisIds[index];
            require(_ownerOfToken(mouseId, genesisAddress) == msg.sender, "not allowed");
            require(!_salvageEventGenesis[id].contains(mouseId), "already in event");
            _salvageEventGenesis[id].add(mouseId);
            ownerGenesisByEvent[msg.sender][id].push(mouseId);
        }
    }

    function _ownerOfToken(uint256 tokenId, address tokenAddress) internal view returns (address) {
        return IERC721Enumerable(tokenAddress).ownerOf(tokenId);
    }

    function claimEventReward(uint64 id) external {
        require(!_getIsEventClaimed(id, msg.sender), "already claimed");

        uint64 eventReward = _getEventReward(id, msg.sender);
        RewardLike(rewardAddress).mintMany(msg.sender, eventReward);
        _markClaimedEvent(id, msg.sender);
    }

    // // ADMIN FUNCTIONS

    function setAddresses(
        address _babiesAddress,
        address _genesisAddress,
        address _cheethAddress,
        address _rewardAddress
    ) external onlyOwner {
        babiesAddress = _babiesAddress;
        genesisAddress = _genesisAddress;
        cheethAddress = _cheethAddress;
        rewardAddress = _rewardAddress;
    }

    function setGenesisSalvageEventReward(uint16 _genesisSalvageEventReward) external onlyOwner {
        genesisSalvageEventReward = _genesisSalvageEventReward;
    }

    function setBabiesSalvageEventReward(uint16 _babiesSalvageEventReward) external onlyOwner {
        babiesSalvageEventReward = _babiesSalvageEventReward;
    }

    function registerSalvageEvent(uint64 id, uint64 startBlock) external onlyOwner {
        require(id > 0, "invalid id");
        salvageEvents[id].id = id;
        salvageEvents[id].startBlock = startBlock;
    }

    function startSalvageEvent(
        uint64 id,
        uint64 endBlock,
        uint64 rngSeed
    ) external onlyOwner {
        require(id > 0, "invalid id");
        salvageEvents[id].id = id;
        salvageEvents[id].endBlock = endBlock;
        salvageEvents[id].rngSeed = rngSeed;
    }

    function withdraw(address to) external onlyOwner {
        ERC20Burnable(cheethAddress).transfer(to, ERC20Burnable(cheethAddress).balanceOf(address(this)));
    }

    // // GETTERS

    function getClaimableEventRewards(uint64 id, address wallet) external view returns (uint64) {
        if (_getIsEventClaimed(id, wallet)) {
            return 0;
        }
        return _getEventReward(id, wallet);
    }

    function getEventReward(uint64 id, address wallet) external view returns (uint64) {
        return _getEventReward(id, wallet);
    }

    function getEventMice(uint64 id, address wallet)
        external
        view
        returns (uint256[] memory genesis, uint256[] memory babies)
    {
        genesis = ownerGenesisByEvent[wallet][id];
        babies = ownerBabiesByEvent[wallet][id];
    }

    // // PRIVATE

    function _getEventReward(uint64 id, address wallet) internal view returns (uint64) {
        SalvageEvent memory salvageEvent = salvageEvents[id];
        require(block.number > salvageEvent.startBlock, "not started");
        require(block.number > salvageEvent.endBlock, "not finished");

        uint256[] memory eventBabies = ownerBabiesByEvent[wallet][id];
        uint256[] memory eventGenesis = ownerGenesisByEvent[wallet][id];
        uint256 baseProbability;
        uint256 additionalProbability;
        (baseProbability, additionalProbability) = _eventRewardProbabilities(id, false);

        uint16 rewardCount;
        uint256 mouseId;
        for (uint256 index = 0; index < eventBabies.length; index++) {
            mouseId = eventBabies[index];
            if (_ownerOfToken(mouseId, babiesAddress) != wallet) {
                continue;
            }
            if (_rand(salvageEvent.rngSeed, 10000 + mouseId, id, 1, wallet) < baseProbability) {
                rewardCount++;
            }
            if (_rand(salvageEvent.rngSeed, 10000 + mouseId, id, 2, wallet) < additionalProbability) {
                rewardCount++;
            }
        }

        (baseProbability, additionalProbability) = _eventRewardProbabilities(id, true);
        for (uint256 index = 0; index < eventGenesis.length; index++) {
            mouseId = eventGenesis[index];
            if (_ownerOfToken(mouseId, genesisAddress) != wallet) continue;

            if (_rand(salvageEvent.rngSeed, mouseId, id, 1, wallet) < baseProbability) {
                rewardCount++;
            }
            if (_rand(salvageEvent.rngSeed, mouseId, id, 2, wallet) < additionalProbability) {
                rewardCount++;
            }
        }
        return rewardCount;
    }

    function _eventRewardProbabilities(uint64 id, bool isGenesis) internal view returns (uint256, uint256) {
        uint256 rewardsCount = isGenesis ? genesisSalvageEventReward : babiesSalvageEventReward;
        uint16 eventSize = isGenesis ? salvageEvents[id].genesisCount : salvageEvents[id].babiesCount;
        if (eventSize == 0) return (0, 0);

        uint256 base = (rewardsCount * 100) / eventSize;
        uint256 additional;
        if (rewardsCount > eventSize) {
            uint256 remainingRewards = rewardsCount - eventSize;
            additional = (remainingRewards * 100) / eventSize;
        }
        return (base, additional);
    }

    function _getIsEventClaimed(uint64 id, address player) internal view returns (bool) {
        return !_unclaimedEvents[player].contains(id);
    }

    function _markClaimedEvent(uint64 id, address player) internal {
        _unclaimedEvents[player].remove(id);
    }

    // returns a random number in between 0 and 99 (0 and 99 are valid outputs)
    function _rand(
        uint64 randomness,
        uint256 mouseId,
        uint64 eventId,
        uint8 nonce,
        address wallet
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(wallet, randomness, mouseId, eventId, nonce))) % 100;
    }
}

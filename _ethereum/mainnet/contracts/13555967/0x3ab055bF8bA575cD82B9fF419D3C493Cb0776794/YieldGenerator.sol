// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IApeKing.sol";
import "./IPeach.sol";

contract YieldGenerator is Initializable, OwnableUpgradeable {
    uint256 public BASE_RATE;
    uint256 public INITIAL_ISSUANCE;
    uint256 public REWARD_END;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    uint8[] public rarityBoost;

    uint16 public ogBoost;
    uint16 public genesisBoost;
    uint16 public specialBoost;

    uint16 public BASE_BOOST;
    uint8 public BASE_RARITY;

    IApeKing public apeKing;
    IPeach public peach;

    bool public paused;

    event RewardPaid(address indexed user, uint256 reward);

    function initialize(address _rak, address _peach) public initializer {
        apeKing = IApeKing(_rak);
        peach = IPeach(_peach);
        __Ownable_init();

        INITIAL_ISSUANCE = 200 ether;
        BASE_RATE = 10 ether;

        ogBoost = 12000;
        specialBoost = 12500;
        genesisBoost = 11000;

        BASE_BOOST = 10000;
        BASE_RARITY = 100;

        paused = false;

        REWARD_END = 1762365781; // Wed Nov 05 2025 18:03:01 GMT+0000
    }

    function registerRarityBoost(uint8[] calldata _rarities) external onlyOwner {
        for (uint16 i = 0; i < _rarities.length; i++) rarityBoost.push(_rarities[i]);
    }

    function updateRarityBoost(uint16[] calldata _ids, uint8[] calldata _rarities) external onlyOwner {
        for (uint16 i = 0; i < _ids.length; i++) rarityBoost[_ids[i]] = _rarities[i];
    }

    function setApeKing(address _rak) external onlyOwner {
        apeKing = IApeKing(_rak);
    }

    function setRewardEnd(uint256 _end) external onlyOwner {
        REWARD_END = _end;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setPeachToken(address _peach) external onlyOwner {
        peach = IPeach(_peach);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getRarity(uint256 _tokenId) public view returns (uint256) {
        return rarityBoost.length > _tokenId ? rarityBoost[_tokenId] : BASE_RARITY;
    }

    function getRewardRate(address _user) public view returns (uint256 _rate) {
        uint256[] memory _tokenIds = apeKing.tokensOfOwner(_user);
        if (_tokenIds.length == 0) return 0;

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint256 _rarityRate = getRarity(_tokenIds[i]);
            if (_tokenIds[i] < 3000) _rate += _rarityRate * ogBoost;
            else if (_tokenIds[i] < 6000) _rate += _rarityRate * genesisBoost;
            else if (_tokenIds[i] < 10000) _rate += _rarityRate * BASE_BOOST;
            else _rate += _rarityRate * specialBoost;
        }

        _rate = _rate / _tokenIds.length / BASE_RARITY;
    }

    function updateRewardonMint(
        address _user,
        uint256 /*_tokenId*/
    ) external {
        require(msg.sender == address(apeKing), "not allowed");
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 _lastUpdate = lastUpdate[_user];

        if (_lastUpdate > 0)
            rewards[_user] +=
                ((getRewardRate(_user) * BASE_RATE * (_timestamp - _lastUpdate)) / 86400 / BASE_BOOST) +
                INITIAL_ISSUANCE;
        else rewards[_user] += INITIAL_ISSUANCE;

        lastUpdate[_user] = _timestamp;
    }

    function updateReward(
        address _from,
        address _to,
        uint256 /*_tokenId*/
    ) external {
        require(msg.sender == address(apeKing), "not allowed");

        if (_from != address(0)) {
            _updatePendingReward(_from);
        }
        if (_to != address(0)) {
            _updatePendingReward(_to);
        }
    }

    function _updatePendingReward(address _user) internal {
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 _lastUpdate = lastUpdate[_user];
        if (_lastUpdate > 0)
            rewards[_user] += (getRewardRate(_user) * BASE_RATE * (_timestamp - _lastUpdate)) / 86400 / BASE_BOOST;
        lastUpdate[_user] = _timestamp;
    }

    function claimReward() external {
        require(paused == false, "paused!");

        _updatePendingReward(msg.sender);
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            peach.mint(msg.sender, _reward);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 pending = (getRewardRate(_user) * BASE_RATE * (_timestamp - lastUpdate[_user])) / 86400 / BASE_BOOST;
        return rewards[_user] + pending;
    }
}

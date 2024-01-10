//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

import "./CoreStaking.sol";
import "./ICoreRewarder.sol";
import "./ICollection.sol";
import "./IINT.sol";

contract CoreRewarder is CoreStaking, ICoreRewarder, Ownable, ReentrancyGuard {
    bool public isStakingEnabled;
    bool public isClaimingEnabled;
    address public immutable rewardAddress;

    uint256 public immutable rewardRate;
    uint256 public immutable rewardFrequency;
    uint256 public immutable initialReward;
    uint256 public startTime;
    uint256 public finishTime;

    mapping(uint256 => uint256) public lastClaimTimes;
    mapping(address => uint256) public pendingRewards;

    constructor(
        address _targetAddress,
        address _rewardAddress,
        uint256 _rewardRate,
        uint256 _rewardFrequency,
        uint256 _initialReward,
        uint256 _boostRate
    ) CoreStaking(_targetAddress, _boostRate) {
        rewardAddress = _rewardAddress;
        rewardRate = _rewardRate;
        rewardFrequency = _rewardFrequency;
        initialReward = _initialReward;
    }

    // OWNER CONTROLS

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = _startTime;
    }

    function start() public onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = block.timestamp;
    }

    function setFinishTime(uint256 _finishTime) public onlyOwner {
        finishTime = _finishTime;
    }

    function finish() public onlyOwner {
        finishTime = block.timestamp;
    }

    function setIsStakingEnabled(bool _isStakingEnabled) public onlyOwner {
        isStakingEnabled = _isStakingEnabled;
    }

    function setIsClaimingEnabled(bool _isClaimingEnabled) public onlyOwner {
        isClaimingEnabled = _isClaimingEnabled;
    }

    // PUBLIC - CONTROLS

    function stake(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) public override nonReentrant {
        require(isStakingEnabled, "Stakig is not enabled");
        _updateRewards(_owner, tokenIdsForClaim);
        _stake(tokenIds);
    }

    function withdraw(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) public override nonReentrant {
        _updateRewards(_owner, tokenIdsForClaim);
        _withdraw(tokenIds);
    }

    function claim(address owner, uint256[] calldata tokenIds)
        public
        override
        nonReentrant
    {
        require(isClaimingEnabled, "Claiming is not enabled");
        _claim(owner, tokenIds);
    }

    function earned(address owner, uint256[] calldata tokenIds)
        public
        view
        override
        returns (uint256)
    {
        return _earnedTokenRewards(tokenIds) + pendingRewards[owner];
    }

    // PUBLIC - UTILITY

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _lastClaimTimesOfTokens = new uint256[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lastClaimTimesOfTokens[i] = lastClaimTimes[tokenIds[i]];
        }
        return _lastClaimTimesOfTokens;
    }

    function isOwner(address owner, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return _isOwner(owner, tokenId);
    }

    function stakedTokensOfOwner(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _stakedTokensOfOwner[owner];
    }

    function tokensOfOwner(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = ICollection(targetAddress).tokensOfOwner(
            owner
        );
        uint256[] memory stakedTokensIds = _stakedTokensOfOwner[owner];
        uint256[] memory mergedTokenIds = new uint256[](
            tokenIds.length + stakedTokensIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mergedTokenIds[i] = tokenIds[i];
        }
        for (uint256 i = 0; i < stakedTokensIds.length; i++) {
            mergedTokenIds[i + tokenIds.length] = stakedTokensIds[i];
        }
        return mergedTokenIds;
    }

    // INTERNAL

    function _updateRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        require(
            _tokenIds.length == _allBalanceOf(_owner),
            "Invalid tokenIds for update rewards"
        );
        uint256 rewardAmount = _earnedTokenRewards(_tokenIds);
        _resetTimes(_owner, _tokenIds);
        pendingRewards[_owner] += rewardAmount;
    }

    function _claim(address _owner, uint256[] memory _tokenIds) internal {
        require(
            _tokenIds.length == _allBalanceOf(_owner),
            "Invalid tokenIds for claim"
        );
        uint256 rewardAmount = _earnedTokenRewards(_tokenIds);
        if (rewardAmount == 0) {
            return;
        }
        _resetTimes(_owner, _tokenIds);
        rewardAmount += pendingRewards[_owner];
        pendingRewards[_owner] = 0;
        emit RewardClaimed(_owner, rewardAmount);
        IINT(rewardAddress).mint(_owner, rewardAmount);
    }

    function _resetTimes(address _owner, uint256[] memory _tokenIds) internal {
        uint256 _currentTime = block.timestamp;
        if (finishTime != 0 && finishTime < _currentTime) {
            _currentTime = finishTime;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "You need to own this token"
            );
            lastClaimTimes[_tokenIds[i]] = _currentTime;
        }
    }

    function _earnedTokenRewards(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256)
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = block.timestamp;
        uint256 _boostRate = boostRate;

        uint256 rewardAmount;
        if (finishTime != 0 && finishTime < _currentTime) {
            _currentTime = finishTime;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rewardAmount += _earnedFromToken(
                _tokenIds[i],
                _startTime,
                _currentTime,
                _boostRate
            );
        }
        return rewardAmount;
    }

    function _earnedFromToken(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _boostRate
    ) internal view returns (uint256) {
        uint256 _lastClaimTimeOfToken = lastClaimTimes[_tokenId];
        uint256 lastClaimTime;

        if (_startTime > _lastClaimTimeOfToken) {
            lastClaimTime = _startTime;
        } else {
            lastClaimTime = _lastClaimTimeOfToken;
        }

        uint256 amount;

        if (_startTime != 0 && _startTime <= _currentTime) {
            uint256 multiplier = stakedTokenOwners[_tokenId] != address(0)
                ? _boostRate
                : 1;
            amount +=
                ((_currentTime - lastClaimTime) / rewardFrequency) *
                rewardRate *
                multiplier *
                1e18;
        }

        if (_lastClaimTimeOfToken == 0) {
            return amount + initialReward;
        }

        return amount;
    }

    function _isOwner(address _owner, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (stakedTokenOwners[_tokenId] == _owner) {
            return true;
        }
        return IERC721(targetAddress).ownerOf(_tokenId) == _owner;
    }

    function _allBalanceOf(address _owner) internal view returns (uint256) {
        return
            ICollection(targetAddress).balanceOf(_owner) +
            _stakedTokensOfOwner[_owner].length;
    }

    // EVENTS
    event RewardClaimed(address indexed user, uint256 reward);
}

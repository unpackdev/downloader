// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IWeedWarsERC721.sol";
import "./IWeedERC20.sol";
import "./OwnerOrAdmin.sol";

contract Staking is OwnerOrAdmin {

    event Stake(
        address indexed holder,
        Collection indexed collection,
        uint256 indexed tokenId,
        uint256 period,
        uint256 end,
        uint256 reward
    );
    event Unstake(
        address indexed holder,
        Collection indexed collection,
        uint256 indexed tokenId,
        uint256 reward
    );
    event Lock(
        address indexed receiver,
        Collection indexed collection,
        uint256 indexed tokenId,
        uint256 lockId,
        uint256 start,
        uint256 lockPeriod,
        uint256 amountLocked
    );
    event Claim(
        address indexed receiver, 
        uint256 lockId,
        uint256 claimIndex
    );

    bool public isStakingActive;
    bool public isPrestaking;
    uint16[4] public periods = [30, 90, 180, 270];
    uint32 public stakingPeriodUnit = 86_400; // day
    uint32[4][5] public rewards = [
        [180, 620, 1240, uint32(2420)],
        [420, 1420, 2840, uint32(4200)],
        [880, 2840, 5420, uint32(8420)],
        [1820, 6420, 11420, uint32(17420)],
        [4200, 14200, 28420, uint32(42000)]
    ];
    uint8 public lockPeriod = 10;
    uint32 public lockPeriodUnit = 2_592_000; // month

    mapping(address => mapping(uint256 => StakingInfo)) public warriorsStaked;
    mapping(address => mapping(uint256 => StakingInfo)) public synthsStaked;
    mapping(address => WeedLock[]) public locks;

    IWeedWarsERC721 public warriorsERC721;
    IWeedWarsERC721 public synthsERC721;
    IWeedERC20 public weedERC20;

    enum Collection {
        WARRIOR,
        SYNTH
    }

    struct StakingInfo {
        Collection collection;
        uint256 start;
        uint256 end;
        uint256 reward;
    }

    struct WeedLock {
        uint256 monthlyReward;
        uint256 start;
        uint256 vestingPeriod;
        uint256 claimIndex;
        bool vested;
        Collection collection;
        uint256 tokenId;
    }

    // constructor

    constructor(
        address _warriorsERC721,
        address _synthsERC721,
        address _weedERC20,
        bool _isStakingActive,
        bool _isPrestaking
    ) {
        warriorsERC721 = IWeedWarsERC721(_warriorsERC721);
        synthsERC721 = IWeedWarsERC721(_synthsERC721);
        weedERC20 = IWeedERC20(_weedERC20);
        isStakingActive = _isStakingActive;
        isPrestaking = _isPrestaking;
    }

    // only owner

    function setStakingActive(bool _isStakingActive) external onlyOwnerOrAdmin {
        isStakingActive = _isStakingActive;
    }

    function setPrestaking(bool _isPrestaking) external onlyOwnerOrAdmin {
        isPrestaking = _isPrestaking;
    }

    function setStakingPeriods(uint16[4] memory _periods) external onlyOwnerOrAdmin {
        periods = _periods;
    }

    function setStakingRewards(uint32[4][5] memory _rewards) external onlyOwnerOrAdmin {
        rewards = _rewards;
    }

    function setLockPeriod(uint8 _lockPeriod) external onlyOwnerOrAdmin {
        require(_lockPeriod > 0, "Staking: should be > 0");
        lockPeriod = _lockPeriod;
    }

    function setStakingPeriodUnit(uint32 _stakingPeriodUnit) external onlyOwnerOrAdmin {
        require(_stakingPeriodUnit > 0, "Staking: should be > 0");
        stakingPeriodUnit = _stakingPeriodUnit;
    }

    function setLockPeriodUnit(uint32 _lockPeriodUnit) external onlyOwnerOrAdmin {
        require(_lockPeriodUnit > 0, "Staking: should be > 0");
        lockPeriodUnit = _lockPeriodUnit;
    }

    // user

    function stake(
        uint256 _tokenId,
        Collection _collection,
        uint8 _stakingPeriod
    ) public {
        require(isStakingActive, "Staking: not active");
        require(
            _stakingPeriod >= 0 && _stakingPeriod < 4,
            "Staking: incorrect staking period"
        );
        StakingInfo memory stakingInfo = stakeInfo(msg.sender, _tokenId, _collection);
        require(stakingInfo.start == 0, "Staking: already staked");

        IWeedWarsERC721 nftContract = _collection == Collection.WARRIOR
            ? warriorsERC721
            : synthsERC721;

        nftContract.setLock(_tokenId, msg.sender, true);

        uint256 reward;
        if (isPrestaking || (_tokenId >= 0 && _tokenId <= 556)) {
            reward = rewards[4][_stakingPeriod];
        } else {
            uint256 mergeCount = nftContract.getMergeCount(_tokenId);
            uint256 rank = mergeCount <= 4 ? mergeCount : 4;
            reward = rewards[rank][_stakingPeriod];
        }

        uint16 stakingPeriod = periods[_stakingPeriod];
        uint256 end = block.timestamp + uint256(stakingPeriod) * stakingPeriodUnit;

        stakingInfo = StakingInfo(_collection, block.timestamp, end, reward);
        if (_collection == Collection.WARRIOR) {
            warriorsStaked[msg.sender][_tokenId] = stakingInfo;
        } else {
            synthsStaked[msg.sender][_tokenId] = stakingInfo;
        }

        emit Stake(
            msg.sender,
            _collection,
            _tokenId,
            stakingPeriod,
            end,
            reward
        );
    }

    function unstake(uint256 _tokenId, Collection _collection) public {
        StakingInfo memory stakingInfo = stakeInfo(msg.sender, _tokenId, _collection);
        require(stakingInfo.start != 0, "Staking: Not found");

        uint256 rewardNow;
        if (isStakingFinished(msg.sender, _tokenId, _collection)) {
            rewardNow = stakingInfo.reward / 2;
            _sendReward(rewardNow, msg.sender);
            uint256 lockedReward = stakingInfo.reward - rewardNow;
            _lockReward(
                lockedReward,
                msg.sender,
                stakingInfo.end,
                _collection,
                _tokenId
            );
        }
        emit Unstake(msg.sender, _collection, _tokenId, rewardNow);

        _unstake(_tokenId, _collection);
    }

    function stakeBulk(
        uint256[] memory _tokenIds,
        Collection[] memory _collections,
        uint8 _stakingPeriod
    ) external {
        require(
            _tokenIds.length == _collections.length,
            "Staking: invalid input"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i], _collections[i], _stakingPeriod);
        }
    }

    function unstakeBulk(
        uint256[] memory _tokenIds,
        Collection[] memory _collections
    ) external {
        require(
            _tokenIds.length == _collections.length,
            "Staking: invalid input"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unstake(_tokenIds[i], _collections[i]);
        }
    }

    function claimRewards(uint256 _index) public {
        WeedLock storage lock = locks[msg.sender][_index];
        require(lock.start != 0, "Staking: lock not found");
        require(!lock.vested, "Staking: already vested");

        (uint256 claimableReward, uint256 claimsCount) = lockInfo(
            msg.sender,
            _index
        );

        require(claimsCount > 0, "Staking: nothing to claim");
        lock.claimIndex = lock.claimIndex + claimsCount;

        if (lock.claimIndex == lock.vestingPeriod) {
            lock.vested = true;
        }

        _sendReward(claimableReward, msg.sender);

        emit Claim(msg.sender, _index, lock.claimIndex);
    }

    function claimRewardsBulk(uint256[] memory _indexes) external {
        for (uint256 i = 0; i < _indexes.length; i++) {
            claimRewards(_indexes[i]);
        }
    }

    function locksNumber(address addr) external view returns (uint256) {
        return locks[addr].length;
    }

    function lockInfo(address _receiver, uint256 _index)
        public
        view
        returns (
            uint256 claimableReward_,
            uint256 claimsCount_
        )
    {
        WeedLock memory lock = locks[_receiver][_index];
        require(lock.start != 0, "Staking: lock not found");

        if (lock.vested) {
            return (0, 0);
        }

        uint256 claimsLeft = lock.vestingPeriod - lock.claimIndex;
        uint256 monthsVested = (block.timestamp - lock.start) / lockPeriodUnit;

        if (monthsVested > lock.vestingPeriod) {
            monthsVested = lock.vestingPeriod;
        }

        if (lock.claimIndex >= monthsVested) {
            claimsCount_ = 0;
        } else {
            claimableReward_ =
                (monthsVested - lock.claimIndex) *
                lock.monthlyReward;
            claimsCount_ = monthsVested - lock.claimIndex;
        }

        if (claimsCount_ >= claimsLeft) {
            claimsCount_ = claimsLeft;
        }
    }

    function stakeInfo(address _address, uint256 _tokenId, Collection _collection)
        public
        view
        returns (StakingInfo memory stakingInfo_)
    {
        return
            _collection == Collection.WARRIOR
                ? warriorsStaked[_address][_tokenId]
                : synthsStaked[_address][_tokenId];
    }

    function isStakingFinished(address _address, uint256 _tokenId, Collection _collection)
        public
        view
        returns (bool)
    {
        StakingInfo memory stakingInfo = stakeInfo(_address, _tokenId, _collection);
        if (stakingInfo.start == 0) {
            return false;
        }
        if (block.timestamp >= stakingInfo.end) {
            return true;
        } else {
            return false;
        }
    }

    function _sendReward(uint256 _amount, address _receiver) internal {
        weedERC20.mint(_receiver, _amount * 10**18);
    }

    function _lockReward(
        uint256 _amount,
        address _receiver,
        uint256 _startTime,
        Collection _collection,
        uint256 _tokenId
    ) internal {
        locks[_receiver].push(
            WeedLock(
                _amount / lockPeriod,
                _startTime,
                lockPeriod,
                0,
                false,
                _collection,
                _tokenId
            )
        );
        emit Lock(_receiver, _collection, _tokenId, locks[_receiver].length - 1, _startTime, lockPeriod, _amount);
    }

    function _unstake(uint256 _tokenId, Collection _collection) internal {
        if (_collection == Collection.WARRIOR) {
            warriorsERC721.setLock(_tokenId, msg.sender, false);
            delete warriorsStaked[msg.sender][_tokenId];
        } else {
            synthsERC721.setLock(_tokenId, msg.sender, false);
            delete synthsStaked[msg.sender][_tokenId];
        }
    }
}

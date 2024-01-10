//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IPaperHands.sol";
import "./IDiamondHandsPass.sol";

// import "./console.sol";

contract PaperHandsStaking is Initializable, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    address public paperHandsContract;
    address public diamondHandsPassContract;
    uint256 public lockDuration;
    uint256 public passiveEmission;
    uint256 public activeEmission;
    uint256 public lockEmission;

    mapping(address => bool) private admins;

    struct LastUpdate {
        uint256 passive;
        uint256 active;
        uint256 lock;
    }

    struct Reward {
        uint256 passive;
        uint256 active;
        uint256 lock;
    }

    // nft staking startTime
    uint256 public startTime;

    // user => timestamp
    mapping(address => LastUpdate) public lastUpdates;

    // user => rewards
    mapping(address => Reward) public rewards;

    // user => tokenIds
    mapping(address => uint256[]) public stakedActiveTokens;
    mapping(address => uint256[]) public stakedLockTokens;
    mapping(uint256 => uint256) public stakedLockTokensTimestamps;

    uint256 public timestamp1155;
    uint256 private constant INTERVAL = 86400;

    event Stake(
        address indexed user,
        uint256[] indexed tokenIDs,
        bool indexed locked
    );
    event Withdraw(
        address indexed user,
        uint256[] indexed tokenIDs,
        bool indexed locked
    );

    function initialize(address _paperHandsContract, uint256 _startTime) public initializer {
        __Ownable_init();
        paperHandsContract = _paperHandsContract;
        startTime = _startTime;
        lockDuration = 86400 * 56;
        passiveEmission = 100 ether;
        activeEmission = 200 ether;
        lockEmission = 888 ether;
    }

    modifier multiAdmin() {
        require(admins[msg.sender] == true, "NOT_ADMIN");
        _;
    }

    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "INVALID_ADDRESS");
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        require(admins[_admin] == true, "ADMIN_NOT_SET");
        admins[_admin] = false;
    }

    function setTimestamp1155(uint256 _timestamp1155) external onlyOwner {
        timestamp1155 = _timestamp1155;
    }

    function setAddress1155(address _address1155) external onlyOwner {
        diamondHandsPassContract = _address1155;
    }

    function setPassiveEmission(uint256 _passiveEmission) external onlyOwner {
        passiveEmission = _passiveEmission;
    }

    function setActiveEmission(uint256 _activeEmission) external onlyOwner {
        activeEmission = _activeEmission;
    }

    function setLockEmission(uint256 _lockEmission) external onlyOwner {
        lockEmission = _lockEmission;
    }

    function viewPassivePendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return _getPassivePendingReward(_user);
    }

    function viewActivePendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return _getActivePendingReward(_user);
    }

    function viewLockPendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return _getLockPendingReward(_user);
    }

    function viewAllPendingReward(address _user)
        external
        view
        returns (uint256)
    {
        return
            _getPassivePendingReward(_user) +
            _getActivePendingReward(_user) +
            _getLockPendingReward(_user);
    }

    function viewAllRewards(address _user) external view returns (uint256) {
        Reward memory _rewards = rewards[_user];
        return _rewards.passive + _rewards.active + _rewards.lock;
    }

    function viewActiveTokens(address _user) external view returns (uint256[] memory activeTokens) {
        uint256 activeArrLength = stakedActiveTokens[_user].length;
        activeTokens = new uint256[](activeArrLength);
        for (uint256 i; i < activeArrLength; i++) {
            activeTokens[i] = stakedActiveTokens[_user][i];
        }
    }

    function viewLockTokens(address _user) external view returns (uint256[] memory lockTokens) {
        uint256 lockArrLength = stakedLockTokens[_user].length;
        lockTokens = new uint256[](lockArrLength);
        for (uint256 i; i < lockArrLength; i++) {
            lockTokens[i] = stakedLockTokens[_user][i];
        }
    }

    function stakeActive(address owner, uint256[] memory tokenIds) external {
        rewards[owner].active += _getActivePendingReward(owner);
        lastUpdates[owner].active = block.timestamp;
        for (uint256 i; i < tokenIds.length; i++) {
            stakedActiveTokens[owner].push(tokenIds[i]);
        }
        IPaperHands(paperHandsContract).batchSafeTransferFrom(
            owner,
            address(this),
            tokenIds,
            ""
        );
        emit Stake(owner, tokenIds, false);
    }

    function withdrawActive() external {
        rewards[msg.sender].active += _getActivePendingReward(msg.sender);
        lastUpdates[msg.sender].active = block.timestamp;
        uint256 arrLen = stakedActiveTokens[msg.sender]
            .length;
        require(arrLen > 0, "NO_ACTIVE_STAKE");
        uint256[] memory tokenIds = new uint256[](arrLen);
        tokenIds = stakedActiveTokens[msg.sender];
        IPaperHands(paperHandsContract).batchSafeTransferFrom(
            address(this),
            msg.sender,
            tokenIds,
            ""
        );
        delete stakedActiveTokens[msg.sender];
        emit Withdraw(msg.sender, tokenIds, false);
    }

    function stakeLock(address owner, uint256[] memory tokenIds) external {
        rewards[owner].lock += _getLockPendingReward(owner);
        lastUpdates[owner].lock = block.timestamp;
        for (uint256 i; i < tokenIds.length; i++) {
            stakedLockTokens[owner].push(tokenIds[i]);
            stakedLockTokensTimestamps[tokenIds[i]] =
                ((block.timestamp + lockDuration) / 86400) *
                86400;
        }
        IPaperHands(paperHandsContract).batchSafeTransferFrom(
            owner,
            address(this),
            tokenIds,
            ""
        );
        if (block.timestamp <= timestamp1155) {
            uint256 quantity = tokenIds.length / 2;
            if (quantity > 0) {
            IDiamondHandsPass(diamondHandsPassContract).mint(owner,quantity);
            }
        }
        emit Stake(owner, tokenIds, true);
    }

    function withdrawLock() external {
        rewards[msg.sender].lock += _getLockPendingReward(msg.sender);
        lastUpdates[msg.sender].lock = block.timestamp;
        uint256[] storage _stakelockTokens = stakedLockTokens[msg.sender];
        uint256 unlockArrLength;
        uint256 lockArrLength;
        for (uint256 i; i < _stakelockTokens.length; i++) {
            block.timestamp < stakedLockTokensTimestamps[_stakelockTokens[i]]
                ? lockArrLength = lockArrLength + 1
                : unlockArrLength = unlockArrLength + 1;
        }
        require(unlockArrLength > 0, "NO_UNLOCKED");
        if (lockArrLength == 0) {
            IPaperHands(paperHandsContract).batchSafeTransferFrom(
                address(this),
                msg.sender,
                _stakelockTokens,
                ""
            );
            emit Withdraw(msg.sender, _stakelockTokens, true);
            delete stakedLockTokens[msg.sender];
        } else {
            uint256[] memory unlockedTokens = new uint256[](unlockArrLength);
            uint256[] memory lockedTokens = new uint256[](lockArrLength);
            uint256 unlockArrLengthConst = unlockArrLength;
            uint256 lockArrLengthConst = lockArrLength;
            for (uint256 i; i < _stakelockTokens.length; i++) {
                if (
                    block.timestamp <
                    stakedLockTokensTimestamps[_stakelockTokens[i]]
                ) {
                    lockedTokens[lockArrLengthConst - lockArrLength] = (
                        _stakelockTokens[i]
                    );
                    lockArrLength = lockArrLength - 1;
                } else {
                    unlockedTokens[unlockArrLengthConst - unlockArrLength] = (
                        _stakelockTokens[i]
                    );
                    unlockArrLength = unlockArrLength - 1;
                }
            }
            stakedLockTokens[msg.sender] = lockedTokens;
            IPaperHands(paperHandsContract).batchSafeTransferFrom(
                address(this),
                msg.sender,
                unlockedTokens,
                ""
            );
            emit Withdraw(msg.sender, unlockedTokens, true);
        }
    }

    function setStartTime(uint256 _timestamp) external onlyOwner {
        if (_timestamp == 0) {
            startTime = block.timestamp;
        } else {
            startTime = _timestamp;
        }
    }

    function _getPassivePendingReward(address _user)
        internal
        view
        returns (uint256)
    {
        if (_user == address(this)) {
            return 0;
        }
        return
            (IPaperHands(paperHandsContract).balanceOf(_user) *
                passiveEmission *
                (block.timestamp -
                    (
                        lastUpdates[_user].passive >= startTime
                            ? lastUpdates[_user].passive
                            : startTime
                    ))) / INTERVAL;
    }

    function _getActivePendingReward(address _user)
        internal
        view
        returns (uint256)
    {
        return
            (stakedActiveTokens[_user].length *
                activeEmission *
                (block.timestamp -
                    (
                        lastUpdates[_user].active >= startTime
                            ? lastUpdates[_user].active
                            : startTime
                    ))) / INTERVAL;
    }

    function _getLockPendingReward(address _user)
        internal
        view
        returns (uint256)
    {
        return
            (stakedLockTokens[_user].length *
                lockEmission *
                (block.timestamp -
                    (
                        lastUpdates[_user].lock >= startTime
                            ? lastUpdates[_user].lock
                            : startTime
                    ))) / INTERVAL;
    }

    function transferRewards(address _from, address _to) external multiAdmin {
        if (_from != address(0) && _from != address(this)) {
            rewards[_from].passive += _getPassivePendingReward(_from);
            lastUpdates[_from].passive = block.timestamp;
        }

        if (_to != address(0) && _to != address(this)) {
            rewards[_to].passive += _getPassivePendingReward(_to);
            lastUpdates[_to].passive = block.timestamp;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

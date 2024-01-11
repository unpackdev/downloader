// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Signature.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

contract NftStaking is
    IERC721Receiver,
    AccessControlUpgradeable,
    Signature,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public constant LOWER_TIER = 0;
    uint256 public constant HIGHER_TIER = 1;

    struct NftCollection {
        IERC721 nft;
        IERC721 nftBoost;
    }

    struct Pool {
        NftCollection nftCollection;
        uint256 boostAPR;
        IERC20 stakingToken;
        IERC20 rewardToken;
        string name;
        uint256 totalStaked;
        uint256 totalPoolSize;
        ApyStruct[] apyStruct;
        uint256 unstakeFee;
        uint256 unstakeFeeDuration;
        address feeReceiverAddress;
        uint256 startJoinTime;
        uint256 endJoinTime;
    }

    struct AdditionalPoolInfo {
        uint256 totalHigherTierCardsPerUser;
        uint256 totalLowerTierCardsPerUser;
        mapping(address => uint256) userBoostApr;
        mapping(address => uint256) userLastStakeTime;
        mapping(address => uint256[]) higherTierCardsStaked;
        mapping(address => uint256[]) lowerTierCardsStaked;
        mapping(address => uint256) boostCardsStaked;
        mapping(address => uint256) tokensStaked;
        mapping(address => uint256) lastUserClaim;
        mapping(address => uint256) userApy;
        mapping(uint256 => uint256) higherTierCards;
        mapping(uint256 => uint256) lowerTierCards;
    }

    uint256 public poolLength;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => AdditionalPoolInfo) public additionalPoolInfos;

    struct ApyStruct {
        uint256 amount;
        uint256 apy;
    }

    event AddedPool(uint256 poolId, string name, uint256 uid);

    event UpdatedPool(uint256 poolId, string name);

    event SetSigner(address signer);

    event SetApyStruct(ApyStruct[] apyStruct);

    event Staked(
        address userAddress,
        uint256 poolId,
        uint256[] ids,
        uint256[] prices,
        uint256 tokenAmount
    );
    event BoostStaked(
        address userAddress,
        uint256 poolId,
        uint256 ids,
        uint256 prices,
        uint256 boostId,
        uint256 tokenAmount
    );
    event Withdrawn(
        address userAddress,
        uint256 poolId,
        uint256[] ids,
        uint256[] prices,
        uint256 tokenAmount,
        uint256 fee
    );
    event BoostWithdrawn(uint256 poolId, uint256 boostId);
    event RewardClaimed(
        address userAddress,
        uint256 poolId,
        uint256 requiredRewardAmount,
        uint256 rewardAmount
    );

    modifier updateState(uint256 _poolId, address _userAddress) {
        _updateUser(_poolId, _userAddress);
        _;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */
    modifier validatePoolById(uint256 _poolId) {
        require(_poolId < poolLength, "MADworld: Pool are not exist");
        _;
    }

    function __Madworld_init() external initializer {
        __AccessControl_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);
    }

    function getUserCardsStaked(uint256 _poolId, address _userAddress)
        external
        view
        validatePoolById(_poolId)
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];
        return (
            additionalPoolInfo.higherTierCardsStaked[_userAddress],
            additionalPoolInfo.lowerTierCardsStaked[_userAddress],
            additionalPoolInfo.boostCardsStaked[_userAddress]
        );
    }

    function getPoolData(uint256 _poolId)
        external
        view
        validatePoolById(_poolId)
        returns (
            uint256 _totalStaked,
            uint256 _poolSize,
            uint256 _remaining,
            uint256 _roiMin,
            uint256 _roiMax
        )
    {
        Pool storage poolInfo = pools[_poolId];

        _totalStaked = poolInfo.totalStaked;
        _poolSize = poolInfo.totalPoolSize;
        _remaining = poolInfo.totalPoolSize - poolInfo.totalStaked;

        if (poolInfo.apyStruct.length > 0) {
            _roiMin = poolInfo.apyStruct[0].apy;
            _roiMax = poolInfo.apyStruct[poolInfo.apyStruct.length - 1].apy;
        }
    }

    function getPoolData2(uint256 _poolId, address _userAddress)
        external
        view
        validatePoolById(_poolId)
        returns (
            uint256 _earnedReward,
            uint256 _roi,
            uint256 _stakedNft,
            uint256 _userStakedTokens
        )
    {
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        _roi = getTotalApy(_poolId, _userAddress);
        _stakedNft =
            additionalPoolInfo.higherTierCardsStaked[_userAddress].length +
            additionalPoolInfo.lowerTierCardsStaked[_userAddress].length;
        if (additionalPoolInfo.boostCardsStaked[_userAddress] > 0) {
            _stakedNft += 1;
        }
        _userStakedTokens = additionalPoolInfo.tokensStaked[_userAddress];
        _earnedReward = getReward(_poolId, _userAddress);
    }

    function updateUsers(uint256 _poolId, address[] calldata _userAddresses)
        external
        nonReentrant
    {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            _updateUser(_poolId, _userAddresses[i]);
        }
    }

    function update(uint256 _poolId) external nonReentrant {
        _updateUser(_poolId, msg.sender);
    }

    function _updateUser(uint256 _poolId, address _userAddress)
        private
        validatePoolById(_poolId)
    {
        require(
            _userAddress != address(0),
            "MADworld: _userAddress can not be zero address"
        );
        Pool storage poolInfo = pools[_poolId];
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        uint256 reward = getReward(_poolId, _userAddress);
        uint256 balance = poolInfo.rewardToken.balanceOf(address(this));

        uint256 userReward = reward < balance ? reward : balance;
        additionalPoolInfo.lastUserClaim[_userAddress] = block.timestamp;

        if (userReward > 0) {
            poolInfo.rewardToken.safeTransfer(_userAddress, userReward);
            emit RewardClaimed(_userAddress, _poolId, reward, userReward);
        }
    }

    function addPool(
        string memory _name,
        uint256 _uid,
        ApyStruct[] memory listApy,
        IERC721[2] memory _nft,
        uint256 _boostAPR,
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _totalPoolSize,
        uint256 _totalHigherTierCardsPerUser,
        uint256 _totalLowerTierCardsPerUser,
        uint256 _startJoinTime,
        uint256 _endJoinTime
    ) external onlyRole(ADMIN) {
        require(
            _endJoinTime >= block.timestamp && _endJoinTime > _startJoinTime,
            "MADworld: invalid end join time"
        );

        require(
            address(_nft[0]) != address(0),
            "MADworld: nft can not be zero address"
        );

        require(
            address(_stakingToken) != address(0),
            "MADworld: _stakingToken can not be zero address"
        );

        require(
            address(_rewardToken) != address(0),
            "MADworld: _rewardToken can not be zero address"
        );

        Pool storage newPool = pools[poolLength++];
        AdditionalPoolInfo storage addidtionalNewPoolInfo = additionalPoolInfos[
            poolLength - 1
        ];

        {
            newPool.name = _name;
            newPool.nftCollection = NftCollection(_nft[0], _nft[1]);
            newPool.boostAPR = _boostAPR;
            newPool.stakingToken = _stakingToken;
            newPool.rewardToken = _rewardToken;

            newPool.totalPoolSize = _totalPoolSize;

            newPool.unstakeFeeDuration = 7 days;
            newPool.unstakeFee = 0.02e18; //2%
            newPool.feeReceiverAddress = msg.sender; // need to be changed

            addidtionalNewPoolInfo
                .totalHigherTierCardsPerUser = _totalHigherTierCardsPerUser;
            addidtionalNewPoolInfo
                .totalLowerTierCardsPerUser = _totalLowerTierCardsPerUser;

            newPool.startJoinTime = _startJoinTime;
            newPool.endJoinTime = _endJoinTime;
        }
        _setApyStruct(poolLength - 1, listApy);

        uint256 uid = _uid;
        emit AddedPool(poolLength - 1, newPool.name, uid);
    }

    function updatePool(uint256 _poolId, string memory _name)
        external
        onlyRole(ADMIN)
        validatePoolById(_poolId)
    {
        Pool storage pool = pools[_poolId];
        pool.name = _name;

        emit UpdatedPool(_poolId, _name);
    }

    function getReward(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        return
            ((block.timestamp -
                additionalPoolInfo.lastUserClaim[_userAddress]) *
                (additionalPoolInfo.tokensStaked[_userAddress] *
                    getTotalApy(_poolId, _userAddress))) /
            1e18 /
            365 days;
    }

    struct StakeCardPayload {
        address _user;
        uint256[] _ids;
        uint256[] _prices;
        uint256[] _tiers; // 0 - lower, 1 - higher
        bytes _signature;
    }

    struct StakeCardWithBoostPayload {
        address _user;
        uint256 _ids;
        uint256 _prices;
        uint256 _tiers; // 0 - lower, 1 - higher
        uint256 _boostId;
        bytes _signature;
    }

    function stakeCardsWithBoost(
        uint256 _poolId,
        StakeCardWithBoostPayload memory _payload
    )
        external
        nonReentrant
        validatePoolById(_poolId)
        updateState(_poolId, msg.sender)
    {
        require(
            _payload._user != address(0),
            "MADworld: _payload._user can not be zero address"
        );

        require(msg.sender == _payload._user, "MADworld: invalid user");

        Pool storage poolInfo = pools[_poolId];
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        require(
            additionalPoolInfo.userBoostApr[msg.sender] == 0 &&
                additionalPoolInfo.boostCardsStaked[msg.sender] == 0,
            "MADworld: already staked boost nft"
        );

        require(
            block.timestamp >= poolInfo.startJoinTime,
            "MADworld: pool is not started yet"
        );

        require(
            block.timestamp <= poolInfo.endJoinTime,
            "MADworld: pool is already closed"
        );

        bytes32 msgHash = getBoostCardsMessageHash(
            _poolId,
            _payload._user,
            _payload._ids,
            _payload._prices,
            _payload._tiers,
            _payload._boostId
        );

        require(
            _verifyStakeCardsSignature(msgHash, _payload._signature),
            "MADworld: invalid signature"
        );

        if (_payload._tiers == HIGHER_TIER) {
            require(
                additionalPoolInfo.higherTierCardsStaked[msg.sender].length <
                    additionalPoolInfo.totalHigherTierCardsPerUser,
                "MADworld: exceed higher tier staking limit"
            );
            additionalPoolInfo.higherTierCardsStaked[msg.sender].push(
                _payload._ids
            );
            additionalPoolInfo.higherTierCards[_payload._ids] = _payload
                ._prices;
        } else if (_payload._tiers == LOWER_TIER) {
            require(
                additionalPoolInfo.lowerTierCardsStaked[msg.sender].length <
                    additionalPoolInfo.totalLowerTierCardsPerUser,
                "MADworld: exceed lower tier staking limit"
            );
            additionalPoolInfo.lowerTierCardsStaked[msg.sender].push(
                _payload._ids
            );
            additionalPoolInfo.lowerTierCards[_payload._ids] = _payload._prices;
        } else {
            revert("MADworld: invalid tier");
        }

        uint256 totalPrice = _payload._prices;

        poolInfo.nftCollection.nft.safeTransferFrom(
            msg.sender,
            address(this),
            _payload._ids,
            "0x"
        );

        additionalPoolInfo.boostCardsStaked[msg.sender] = _payload._boostId;

        poolInfo.nftCollection.nftBoost.safeTransferFrom(
            msg.sender,
            address(this),
            _payload._boostId,
            "0x"
        );

        poolInfo.stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalPrice
        );

        additionalPoolInfo.tokensStaked[msg.sender] += totalPrice;
        poolInfo.totalStaked += totalPrice;

        require(
            additionalPoolInfo.tokensStaked[msg.sender] >=
                poolInfo.apyStruct[0].amount,
            "MADworld: total stake less than minimum"
        );
        require(
            poolInfo.totalStaked <= poolInfo.totalPoolSize,
            "MADworld: exceed pool limit"
        );

        additionalPoolInfo.userBoostApr[msg.sender] = poolInfo.boostAPR;
        additionalPoolInfo.userLastStakeTime[msg.sender] = block.timestamp;

        emit BoostStaked(
            msg.sender,
            _poolId,
            _payload._ids,
            _payload._prices,
            _payload._boostId,
            totalPrice
        );
    }

    function stakeCards(uint256 _poolId, StakeCardPayload memory _payload)
        external
        nonReentrant
        validatePoolById(_poolId)
        updateState(_poolId, msg.sender)
    {
        require(
            _payload._user != address(0),
            "MADworld: _payload._user can not be zero address"
        );

        require(msg.sender == _payload._user, "MADworld: invalid user");

        Pool storage poolInfo = pools[_poolId];
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        require(
            block.timestamp >= poolInfo.startJoinTime,
            "MADworld: pool is not started yet"
        );

        require(
            block.timestamp <= poolInfo.endJoinTime,
            "MADworld: pool is already closed"
        );

        bytes32 msgHash = getMessageHash(
            _poolId,
            _payload._user,
            _payload._ids,
            _payload._prices,
            _payload._tiers
        );

        require(
            _verifyStakeCardsSignature(msgHash, _payload._signature),
            "MADworld: invalid signature"
        );

        uint256 totalPrice;

        for (uint256 i = 0; i < _payload._ids.length; i++) {
            if (_payload._tiers[i] == HIGHER_TIER) {
                require(
                    additionalPoolInfo
                        .higherTierCardsStaked[msg.sender]
                        .length <
                        additionalPoolInfo.totalHigherTierCardsPerUser,
                    "MADworld: exceed higher tier staking limit"
                );
                additionalPoolInfo.higherTierCardsStaked[msg.sender].push(
                    _payload._ids[i]
                );
                additionalPoolInfo.higherTierCards[_payload._ids[i]] = _payload
                    ._prices[i];
            } else if (_payload._tiers[i] == LOWER_TIER) {
                require(
                    additionalPoolInfo.lowerTierCardsStaked[msg.sender].length <
                        additionalPoolInfo.totalLowerTierCardsPerUser,
                    "MADworld: exceed lower tier staking limit"
                );
                additionalPoolInfo.lowerTierCardsStaked[msg.sender].push(
                    _payload._ids[i]
                );
                additionalPoolInfo.lowerTierCards[_payload._ids[i]] = _payload
                    ._prices[i];
            } else {
                revert("MADworld: invalid tier");
            }

            poolInfo.nftCollection.nft.safeTransferFrom(
                msg.sender,
                address(this),
                _payload._ids[i],
                "0x"
            );
            totalPrice += _payload._prices[i];
        }

        poolInfo.stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalPrice
        );
        additionalPoolInfo.tokensStaked[msg.sender] += totalPrice;
        poolInfo.totalStaked += totalPrice;

        require(
            additionalPoolInfo.tokensStaked[msg.sender] >=
                poolInfo.apyStruct[0].amount,
            "MADworld: total stake less than minimum"
        );
        require(
            poolInfo.totalStaked <= poolInfo.totalPoolSize,
            "MADworld: exceed pool limit"
        );

        additionalPoolInfo.userLastStakeTime[msg.sender] = block.timestamp;

        emit Staked(
            msg.sender,
            _poolId,
            _payload._ids,
            _payload._prices,
            totalPrice
        );
    }

    // solhint-disable-next-line
    function withdraw(
        uint256 _poolId,
        uint256 _boostId,
        uint256[] calldata _ids
    )
        external
        nonReentrant
        validatePoolById(_poolId)
        updateState(_poolId, msg.sender)
    {
        Pool storage poolInfo = pools[_poolId];
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];

        uint256 totalPrice;
        uint256[] memory _prices = new uint256[](_ids.length);

        if (_boostId > 0) {
            require(
                additionalPoolInfo.boostCardsStaked[msg.sender] == _boostId,
                "MADworld: invalid boost nft id input"
            );

            poolInfo.nftCollection.nftBoost.safeTransferFrom(
                address(this),
                msg.sender,
                _boostId,
                "0x"
            );

            additionalPoolInfo.boostCardsStaked[msg.sender] = 0;
            additionalPoolInfo.userBoostApr[msg.sender] = 0;

            emit BoostWithdrawn(_poolId, _boostId);
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] != 0, "MADworld: invalid input");

            uint256 price;

            bool found;

            for (
                uint256 j = 0;
                j < additionalPoolInfo.higherTierCardsStaked[msg.sender].length;
                j++
            ) {
                if (
                    additionalPoolInfo.higherTierCardsStaked[msg.sender][j] ==
                    _ids[i]
                ) {
                    found = true;
                    price = additionalPoolInfo.higherTierCards[_ids[i]];
                    _prices[i] = additionalPoolInfo.higherTierCards[_ids[i]];
                    additionalPoolInfo.higherTierCardsStaked[msg.sender][j] = 0;
                    break;
                }
            }

            if (!found) {
                for (
                    uint256 j = 0;
                    j <
                    additionalPoolInfo.lowerTierCardsStaked[msg.sender].length;
                    j++
                ) {
                    if (
                        additionalPoolInfo.lowerTierCardsStaked[msg.sender][
                            j
                        ] == _ids[i]
                    ) {
                        found = true;
                        price = additionalPoolInfo.lowerTierCards[_ids[i]];
                        _prices[i] = additionalPoolInfo.lowerTierCards[_ids[i]];
                        additionalPoolInfo.lowerTierCardsStaked[msg.sender][
                                j
                            ] = 0;
                        break;
                    }
                }
            }

            require(found, "MADworld: token is not staked");

            poolInfo.nftCollection.nft.safeTransferFrom(
                address(this),
                msg.sender,
                _ids[i],
                "0x"
            );
            totalPrice += price;
        }

        additionalPoolInfo.tokensStaked[msg.sender] -= totalPrice;
        poolInfo.totalStaked -= totalPrice;

        uint256 _fee;
        if (
            block.timestamp <
            additionalPoolInfo.userLastStakeTime[msg.sender] +
                (poolInfo.unstakeFeeDuration) &&
            poolInfo.rewardToken.balanceOf(address(this)) > 0
        ) //You do not pay unstaking fee when staking event is over
        {
            //charge fee
            _fee = (totalPrice * (poolInfo.unstakeFee)) / 1e18;
            poolInfo.stakingToken.safeTransfer(
                poolInfo.feeReceiverAddress,
                _fee
            );
        }

        uint256[] memory _higherTierCardsStaked = additionalPoolInfo
            .higherTierCardsStaked[msg.sender];
        uint256[] memory _lowerTierCardsStaked = additionalPoolInfo
            .lowerTierCardsStaked[msg.sender];

        additionalPoolInfo.higherTierCardsStaked[msg.sender] = new uint256[](0);
        additionalPoolInfo.lowerTierCardsStaked[msg.sender] = new uint256[](0);

        for (uint256 i = 0; i < _higherTierCardsStaked.length; i++) {
            if (_higherTierCardsStaked[i] > 0) {
                additionalPoolInfo.higherTierCardsStaked[msg.sender].push(
                    _higherTierCardsStaked[i]
                );
            }
        }

        for (uint256 i = 0; i < _lowerTierCardsStaked.length; i++) {
            if (_lowerTierCardsStaked[i] > 0) {
                additionalPoolInfo.lowerTierCardsStaked[msg.sender].push(
                    _lowerTierCardsStaked[i]
                );
            }
        }

        {
            uint256 balance = poolInfo.stakingToken.balanceOf(address(this));

            require(
                balance >= totalPrice - _fee,
                "MADworld: contract insufficient balance"
            );
        }

        poolInfo.stakingToken.safeTransfer(msg.sender, totalPrice - _fee);

        emit Withdrawn(msg.sender, _poolId, _ids, _prices, totalPrice, _fee);
    }

    function setSigner(address _signer) external override onlyRole(ADMIN) {
        signer = _signer;

        emit SetSigner(_signer);
    }

    function _setApyStruct(uint256 _poolId, ApyStruct[] memory listApy)
        private
        validatePoolById(_poolId)
        onlyRole(ADMIN)
    {
        Pool storage poolInfo = pools[_poolId];

        uint256 len = listApy.length;

        for (uint256 i = 0; i < len; i++) {
            require(listApy[i].amount > 0, "MADworld: invalid APY amount");
            require(listApy[i].apy > 0, "MADworld: invalid APY value");

            poolInfo.apyStruct.push(
                ApyStruct({ amount: listApy[i].amount, apy: listApy[i].apy })
            );
        }

        emit SetApyStruct(poolInfo.apyStruct);
    }

    function getApyByStake(uint256 _poolId, uint256 _amount)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        Pool storage poolInfo = pools[_poolId];

        if (
            poolInfo.apyStruct.length == 0 ||
            _amount < poolInfo.apyStruct[0].amount
        ) {
            return 0;
        }

        for (uint256 i = 0; i < poolInfo.apyStruct.length; i++) {
            if (_amount <= poolInfo.apyStruct[i].amount) {
                return poolInfo.apyStruct[i].apy;
            }
        }

        return poolInfo.apyStruct[poolInfo.apyStruct.length - 1].apy;
    }

    function getTotalApy(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        AdditionalPoolInfo storage additionalPoolInfo = additionalPoolInfos[
            _poolId
        ];
        uint256 baseAPY = getApyByStake(
            _poolId,
            additionalPoolInfo.tokensStaked[_userAddress]
        );
        uint256 boostedApy = additionalPoolInfo.userBoostApr[_userAddress];
        return (baseAPY * (1e18 + boostedApy)) / 1e18;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

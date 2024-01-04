//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./IMintable.sol";

contract NFTStaking is ReentrancyGuard, Ownable, ERC1155Holder {
    using SafeMath for uint256;
    using Address for address;

    // Events
    event NFTRegistred(uint256 indexed nftokenId_, uint256 multiplier_);
    event Staked(address indexed from_, uint256 amount_, uint256 nftokenId_);
    event Withdrawn(address indexed to_, uint256 amount_, uint256 nftokenId_);
    event Claimed(address indexed to_, uint256 amount_);

    // NFT token address
    IERC1155 public nfToken;

    // Supported NFT ids
    uint256 public constant G003_NFTID = 181077;
    uint256 public constant G002_NFTID = 181123;
    uint256 public constant G001_NFTID = 181087;

    // base value of supported NFTs
    uint256 public constant BASE_NFT_VALUE = 0.25 ether;

    // NFT multipliers per id ( = NFTValue / BASE_NFT_VALUE )
    mapping(uint256 => uint256) public nftMultipliers;

    struct UserInfos {
        mapping(uint256 => uint256) balances; // balances per NFT id
        uint256 pendingReward; // claimable reward
        uint256 rewardPerBaseNFTPaid; // accumulated
    }

    struct PoolInfos {
        uint256 lastUpdateTimestamp;
        uint256 rewardPerBaseNFTStored;
        uint256 totalValueStacked; // Total value of NFT stacked ( = SUM (NFT * multiplier ) )
    }

    PoolInfos private _poolInfos;
    mapping(address => UserInfos) private _usersInfos; // Users infos per address

    // Mintable reward token
    IMintable public rewardToken;
    // reward rate per second
    uint256 public rewardRate;

    uint256 public constant DURATION = 31 days;

    // Mintable reward amount
    uint256 public constant REWARD_ALLOCATION = 9900 * 1e18;

    // Farming will be open on 15/03/2021 at 07:00:00 UTC
    uint256 public constant FARMING_START_TIMESTAMP = 1615791600;

    // No more rewards after 15/04/2021 at 07:00:00 UTC
    uint256 public constant FARMING_END_TIMESTAMP =
        FARMING_START_TIMESTAMP + DURATION;

    bool public farmingStarted = false;

    constructor(address nfToken_, address rewardToken_) public {
        require(
            rewardToken_.isContract(),
            "NFTStaking: rewardToken_ should be a contract"
        );
        require(
            nfToken_.isContract(),
            "NFTStaking: nfToken_ should be a contract"
        );
        rewardToken = IMintable(rewardToken_);
        nfToken = IERC1155(nfToken_);
        rewardRate = REWARD_ALLOCATION.div(DURATION);
        _registerNFT(G003_NFTID, 1); // multiplier is 1 = 0.25eth / BASE_NFT_VALUE
        _registerNFT(G002_NFTID, 4);
        _registerNFT(G001_NFTID, 400);
    }

    function _registerNFT(uint256 nftokenId_, uint256 multiplier_) internal {
        require(nftMultipliers[nftokenId_] == 0, "NFTStaking: Only once");
        _checkNftokenId(nftokenId_);
        nftMultipliers[nftokenId_] = multiplier_;
        emit NFTRegistred(nftokenId_, multiplier_);
    }

    function stake(uint256 nftokenId_, uint256 amount_) external nonReentrant {
        _checkNftokenId(nftokenId_);
        _checkFarming();
        _updateReward(msg.sender);

        require(
            !address(msg.sender).isContract(),
            "NFTStaking: Please use your individual account"
        );

        require(amount_ > 0, "NFTStaking: Cannot stake 0");

        // withdraw NFT from the caller
        nfToken.safeTransferFrom(
            msg.sender,
            address(this),
            nftokenId_,
            amount_,
            ""
        );

        uint256 multiplier = nftMultipliers[nftokenId_];
        _poolInfos.totalValueStacked = _poolInfos.totalValueStacked.add(
            amount_.mul(multiplier)
        );

        // Add to balance
        _usersInfos[msg.sender].balances[nftokenId_] = _usersInfos[msg.sender]
            .balances[nftokenId_]
            .add(amount_);

        emit Staked(msg.sender, amount_, nftokenId_);
    }

    function withdraw(uint256 nftokenId_, uint256 amount_)
        public
        nonReentrant
    {
        _checkNftokenId(nftokenId_);
        _checkFarming();
        _updateReward(msg.sender);

        require(amount_ > 0, "NFTStaking: Cannot withdraw 0");
        require(
            balanceOf(msg.sender, nftokenId_) >= amount_,
            "NFTStaking: Insufficent balance"
        );

        uint256 multiplier = nftMultipliers[nftokenId_];
        _poolInfos.totalValueStacked = _poolInfos.totalValueStacked.sub(
            amount_.mul(multiplier)
        );

        // Reduce balance
        _usersInfos[msg.sender].balances[nftokenId_] = _usersInfos[msg.sender]
            .balances[nftokenId_]
            .sub(amount_);

        // send NFT to the caller
        nfToken.safeTransferFrom(
            address(this),
            msg.sender,
            nftokenId_,
            amount_,
            ""
        );
        emit Withdrawn(msg.sender, amount_, nftokenId_);
    }

    function claim() public nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        uint256 reward = _usersInfos[msg.sender].pendingReward;
        if (reward > 0) {
            _usersInfos[msg.sender].pendingReward = 0;
            rewardToken.mint(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function withdrawAndClaim(uint256 nftokenId_, uint256 amount_) public {
        withdraw(nftokenId_, amount_);
        claim();
    }

    function exit(uint256 nftokenId_) external {
        withdrawAndClaim(nftokenId_, balanceOf(msg.sender, nftokenId_));
    }

    function totalValueStacked() external view returns (uint256) {
        return _poolInfos.totalValueStacked;
    }

    function rewardPerBaseNFTStored() external view returns (uint256) {
        return _poolInfos.rewardPerBaseNFTStored;
    }

    function balanceOf(address account_, uint256 nftokenId_)
        public
        view
        returns (uint256)
    {
        return _usersInfos[account_].balances[nftokenId_];
    }

    function rewardPerBaseNFT() public view returns (uint256) {
        if (_poolInfos.totalValueStacked == 0) {
            return _poolInfos.rewardPerBaseNFTStored;
        }
        return
            _poolInfos.rewardPerBaseNFTStored.add(
                lastTimeRewardApplicable()
                    .sub(_poolInfos.lastUpdateTimestamp)
                    .mul(rewardRate)
                    .div(_poolInfos.totalValueStacked)
            );
    }

    function pendingReward(address account_) public view returns (uint256) {
        uint256 g001Reward = _pendingRewardByNFTokenId(account_, G001_NFTID);
        uint256 g002Reward = _pendingRewardByNFTokenId(account_, G002_NFTID);
        uint256 g003Reward = _pendingRewardByNFTokenId(account_, G003_NFTID);
        return
            _usersInfos[account_]
                .pendingReward
                .add(g001Reward)
                .add(g002Reward)
                .add(g003Reward);
    }

    function _pendingRewardByNFTokenId(address account_, uint256 nftokenId_)
        private
        view
        returns (uint256)
    {
        return
            balanceOf(account_, nftokenId_)
                .mul(
                rewardPerBaseNFT().sub(
                    _usersInfos[account_].rewardPerBaseNFTPaid
                )
            )
                .mul(nftMultipliers[nftokenId_]);
    }

    function _updateReward(address account_) internal {
        _poolInfos.rewardPerBaseNFTStored = rewardPerBaseNFT();
        _poolInfos.lastUpdateTimestamp = lastTimeRewardApplicable();
        if (account_ != address(0)) {
            _usersInfos[account_].pendingReward = pendingReward(account_);

            _usersInfos[account_].rewardPerBaseNFTPaid = _poolInfos
                .rewardPerBaseNFTStored;
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, FARMING_END_TIMESTAMP);
    }

    function getNFTValue(uint256 nftokenId_) public view returns (uint256) {
        return BASE_NFT_VALUE.mul(nftMultipliers[nftokenId_]);
    }

    function _checkNftokenId(uint256 nftokenId_) private pure {
        require(
            nftokenId_ == G001_NFTID ||
                nftokenId_ == G002_NFTID ||
                nftokenId_ == G003_NFTID,
            "NFTStaking: unsupported nftokenId_"
        );
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(
            FARMING_START_TIMESTAMP <= block.timestamp,
            "NFTStaking: Please wait until farming started"
        );
        if (!farmingStarted) {
            farmingStarted = true;
            _poolInfos.lastUpdateTimestamp = block.timestamp;
        }
    }
}

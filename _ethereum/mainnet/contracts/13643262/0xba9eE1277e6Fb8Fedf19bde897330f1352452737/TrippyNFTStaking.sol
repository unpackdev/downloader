// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Enumerable.sol";
import "./IxTrippyToken.sol";
import "./ITrippyNFTStaking.sol";

contract TrippyNFTStaking is
    ITrippyNFTStaking,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    mapping(address => UserInfo) public userInfo;

    IERC721Enumerable public trippyNFT;
    IxTrippyToken public trippyToken;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerBlock;
    uint256 public totalHashes;
    uint256 public accTrippyNFTPerShare;
    uint256 constant ACC_TRIPPY_PRECISION = 1e12;

    uint256 public ownerFee = 1000; // 10%
    address public ownerFeeReceiver;
    uint256 public daoFee = 2500; // 25%
    address public daoFeeReceiver;
    uint256 public communityFee = 1500; // 15%
    address public communityFeeReceiver;

    modifier updateRewardPool() {
        if (totalHashes > 0) {
            uint256 reward = _calculateReward();
            accTrippyNFTPerShare = accTrippyNFTPerShare.add(
                reward.mul(ACC_TRIPPY_PRECISION).div(totalHashes)
            );
        }
        lastUpdateBlock = block.number;
        _;
    }

    function initialize(
        address _trippyNFT,
        address _trippy,
        uint256 _rewardPerBlock,
        address _ownerFeeReceiver,
        address _daoFeeReceiver,
        address _communityFeeReceiver
    ) external initializer {
        __Ownable_init();

        trippyNFT = IERC721Enumerable(_trippyNFT);
        trippyToken = IxTrippyToken(_trippy);
        rewardPerBlock = _rewardPerBlock;
        ownerFeeReceiver = _ownerFeeReceiver;
        daoFeeReceiver = _daoFeeReceiver;
        communityFeeReceiver = _communityFeeReceiver;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setOwnerFee(uint256 _ownerFee) external onlyOwner {
        ownerFee = _ownerFee;
    }

    function setOwnerFeeReceiver(address _ownerFeeReceiver) external onlyOwner {
        ownerFeeReceiver = _ownerFeeReceiver;
    }

    function setDAOFee(uint256 _daoFee) external onlyOwner {
        daoFee = _daoFee;
    }

    function setDAOFeeReceiver(address _daoFeeReceiver) external onlyOwner {
        daoFeeReceiver = _daoFeeReceiver;
    }

    function setCommunityFee(uint256 _communityFee) external onlyOwner {
        communityFee = _communityFee;
    }

    function setCommunityFeeReceiver(address _communityFeeReceiver)
        external
        onlyOwner
    {
        communityFeeReceiver = _communityFeeReceiver;
    }

    function stake(uint256 _nftId)
        public
        override
        updateRewardPool
        whenNotPaused
    {
        require(_nftId > 0, "Staking: Nft id must be greater than 0");

        UserInfo storage user = userInfo[_msgSender()];

        // Calculate Fee & Reward
        (
            uint256 feeToOwner,
            uint256 feeToDAO,
            uint256 feeToCommunity,
            uint256 rewardToUser
        ) = _calculateRewardOfUser(user);

        // Distribute the TrippyToken
        if (feeToOwner > 0) {
            trippyToken.mint(ownerFeeReceiver, feeToOwner);
        }
        if (feeToDAO > 0) {
            trippyToken.mint(daoFeeReceiver, feeToDAO);
        }
        if (feeToCommunity > 0) {
            trippyToken.mint(communityFeeReceiver, feeToCommunity);
        }
        if (rewardToUser > 0) {
            trippyToken.mint(_msgSender(), rewardToUser);
        }

        // Transfer NFT
        trippyNFT.transferFrom(_msgSender(), address(this), _nftId);
        totalHashes = totalHashes.add(1);

        // Update User Info
        user.hashes = user.hashes.add(1);
        user.rewardDebt = user.hashes.mul(accTrippyNFTPerShare).div(
            ACC_TRIPPY_PRECISION
        );
        user.isStaked[_nftId] = true;

        emit StakedTrippyNFT(_nftId, address(this));
    }

    function stakeMultiple(uint256[] memory _nftIds) external {
        uint256 length = _nftIds.length;

        for (uint256 i = 0; i < length; i++) {
            stake(_nftIds[i]);
        }
    }

    function withdraw(uint256 _nftId)
        public
        override
        updateRewardPool
        whenNotPaused
    {
        require(_nftId > 0, "Withdraw: Nft id must be greater than 0");
        UserInfo storage user = userInfo[_msgSender()];
        require(user.hashes > 0, "Withdraw: no NFTs to withdraw");
        require(user.isStaked[_nftId], "Withdraw: didnt stake the NFT");

        // Calculate Fee & Reward
        (
            uint256 feeToOwner,
            uint256 feeToDAO,
            uint256 feeToCommunity,
            uint256 rewardToUser
        ) = _calculateRewardOfUser(user);

        // Distribute the TrippyToken
        if (feeToOwner > 0) {
            trippyToken.mint(ownerFeeReceiver, feeToOwner);
        }
        if (feeToDAO > 0) {
            trippyToken.mint(daoFeeReceiver, feeToDAO);
        }
        if (feeToCommunity > 0) {
            trippyToken.mint(communityFeeReceiver, feeToCommunity);
        }
        if (rewardToUser > 0) {
            trippyToken.mint(_msgSender(), rewardToUser);
        }

        // Transfer NFT
        trippyNFT.transferFrom(address(this), _msgSender(), _nftId);
        totalHashes = totalHashes.sub(1);

        // Update UserInfo
        user.hashes = user.hashes.sub(1);
        user.rewardDebt = user.hashes.mul(accTrippyNFTPerShare).div(
            ACC_TRIPPY_PRECISION
        );
        user.isStaked[_nftId] = false;

        emit WithdrawnTrippyNFT(_nftId, _msgSender());
    }

    function withdrawMultiple(uint256[] memory _nftIds) external {
        uint256 length = _nftIds.length;

        for (uint256 i = 0; i < length; i++) {
            withdraw(_nftIds[i]);
        }
    }

    function claim() external override updateRewardPool {
        UserInfo storage user = userInfo[_msgSender()];
        require(user.hashes > 0, "Withdraw: no NFTs to withdraw");

        // Calculate Fee & Reward
        (
            uint256 feeToOwner,
            uint256 feeToDAO,
            uint256 feeToCommunity,
            uint256 rewardToUser
        ) = _calculateRewardOfUser(user);

        // Distribute the TrippyToken
        if (feeToOwner > 0) {
            trippyToken.mint(ownerFeeReceiver, feeToOwner);
        }
        if (feeToDAO > 0) {
            trippyToken.mint(daoFeeReceiver, feeToDAO);
        }
        if (feeToCommunity > 0) {
            trippyToken.mint(communityFeeReceiver, feeToCommunity);
        }
        if (rewardToUser > 0) {
            trippyToken.mint(_msgSender(), rewardToUser);
            emit ClaimTrippyNFT(rewardToUser, _msgSender());
        }

        // Update UserInfo
        user.rewardDebt = user.hashes.mul(accTrippyNFTPerShare).div(
            ACC_TRIPPY_PRECISION
        );
    }

    function setRewardPerBlock(uint256 _amount) external override onlyOwner {
        rewardPerBlock = _amount;
    }

    function calculateReward(address _owner) external view returns (uint256) {
        if (totalHashes > 0) {
            UserInfo storage user = userInfo[_owner];
            uint256 reward = _calculateReward();
            uint256 _accTrippyNFTPerShare = accTrippyNFTPerShare.add(
                reward.mul(ACC_TRIPPY_PRECISION).div(totalHashes)
            );

            return
                user
                    .hashes
                    .mul(_accTrippyNFTPerShare)
                    .div(ACC_TRIPPY_PRECISION)
                    .sub(user.rewardDebt)
                    .mul(1e4 - ownerFee - daoFee - communityFee)
                    .div(1e4);
        }

        return 0;
    }

    function stakedTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        UserInfo storage user = userInfo[_owner];
        uint256[] memory nftIds = new uint256[](user.hashes);

        if (user.hashes > 0) {
            uint256 balance = trippyNFT.balanceOf(address(this));
            uint256 j = 0;

            for (uint256 i = 0; i < balance; i++) {
                uint256 nftId = trippyNFT.tokenOfOwnerByIndex(address(this), i);

                if (user.isStaked[nftId]) {
                    nftIds[j++] = nftId;
                }
            }
        }

        return nftIds;
    }

    function _calculateReward() internal view returns (uint256) {
        uint256 blocksPassed = block.number.sub(lastUpdateBlock);
        return rewardPerBlock.mul(blocksPassed);
    }

    function _calculateRewardOfUser(UserInfo storage user)
        internal
        view
        returns (
            uint256 feeToOwner,
            uint256 feeToDAO,
            uint256 feeToCommunity,
            uint256 rewardToUser
        )
    {
        uint256 pending = user
            .hashes
            .mul(accTrippyNFTPerShare)
            .div(ACC_TRIPPY_PRECISION)
            .sub(user.rewardDebt);

        feeToOwner = pending.mul(ownerFee).div(1e4);
        feeToDAO = pending.mul(daoFee).div(1e4);
        feeToCommunity = pending.mul(communityFee).div(1e4);
        rewardToUser = pending.sub(feeToOwner).sub(feeToDAO).sub(
            feeToCommunity
        );
    }
}

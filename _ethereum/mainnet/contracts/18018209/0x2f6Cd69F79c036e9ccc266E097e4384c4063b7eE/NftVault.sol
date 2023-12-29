// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./EnumerableSetUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./INftVault.sol";
import "./IDelegationRegistry.sol";

import "./ApeStakingLib.sol";
import "./VaultLogic.sol";

contract NftVault is INftVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ApeStakingLib for IApeCoinStaking;

    VaultStorage internal _vaultStorage;

    modifier onlyApe(address nft_) {
        require(
            nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc || nft_ == _vaultStorage.bakc,
            "NftVault: not ape"
        );
        _;
    }

    modifier onlyApeCaller() {
        require(
            msg.sender == _vaultStorage.bayc || msg.sender == _vaultStorage.mayc || msg.sender == _vaultStorage.bakc,
            "NftVault: caller not ape"
        );
        _;
    }

    modifier onlyAuthorized() {
        require(_vaultStorage.authorized[msg.sender], "StNft: caller is not authorized");
        _;
    }

    function initialize(IApeCoinStaking apeCoinStaking_, IDelegationRegistry delegationRegistry_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _vaultStorage.apeCoinStaking = apeCoinStaking_;
        _vaultStorage.delegationRegistry = delegationRegistry_;
        _vaultStorage.apeCoin = IERC20Upgradeable(_vaultStorage.apeCoinStaking.apeCoin());
        _vaultStorage.bayc = address(_vaultStorage.apeCoinStaking.bayc());
        _vaultStorage.mayc = address(_vaultStorage.apeCoinStaking.mayc());
        _vaultStorage.bakc = address(_vaultStorage.apeCoinStaking.bakc());
        _vaultStorage.apeCoin.approve(address(_vaultStorage.apeCoinStaking), type(uint256).max);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override onlyApeCaller returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function stakerOf(address nft_, uint256 tokenId_) external view onlyApe(nft_) returns (address) {
        return VaultLogic._stakerOf(_vaultStorage, nft_, tokenId_);
    }

    function ownerOf(address nft_, uint256 tokenId_) external view onlyApe(nft_) returns (address) {
        return VaultLogic._ownerOf(_vaultStorage, nft_, tokenId_);
    }

    function refundOf(address nft_, address staker_) external view onlyApe(nft_) returns (Refund memory) {
        return _vaultStorage.refunds[nft_][staker_];
    }

    function positionOf(address nft_, address staker_) external view onlyApe(nft_) returns (Position memory) {
        return _vaultStorage.positions[nft_][staker_];
    }

    function pendingRewards(address nft_, address staker_) external view onlyApe(nft_) returns (uint256) {
        IApeCoinStaking.PoolWithoutTimeRange memory pool = _vaultStorage.apeCoinStaking.getNftPool(nft_);
        Position memory position = _vaultStorage.positions[nft_][staker_];

        (uint256 rewardsSinceLastCalculated, ) = _vaultStorage.apeCoinStaking.getNftRewardsBy(
            nft_,
            pool.lastRewardedTimestampHour,
            ApeStakingLib.getPreviousTimestampHour()
        );
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (
            block.timestamp > pool.lastRewardedTimestampHour + ApeStakingLib.SECONDS_PER_HOUR && pool.stakedAmount != 0
        ) {
            accumulatedRewardsPerShare =
                accumulatedRewardsPerShare +
                (rewardsSinceLastCalculated * ApeStakingLib.APE_COIN_PRECISION) /
                pool.stakedAmount;
        }
        return
            uint256(int256(position.stakedAmount * accumulatedRewardsPerShare) - position.rewardsDebt) /
            ApeStakingLib.APE_COIN_PRECISION;
    }

    function totalStakingNft(address nft_, address staker_) external view returns (uint256) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].length();
    }

    function stakingNftIdByIndex(address nft_, address staker_, uint256 index_) external view returns (uint256) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].at(index_);
    }

    function isStaking(address nft_, address staker_, uint256 tokenId_) external view returns (bool) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].contains(tokenId_);
    }

    function authorise(address addr_, bool authorized_) external override onlyOwner {
        _vaultStorage.authorized[addr_] = authorized_;
    }

    function setDelegateCash(
        address delegate_,
        address nft_,
        uint256[] calldata tokenIds_,
        bool value_
    ) external override onlyAuthorized onlyApe(nft_) {
        require(delegate_ != address(0), "nftVault: invalid delegate");
        uint256 tokenId_;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenId_ = tokenIds_[i];
            require(
                msg.sender == VaultLogic._ownerOf(_vaultStorage, nft_, tokenId_),
                "nftVault: only owner can delegate"
            );
            _vaultStorage.delegationRegistry.delegateForToken(delegate_, nft_, tokenId_, value_);
        }
    }

    function hasDelegateCash(
        address nft_,
        address delegate_,
        uint256[] calldata tokenIds_
    ) external view override onlyApe(nft_) returns (bool[] memory delegations) {
        delegations = new bool[](tokenIds_.length);
        uint256 tokenId_;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenId_ = tokenIds_[i];
            delegations[i] = _vaultStorage.delegationRegistry.checkDelegateForToken(
                delegate_,
                address(this),
                nft_,
                tokenId_
            );
        }
    }

    function getDelegateCashForToken(
        address nft_,
        uint256[] calldata tokenIds_
    ) external view override returns (address[][] memory delegates) {
        delegates = new address[][](tokenIds_.length);
        uint256 tokenId_;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenId_ = tokenIds_[i];
            delegates[i] = _vaultStorage.delegationRegistry.getDelegatesForToken(address(this), nft_, tokenId_);
        }
    }

    function depositNft(
        address nft_,
        uint256[] calldata tokenIds_,
        address staker_
    ) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        uint256 tokenId_;
        uint256 poolId_;
        IApeCoinStaking.Position memory position_;
        IApeCoinStaking.PairingStatus memory pairingStatus_;

        // transfer nft and set permission
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // block partially stake from official contract
            tokenId_ = tokenIds_[i];
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, tokenId_);
            require(position_.stakedAmount == 0, "nftVault: nft already staked");

            if (nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc) {
                poolId_ = _vaultStorage.apeCoinStaking.getNftPoolId(nft_);
                pairingStatus_ = _vaultStorage.apeCoinStaking.mainToBakc(poolId_, tokenId_);
                // block bayc & mayc which already paired with bakc
                require(!pairingStatus_.isPaired, "nftVault: already paired with bakc");
            }

            IERC721Upgradeable(nft_).safeTransferFrom(msg.sender, address(this), tokenIds_[i]);
            _vaultStorage.nfts[nft_][tokenIds_[i]] = NftStatus(msg.sender, staker_);
        }
        emit NftDeposited(nft_, msg.sender, staker_, tokenIds_);
    }

    function withdrawNft(
        address nft_,
        uint256[] calldata tokenIds_
    ) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");
        address staker_ = VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[0]);
        if (nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc) {
            VaultLogic._refundSinglePool(_vaultStorage, nft_, tokenIds_);
        } else if (nft_ == _vaultStorage.bakc) {
            VaultLogic._refundPairingPool(_vaultStorage, tokenIds_);
        }
        // transfer nft to sender
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._ownerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft owner"
            );
            require(
                staker_ == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: staker must be same"
            );
            delete _vaultStorage.nfts[nft_][tokenIds_[i]];
            // transfer nft
            IERC721Upgradeable(nft_).safeTransferFrom(address(this), msg.sender, tokenIds_[i]);
        }
        emit NftWithdrawn(nft_, msg.sender, staker_, tokenIds_);
    }

    function withdrawRefunds(address nft_) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        Refund memory _refund = _vaultStorage.refunds[nft_][msg.sender];
        uint256 amount = _refund.principal + _refund.reward;
        delete _vaultStorage.refunds[nft_][msg.sender];
        _vaultStorage.apeCoin.transfer(msg.sender, amount);
    }

    function stakeBaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external override onlyAuthorized nonReentrant {
        address nft_ = _vaultStorage.bayc;
        uint256 totalStakedAmount = 0;
        IApeCoinStaking.SingleNft memory singleNft_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be bayc staker"
            );
            totalStakedAmount += singleNft_.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(singleNft_.tokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalStakedAmount);
        _vaultStorage.apeCoinStaking.depositBAYC(nfts_);

        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalStakedAmount);

        emit SingleNftStaked(nft_, msg.sender, nfts_);
    }

    function unstakeBaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.bayc;
        IApeCoinStaking.SingleNft memory singleNft_;
        IApeCoinStaking.Position memory position_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be nft staker"
            );
            principal += singleNft_.amount;
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, singleNft_.tokenId);
            if (position_.stakedAmount == singleNft_.amount) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(singleNft_.tokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.withdrawBAYC(nfts_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        emit SingleNftUnstaked(nft_, msg.sender, nfts_);
    }

    function claimBaycPool(
        uint256[] calldata tokenIds_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.bayc;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(address(recipient_));
        _vaultStorage.apeCoinStaking.claimBAYC(tokenIds_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        emit SingleNftClaimed(nft_, msg.sender, tokenIds_, rewards);
    }

    function stakeMaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external override onlyAuthorized nonReentrant {
        address nft_ = _vaultStorage.mayc;
        uint256 totalApeCoinAmount = 0;
        IApeCoinStaking.SingleNft memory singleNft_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be mayc staker"
            );
            totalApeCoinAmount += singleNft_.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(singleNft_.tokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalApeCoinAmount);
        _vaultStorage.apeCoinStaking.depositMAYC(nfts_);
        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalApeCoinAmount);

        emit SingleNftStaked(nft_, msg.sender, nfts_);
    }

    function unstakeMaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.mayc;
        IApeCoinStaking.SingleNft memory singleNft_;
        IApeCoinStaking.Position memory position_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be nft staker"
            );
            principal += singleNft_.amount;
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, singleNft_.tokenId);
            if (position_.stakedAmount == singleNft_.amount) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(singleNft_.tokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);

        _vaultStorage.apeCoinStaking.withdrawMAYC(nfts_, recipient_);

        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        emit SingleNftUnstaked(nft_, msg.sender, nfts_);
    }

    function claimMaycPool(
        uint256[] calldata tokenIds_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.mayc;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.claimMAYC(tokenIds_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        emit SingleNftClaimed(nft_, msg.sender, tokenIds_, rewards);
    }

    function stakeBakcPool(
        IApeCoinStaking.PairNftDepositWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftDepositWithAmount[] calldata maycPairs_
    ) external override onlyAuthorized nonReentrant {
        uint256 totalStakedAmount = 0;
        IApeCoinStaking.PairNftDepositWithAmount memory pair;
        address nft_ = _vaultStorage.bakc;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            totalStakedAmount += pair.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(pair.bakcTokenId);
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            totalStakedAmount += pair.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(pair.bakcTokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalStakedAmount);
        _vaultStorage.apeCoinStaking.depositBAKC(baycPairs_, maycPairs_);

        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalStakedAmount);

        emit PairedNftStaked(msg.sender, baycPairs_, maycPairs_);
    }

    function unstakeBakcPool(
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata maycPairs_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.bakc;
        IApeCoinStaking.Position memory position_;
        IApeCoinStaking.PairNftWithdrawWithAmount memory pair;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, pair.bakcTokenId);
            principal += (pair.isUncommit ? position_.stakedAmount : pair.amount);
            if (pair.isUncommit) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(pair.bakcTokenId);
            }
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, pair.bakcTokenId);
            principal += (pair.isUncommit ? position_.stakedAmount : pair.amount);
            if (pair.isUncommit) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(pair.bakcTokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(address(this));
        _vaultStorage.apeCoinStaking.withdrawBAKC(baycPairs_, maycPairs_);
        rewards = _vaultStorage.apeCoin.balanceOf(address(this)) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        _vaultStorage.apeCoin.transfer(recipient_, principal + rewards);

        emit PairedNftUnstaked(msg.sender, baycPairs_, maycPairs_);
    }

    function claimBakcPool(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.bakc;
        IApeCoinStaking.PairNft memory pair;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bakc, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.claimBAKC(baycPairs_, maycPairs_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        emit PairedNftClaimed(msg.sender, baycPairs_, maycPairs_, rewards);
    }
}

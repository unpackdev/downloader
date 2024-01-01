// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./MessageHashUtils.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./IERC721.sol";

interface IApeCoinStaking {
    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    function depositSelfApeCoin(uint256 _amount) external;
    function getApeCoinStake(address _address) external view returns (DashboardStake memory);
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
    function withdrawApeCoin(uint256 _amount, address _recipient) external;
    function withdrawSelfApeCoin(uint256 _amount) external;
    function claimApeCoin(address _recipient) external;
    function claimSelfApeCoin() external;
}

library B3LApeStakingStorage {
    struct Layout {
        address signer;
        uint256 maxApeCoinPerB3AST;
        mapping(uint256 => uint256) stakedApeCoin;
        mapping(uint256 => uint256) nftClaimedRewards;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("B3LApeStaking.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract B3LApeStaking is OwnableUpgradeable {
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrNotOwner();
    error ErrExceedMaxApeCoinPerB3AST();
    error ErrInvalidSignature();
    error ErrExpiredSignature();
    error ErrNothingToUnstake();
    error ErrNothingToClaim();
    error ErrNothingStaked();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EvStake(address indexed sender, uint256[] nftIDs, uint256[] amounts);
    event EvClaim(address indexed sender, uint256[] nftIDs, uint256[] totalEarneds, uint256 totalClaim);
    event EvUnstake(address indexed sender, uint256[] nftIDs, uint256[] totalEarneds, uint256 totalUnstake);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    IERC721 public immutable B3ASTS;
    IERC20 public immutable APECOIN;
    IApeCoinStaking public immutable APECOIN_STAKING;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address b3astsAddress_, address apecoinAddress_, address apecoinStakingAddress_) {
        B3ASTS = IERC721(b3astsAddress_);
        APECOIN = IERC20(apecoinAddress_);
        APECOIN_STAKING = IApeCoinStaking(apecoinStakingAddress_);
    }

    function initialize(address signer_) external initializer {
        __Ownable_init(tx.origin);
        B3LApeStakingStorage.layout().signer = signer_;
        B3LApeStakingStorage.layout().maxApeCoinPerB3AST = 70 ether;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function stakeApeCoin(
        uint256[] calldata nftIDs_,
        uint256 expirationTimestamp_,
        bytes calldata signature_,
        uint256[] calldata amounts_
    ) external {
        B3LApeStakingStorage.Layout storage __storage = B3LApeStakingStorage.layout();
        uint256 __maxApeCoinPerB3AST = __storage.maxApeCoinPerB3AST;

        // loop nfts
        uint256 __totalToStake;
        for (uint256 i = 0; i < nftIDs_.length; i++) {
            uint256 __amount = amounts_[i];
            uint256 __nftID = nftIDs_[i];

            // check owner
            if (B3ASTS.ownerOf(__nftID) != msg.sender) {
                revert ErrNotOwner();
            }

            // check amount
            if (__amount + __storage.stakedApeCoin[__nftID] > __maxApeCoinPerB3AST) {
                revert ErrExceedMaxApeCoinPerB3AST();
            }

            // update state
            B3LApeStakingStorage.layout().stakedApeCoin[__nftID] += __amount;

            // update accumulator
            __totalToStake += __amount;
        }

        // check signature
        bytes32 messageHash = keccak256(abi.encodePacked(nftIDs_, expirationTimestamp_, true));
        if (messageHash.toEthSignedMessageHash().recover(signature_) != __storage.signer) {
            revert ErrInvalidSignature();
        }

        // check expiration
        if (block.timestamp > expirationTimestamp_) {
            revert ErrExpiredSignature();
        }

        // transfer
        APECOIN.transferFrom(msg.sender, address(this), __totalToStake);

        // emit
        emit EvStake(msg.sender, nftIDs_, amounts_);
    }

    function claim(uint256[] calldata nftIDs_, uint256[] calldata totalEarneds_, bytes calldata signature_) external {
        B3LApeStakingStorage.Layout storage __storage = B3LApeStakingStorage.layout();

        // check signature
        bytes32 messageHash = keccak256(abi.encodePacked(nftIDs_, totalEarneds_, true));
        if (messageHash.toEthSignedMessageHash().recover(signature_) != __storage.signer) {
            revert ErrInvalidSignature();
        }

        // loop nfts
        uint256 __totalClaim = 0;
        for (uint256 i = 0; i < nftIDs_.length; i++) {
            uint256 __totalEarned = totalEarneds_[i];
            uint256 __nftID = nftIDs_[i];
            uint256 __claimedReward = __storage.nftClaimedRewards[__nftID];

            // check owner
            if (B3ASTS.ownerOf(__nftID) != msg.sender) {
                revert ErrNotOwner();
            }

            // check has staked coins
            if (__storage.stakedApeCoin[__nftID] == 0) {
                revert ErrNothingStaked();
            }

            // calculate claimable
            uint256 __claimable = __totalEarned - __claimedReward;

            // update state
            B3LApeStakingStorage.layout().nftClaimedRewards[__nftID] += __claimable;

            // update accumulator
            __totalClaim += __claimable;
        }

        if (__totalClaim == 0) {
            revert ErrNothingToClaim();
        }

        // transfer
        APECOIN.transfer(msg.sender, __totalClaim);

        // emit
        emit EvClaim(msg.sender, nftIDs_, totalEarneds_, __totalClaim);
    }

    function unstake(uint256[] calldata nftIDs_, uint256[] calldata totalEarneds_, bytes calldata signature_)
        external
    {
        B3LApeStakingStorage.Layout storage __storage = B3LApeStakingStorage.layout();

        // check signature
        bytes32 messageHash = keccak256(abi.encodePacked(nftIDs_, totalEarneds_, true));
        if (messageHash.toEthSignedMessageHash().recover(signature_) != __storage.signer) {
            revert ErrInvalidSignature();
        }

        // loop nfts
        uint256 __totalUnstakeAndClaim = 0;
        for (uint256 i = 0; i < nftIDs_.length; i++) {
            uint256 __totalEarned = totalEarneds_[i];
            uint256 __nftID = nftIDs_[i];
            uint256 __claimedReward = __storage.nftClaimedRewards[__nftID];
            uint256 __staked = __storage.stakedApeCoin[__nftID];

            // check owner
            if (B3ASTS.ownerOf(__nftID) != msg.sender) {
                revert ErrNotOwner();
            }

            // check has staked coins
            if (__staked == 0) {
                revert ErrNothingStaked();
            }

            // calculate claimable
            uint256 __claimable = __totalEarned - __claimedReward;

            // update state
            __storage.nftClaimedRewards[__nftID] += __claimable;
            __storage.stakedApeCoin[__nftID] = 0;

            __totalUnstakeAndClaim += __claimable;
            __totalUnstakeAndClaim += __staked;
        }

        // transfer
        APECOIN.transfer(msg.sender, __totalUnstakeAndClaim);

        // emit
        emit EvUnstake(msg.sender, nftIDs_, totalEarneds_, __totalUnstakeAndClaim);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setSigner(address signer_) external onlyOwner {
        B3LApeStakingStorage.layout().signer = signer_;
    }

    function setMaxApeCoinPerB3AST(uint256 maxApeCoinPerB3AST_) external onlyOwner {
        B3LApeStakingStorage.layout().maxApeCoinPerB3AST = maxApeCoinPerB3AST_;
    }

    function emergencyWithdraw() external onlyOwner {
        APECOIN.transfer(owner(), APECOIN.balanceOf(address(this)));
    }

    function stakeNativeApeCoin(uint256 amount_) external onlyOwner {
        APECOIN.approve(address(APECOIN_STAKING), amount_);
        APECOIN_STAKING.depositSelfApeCoin(amount_);
    }

    function stakeNativeApeCoinFromSender(uint256 amount_) external onlyOwner {
        APECOIN.transferFrom(msg.sender, address(this), amount_);
        APECOIN.approve(address(APECOIN_STAKING), amount_);
        APECOIN_STAKING.depositSelfApeCoin(amount_);
    }

    function withdrawStakedNativeApeCoinStaking() external onlyOwner {
        IApeCoinStaking.DashboardStake memory nativeStaked = getNativeStakedApeCoin();
        APECOIN_STAKING.withdrawSelfApeCoin(nativeStaked.deposited);
    }

    function withdrawNativeApeCoinStaking(uint256 amount_, address to_) external onlyOwner {
        APECOIN_STAKING.withdrawApeCoin(amount_, to_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function signer() external view returns (address) {
        return B3LApeStakingStorage.layout().signer;
    }

    function maxApeCoinPerB3AST() external view returns (uint256) {
        return B3LApeStakingStorage.layout().maxApeCoinPerB3AST;
    }

    function claimedRewards(uint256 nftID_) external view returns (uint256) {
        return B3LApeStakingStorage.layout().nftClaimedRewards[nftID_];
    }

    function getBatchClaimedRewards(uint256[] calldata nftIDs_) external view returns (uint256[] memory) {
        uint256[] memory _claimedRewards = new uint256[](nftIDs_.length);
        B3LApeStakingStorage.Layout storage __storage = B3LApeStakingStorage.layout();
        for (uint256 i = 0; i < nftIDs_.length; i++) {
            _claimedRewards[i] = __storage.nftClaimedRewards[nftIDs_[i]];
        }
        return _claimedRewards;
    }

    function stakedApeCoin(uint256 nftID_) external view returns (uint256) {
        return B3LApeStakingStorage.layout().stakedApeCoin[nftID_];
    }

    function getBatchStakedApeCoin(uint256[] calldata nftIDs_) external view returns (uint256[] memory) {
        uint256[] memory _stakedApeCoins = new uint256[](nftIDs_.length);
        B3LApeStakingStorage.Layout storage __storage = B3LApeStakingStorage.layout();
        for (uint256 i = 0; i < nftIDs_.length; i++) {
            _stakedApeCoins[i] = __storage.stakedApeCoin[nftIDs_[i]];
        }
        return _stakedApeCoins;
    }

    function getNativeStakedApeCoin() public view returns (IApeCoinStaking.DashboardStake memory) {
        return APECOIN_STAKING.getApeCoinStake(address(this));
    }

    function getNativeStakedApecoinPendingRewards() external view returns (uint256) {
        return APECOIN_STAKING.pendingRewards(0, address(this), 0);
    }
}

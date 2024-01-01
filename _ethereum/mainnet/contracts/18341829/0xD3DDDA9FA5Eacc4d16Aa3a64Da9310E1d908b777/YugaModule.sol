// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

import "./ERC721Module.sol";
import "./IApeCoinStaking.sol";
import "./ICyanApeCoinPlan.sol";
import "./AddressProvider.sol";

error TokenIsLocked();
error AlreadyInLockState();
error NotEnoughRewards();
error NotPaired();
error ApeCoinStakingIsLocked();

/// @title Cyan Wallet Yuga Module - A Cyan wallet's Ape & ApeCoin handling module.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract YugaModule is ERC721Module {
    AddressProvider constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    // ApePool ids
    uint256 public constant APECOIN_POOL_ID = 0;
    uint256 public constant BAYC_POOL_ID = 1;
    uint256 public constant MAYC_POOL_ID = 2;
    uint256 public constant BAKC_POOL_ID = 3;

    uint8 public constant LOCK_BIT_INDEX_0 = 0; // Lock bit index of BAYC & MAYC
    uint8 public constant LOCK_BIT_INDEX_1 = 1; // Lock bit index of BAKC
    uint8 public constant LOCK_BIT_INDEX_2 = 2; // Lock bit index of ApeCoin

    address private immutable BAYC;
    address private immutable MAYC;
    address private immutable BAKC;
    IERC20 private immutable apeCoin;
    IApeCoinStaking private immutable apeStaking;

    event SetLockedApeNFT(address collection, uint256 tokenId, uint8 lockStatus);

    constructor() {
        BAYC = addressProvider.addresses("BAYC");
        MAYC = addressProvider.addresses("MAYC");
        BAKC = addressProvider.addresses("BAKC");

        apeCoin = IERC20(addressProvider.addresses("APE_COIN"));
        apeStaking = IApeCoinStaking(addressProvider.addresses("APE_COIN_STAKING"));
    }

    /// @inheritdoc IModule
    function handleTransaction(
        address collection,
        uint256 value,
        bytes calldata data
    ) public payable override returns (bytes memory) {
        bytes4 funcHash = Utils.parseFunctionSelector(data);

        // BAYC deposit & withdraw checks
        if (
            funcHash == IApeCoinStaking.depositBAYC.selector ||
            funcHash == IApeCoinStaking.withdrawSelfBAYC.selector ||
            funcHash == IApeCoinStaking.withdrawBAYC.selector
        ) {
            _performSingleNftChecks(BAYC, data);
        }

        // MAYC deposit & withdraw checks
        if (
            funcHash == IApeCoinStaking.depositMAYC.selector ||
            funcHash == IApeCoinStaking.withdrawSelfMAYC.selector ||
            funcHash == IApeCoinStaking.withdrawMAYC.selector
        ) {
            _performSingleNftChecks(MAYC, data);
        }

        // BAYC & MAYC claim checks
        if (funcHash == IApeCoinStaking.claimBAYC.selector || funcHash == IApeCoinStaking.claimSelfBAYC.selector) {
            _performTokenIdChecks(BAYC, data);
        }
        if (funcHash == IApeCoinStaking.claimMAYC.selector || funcHash == IApeCoinStaking.claimSelfMAYC.selector) {
            _performTokenIdChecks(MAYC, data);
        }

        // BAKC checks
        if (funcHash == IApeCoinStaking.depositBAKC.selector) {
            _performPairDepositChecks(data);
        }
        if (funcHash == IApeCoinStaking.withdrawBAKC.selector) {
            _performPairWithdrawChecks(data);
        }
        if (funcHash == IApeCoinStaking.claimBAKC.selector || funcHash == IApeCoinStaking.claimSelfBAKC.selector) {
            _performPairClaims(data);
        }
        if (
            funcHash == IApeCoinStaking.withdrawApeCoin.selector ||
            funcHash == IApeCoinStaking.withdrawSelfApeCoin.selector ||
            funcHash == IApeCoinStaking.claimApeCoin.selector ||
            funcHash == IApeCoinStaking.claimSelfApeCoin.selector
        ) {
            _performApeCoinStakeChecks();
        }

        return super.handleTransaction(collection, value, data);
    }

    function getIsLocked(address collection, uint256 tokenId) internal view override returns (bool) {
        return Lockers.isLockedERC721(collection, tokenId);
    }

    function _performSingleNftChecks(address collection, bytes calldata data) private view {
        IApeCoinStaking.SingleNft[] memory nfts = abi.decode(data[4:], (IApeCoinStaking.SingleNft[]));

        for (uint256 i; i < nfts.length; ) {
            if (_isLocked(collection, nfts[i].tokenId, LOCK_BIT_INDEX_0)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    function _performTokenIdChecks(address collection, bytes calldata data) private view {
        uint256[] memory tokenIds = abi.decode(data[4:], (uint256[]));

        for (uint256 i; i < tokenIds.length; ) {
            if (_isLocked(collection, tokenIds[i], LOCK_BIT_INDEX_0)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    function _performPairDepositChecks(bytes calldata data) private view {
        (
            IApeCoinStaking.PairNftDepositWithAmount[] memory baycPairs,
            IApeCoinStaking.PairNftDepositWithAmount[] memory maycPairs
        ) = abi.decode(
                data[4:],
                (IApeCoinStaking.PairNftDepositWithAmount[], IApeCoinStaking.PairNftDepositWithAmount[])
            );

        _checkLockOfPairDeposits(baycPairs);
        _checkLockOfPairDeposits(maycPairs);
    }

    function _performPairWithdrawChecks(bytes calldata data) private view {
        (
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory baycPairs,
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory maycPairs
        ) = abi.decode(
                data[4:],
                (IApeCoinStaking.PairNftWithdrawWithAmount[], IApeCoinStaking.PairNftWithdrawWithAmount[])
            );

        _checkLockOfPairWithdrawals(baycPairs);
        _checkLockOfPairWithdrawals(maycPairs);
    }

    function _performPairClaims(bytes calldata data) private view {
        IApeCoinStaking.PairNft[] memory baycPairs;
        IApeCoinStaking.PairNft[] memory maycPairs;

        (baycPairs, maycPairs) = abi.decode(data[4:], (IApeCoinStaking.PairNft[], IApeCoinStaking.PairNft[]));
        _checkLockOfPairClaims(baycPairs);
        _checkLockOfPairClaims(maycPairs);
    }

    function _performApeCoinStakeChecks() private view {
        if (_isLocked(address(apeCoin), 0, LOCK_BIT_INDEX_2)) revert ApeCoinStakingIsLocked();
    }

    // Internal module methods, only operators can call these methods

    /// @notice Allows operators to lock BAYC and stake to the ape pool.
    /// @param tokenId Token ID of BAYC
    /// @param amount Loaning ApeCoin amount
    function depositBAYCAndLock(uint32 tokenId, uint224 amount) external {
        _depositSingleNftAndLock(BAYC, tokenId, amount);
    }

    /// @notice Allows operators to lock MAYC and stake to the ape pool.
    /// @param tokenId Token ID of MAYC
    /// @param amount Loaning ApeCoin amount
    function depositMAYCAndLock(uint32 tokenId, uint224 amount) external {
        _depositSingleNftAndLock(MAYC, tokenId, amount);
    }

    function _depositSingleNftAndLock(
        address collection,
        uint32 tokenId,
        uint224 amount
    ) private {
        _lock(collection, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(tokenId, amount);
        apeCoin.approve(address(apeStaking), amount);

        (collection == BAYC) ? apeStaking.depositBAYC(nfts) : apeStaking.depositMAYC(nfts);
    }

    /// @notice Allows operators to lock BAKC and stake to the ape pool.
    /// @param mainCollection BAYC or MAYC address
    /// @param mainTokenId BAYC or MAYC token ID
    /// @param bakcTokenId BAKC token ID
    /// @param amount Loaning ApeCoin amount
    function depositBAKCAndLock(
        address mainCollection,
        uint32 mainTokenId,
        uint32 bakcTokenId,
        uint224 amount
    ) external {
        _lock(mainCollection, mainTokenId, LOCK_BIT_INDEX_1);
        _lock(BAKC, bakcTokenId, LOCK_BIT_INDEX_1);

        IApeCoinStaking.PairNftDepositWithAmount[] memory baycs;
        IApeCoinStaking.PairNftDepositWithAmount[] memory maycs;

        if (mainCollection == BAYC) {
            baycs = new IApeCoinStaking.PairNftDepositWithAmount[](1);
            baycs[0] = IApeCoinStaking.PairNftDepositWithAmount(mainTokenId, bakcTokenId, uint184(amount));
        } else if (mainCollection == MAYC) {
            maycs = new IApeCoinStaking.PairNftDepositWithAmount[](1);
            maycs[0] = IApeCoinStaking.PairNftDepositWithAmount(mainTokenId, bakcTokenId, uint184(amount));
        }

        apeCoin.approve(address(apeStaking), amount);
        apeStaking.depositBAKC(baycs, maycs);
    }

    /// @notice Allows operators to lock ApeCoin pool stake, claim and withdraw function
    /// @param amount Staking ApeCoin amount
    function depositApeCoinAndLock(uint256 amount) external {
        _lock(address(apeCoin), 0, LOCK_BIT_INDEX_2);

        if (amount > 0) {
            apeCoin.approve(address(apeStaking), amount);
            apeStaking.depositSelfApeCoin(amount);
        }
    }

    /// @notice Allows operators to unlock BAYC and unstake from the ape pool.
    /// @param tokenId Token ID of BAYC
    function withdrawBAYCAndUnlock(uint32 tokenId) external {
        _unlock(BAYC, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(
            tokenId,
            uint224(apeStaking.nftPosition(BAYC_POOL_ID, tokenId).stakedAmount)
        );
        apeStaking.withdrawBAYC(nfts, msg.sender);
    }

    /// @notice Allows operators to unlock MAYC and unstake from the ape pool.
    /// @param tokenId Token ID of MAYC
    function withdrawMAYCAndUnlock(uint32 tokenId) external {
        _unlock(MAYC, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(
            tokenId,
            uint224(apeStaking.nftPosition(MAYC_POOL_ID, tokenId).stakedAmount)
        );
        apeStaking.withdrawMAYC(nfts, msg.sender);
    }

    /// @notice Allows operators to unlock BAKC and unstake from the ape pool.
    /// @param tokenId BAKC token ID
    function withdrawBAKCAndUnlock(uint32 tokenId) external {
        IApeCoinStaking.PairingStatus memory baycStatus = apeStaking.bakcToMain(tokenId, BAYC_POOL_ID);

        address mainCollection;
        uint32 mainTokenId;

        IApeCoinStaking.PairNftWithdrawWithAmount[] memory baycs;
        IApeCoinStaking.PairNftWithdrawWithAmount[] memory maycs;
        if (baycStatus.isPaired) {
            mainCollection = BAYC;
            mainTokenId = uint32(baycStatus.tokenId);
            baycs = new IApeCoinStaking.PairNftWithdrawWithAmount[](1);
            baycs[0] = IApeCoinStaking.PairNftWithdrawWithAmount(mainTokenId, tokenId, 0, true);
        } else {
            IApeCoinStaking.PairingStatus memory maycStatus = apeStaking.bakcToMain(tokenId, MAYC_POOL_ID);
            if (maycStatus.isPaired) {
                mainCollection = MAYC;
                mainTokenId = uint32(maycStatus.tokenId);
                maycs = new IApeCoinStaking.PairNftWithdrawWithAmount[](1);
                maycs[0] = IApeCoinStaking.PairNftWithdrawWithAmount(mainTokenId, tokenId, 0, true);
            } else {
                revert NotPaired();
            }
        }

        uint256 stakedAmount = apeStaking.nftPosition(BAKC_POOL_ID, tokenId).stakedAmount;
        uint256 rewards = apeStaking.pendingRewards(BAKC_POOL_ID, address(this), tokenId);

        _unlock(mainCollection, mainTokenId, LOCK_BIT_INDEX_1);
        _unlock(BAKC, tokenId, LOCK_BIT_INDEX_1);

        apeStaking.withdrawBAKC(baycs, maycs);
        apeCoin.transfer(msg.sender, stakedAmount + rewards);
    }

    /// @notice Allows operators to unlock ApeCoin pool stake, claim and withdraw function
    /// @param unstakeAmount Unstake amount
    /// @param serviceFee Service fee amount
    function withdrawApeCoinAndUnlock(uint256 unstakeAmount, uint256 serviceFee) external {
        _unlock(address(apeCoin), 0, LOCK_BIT_INDEX_2);

        apeStaking.withdrawSelfApeCoin(unstakeAmount);
        apeCoin.transfer(msg.sender, serviceFee);
    }

    function autoCompound(uint256 poolId, uint32 tokenId) public {
        _claimRewards(poolId, tokenId, msg.sender);
    }

    function autoCompoundApeCoinPool() public {
        apeStaking.claimApeCoin(msg.sender);
    }

    function _claimRewards(
        uint256 poolId,
        uint32 tokenId,
        address recipient
    ) private {
        if (poolId == BAYC_POOL_ID) {
            uint256[] memory nfts = new uint256[](1);
            nfts[0] = tokenId;

            apeStaking.claimBAYC(nfts, recipient);
        } else if (poolId == MAYC_POOL_ID) {
            uint256[] memory nfts = new uint256[](1);
            nfts[0] = tokenId;

            apeStaking.claimMAYC(nfts, recipient);
        } else {
            IApeCoinStaking.PairingStatus memory baycStatus = apeStaking.bakcToMain(tokenId, BAYC_POOL_ID);

            IApeCoinStaking.PairNft[] memory baycs;
            IApeCoinStaking.PairNft[] memory maycs;
            if (baycStatus.isPaired) {
                baycs = new IApeCoinStaking.PairNft[](1);
                baycs[0] = IApeCoinStaking.PairNft(uint128(baycStatus.tokenId), tokenId);
            } else {
                IApeCoinStaking.PairingStatus memory maycStatus = apeStaking.bakcToMain(tokenId, MAYC_POOL_ID);
                if (maycStatus.isPaired) {
                    maycs = new IApeCoinStaking.PairNft[](1);
                    maycs[0] = IApeCoinStaking.PairNft(uint128(maycStatus.tokenId), tokenId);
                }
            }

            apeStaking.claimBAKC(baycs, maycs, recipient);
        }
    }

    // Lock handlers
    function _isLocked(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private view returns (bool) {
        Lockers.ApePlanLocker storage locker = Lockers.getApePlanLocker();

        uint8 lockState = (uint8(1) << bitIndex);
        return (locker.tokens[collection][tokenId] & lockState) == lockState;
    }

    function _lock(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private {
        Lockers.ApePlanLocker storage locker = Lockers.getApePlanLocker();
        if (_isLocked(collection, tokenId, bitIndex)) revert AlreadyInLockState();

        locker.tokens[collection][tokenId] |= (uint8(1) << bitIndex);
        emit SetLockedApeNFT(collection, tokenId, locker.tokens[collection][tokenId]);
    }

    function _unlock(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private {
        Lockers.ApePlanLocker storage locker = Lockers.getApePlanLocker();
        if (!_isLocked(collection, tokenId, bitIndex)) revert AlreadyInLockState();

        locker.tokens[collection][tokenId] &= ~(uint8(1) << bitIndex);
        emit SetLockedApeNFT(collection, tokenId, locker.tokens[collection][tokenId]);
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNftDepositWithAmount structs
    function _checkLockOfPairDeposits(IApeCoinStaking.PairNftDepositWithAmount[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNftWithdrawWithAmount structs
    function _checkLockOfPairWithdrawals(IApeCoinStaking.PairNftWithdrawWithAmount[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNft structs
    function _checkLockOfPairClaims(IApeCoinStaking.PairNft[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    function completeApeCoinPlan(uint256 planId) external {
        ICyanApeCoinPlan(addressProvider.addresses("CYAN_APE_COIN_PLAN")).complete(planId);
    }
}

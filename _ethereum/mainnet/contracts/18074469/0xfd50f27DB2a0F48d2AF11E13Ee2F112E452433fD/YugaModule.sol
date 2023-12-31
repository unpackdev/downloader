// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";

import "./ERC721Module.sol";
import "./IApeCoinStaking.sol";

struct ApeLocker {
    /// @notice Map of the locked tokens.
    ///     Note: Collection Address => Token ID => Lock state
    mapping(address => mapping(uint256 => uint8)) tokens;
}

error TokenIsLocked();
error AlreadyInLockState();
error NotEnoughRewards();
error NotPaired();

/// @title Cyan Wallet Yuga Module - A Cyan wallet's Ape & ApeCoin handling module.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract YugaModule is ERC721Module {
    // keccak256("wallet.YugaModule.lockedApe")
    bytes32 public constant APE_LOCKER_SLOT = 0x010881fa8a1edce184936a8e4e08060bba49cb5145c9b396e6e80c0c6b0e1269;

    // Yuga contracts
    IApeCoinStaking public constant apePool = IApeCoinStaking(0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9);
    IERC20 public constant apeCoin = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
    address public constant BAYC_ADDRESS = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public constant MAYC_ADDRESS = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address public constant BAKC_ADDRESS = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;

    // ApePool ids
    uint256 public constant BAYC_POOL_ID = 1;
    uint256 public constant MAYC_POOL_ID = 2;
    uint256 public constant BAKC_POOL_ID = 3;

    uint8 public constant LOCK_BIT_INDEX_0 = 0; // Lock bit index of BAYC & MAYC
    uint8 public constant LOCK_BIT_INDEX_1 = 1; // Lock bit index of BAKC

    event SetLockedApeNFT(address collection, uint256 tokenId, uint8 lockStatus);

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
            _performSingleNftChecks(BAYC_ADDRESS, data);
        }

        // MAYC deposit & withdraw checks
        if (
            funcHash == IApeCoinStaking.depositMAYC.selector ||
            funcHash == IApeCoinStaking.withdrawSelfMAYC.selector ||
            funcHash == IApeCoinStaking.withdrawMAYC.selector
        ) {
            _performSingleNftChecks(MAYC_ADDRESS, data);
        }

        // BAYC & MAYC claim checks
        if (funcHash == IApeCoinStaking.claimBAYC.selector || funcHash == IApeCoinStaking.claimSelfBAYC.selector) {
            _performTokenIdChecks(BAYC_ADDRESS, data);
        }
        if (funcHash == IApeCoinStaking.claimMAYC.selector || funcHash == IApeCoinStaking.claimSelfMAYC.selector) {
            _performTokenIdChecks(MAYC_ADDRESS, data);
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

        return super.handleTransaction(collection, value, data);
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

    // Internal module methods, only operators can call these methods

    /// @notice Allows operators to lock BAYC and stake to the ape pool.
    /// @param tokenId Token ID of BAYC
    /// @param amount Loaning ApeCoin amount
    function depositBAYCAndLock(uint32 tokenId, uint224 amount) external {
        _depositSingleNftAndLock(BAYC_ADDRESS, tokenId, amount);
    }

    /// @notice Allows operators to lock MAYC and stake to the ape pool.
    /// @param tokenId Token ID of MAYC
    /// @param amount Loaning ApeCoin amount
    function depositMAYCAndLock(uint32 tokenId, uint224 amount) external {
        _depositSingleNftAndLock(MAYC_ADDRESS, tokenId, amount);
    }

    function _depositSingleNftAndLock(
        address collection,
        uint32 tokenId,
        uint224 amount
    ) private {
        _lock(collection, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(tokenId, amount);
        apeCoin.approve(address(apePool), amount);

        (collection == BAYC_ADDRESS) ? apePool.depositBAYC(nfts) : apePool.depositMAYC(nfts);
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
        _lock(BAKC_ADDRESS, bakcTokenId, LOCK_BIT_INDEX_1);

        IApeCoinStaking.PairNftDepositWithAmount[] memory baycs;
        IApeCoinStaking.PairNftDepositWithAmount[] memory maycs;

        if (mainCollection == BAYC_ADDRESS) {
            baycs = new IApeCoinStaking.PairNftDepositWithAmount[](1);
            baycs[0] = IApeCoinStaking.PairNftDepositWithAmount(mainTokenId, bakcTokenId, uint184(amount));
        } else if (mainCollection == MAYC_ADDRESS) {
            maycs = new IApeCoinStaking.PairNftDepositWithAmount[](1);
            maycs[0] = IApeCoinStaking.PairNftDepositWithAmount(mainTokenId, bakcTokenId, uint184(amount));
        }

        apeCoin.approve(address(apePool), amount);
        apePool.depositBAKC(baycs, maycs);
    }

    /// @notice Allows operators to unlock BAYC and unstake from the ape pool.
    /// @param tokenId Token ID of BAYC
    function withdrawBAYCAndUnlock(uint32 tokenId) external {
        _unlock(BAYC_ADDRESS, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(tokenId, uint224(apePool.nftPosition(BAYC_POOL_ID, tokenId).stakedAmount));
        apePool.withdrawBAYC(nfts, msg.sender);
    }

    /// @notice Allows operators to unlock MAYC and unstake from the ape pool.
    /// @param tokenId Token ID of MAYC
    function withdrawMAYCAndUnlock(uint32 tokenId) external {
        _unlock(MAYC_ADDRESS, tokenId, LOCK_BIT_INDEX_0);

        IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
        nfts[0] = IApeCoinStaking.SingleNft(tokenId, uint224(apePool.nftPosition(MAYC_POOL_ID, tokenId).stakedAmount));
        apePool.withdrawMAYC(nfts, msg.sender);
    }

    /// @notice Allows operators to unlock BAKC and unstake from the ape pool.
    /// @param tokenId BAKC token ID
    function withdrawBAKCAndUnlock(uint32 tokenId) external {
        IApeCoinStaking.PairingStatus memory baycStatus = apePool.bakcToMain(tokenId, BAYC_POOL_ID);

        address mainCollection;
        uint32 mainTokenId;

        IApeCoinStaking.PairNftWithdrawWithAmount[] memory baycs;
        IApeCoinStaking.PairNftWithdrawWithAmount[] memory maycs;
        if (baycStatus.isPaired) {
            mainCollection = BAYC_ADDRESS;
            mainTokenId = uint32(baycStatus.tokenId);
            baycs = new IApeCoinStaking.PairNftWithdrawWithAmount[](1);
            baycs[0] = IApeCoinStaking.PairNftWithdrawWithAmount(mainTokenId, tokenId, 0, true);
        } else {
            IApeCoinStaking.PairingStatus memory maycStatus = apePool.bakcToMain(tokenId, MAYC_POOL_ID);
            if (maycStatus.isPaired) {
                mainCollection = MAYC_ADDRESS;
                mainTokenId = uint32(maycStatus.tokenId);
                maycs = new IApeCoinStaking.PairNftWithdrawWithAmount[](1);
                maycs[0] = IApeCoinStaking.PairNftWithdrawWithAmount(mainTokenId, tokenId, 0, true);
            } else {
                revert NotPaired();
            }
        }

        uint256 stakedAmount = apePool.nftPosition(BAKC_POOL_ID, tokenId).stakedAmount;
        uint256 rewards = apePool.pendingRewards(BAKC_POOL_ID, address(this), tokenId);

        _unlock(mainCollection, mainTokenId, LOCK_BIT_INDEX_1);
        _unlock(BAKC_ADDRESS, tokenId, LOCK_BIT_INDEX_1);

        apePool.withdrawBAKC(baycs, maycs);
        apeCoin.transfer(msg.sender, stakedAmount + rewards);
    }

    function autoCompound(uint256 poolId, uint32 tokenId) public {
        _claimRewards(poolId, tokenId, msg.sender);
    }

    function _claimRewards(
        uint256 poolId,
        uint32 tokenId,
        address recipient
    ) private {
        if (poolId == BAYC_POOL_ID) {
            uint256[] memory nfts = new uint256[](1);
            nfts[0] = tokenId;

            apePool.claimBAYC(nfts, recipient);
        } else if (poolId == MAYC_POOL_ID) {
            uint256[] memory nfts = new uint256[](1);
            nfts[0] = tokenId;

            apePool.claimMAYC(nfts, recipient);
        } else {
            IApeCoinStaking.PairingStatus memory baycStatus = apePool.bakcToMain(tokenId, BAYC_POOL_ID);

            IApeCoinStaking.PairNft[] memory baycs;
            IApeCoinStaking.PairNft[] memory maycs;
            if (baycStatus.isPaired) {
                baycs = new IApeCoinStaking.PairNft[](1);
                baycs[0] = IApeCoinStaking.PairNft(uint128(baycStatus.tokenId), tokenId);
            } else {
                IApeCoinStaking.PairingStatus memory maycStatus = apePool.bakcToMain(tokenId, MAYC_POOL_ID);
                if (maycStatus.isPaired) {
                    maycs = new IApeCoinStaking.PairNft[](1);
                    maycs[0] = IApeCoinStaking.PairNft(uint128(maycStatus.tokenId), tokenId);
                }
            }

            apePool.claimBAKC(baycs, maycs, recipient);
        }
    }

    // Lock handlers
    function _isLocked(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private view returns (bool) {
        ApeLocker storage locker = _getApeLocker();

        uint8 lockState = (uint8(1) << bitIndex);
        return (locker.tokens[collection][tokenId] & lockState) == lockState;
    }

    function _lock(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private {
        ApeLocker storage locker = _getApeLocker();
        if (_isLocked(collection, tokenId, bitIndex)) revert AlreadyInLockState();

        locker.tokens[collection][tokenId] |= (uint8(1) << bitIndex);
        emit SetLockedApeNFT(collection, tokenId, locker.tokens[collection][tokenId]);
    }

    function _unlock(
        address collection,
        uint256 tokenId,
        uint8 bitIndex
    ) private {
        ApeLocker storage locker = _getApeLocker();
        if (!_isLocked(collection, tokenId, bitIndex)) revert AlreadyInLockState();

        locker.tokens[collection][tokenId] &= ~(uint8(1) << bitIndex);
        emit SetLockedApeNFT(collection, tokenId, locker.tokens[collection][tokenId]);
    }

    /// @notice Checks whether the token is locked or not.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @return isLocked Whether the token is locked or not.
    function checkIsLocked(address collection, uint256 tokenId) public view override returns (bool) {
        return _isApeLocked(collection, tokenId) || super.checkIsLocked(collection, tokenId);
    }

    /// @dev Returns the map of the locked tokens.
    /// @return result ERC721Locker struct of the locked tokens.
    ///     Note: Collection Address => Token ID => Lock state
    function _getApeLocker() internal pure returns (ApeLocker storage result) {
        assembly {
            result.slot := APE_LOCKER_SLOT
        }
    }

    /// @notice Checks whether the token is ape locked or not.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @return isLocked Whether the token is ape locked or not.
    function _isApeLocked(address collection, uint256 tokenId) private view returns (bool) {
        return _getApeLocker().tokens[collection][tokenId] != 0;
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNftDepositWithAmount structs
    function _checkLockOfPairDeposits(IApeCoinStaking.PairNftDepositWithAmount[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC_ADDRESS, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNftWithdrawWithAmount structs
    function _checkLockOfPairWithdrawals(IApeCoinStaking.PairNftWithdrawWithAmount[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC_ADDRESS, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks whether any of the tokens is locked or not.
    /// @param pairs Array of IApeCoinStaking.PairNft structs
    function _checkLockOfPairClaims(IApeCoinStaking.PairNft[] memory pairs) private view {
        for (uint256 i; i < pairs.length; ) {
            if (_isLocked(BAKC_ADDRESS, pairs[i].bakcTokenId, LOCK_BIT_INDEX_1)) revert TokenIsLocked();
            unchecked {
                ++i;
            }
        }
    }
}

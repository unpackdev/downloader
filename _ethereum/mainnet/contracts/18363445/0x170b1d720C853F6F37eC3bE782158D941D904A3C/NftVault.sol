// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";

import "./IDepositValidator.sol";
import "./IWithdrawValidator.sol";
import "./IterableAddressMap.sol";
import "./IterableLock.sol";
import "./UniversalERC20.sol";
import "./BaseVault.sol";

contract NftVault is BaseVault, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableLock for ItLock;
    using IterableAddressMap for ItAddressMap;
    using UniversalERC20 for IERC20;

    /// @notice Locked tokens for the nft token address + nft token id
    /// @dev key (bytes32) is the hash value of nft address and token id
    mapping(bytes32 => ItAddressMap) private _lockedTokens;

    /// @notice ERC20 token balance for the nft token
    /// @dev Key (bytes32) is the hash value of nft address, nft token id and erc20 token address
    mapping(bytes32 => ItLock) private _balances;

    /// @notice total balance for each erc20 token
    mapping(address => uint256) private _balancePerToken;

    address private _trustedForwarder;

    constructor(
        address payable treasury_,
        address depositValidator_,
        address withdrawValidator_
    ) {
        if (
            treasury_ == address(0) ||
            depositValidator_ == address(0) ||
            withdrawValidator_ == address(0)
        ) revert InvalidZeroAddress();

        _treasury = treasury_;
        _depositValidator = depositValidator_;
        _withdrawValidator = withdrawValidator_;

        _depositFee = 500; // default 5%
        _withdrawFee = 200; // default 2%
    }

    /// @notice Deposit ERC20 token with locked time for nft token + token id
    /// @param erc20Token_ ERC20 token contract address to deposit
    /// @param nftAddress_ key NFT contract address
    /// @param nftTokenId_ key NFT contract token ID
    /// @param amount_ deposit amount
    /// @param unlockAt_ the time until the deposited token is locked
    function deposit(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_,
        uint64 unlockAt_
    ) external payable nonReentrant {
        _deposit(erc20Token_, nftAddress_, nftTokenId_, amount_, unlockAt_);
        _transferToken(erc20Token_, amount_);
    }

    /// @notice Batch deposit for several nft tokens + token ids
    /// @param erc20Token_ ERC20 token contract address to deposit
    /// @param nftAddresses_ key NFT contract addresses
    /// @param nftTokenIds_ key NFT contract token IDs
    /// @param amounts_ deposit amounts
    /// @param unlockAt_ the time until the deposited tokens are locked
    function batchDeposit(
        address erc20Token_,
        address[] calldata nftAddresses_,
        uint256[] calldata nftTokenIds_,
        uint256[] calldata amounts_,
        uint64 unlockAt_
    ) external payable override nonReentrant {
        if (
            nftAddresses_.length != nftTokenIds_.length ||
            nftTokenIds_.length != amounts_.length
        ) revert InvalidArraySize();
        uint256 batchCount = nftAddresses_.length;
        uint256 batchLimit = _batchTxLimit;
        if (batchCount > batchLimit) revert Overflow256(batchLimit, batchCount);

        uint256 sumAmount;
        uint256 i;

        for (; i < batchCount; ) {
            _deposit(
                erc20Token_,
                nftAddresses_[i],
                nftTokenIds_[i],
                amounts_[i],
                unlockAt_
            );
            sumAmount += amounts_[i];

            unchecked {
                ++i;
            }
        }
        _transferToken(erc20Token_, sumAmount);
    }

    /// @notice Update balance data for the deposit operation
    function _deposit(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_,
        uint64 unlockAt_
    ) internal {
        if (unlockAt_ > block.timestamp + MAX_LOCK_TIME_BUFFER)
            revert InvalidUnlockTime();
        if (tokenInBlacklist(erc20Token_)) revert InvalidToken(erc20Token_);
        if (
            !IDepositValidator(_depositValidator).isValid(
                _msgSender(),
                nftAddress_,
                nftTokenId_
            ) ||
            (_isUseNftWhitelist && !_nftWhitelist.contains(nftAddress_)) ||
            tokenIdInBlacklist(nftAddress_, nftTokenId_)
        ) revert InvalidNft();

        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];

        // Iterate the locks and mark the expired locks as unlocked
        itLock.deposit(unlockAt_, amount_);

        ItAddressMap storage itAddressMap = _lockedTokens[
            _hash2(nftAddress_, nftTokenId_)
        ];
        itAddressMap.insert(erc20Token_);

        _balancePerToken[erc20Token_] += amount_;

        emit Deposited(
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            amount_,
            unlockAt_
        );
    }

    /// @notice Transfer deposited token to the nft vault, and the fee to the treasury account
    function _transferToken(address token_, uint256 amount_) internal {
        uint256 feeAmount = depositFee(token_, amount_);
        amount_ += feeAmount;

        // Transfer total deposit amount to the NftVault contract
        uint256 amountTransferred = IERC20(token_).universalTransferFrom(
            _msgSender(),
            address(this),
            amount_
        );
        // Fee token is not supported in the NftVault
        if (amountTransferred < amount_)
            revert InsufficientTransfer(amount_, amountTransferred);

        // Transfer fee to the treasury account
        if (feeAmount == 0) return;
        uint256 feeTransferred = IERC20(token_).universalTransfer(
            _treasury,
            feeAmount
        );

        if (feeTransferred < feeAmount)
            revert InsufficientTransfer(feeAmount, feeTransferred);
    }

    /// @notice withdraw ERC20 token from NftVault contract
    /// _msgSender() should own key NFT
    /// recipient is _msgSender()
    /// @param nftAddress_ key NFT contract address
    /// @param nftTokenId_ key NFT token ID
    /// @param erc20Token_ withdraw token contract address
    /// @param amount_ withdraw amount
    function withdraw(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_
    ) external {
        // Check the user who wants to withdraw owns this nft token id
        if (
            IERC721(nftAddress_).ownerOf(nftTokenId_) != _msgSender() ||
            !IWithdrawValidator(_withdrawValidator).isValid(
                _msgSender(),
                nftAddress_,
                nftTokenId_
            )
        ) revert Unpermitted();

        // For the withdrwal of zero amount, it is reverted
        if (amount_ == 0) revert InvalidZeroAmount();

        _withdraw(
            false,
            _msgSender(),
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            amount_
        );
    }

    /// @notice Withdraw for making payment for the Slash Protocol
    /// @param account_ Account who is going to make payment via Slash
    /// @param nftAddress_ key NFT contract address
    /// @param nftTokenId_ key NFT token ID
    /// @param erc20Token_ withdraw token contract address
    /// @param amount_ withdraw amount
    function withdrawForPayment(
        address account_,
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_
    ) external override {
        // If called via a forwarder, _msgSender() may not be a wrapper, so check with msg.sender.
        if (!_wrapperList.contains(msg.sender)) revert Unpermitted();
        bytes32 key = keccak256(abi.encodePacked(account_, msg.sender));
        if (!_withdrawForPaymentApproved[key]) revert UnapprovedWrapper();

        // Check the user who wants to make the slash payment owns this nft token id
        // We check account_, not _msgSender() because _msgSender() is Payment wrapper contract
        if (
            IERC721(nftAddress_).ownerOf(nftTokenId_) != account_ ||
            !IWithdrawValidator(_withdrawValidator).isValid(
                account_,
                nftAddress_,
                nftTokenId_
            )
        ) revert Unpermitted();

        _withdraw(
            true,
            msg.sender, // Withdraw to Payment wrapper contract
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            amount_
        );
    }

    function _withdraw(
        bool fromWrapper,
        address recipient_,
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_
    ) internal nonReentrant {
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];

        // Deposited tokens in the vault for this nft + token id + erc20 token
        uint256 tokenAmountInVault = itLock.availableAmount();

        if (amount_ > tokenAmountInVault) {
            if (fromWrapper)
                amount_ = tokenAmountInVault; // In case of the withdrawal request for the slash payment, we just withdraw available amount in the vault
            else revert TooMuchWithdrawals(tokenAmountInVault, amount_); // In case of the normal withdrawal, it is reverted
        }

        itLock.withdraw(amount_);
        _balancePerToken[erc20Token_] -= amount_;

        // If this token does not have amount left per this nft id, remove it from lockedTokens list
        if (itLock.empty())
            _lockedTokens[_hash2(nftAddress_, nftTokenId_)].remove(erc20Token_);

        uint256 feeAmount;
        if (!fromWrapper) {
            feeAmount = withdrawFee(erc20Token_, amount_);
            IERC20(erc20Token_).universalTransfer(_treasury, feeAmount);

            amount_ -= feeAmount;
        }

        IERC20(erc20Token_).universalTransfer(recipient_, amount_);

        emit Withdrawn(
            recipient_,
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            amount_,
            feeAmount
        );
    }

    /// @notice Lock the unlocked tokens directly
    /// @dev Only nft holder can relock tokens
    function lock(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 amount_,
        uint64 unlockAt_
    ) external {
        if (unlockAt_ > block.timestamp + MAX_LOCK_TIME_BUFFER)
            revert InvalidUnlockTime();
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        // Check the user is the honest holder
        if (IERC721(nftAddress_).ownerOf(nftTokenId_) != _msgSender())
            revert Unpermitted();
        itLock.lock(unlockAt_, amount_);

        emit Locked(
            _msgSender(),
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            amount_,
            unlockAt_
        );
    }

    /// @notice Relock the tokens with new lock duration
    /// @dev Only nft holder can relock tokens
    function relock(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint64 lockId_,
        uint64 unlockAt_
    ) external {
        if (unlockAt_ > block.timestamp + MAX_LOCK_TIME_BUFFER)
            revert InvalidUnlockTime();
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        // Check the user is the honest holder
        if (IERC721(nftAddress_).ownerOf(nftTokenId_) != _msgSender())
            revert Unpermitted();
        itLock.relock(lockId_, unlockAt_);

        emit Relocked(
            _msgSender(),
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            lockId_,
            unlockAt_
        );
    }

    /// @notice Unlock expired lock for the nft token & erc20 token
    /// @dev Only nft holder can unlock expired token
    function unlock(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint64 lockId_
    ) external {
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        // Check the user is the honest holder
        if (IERC721(nftAddress_).ownerOf(nftTokenId_) != _msgSender())
            revert Unpermitted();
        itLock.unlock(lockId_);

        emit Unlocked(
            _msgSender(),
            erc20Token_,
            nftAddress_,
            nftTokenId_,
            lockId_
        );
    }

    /// @notice Function for getting hash value from (address, uint256)
    function _hash2(
        address param1_,
        uint256 param2_
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(param1_, param2_));
    }

    /// @notice Function for getting hash value from (address, uint256, address)
    function _hash3(
        address param1_,
        uint256 param2_,
        address param3_
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(param1_, param2_, param3_));
    }

    /// @notice Return the count of tokens lokced in this nft token id
    function lockedTokenCount(
        address nftAddress_,
        uint256 nftTokenId_
    ) external view returns (uint256) {
        return _lockedTokens[_hash2(nftAddress_, nftTokenId_)].itemCount();
    }

    /// @notice Return tokens locked in this nft token id
    /// @param nftAddress_ NFT contract address to fetch
    /// @param nftTokenId_ NFT Token ID to fetch
    /// @return tokens Token list locked in this nft token id
    function lockedTokens(
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 offset_,
        uint256 count_
    ) external view returns (address[] memory tokens) {
        return
            _lockedTokens[_hash2(nftAddress_, nftTokenId_)].fetchItems(
                offset_,
                count_
            );
    }

    /// @notice View unlocked token amount for the nft token id
    function unlockedAmount(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_
    ) external view returns (uint256) {
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        return itLock.unlockedAmount;
    }

    /// @notice View data of the token locked for the nft token id
    /// @param nftAddress_ NFT contract address
    /// @param nftTokenId_ NFT token ID
    /// @param erc20Token_ Locked token
    /// @return unlockDates Array of lock end dates
    /// @return amounts Array of locked amounts
    function viewLocks(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint256 offset_,
        uint256 count_
    ) external view returns (uint64[] memory, uint256[] memory) {
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        return itLock.fetchItems(offset_, count_);
    }

    /// @notice View locked data of given lock id
    /// @param nftAddress_ NFT contract address
    /// @param nftTokenId_ NFT token ID
    /// @param erc20Token_ Locked token
    /// @param lockId_ Lock id, same as unlock date
    /// @return unlockDate Lock end date
    /// @return amount Locked amounts
    function viewLock(
        address erc20Token_,
        address nftAddress_,
        uint256 nftTokenId_,
        uint64 lockId_
    ) external view returns (uint64, uint256) {
        ItLock storage itLock = _balances[
            _hash3(nftAddress_, nftTokenId_, erc20Token_)
        ];
        return itLock.fetchItem(lockId_);
    }

    /// @notice Return total balance of the token deposited for nfts
    /// @param erc20Token_ Token address
    function balanceOf(address erc20Token_) external view returns (uint256) {
        return _balancePerToken[erc20Token_];
    }

    /// @notice Set given `forwarder_` as trustable forwarder
    function updateTrustedForwarder(address forwarder_) public onlyOwner {
        _trustedForwarder = forwarder_;
        emit UpdateTrustedForwarder(forwarder_);
    }

    function trustedForwarder() public view returns (address) {
        return _trustedForwarder;
    }

    function isTrustedForwarder(address forwarder_) public view returns (bool) {
        return forwarder_ == _trustedForwarder;
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /// @notice Recover tokens remained in the contract except the users deposited
    /// @dev Only owner can withdraw tokens
    /// @param token_ withdraw token contract address
    function recoverWrongToken(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).universalBalanceOf(address(this));
        /// @notice It should be failed when users' deposited amount is same as total balance
        uint256 withdrawable = balance - _balancePerToken[token_];

        IERC20(token_).universalTransfer(_msgSender(), withdrawable);

        emit RecoverWrongToken(token_, withdrawable);
    }
}

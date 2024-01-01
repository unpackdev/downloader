// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./Address.sol";
import "./EnumerableSet.sol";

import "./INftVault.sol";

/// @notice Base configuration contract for the NFT Vault
abstract contract BaseVault is INftVault, Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Basis points denominator in fee values
    uint256 private constant BASIS_POINTS_DENOMINATOR = 10_000;

    /// @notice max lock time buffer
    uint256 internal constant MAX_LOCK_TIME_BUFFER = 1825 days; // 5 years

    /// @notice max deposit fee 10%
    uint16 private constant MAX_DEPOSIT_FEE = 1000;
    /// @notice max withdraw fee 10%
    uint16 private constant MAX_WITHDRAW_FEE = 1000;

    /// @notice Array limit in the batch tx functions. Default 20 items
    uint256 internal _batchTxLimit = 20;

    /// @notice deposit fee percentage. denominator 10000
    uint256 internal _depositFee;
    /// @notice Withdraw fee percentage. denominator 10000
    uint256 internal _withdrawFee;

    /// @notice Flag to see if we use only depositable nfts (true) or use all nfts (false)
    bool internal _isUseNftWhitelist;

    /// @notice deposit fee receive wallet address
    address payable internal _treasury;

    address internal _depositValidator;
    address internal _withdrawValidator;

    /// @notice ERC20 tokens which are exempted from the deposit fee when deposited
    mapping(address => bool) internal _depositFeeExemptedTokenList;

    /// @notice ERC20 tokens which are exempted from the withdraw fee when withdrawn
    mapping(address => bool) internal _withdrawFeeExemptedTokenList;

    /// @notice A wrapper is allowed to withdraw user's token deposited
    /// @dev key is a hash of user address and wrapper address
    mapping(bytes32 => bool) internal _withdrawForPaymentApproved;
    /// @notice Payment wrapper contract list which can make payment for Slash
    EnumerableSet.AddressSet internal _wrapperList;

    /// @notice Allowed nfts to be used in the NFT Vault
    EnumerableSet.AddressSet internal _nftWhitelist;

    /// @notice NFT address is on the blacklist
    EnumerableSet.AddressSet internal _nftBlacklist;

    /// @notice Tokenid is on the blacklist
    mapping(address => EnumerableSet.UintSet) internal _tokenIdBlacklist;

    /// @notice EIP20 address is on the blacklist
    EnumerableSet.AddressSet internal _tokenBlacklist;

    /// @notice Update limit of the array in the batch tx functions
    /// @dev Only owner is allowed to call this function
    function updateBatchTxLimit(uint256 limit_) external onlyOwner {
        if (_batchTxLimit == limit_) revert AlreadyConfigured();
        _batchTxLimit = limit_;
        emit BatchTxLimitUpdated(limit_);
    }

    function batchTxLimit() external view returns (uint256) {
        return _batchTxLimit;
    }

    /// @notice Update treasury wallet to receive fee
    /// @param treasury_ fee receive address
    function updateTreasury(address payable treasury_) external onlyOwner {
        if (treasury_ == address(0)) revert InvalidZeroAddress();
        if (_treasury == treasury_) revert AlreadyConfigured();

        treasury_.sendValue(0); // We try to send 0 ETH to the new treasury address to check if it can receive ETH

        _treasury = treasury_;

        emit TreasuryUpdated(treasury_);
    }

    function treasury() external view returns (address payable) {
        return _treasury;
    }

    /// @notice Exempt token from the deposit fee
    function exemptTokenFromDepositFee(
        address token_,
        bool flag_
    ) external onlyOwner {
        if (_depositFeeExemptedTokenList[token_] == flag_)
            revert AlreadyConfigured();
        _depositFeeExemptedTokenList[token_] = flag_;

        emit TokenExemptedFromDepositFee(token_, flag_);
    }

    /// @notice Check if the token is exempted from deposit fee in the vault
    function isTokenExemptedFromDepositFee(
        address token_
    ) external view returns (bool) {
        return _depositFeeExemptedTokenList[token_];
    }

    /// @notice Get fee amount when deposit is made with the `token` and `amount`
    /// @dev For the exempted token, fee amount is 0
    /// @param token_ ERC20 token which is being deposited
    function depositFee(
        address token_,
        uint256 amount_
    ) public view override returns (uint256) {
        if (_depositFeeExemptedTokenList[token_]) return 0;
        return (amount_ * _depositFee) / BASIS_POINTS_DENOMINATOR;
    }

    function depositFee() external view returns (uint256) {
        return _depositFee;
    }

    /// @notice Update deposit fee percentage
    /// @dev Must be less than MAX_DEPOSIT_FEE 10%
    /// @param fee_ deposit fee percentage (denominator 10000)
    function updateDepositFee(uint256 fee_) external onlyOwner {
        if (fee_ > MAX_DEPOSIT_FEE) revert Overflow256(MAX_DEPOSIT_FEE, fee_);
        if (_depositFee == fee_) revert AlreadyConfigured();
        _depositFee = fee_;
        emit DepositFeeUpdated(fee_);
    }

    /// @notice Exempt token from the withdraw fee
    function exemptTokenFromWithdrawFee(
        address token_,
        bool flag_
    ) external onlyOwner {
        if (_withdrawFeeExemptedTokenList[token_] == flag_)
            revert AlreadyConfigured();
        _withdrawFeeExemptedTokenList[token_] = flag_;

        emit TokenExemptedFromWithdrawFee(token_, flag_);
    }

    /// @notice Check if the token is exempted from deposit fee in the vault
    function isTokenExemptedFromWithdrawFee(
        address token_
    ) external view returns (bool) {
        return _withdrawFeeExemptedTokenList[token_];
    }

    /// @notice Update withdraw fee percentage
    /// @dev Must be less than MAX_WITHDRAW_FEE 10%
    /// @param fee_ withdraw fee percentage (denominator 10000)
    function updateWithdrawFee(uint256 fee_) external onlyOwner {
        if (fee_ > MAX_WITHDRAW_FEE) revert Overflow256(MAX_WITHDRAW_FEE, fee_);
        if (_withdrawFee == fee_) revert AlreadyConfigured();
        _withdrawFee = fee_;

        emit WithdrawFeeUpdated(fee_);
    }

    /// @notice Get fee amount when withdraw is made with the `token` and `amount`
    /// @dev For the exempted token, fee amount is 0
    /// @param token_ ERC20 token which is being withdrawn
    function withdrawFee(
        address token_,
        uint256 amount_
    ) public view override returns (uint256) {
        if (_withdrawFeeExemptedTokenList[token_]) return 0;
        return (amount_ * _withdrawFee) / BASIS_POINTS_DENOMINATOR;
    }

    function withdrawFee() external view returns (uint256) {
        return _withdrawFee;
    }

    /// @notice Update deposit validator
    function updateDepositValidator(address validator_) external onlyOwner {
        if (_depositValidator == validator_) revert AlreadyConfigured();
        if (validator_ == address(0)) revert InvalidZeroAddress();
        _depositValidator = validator_;
    }

    function depositValidator() external view returns (address) {
        return _depositValidator;
    }

    /// @notice Update withdraw validator
    function updateWithdrawValidator(address validator_) external onlyOwner {
        if (_withdrawValidator == validator_) revert AlreadyConfigured();
        if (validator_ == address(0)) revert InvalidZeroAddress();

        _withdrawValidator = validator_;
    }

    function withdrawValidator() external view returns (address) {
        return _withdrawValidator;
    }

    /// @notice Check if the NFT deposit whitelist is being used
    /// @return - true when used, false when not being used
    function isUseNftWhitelist() external view returns (bool) {
        return _isUseNftWhitelist;
    }

    /// @notice Set the flag for using deposit whitelist or not
    function updateIsUseNftWhitelist(bool flag_) external onlyOwner {
        if (_isUseNftWhitelist == flag_) revert AlreadyConfigured();
        _isUseNftWhitelist = flag_;

        emit NftWhitelistUsed(flag_);
    }

    /// @notice Get whitelisted nft count
    function whitelistedNftCount() external view returns (uint256) {
        return _nftWhitelist.length();
    }

    /// @notice Get blacklisted tokenId
    function blacklistTokenIdCount(
        address nftAddress_
    ) external view returns (uint256) {
        return _tokenIdBlacklist[nftAddress_].length();
    }

    /// @notice Get blacklisted nft
    function blacklistNftCount() external view returns (uint256) {
        return _nftBlacklist.length();
    }

    /// @notice Get blacklisted token
    function blacklistTokenCount() external view returns (uint256) {
        return _tokenBlacklist.length();
    }

    /// @notice Allow / disallow the given nft address for the deposit
    /// @dev We always update the whitelist regardless whitelist is used or not
    function updateNftWhitelist(
        address[] calldata nftAddresses_,
        bool flag_
    ) external onlyOwner {
        uint256 i;
        uint256 length = nftAddresses_.length;
        for (; i < length; ) {
            if (_nftWhitelist.contains(nftAddresses_[i]) != flag_) {
                if (flag_) _nftWhitelist.add(nftAddresses_[i]);
                else _nftWhitelist.remove(nftAddresses_[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit NftWhitelistUpdated(nftAddresses_, flag_);
    }

    /// @notice Allow / disallow the given nft address for the deposit
    /// @dev We always update the whitelist regardless whitelist is used or not
    function updateNftBlacklist(
        address[] calldata nftAddresses_,
        bool flag_
    ) external onlyOwner {
        uint256 i;
        uint256 length = nftAddresses_.length;
        for (; i < length; ) {
            if (_nftBlacklist.contains(nftAddresses_[i]) != flag_) {
                if (flag_) _nftBlacklist.add(nftAddresses_[i]);
                else _nftBlacklist.remove(nftAddresses_[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit NftBlacklistUpdated(nftAddresses_, flag_);
    }

    /// @notice Allow / disallow the given token address for the deposit
    /// @dev We always update the blacklist regardless blacklist is used or not
    function updateTokenBlacklist(
        address[] calldata tokens_,
        bool flag_
    ) external onlyOwner {
        uint256 i;
        uint256 length = tokens_.length;
        for (; i < length; ) {
            if (_tokenBlacklist.contains(tokens_[i]) != flag_) {
                if (flag_) _tokenBlacklist.add(tokens_[i]);
                else _tokenBlacklist.remove(tokens_[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit TokenBlacklistUpdated(tokens_, flag_);
    }

    /// @notice Add / remove the exact tokenId in nft collection for the blacklist deposit
    function updateTokenIdBlacklist(
        address nftAddress_,
        uint256 tokenId_,
        bool flag_
    ) external onlyOwner {
        if (_tokenIdBlacklist[nftAddress_].contains(tokenId_) == flag_)
            revert AlreadyConfigured();

        if (flag_) {
            _tokenIdBlacklist[nftAddress_].add(tokenId_);
            if (!_nftBlacklist.contains(nftAddress_))
                _nftBlacklist.add(nftAddress_);
        } else {
            _tokenIdBlacklist[nftAddress_].remove(tokenId_);
            if (_tokenIdBlacklist[nftAddress_].length() == 0)
                _nftBlacklist.remove(nftAddress_);
        }

        emit TokenIdBlacklistUpdated(nftAddress_, tokenId_, flag_);
    }

    /// @notice Check tokenId is blacklisted or not
    function tokenIdInBlacklist(
        address nftAddress_,
        uint256 tokenId_
    ) public view returns (bool) {
        return _tokenIdBlacklist[nftAddress_].contains(tokenId_);
    }

    /// @notice Check token is blacklisted or not
    function tokenInBlacklist(address token) public view returns (bool) {
        return _tokenBlacklist.contains(token);
    }

    /// @notice Return deposit allowed nft list
    /// @dev This function is paginated for considering gas wastes in bulk cases
    function getNftWhitelistPaging(
        uint256 offset_,
        uint256 limit_
    )
        external
        view
        returns (
            address[] memory nftAddresses,
            uint256[] memory nftTokenIds,
            uint256 nextOffset,
            uint256 total
        )
    {
        EnumerableSet.AddressSet storage nftWhitelist = _nftWhitelist;
        total = nftWhitelist.length();
        nftTokenIds = new uint256[](0); // nftTokenIds will not be used at the moment
        if (offset_ >= total) nextOffset = offset_;
        else {
            if (offset_ + limit_ > total) limit_ = total - offset_;
            nextOffset = offset_ + limit_;
            nftAddresses = new address[](limit_);
            uint256 i;
            for (; i < limit_; ) {
                nftAddresses[i] = nftWhitelist.at(i + offset_);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Return deposit blacklist nft list
    /// @dev This function is paginated for considering gas wastes in bulk cases
    function getNftBlacklistPaging(
        uint256 offset_,
        uint256 limit_
    )
        external
        view
        returns (
            address[] memory nftAddresses,
            uint256 nextOffset,
            uint256 total
        )
    {
        EnumerableSet.AddressSet storage nftBlacklist = _nftBlacklist;
        total = nftBlacklist.length();
        if (offset_ >= total) nextOffset = offset_;
        else {
            if (offset_ + limit_ > total) limit_ = total - offset_;
            nextOffset = offset_ + limit_;
            nftAddresses = new address[](limit_);
            uint256 i;
            for (; i < limit_; ) {
                nftAddresses[i] = nftBlacklist.at(i + offset_);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Return deposit blacklist token list
    /// @dev This function is paginated for considering gas wastes in bulk cases
    function getTokenBlacklistPaging(
        uint256 offset_,
        uint256 limit_
    )
        external
        view
        returns (address[] memory tokens, uint256 nextOffset, uint256 total)
    {
        EnumerableSet.AddressSet storage tokenBlacklist = _tokenBlacklist;
        total = tokenBlacklist.length();
        if (offset_ >= total) nextOffset = offset_;
        else {
            if (offset_ + limit_ > total) limit_ = total - offset_;
            nextOffset = offset_ + limit_;
            tokens = new address[](limit_);
            uint256 i;
            for (; i < limit_; ) {
                tokens[i] = tokenBlacklist.at(i + offset_);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Return deposit blacklist nft tokenid
    /// @dev This function is paginated for considering gas wastes in bulk cases
    function getTokenIdBlacklistPaging(
        address nftAddress_,
        uint256 offset_,
        uint256 limit_
    )
        external
        view
        returns (
            uint256[] memory nftTokenIds,
            uint256 nextOffset,
            uint256 total
        )
    {
        EnumerableSet.UintSet storage tokenIdBlacklist = _tokenIdBlacklist[
            nftAddress_
        ];
        total = tokenIdBlacklist.length();
        nftTokenIds = new uint256[](0); // nftTokenIds will not be used at the moment
        if (offset_ >= total) nextOffset = offset_;
        else {
            if (offset_ + limit_ > total) limit_ = total - offset_;
            nextOffset = offset_ + limit_;
            nftTokenIds = new uint256[](limit_);
            uint256 i;
            for (; i < limit_; ) {
                nftTokenIds[i] = tokenIdBlacklist.at(i + offset_);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Get payment wrapper count
    function wrapperCount() external view returns (uint256) {
        return _wrapperList.length();
    }

    /// @notice Return wrapper count
    /// @dev This function is paginated for considering gas wastes in bulk cases
    function getWrapperListPaging(
        uint256 offset_,
        uint256 limit_
    )
        external
        view
        returns (address[] memory wrappers, uint256 nextOffset, uint256 total)
    {
        EnumerableSet.AddressSet storage wrapperList = _wrapperList;
        total = wrapperList.length();
        if (offset_ >= total) nextOffset = offset_;
        else {
            if (offset_ + limit_ > total) limit_ = total - offset_;
            nextOffset = offset_ + limit_;
            wrappers = new address[](limit_);
            uint256 i;
            for (; i < limit_; ) {
                wrappers[i] = wrapperList.at(i + offset_);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Add / remove item in the wrapper list
    function updateWrapperList(
        address wrapper_,
        bool flag_
    ) external onlyOwner {
        if (_wrapperList.contains(wrapper_) == flag_)
            revert AlreadyConfigured();

        if (flag_) _wrapperList.add(wrapper_);
        else _wrapperList.remove(wrapper_);

        emit WrapperUpdated(wrapper_, flag_);
    }

    /// @notice Check if the given contract is allowed to call deposit & payment function
    function isWrapper(address contract_) external view returns (bool) {
        return _wrapperList.contains(contract_);
    }

    /// @notice Approve wrapper to withdraw funds from the vault contract
    function approveWrapper(address wrapper_, bool flag_) external {
        if (!_wrapperList.contains(wrapper_) && flag_) revert InvalidWrapper();
        bytes32 key = keccak256(abi.encodePacked(_msgSender(), wrapper_));
        if (_withdrawForPaymentApproved[key] == flag_)
            revert AlreadyConfigured();
        _withdrawForPaymentApproved[key] = flag_;

        emit WrapperApprovedForPayment(_msgSender(), wrapper_, flag_);
    }

    /// @notice Check if the wrapper is approved to withdraw user's tokens
    function wrapperApproved(
        address account_,
        address wrapper_
    ) external view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(account_, wrapper_));
        return _withdrawForPaymentApproved[key];
    }
}

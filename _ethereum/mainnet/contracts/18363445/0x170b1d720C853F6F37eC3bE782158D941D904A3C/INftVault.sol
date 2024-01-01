// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface INftVault {
    enum BalanceFetchType {
        UNLOCKED_ONLY,
        LOCKED_ONLY,
        ALL
    }

    /// @notice Get fee amount when withdraw is made with the `token` and `amount`
    /// @dev For the exempted token, fee amount is 0
    /// @param token_ ERC20 token which is being withdrawn
    function withdrawFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    /// @notice Get fee amount when deposit is made with the `token` and `amount`
    /// @dev For the exempted token, fee amount is 0
    /// @param token_ ERC20 token which is being deposited
    function depositFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

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
    ) external payable;

    /// @notice Withdraw for making payment on the Slash Protocol
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
    ) external;

    event BatchTxLimitUpdated(uint256 limit);
    event Deposited(
        address erc20Token,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint64 unlockAt
    );
    event DepositFeeUpdated(uint256 fee);
    event NftWhitelistUpdated(address nftAddress, bool flag);
    event TokenIdBlacklistUpdated(
        address nftAddress,
        uint256 tokenId,
        bool flag
    );
    event UpdateTrustedForwarder(address forwarder);
    event NftWhitelistUpdated(address[] nftAddress, bool flag);
    event NftBlacklistUpdated(address[] nftAddress, bool flag);
    event TokenBlacklistUpdated(address[] tokens, bool flag);
    event NftWhitelistUsed(bool flag);
    event RecoverWrongToken(address token, uint256 amount);
    event TokenExemptedFromDepositFee(address token, bool flag);
    event TokenExemptedFromWithdrawFee(address token, bool flag);
    event TreasuryUpdated(address payable treasury);
    event Locked(
        address holder,
        address erc20Token,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint64 unlockAt
    );
    event Relocked(
        address holder,
        address erc20Token,
        address nftAddress,
        uint256 nftTokenId,
        uint64 lockId,
        uint64 unlockAt
    );
    event Unlocked(
        address holder,
        address erc20Token,
        address nftAddress,
        uint256 nftTokenId,
        uint64 lockId
    );
    event WithdrawFeeUpdated(uint256 fee);
    event Withdrawn(
        address recipient,
        address erc20Token,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amountWithdrawn,
        uint256 feePaid
    );
    event WrapperApprovedForPayment(
        address account,
        address wrapper,
        bool flag
    );
    event WrapperUpdated(address wrapper, bool flag);

    error AlreadyConfigured();
    error AlreadyLocked();
    error InsufficientTransfer(uint256 expected, uint256 actual);
    error InvalidNft();
    error InvalidWrapper();
    error InvalidZeroAddress();
    error InvalidZeroAmount();
    error Overflow256(uint256 limit, uint256 actual);
    error TooMuchWithdrawals(uint256 available, uint256 actual);
    error UnapprovedWrapper();
    error Unpermitted();
    error InvalidUnlockTime();
    error InvalidArraySize();
    error InvalidToken(address token);
}

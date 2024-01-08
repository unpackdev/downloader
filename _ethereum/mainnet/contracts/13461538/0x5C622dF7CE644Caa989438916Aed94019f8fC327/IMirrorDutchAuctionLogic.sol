// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorDutchAuctionLogic {
    /// @notice Emitted when the auction starts
    event AuctionStarted(uint256 blockNumber);

    /// @notice Emitted when a withdrawal takes place.
    event Withdrawal(address recipient, uint256 amount, uint256 fee);

    /// @notice Emitted when a bid takes place.
    event Bid(address recipient, uint256 price, uint256 tokenId);

    struct AuctionConfig {
        uint256[] prices;
        uint256 interval;
        uint256 startTokenId;
        uint256 endTokenId;
        address recipient;
        address nft;
        address nftOwner;
    }

    /// @notice Get a list of prices
    function prices(uint256 index) external returns (uint256);

    /// @notice Get the time interval in blocks
    function interval() external returns (uint256);

    /// @notice Get the current tokenId
    function tokenId() external returns (uint256);

    /// @notice Get the last tokenId
    function endTokenId() external returns (uint256);

    /// @notice Get total time elapsed since auction started
    function globalTimeElapsed() external returns (uint256);

    /// @notice Get the recipient of the funds for withdrawals
    function recipient() external returns (address);

    /// @notice Get whether an account has purchased
    function purchased(address account) external returns (bool);

    /// @notice Get the block at which auction started
    function auctionStartBlock() external returns (uint256);

    /// @notice Get the block at which auction was paused, only set if auction has started
    function pauseBlock() external returns (uint256);

    /// @notice Get the block at which auction was unpaused
    function unpauseBlock() external returns (uint256);

    /// @notice Get the contract that holds the NFTs
    function nft() external returns (address);

    /// @notice Set the owner of the nfts transfered
    function nftOwner() external returns (address);

    /// @notice Get the ending price
    function endingPrice() external returns (uint256);

    /// @notice Change the withdrawal recipient
    function changeRecipient(address newRecipient) external;

    /// @notice Get the contract that holds the treasury configuration
    function getAllPrices() external returns (uint256[] memory);

    /**
     * @dev This contract is used as the logic for proxies. Hence we include
     * the ability to call "initialize" when deploying a proxy to set initial
     * variables without having to define them and implement in the proxy's
     * constructor. This function reverts if called after deployment.
     */
    function initialize(
        address owner_,
        address treasuryConfig_,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig_
    ) external;

    /// @notice Pause auction
    function pause() external;

    /// @notice Unpause auction
    function unpause() external;

    /// @notice Withdraw all funds and destroy contract
    function cancel() external;

    /// @notice Current price. Zero if auction has not started.
    function price() external view returns (uint256);

    /// @notice Current time elapsed.
    function time() external view returns (uint256);

    /**
     * @notice Bid for an NFT. If the price is met transfer NFT to sender.
     * If price drops before the transaction mines, refund value.
     */
    function bid() external payable;

    /// @notice Withdraw all funds, and pay fee
    function withdraw() external;
}

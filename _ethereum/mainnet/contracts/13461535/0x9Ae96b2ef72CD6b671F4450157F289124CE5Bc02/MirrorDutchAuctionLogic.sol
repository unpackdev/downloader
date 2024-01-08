// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IMirrorDutchAuctionLogic.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";
import "./Reentrancy.sol";

/**
 * @title MirrorDutchAuctionLogic
 * @author MirrorXYZ
 *
 * This contract implements a simple Dutch Auction system.
 * The auction works as follows:
 *  - Generate a list of numbers that represent all the prices at which
 *    the assets are offered. The first item is the highest price, the last
 *    item is the lowest price.
 *  - Set a time interval that represents how much time will elapse between price changes.
 *  - After the auction starts, every bid pays the price at the time that their transaction
 *    mines and receives their asset.
 *
 * The auction can be paused and unpaused by the owner without affecting the price mechanism.
 * The auction has a "cancel" functionality that withdraws all funds (paying a fee) and
 * renounces ownership which ensures that the auction cannot be restarted again.
 * The auction assumes that tokenIds of the assets transfered are sequential, beginning at
 * "startTokenId" and ending at "endTokenId".
 * The auction uses blocks as the unit for the interval.
 */
contract MirrorDutchAuctionLogic is
    IMirrorDutchAuctionLogic,
    Ownable,
    Pausable,
    Reentrancy,
    IERC721Events
{
    /// @notice Set a list of prices
    uint256[] public override prices;

    /// @notice Set the time interval in blocks
    uint256 public override interval;

    /// @notice Set the current tokenId
    uint256 public override tokenId;

    /// @notice Set the last tokenId
    uint256 public override endTokenId;

    /// @notice Set total time elapsed since auction started
    uint256 public override globalTimeElapsed;

    /// @notice Set the recipient of the funds for withdrawals
    address public override recipient;

    /// @notice Set whether an account has purchased
    mapping(address => bool) public override purchased;

    /// @notice Set the block at which auction started
    uint256 public override auctionStartBlock;

    /// @notice Set the block at which auction was paused, only set if auction has started
    uint256 public override pauseBlock;

    /// @notice Set the block at which auction was unpaused
    uint256 public override unpauseBlock;

    /// @notice Set the contract that holds the NFTs
    address public override nft;

    /// @notice Set the owner of the nfts transfered
    address public override nftOwner;

    /// @notice Set the ending price
    uint256 public override endingPrice;

    /// @notice Set the contract that holds the treasury configuration
    address public treasuryConfig;

    modifier onlyOnce() {
        require(!purchased[msg.sender], "already purchased");
        _;
    }

    constructor(address owner_) Ownable(owner_) Pausable(true) {}

    /// @notice Change the withdrawal recipient
    function changeRecipient(address newRecipient) external override onlyOwner {
        recipient = newRecipient;
    }

    /// @notice Get a list of all prices
    function getAllPrices() external view override returns (uint256[] memory) {
        return prices;
    }

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
    ) external override {
        // Ensure that this function is only callable during contract construction
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        // ensure auction is paused
        _pause();

        // set owner
        _setOwner(address(0), owner_);

        // set treasury config
        treasuryConfig = treasuryConfig_;

        // save auction configuration
        prices = auctionConfig_.prices;
        interval = auctionConfig_.interval;
        recipient = auctionConfig_.recipient;
        tokenId = auctionConfig_.startTokenId;
        endTokenId = auctionConfig_.endTokenId;
        nft = auctionConfig_.nft;
        nftOwner = auctionConfig_.nftOwner;
    }

    /// @notice Pause auction
    function pause() external override whenNotPaused onlyOwner {
        // auction has started
        if (auctionStartBlock > 0) {
            globalTimeElapsed = _currentTimeElapsed();

            pauseBlock = block.number;
        }

        _pause();
    }

    /// @notice Unpause auction
    function unpause() external override whenPaused onlyOwner {
        if (auctionStartBlock == 0) {
            auctionStartBlock = block.number;

            emit AuctionStarted(auctionStartBlock);
        } else {
            unpauseBlock = block.number;
        }

        _unpause();
    }

    /// @notice Withdraw all funds and renounce contract ownership
    function cancel() external override onlyOwner nonReentrant {
        _pause();

        _renounceOwnership();

        _withdraw();
    }

    /// @notice Current price. Zero if auction has not started.
    function price() external view override returns (uint256) {
        return _currentPrice();
    }

    /// @notice Current time elapsed.
    function time() external view override returns (uint256) {
        if (auctionStartBlock > 0) {
            return _currentTimeElapsed();
        }

        return 0;
    }

    /**
     * @notice Bid for an NFT. If the price is met transfer NFT to sender.
     * If price drops before the transaction mines, refund value.
     */
    function bid()
        external
        payable
        override
        nonReentrant
        whenNotPaused
        onlyOnce
    {
        require(auctionStartBlock > 0, "auction has not started");

        require(tokenId <= endTokenId, "auction sold out");

        uint256 currentPrice = _currentPrice();

        require(msg.value >= currentPrice, "insufficient funds");

        // transfer NFT
        IERC721(nft).transferFrom(nftOwner, msg.sender, tokenId);

        emit Bid(msg.sender, currentPrice, tokenId);

        tokenId++;

        purchased[msg.sender] = true;

        // refund excess eth when price decrease before the transaction mines
        if (msg.value > currentPrice) {
            _transferEther(payable(msg.sender), msg.value - currentPrice);
        }

        // snapshot the ending price
        if (tokenId > endTokenId) {
            endingPrice = currentPrice;
        }
    }

    /// @notice Withdraw all funds, and pay fee
    function withdraw() external override nonReentrant {
        _withdraw();
    }

    //======== Internal Methods =========
    function _currentPrice() internal view returns (uint256) {
        // auction has not started
        if (auctionStartBlock == 0) {
            return 0;
        }

        // if ending price has been set i.e. all nfts are sold
        if (endingPrice != 0) {
            return endingPrice;
        }

        uint256 timeElapsed = _currentTimeElapsed();

        uint256 priceIndex = timeElapsed / interval;

        // price becomes the reserve price i.e. last in the list of prices
        if (priceIndex >= prices.length) {
            return prices[prices.length - 1];
        }

        return prices[priceIndex];
    }

    function _currentTimeElapsed() internal view returns (uint256 timeElapsed) {
        // if auction has been paused before
        // if not return time elapse since the start of the auction
        if (pauseBlock > 0) {
            // if currently paused return global time elapsed, which is saved when pausing
            // if not return global time elapsed, plus time elapsed since it was unpaused
            if (paused) {
                timeElapsed = globalTimeElapsed;
            } else {
                timeElapsed = globalTimeElapsed + (block.number - unpauseBlock);
            }
        } else {
            timeElapsed = block.number - auctionStartBlock;
        }
    }

    function _withdraw() internal {
        uint256 feePercentage = 250;

        uint256 fee = _feeAmount(address(this).balance, feePercentage);

        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury()).contribute{
            value: fee
        }(fee);

        // transfer the remaining available balance to the recipient
        uint256 withdrawalAmount = address(this).balance;

        _transferEther(payable(recipient), withdrawalAmount);

        emit Withdrawal(recipient, withdrawalAmount, fee);
    }

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    function _transferEther(address payable account, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "insufficient balance for send"
        );

        (bool success, ) = account.call{value: amount}("");
        require(success, "unable to send value: recipient may have reverted");
    }
}

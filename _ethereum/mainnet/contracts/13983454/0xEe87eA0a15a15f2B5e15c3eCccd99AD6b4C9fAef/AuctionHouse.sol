// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AuctionHouseStorage.sol";
import "./IWETH.sol";
import "./IAuctionHouse.sol";

contract AuctionHouse is
Initializable,
UUPSUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
OwnableUpgradeable,
AuctionHouseStorage,
IAuctionHouse
{
    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        ICongruentNFT _nft,
        address _weth,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration,
        uint256 _amount
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        nft = _nft;
        weth = _weth;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        amount = _amount;
    }

    /**
     * @notice Settle the current auction, mint a new NFT, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
    external
    override
    nonReentrant
    whenNotPaused
    {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a NFT, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 nftId)
    external
    payable
    override
    nonReentrant
    {
        IAuctionHouse.Auction memory _auction = auction;

        require(
            _auction.nftId == nftId,
            "NFT not up for auction"
        );
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
            _auction.amount +
            ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        emit AuctionBid(
            _auction.nftId,
            msg.sender,
            msg.value
        );
    }

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice)
    external
    override
    onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction duration.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
    }

    /**
     * @notice Set the auction amount.
     * @dev Only callable by the owner.
     */
    function setAmount(uint256 _amount) external override onlyOwner {
        amount = _amount;

        emit AuctionAmountUpdated(_amount);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
    external
    override
    onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        if (amount > nft.currentTokenId()) {
            try nft.mint(address(this)) returns (uint256 nftId) {
                uint256 startTime = block.timestamp;
                uint256 endTime = startTime + duration;

                auction = Auction({
                nftId : nftId,
                amount : 0,
                startTime : startTime,
                endTime : endTime,
                bidder : payable(0),
                settled : false
                });

                emit AuctionCreated(nftId, startTime, endTime);
            } catch Error(string memory) {
                _pause();
            }
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the NFT is burned.
     */
    function _settleAuction() internal {
        IAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            nft.burn(_auction.nftId);
        } else {
            nft.transferFrom(
                address(this),
                _auction.bidder,
                _auction.nftId
            );
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(
            _auction.nftId,
            _auction.bidder,
            _auction.amount
        );
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value : amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
    internal
    returns (bool)
    {
        (bool success,) = to.call{value : value, gas : 30_000}(new bytes(0));
        return success;
    }

    /**
     * @dev _authorizeUpgrade is used by UUPSUpgradeable to determine if it's allowed to upgrade a proxy implementation.
     //     added onlyOwner modifier for access control
     * @param newImplementation The new implementation
     *
     * Ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
    {}
}

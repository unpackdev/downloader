// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./FullMath.sol";
import "./MinterReceiver.sol";

/// @title HEX Share Market
/// @author Sam Presnal - Staker
/// @dev Sell shares priced at the original purchase rate
/// plus the applied premium
contract ShareMarket is MinterReceiver {
    IERC20 public immutable hexContract;
    address public immutable minterContract;

    /// @dev Share price is sharesBalance/heartsBalance
    /// Both balances reduce on buyShares to maintain the price,
    /// keep track of hearts owed to supplier, and determine
    /// when the listing is no longer buyable
    struct ShareListing {
        uint72 sharesBalance;
        uint72 heartsBalance;
    }
    mapping(uint40 => ShareListing) public shareListings;

    /// @dev The values are initialized onSharesMinted and
    /// onEarningsMinted respectively. Used to calculate personal
    /// earnings for a listing sharesOwned/sharesTotal*heartsEarned
    struct ShareEarnings {
        uint72 sharesTotal;
        uint72 heartsEarned;
    }
    mapping(uint40 => ShareEarnings) public shareEarnings;

    /// @notice Maintains which addresses own shares of particular stakes
    /// @dev heartsOwed is only set for the supplier to keep track of
    /// repayment for creating the stake
    struct ListingOwnership {
        uint72 sharesOwned;
        uint72 heartsOwed;
    }
    //keccak(stakeId, address) => ListingOwnership
    mapping(bytes32 => ListingOwnership) internal shareOwners;

    struct ShareOrder {
        uint40 stakeId;
        uint256 sharesPurchased;
        address shareReceiver;
    }

    event AddListing(
        uint40 indexed stakeId,
        address indexed supplier,
        uint256 data0 //shares | hearts << 72
    );
    event AddEarnings(uint40 indexed stakeId, uint256 heartsEarned);
    event BuyShares(
        uint40 indexed stakeId,
        address indexed owner,
        uint256 data0, //sharesPurchased | sharesOwned << 72
        uint256 data1 //sharesBalance | heartsBalance << 72
    );
    event ClaimEarnings(uint40 indexed stakeId, address indexed claimer, uint256 heartsClaimed);
    event SupplierWithdraw(uint40 indexed stakeId, address indexed supplier, uint256 heartsWithdrawn);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IERC20 _hex, address _minter) {
        hexContract = _hex;
        minterContract = _minter;
    }

    /// @inheritdoc MinterReceiver
    function onSharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external override {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");

        //Seed pool with shares and hearts determining the rate
        shareListings[stakeId] = ShareListing(stakeShares, stakedHearts);

        //Store total shares to calculate user earnings for claiming
        shareEarnings[stakeId].sharesTotal = stakeShares;

        //Store how many hearts the supplier needs to be paid back
        shareOwners[_hash(stakeId, supplier)].heartsOwed = uint72(stakedHearts);

        emit AddListing(stakeId, supplier, uint256(uint72(stakeShares)) | (uint256(uint72(stakedHearts)) << 72));
    }

    /// @inheritdoc MinterReceiver
    function onEarningsMinted(uint40 stakeId, uint72 heartsEarned) external override {
        require(msg.sender == minterContract, "CALLER_NOT_MINTER");
        //Hearts earned and total shares now stored in earnings
        //for payout calculations
        shareEarnings[stakeId].heartsEarned = heartsEarned;
        emit AddEarnings(stakeId, heartsEarned);
    }

    /// @return Supplier hearts payable resulting from user purchases
    function supplierHeartsPayable(uint40 stakeId, address supplier) external view returns (uint256) {
        (uint256 heartsBalance, ) = listingBalances(stakeId);
        uint256 heartsOwed = shareOwners[_hash(stakeId, supplier)].heartsOwed;
        return heartsOwed - heartsBalance;
    }

    /// @dev Used to calculate share price
    /// @return hearts Balance of hearts remaining in the listing to be input
    /// @return shares Balance of shares reamining in the listing to be sold
    function listingBalances(uint40 stakeId) public view returns (uint256 hearts, uint256 shares) {
        ShareListing memory listing = shareListings[stakeId];
        hearts = listing.heartsBalance;
        shares = listing.sharesBalance;
    }

    /// @dev Used to calculate personal earnings
    /// @return heartsEarned Total hearts earned by the stake
    /// @return sharesTotal Total shares originally on the market
    function listingEarnings(uint40 stakeId) public view returns (uint256 heartsEarned, uint256 sharesTotal) {
        ShareEarnings memory earnings = shareEarnings[stakeId];
        heartsEarned = earnings.heartsEarned;
        sharesTotal = earnings.sharesTotal;
    }

    /// @dev Shares owned is set to 0 when a user claims earnings
    /// @return Current shares owned of a particular listing
    function sharesOwned(uint40 stakeId, address owner) public view returns (uint256) {
        return shareOwners[_hash(stakeId, owner)].sharesOwned;
    }

    /// @dev Hash together stakeId and address to form a key for
    /// storage access
    /// @return Listing address storage key
    function _hash(uint40 stakeId, address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(stakeId, addr));
    }

    /// @notice Allows user to purchase shares from multiple listings
    /// @dev Lumps owed HEX into single transfer
    function multiBuyShares(ShareOrder[] memory orders) external lock {
        uint256 totalHeartsOwed;
        for (uint256 i = 0; i < orders.length; i++) {
            ShareOrder memory order = orders[i];
            totalHeartsOwed += _buyShares(order.stakeId, order.shareReceiver, order.sharesPurchased);
        }

        hexContract.transferFrom(msg.sender, address(this), totalHeartsOwed);
    }

    /// @notice Allows user to purchase shares from a single listing
    /// @param stakeId HEX stakeId to purchase shares from
    /// @param shareReceiver The receiver of the shares being purchased
    /// @param sharesPurchased The number of shares to purchase
    function buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint256 sharesPurchased
    ) external lock {
        uint256 heartsOwed = _buyShares(stakeId, shareReceiver, sharesPurchased);
        hexContract.transferFrom(msg.sender, address(this), heartsOwed);
    }

    function _buyShares(
        uint40 stakeId,
        address shareReceiver,
        uint256 sharesPurchased
    ) internal returns (uint256 heartsOwed) {
        require(sharesPurchased != 0, "INSUFFICIENT_SHARES_PURCHASED");

        (uint256 _heartsBalance, uint256 _sharesBalance) = listingBalances(stakeId);
        require(sharesPurchased <= _sharesBalance, "INSUFFICIENT_SHARES_AVAILABLE");

        //mulDivRoundingUp may result in 1 extra heart cost
        //any shares purchased will always cost at least 1 heart
        heartsOwed = FullMath.mulDivRoundingUp(sharesPurchased, _heartsBalance, _sharesBalance);

        //Reduce hearts owed to remaining hearts balance if it exceeds it
        //This can happen from extra 1 heart cost
        if (heartsOwed > _heartsBalance) heartsOwed = _heartsBalance;

        //Reduce both sides of the pool to maintain price
        uint256 sharesBalance = _sharesBalance - sharesPurchased;
        uint256 heartsBalance = _heartsBalance - heartsOwed;
        shareListings[stakeId] = ShareListing(uint72(sharesBalance), uint72(heartsBalance));

        //Add shares purchased to currently owned shares if any
        bytes32 shareOwner = _hash(stakeId, shareReceiver);
        uint256 newSharesOwned = shareOwners[shareOwner].sharesOwned + sharesPurchased;
        shareOwners[shareOwner].sharesOwned = uint72(newSharesOwned);
        emit BuyShares(
            stakeId,
            shareReceiver,
            uint256(uint72(sharesPurchased)) | (uint256(uint72(newSharesOwned)) << 72),
            uint256(uint72(sharesBalance)) | (uint256(uint72(heartsBalance)) << 72)
        );
    }

    /// @notice Withdraw earnings as a supplier
    /// @param stakeId HEX stakeId to withdraw earnings from
    /// @dev Combines supplier withdraw from two sources
    /// 1. Hearts paid for supplied shares by market participants
    /// 2. Hearts earned from staking supplied shares (buyer fee %)
    /// Note: If a listing has ended, assigns all leftover shares before withdraw
    function supplierWithdraw(uint40 stakeId) external lock {
        //Track total withdrawable
        uint256 totalHeartsOwed = 0;
        bytes32 supplier = _hash(stakeId, msg.sender);

        //Check to see if heartsOwed for sold shares in listing
        uint256 heartsOwed = uint256(shareOwners[supplier].heartsOwed);
        (uint256 heartsBalance, uint256 sharesBalance) = listingBalances(stakeId);
        //The delta between heartsOwed and heartsBalance is created
        //by users buying shares from the pool and reducing heartsBalance
        if (heartsOwed > heartsBalance) {
            //Withdraw any hearts for shares sold
            uint256 heartsPayable = heartsOwed - heartsBalance;
            uint256 newHeartsOwed = heartsOwed - heartsPayable;
            //Update hearts owed
            shareOwners[supplier].heartsOwed = uint72(newHeartsOwed);

            totalHeartsOwed = heartsPayable;
        }

        //Claim earnings including unsold shares only if the
        //earnings have already been minted
        (uint256 heartsEarned, ) = listingEarnings(stakeId);
        if (heartsEarned != 0) {
            //Check for unsold shares
            if (sharesBalance != 0) {
                //Add unsold shares to supplier balance
                uint72 totalSharesOwned = shareOwners[supplier].sharesOwned + uint72(sharesBalance);
                shareOwners[supplier].sharesOwned = totalSharesOwned;
                //Close buying from share listing
                delete shareListings[stakeId];
                emit BuyShares(
                    stakeId,
                    msg.sender,
                    uint256(uint72(sharesBalance)) | (uint256(totalSharesOwned) << 72),
                    0
                );
            }

            totalHeartsOwed += _claimEarnings(stakeId);
        }

        require(totalHeartsOwed != 0, "NO_HEARTS_CLAIMABLE");
        hexContract.transfer(msg.sender, totalHeartsOwed);

        emit SupplierWithdraw(stakeId, msg.sender, totalHeartsOwed);
    }

    /// @notice Withdraw earnings as a market participant
    /// @param stakeId HEX stakeId to withdraw earnings from
    function claimEarnings(uint40 stakeId) external lock {
        uint256 heartsEarned = _claimEarnings(stakeId);
        hexContract.transfer(msg.sender, heartsEarned);
    }

    function _claimEarnings(uint40 stakeId) internal returns (uint256 heartsOwed) {
        (uint256 heartsEarned, uint256 sharesTotal) = listingEarnings(stakeId);
        require(sharesTotal != 0, "LISTING_NOT_FOUND");
        require(heartsEarned != 0, "SHARES_NOT_MATURE");

        bytes32 owner = _hash(stakeId, msg.sender);
        uint256 ownedShares = shareOwners[owner].sharesOwned;
        heartsOwed = FullMath.mulDiv(heartsEarned, ownedShares, sharesTotal);
        require(heartsOwed != 0, "NO_HEARTS_CLAIMABLE");

        shareOwners[owner].sharesOwned = 0;
        emit ClaimEarnings(stakeId, msg.sender, heartsOwed);
    }
}

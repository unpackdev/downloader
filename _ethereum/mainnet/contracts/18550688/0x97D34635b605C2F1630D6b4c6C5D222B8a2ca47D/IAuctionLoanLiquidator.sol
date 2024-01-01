// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IMultiSourceLoan.sol";

/// @title Liquidates Collateral for Defaulted Loans using English Auctions.
/// @author Florida St
/// @notice It liquidates collateral corresponding to defaulted loans
///         and sends back the proceeds to the loan contract for distribution.
interface IAuctionLoanLiquidator {
    /// @notice The auction struct.
    /// @param loanAddress The loan contract address.
    /// @param loanId The loan id.
    /// @param highestBid The highest bid.
    /// @param highestBidder The highest bidder.
    /// @param duration The auction duration.
    /// @param asset The asset address.
    /// @param startTime The auction start time.
    /// @param originator The address that triggered the liquidation.
    /// @param lastBidTime The last bid time.
    struct Auction {
        address loanAddress;
        uint256 loanId;
        uint256 highestBid;
        uint256 triggerFee;
        address highestBidder;
        uint96 duration;
        address asset;
        uint96 startTime;
        address originator;
        uint96 lastBidTime;
    }

    /// @notice Add a loan contract to the list of accepted contracts.
    /// @param _loanContract The loan contract to be added.
    function addLoanContract(address _loanContract) external;

    /// @notice Remove a loan contract from the list of accepted contracts.
    /// @param _loanContract The loan contract to be removed.
    function removeLoanContract(address _loanContract) external;

    /// @return The loan contracts that are accepted by this liquidator.
    function getValidLoanContracts() external view returns (address[] memory);

    /// @notice Update liquidation distributor.
    /// @param _liquidationDistributor The new liquidation distributor.
    function updateLiquidationDistributor(address _liquidationDistributor) external;

    /// @return liquidationDistributor The liquidation distributor address.
    function getLiquidationDistributor() external view returns (address);

    /// @notice Called by the owner to update the trigger fee.
    /// @param triggerFee The new trigger fee.
    function updateTriggerFee(uint256 triggerFee) external;

    /// @return triggerFee The trigger fee.
    function getTriggerFee() external view returns (uint256);

    /// @notice When a bid is placed, the contract takes possesion of the bid, and
    ///         if there was a previous bid, it returns that capital to the original
    ///         bidder.
    /// @param _contract The nft contract address.
    /// @param _tokenId The nft id.
    /// @param _auction The auction struct.
    /// @param _bid The bid amount.
    /// @return auction The updated auction struct.
    function placeBid(address _contract, uint256 _tokenId, Auction memory _auction, uint256 _bid)
        external
        returns (Auction memory);

    /// @notice On settlement, the NFT is sent to the highest bidder.
    ///         Calls loan liquidated for accounting purposes.
    /// @param _auction The auction struct.
    /// @param _loan The loan struct.
    function settleAuction(Auction calldata _auction, IMultiSourceLoan.Loan calldata _loan) external;

    /// @notice The contract has hashes of all auctions to save space (not the actual struct)
    /// @param _contract The nft contract address.
    /// @param _tokenId The nft id.
    /// @return auctionHash The auction hash.
    function getAuctionHash(address _contract, uint256 _tokenId) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";

import "./IPayment.sol";

interface IvRent is IERC721Receiver {
    event Leased(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 leasingId,
        address indexed leaserAddress,
        uint8 maxRentDuration,
        bytes4 dailyRentPrice,
        IPayment.PaymentToken paymentToken
    );

    event Rented(
        uint256 leasingId,
        address indexed renterAddress,
        uint8 rentDuration,
        uint32 rentedAt
    );

    event Returned(uint256 indexed leasingId, uint32 returnedAt);

    event CollateralClaimed(uint256 indexed leasingId, uint32 claimedAt);

    event LeasingStopped(uint256 indexed leasingId, uint32 stoppedAt);

    /**
     * @dev sends your NFT to ReNFT contract, which acts as an escrow
     * between the lender and the renter
     */
    function lease(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint8[] memory _maxRentDuration,
        bytes4[] memory _dailyRentPrice,
        IPayment.PaymentToken[] memory _paymentToken
    ) external;

    /**
     * @dev renter sends rentDuration * dailyRentPrice
     * to cover for the potentially full cost of renting. They also
     * must send the collateral (nft price set by the lender in lend)
     */
    function rentNFT(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) external;

    /**
     * @dev renters call this to return the rented NFT before the
     * deadline. If they fail to do so, they will lose the posted
     * collateral
     */
    function endRent(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds
    ) external;

    /**
     * @dev stop lending releases the NFT from escrow and sends it back
     * to the lender
     */
    function cancelLeasing(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds
    ) external;
}
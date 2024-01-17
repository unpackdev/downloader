// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊◊ ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊        ◊◊◊◊ ◊◊◊◊  ◊◊◊◊ ◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊   ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊

 */

import "./Auth.sol";
import "./FixedPrice.sol";
import "./Withdraw.sol";
import "./ReentrancyGuard.sol";
import "./IOperatorCollectable.sol";

/**
 * @author Fount Gallery
 * @title  Arrangement One - The Garden
 * @notice The first arrangement of sale for The Garden NFT project.
 */
contract ArrangementOneSale is FixedPrice, Auth, Withdraw, ReentrancyGuard {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice The NFT contract address
    IOperatorCollectable public nft;

    /// @notice The price of each NFT
    uint256 public salePrice;

    /// @notice The start time of the public sale
    uint256 public saleStartTime;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /// @dev When trying to purchase when the sale is not live
    error SaleIsNotLive();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the sale price is updated
     * @param price The new sale price
     */
    event SalePriceUpdated(uint256 indexed price);

    /**
     * @notice When the sale start time is updated
     * @param startTime The new sale start time
     */
    event SaleStartTimeUpdated(uint256 indexed startTime);

    /**
     * @notice When an NFT is sold via this contract
     * @param id The token id that was sold
     * @param buyer The account that purchased the NFT
     * @param price The price paid for the NFT
     */
    event NFTSold(uint256 indexed id, address indexed buyer, uint256 indexed price);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param nft_ The address of the NFT contract to transfer tokens from
     * @param salePrice_ The price of each NFT
     * @param saleStartTime_ The start time of the sale in seconds
     */
    constructor(
        address owner_,
        address admin_,
        address nft_,
        uint256 salePrice_,
        uint256 saleStartTime_
    ) FixedPrice() Auth(owner_, admin_) {
        nft = IOperatorCollectable(nft_);
        salePrice = salePrice_;
        saleStartTime = saleStartTime_;

        emit SalePriceUpdated(salePrice_);
        emit SaleStartTimeUpdated(saleStartTime_);
    }

    /* ------------------------------------------------------------------------
       S A L E
    ------------------------------------------------------------------------ */

    /**
     * @notice Purchase a specific token id
     */
    function purchase(uint256 id) public payable onlyWithCorrectPayment(salePrice) nonReentrant {
        if (block.timestamp < saleStartTime || saleStartTime == 0) revert SaleIsNotLive();
        nft.collect(id, msg.sender);
        emit NFTSold(id, msg.sender, salePrice);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set the sale price
     * @param price The new sale price in ETH
     */
    function setSalePrice(uint256 price) external onlyOwnerOrAdmin {
        salePrice = price;
        emit SalePriceUpdated(price);
    }

    /**
     * @notice Admin function to set the sale start time
     * @param startTime The new sale start time in seconds
     */
    function setSaleStartTime(uint256 startTime) external onlyOwnerOrAdmin {
        saleStartTime = startTime;
        emit SaleStartTimeUpdated(startTime);
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `owner` address
     * @param to The address to withdraw ETH to
     */
    function withdrawETH(address to) public onlyOwnerOrAdmin {
        _withdrawETH(to);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `owner` address
     * @param token The address of the ERC-20 token to withdraw
     * @param to The address to withdraw tokens to
     */
    function withdrawToken(address token, address to) public onlyOwnerOrAdmin {
        _withdrawToken(token, to);
    }
}

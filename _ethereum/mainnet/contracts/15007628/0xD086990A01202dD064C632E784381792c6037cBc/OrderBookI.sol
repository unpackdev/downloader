// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC1155ReceiverUpgradeable.sol";

interface OrderBookI {
    event OrderPlaced(
        uint256 indexed tokenID,
        uint256 indexed orderID,
        uint256 indexed askingPrice,
        uint256 amountForSale,
        address account,
        address token,
        bool lookingFor,
        bool primary
    );

    event OrderFulfilled(
        uint256 indexed orderID,
        uint256 salePrice,
        uint256 platformFee,
        uint256 royaltyAmount,
        address indexed royaltyReceiver,
        uint256 amountSold,
        bool    isPrimaryMarket,
        address indexed fulfilledBy
    );

    event OrderCanceled(uint256 indexed _orderId);

    /**
    @notice createOrderExisting allows for the creation of a new order for an existing NFT
    @param _tokenId is the id of the NFT token being sold in the order
    @param _askingPrice is the asking price in 1e18
    @param _amount is the amount of tokens in the order
    @param _token is the address of the ERC20 token the NFT will be exchanged for(use 0x0 add for ETH)
    @param _nft is the address of the NFT contract for the NFT being added to the order
    @param _lookingFor is aa bool representing whether or not the asker owns the NFT
  */
    function createOrderExisting(
        uint256 _tokenId,
        uint256 _askingPrice,
        uint256 _amount,
        address _token,
        address _nft,
        bool _lookingFor
    ) external payable returns (uint256);

    /**
  @notice createOrderNew allows for the creation of a new order for new NFT
  @param _orgName string that represents the name of the organizastion the artist belongs to
  @param _metadataUri  is a string where the metadata URI for the NFT is stored
  @param _royaltyReceiver the address taht will receive the royalties when this NFT is traded on the platform
  @param _token is the address of the ERC20 token the NFT will be exchanged for(use 0x0 add for ETH)
  @param _for is the address of the artist the NFT(s) are being minted for
  @param _askingPrice is the asking price in 1e18
  @param _royalty the percentage value of the royalty?
  */
    function createOrderNew(
        string memory _orgName,
        string memory _metadataUri,
        address _royaltyReceiver,
        address _token,
        address _for,
        uint256 _askingPrice,
        uint256 _issues,
        uint24 _royalty,
        bool _splitPayable
    ) external returns (uint256);

    /**
    @notice fulfillOrder allows for the fulfillment of an order either when the order price is met
              OR when a counter offer has been accepted
    @param _orderId is the id of the order being fulfilled
    @dev this function will mint a new NFT to the fulfiller if the NFT does not yet exist
          this function transfers the funds from the purchaser to the artist/seller AND
          the NFT from the artist/owner
  */
    function fulfillOrder(uint256 _orderId, uint256 _numberOfIssues, bool _splitPayable)
        external
        payable;

    /**
    @notice cancelOrder allows for the cancleation of an order
    @param _orderId is the id of the order being fulfilled
  */
    function cancelOrder(uint256 _orderId) external;

    /**
    @notice unlockPlatform allows for owner of this contract to open up the platforms listings to
              non MGD NFT types
  */
    function unlockPlatform() external;

    /**
    @notice setMintFee allows a the owner to set the fee for minting and listing through the orderbook
    @param _fee is the value representing the percentage of a sale taken as a platform fee
  */
    function setMintFee(uint256 _fee) external;

    /**
    @notice setListingFee allows a the owner to set the fee for secondary listings through the orderbook
    @param _fee is the value representing the percentage of a sale taken as a platform fee
  */
    function setListingFee(uint256 _fee) external;

    /**
    @notice setFeeAdd allows the owner to set the fee address
    @param _add is the address that will receive the fee's
    */
    function setFeeAdd(address _add) external;
}

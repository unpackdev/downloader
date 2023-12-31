// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/**
 * @title Interface for PolyOne Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Base interface for the creation of PolyOne drop listing contracts
 */
interface IPolyOneDrop {
  /**
   * @dev Structure of parameters required for the creation of a new drop
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  struct Drop {
    uint256 startingPrice;
    uint128 bidIncrement;
    uint128 qty;
    uint64 startDate;
    uint64 dropLength;
    address collection;
    string baseTokenURI;
    Royalties royalties;
  }

  /**
   * @dev Structure of parameters required for primary sale and secondary royalties
   *      This must include PolyOne's primary sale and secondary royalties
   *      The secondary royalties are optional but the primary sale royalties are not (they must total 100% in bps)
   * @param royaltyReceivers The addresses of the secondary royalty receivers. The PolyOne fee wallet should be the first in the array
   * @param royaltyBasisPoints The basis points of each of the secondary royalty receivers
   * @param saleReceivers The addresses of the primary sale receivers. The PolyOne fee wallet should be the first in the array
   * @param saleBasisPoints The basis points of each of the primary sale receivers
   */
  struct Royalties {
    address payable[] royaltyReceivers;
    uint256[] royaltyBasisPoints;
    address payable[] saleReceivers;
    uint256[] saleBasisPoints;
  }

  /**
   * @dev Structure of parameters required for a bid on a drop
   * @param bidder The address of the bidder
   * @param amount The value of the bid in wei
   */
  struct Bid {
    address bidder;
    uint256 amount;
  }

  /**
   * @dev Thrown if a drop is being access that does not exist on the drop contract
   * @param dropId The id of the drop that does not exist
   */
  error DropNotFound(uint256 dropId);

  /**
   * @dev Thrown if a token is being accessed that does not exist in a drop (i.e token index out of the drop range)
   * @param dropId The id of the drop being accessed
   * @param tokenIndex The index of the token being accessed
   */
  error TokenNotFoundInDrop(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if a drop is being created that already exists on the drop contract
   * @param dropId The id of the drop that already exists
   */
  error DropAlreadyExists(uint256 dropId);

  /**
   * @dev Thrown when attempting to modify a date that is not permitted (e.g a date in the past)
   * @param date The date that is invalid
   */
  error InvalidDate(uint256 date);

  /**
   * @dev Thrown if attempting to purchase a drop which has not started yet
   * @param dropId The id of the drop
   */
  error DropNotStarted(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase a drop which has already finished
   * @param dropId The id of the drop
   */
  error DropFinished(uint256 dropId);

  /**
   * @dev Thrown if attempting to claim a drop which has not yet finished
   * @param dropId The id of the drop
   */
  error DropInProgress(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase or bid on a token with an invalid amount
   * @param price The price that was attempted to be paid
   */
  error InvalidPurchasePrice(uint256 price);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token in the drop
   */
  error TokenAlreadyClaimed(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed or is not claimable by the caller
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token
   * @param claimant The address attempting to claim a token
   */
  error InvalidClaim(uint256 dropId, uint256 tokenIndex, address claimant);

  /**
   * @dev Emitted when a drop is extended by a bid extension mechanism
   * @param dropId The id of the drop that was extended
   * @param newDropLength The new length of the drop
   */
  event DropExtended(uint256 indexed dropId, uint256 newDropLength);

  /**
   * @notice Registers a new upcoming drop
   * @param _dropId The id of the new drop to create
   * @param _drop The parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function createDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update an existing drop
   * @param _dropId The id of the existing drop
   * @param _drop The updated parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update the royalties for an existing drop
   * @param _dropId The id of the existing drop
   * @param _royalties The updated royalties for the drop
   */
  function updateDropRoyalties(uint256 _dropId, Royalties calldata _royalties) external;

  /**
   * @notice Register a bid (or intent to purchase) a token from PolyOne
   * @dev For fixed price drops, the amount must be equal to the starting price, and the token will be transferred instantly.
   *      For auction style drops, the amount must be greater than the starting price.
   * @param _dropId The id of the drop to place a purchase for
   * @param _tokenIndex The index of the token to purchase in this drop
   * @param _bidder The address of the bidder
   * @param _amount The amount of the purchase intent (in wei)
   * @param _data Any additional data that should be passed to the drop contract
   * @return instantClaim Whether this should be an instant claim (for fixed priced drop) or not (for auction style drops)
   * @return collection The collection address of the new token to be minted (if instant claim is also true)
   * @return tokenURI The token URI of the new token to be minted (if instant claim is also true)
   * @return royalties The royalties for the new token to be minted (if instant claim is also true)
   */
  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _bidder,
    uint256 _amount,
    bytes calldata _data
  ) external payable returns (bool instantClaim, address collection, string memory tokenURI, Royalties memory royalties);

  /**
   * @notice Validates that a token is allowed to be claimed by the claimant based on the status of the drop
   * @dev This will always revert for fixed price drops (where the bid increment is zero)
   *      This will return the claim data for fixed price drops if the token has been won by the claimaint and the auction has ended
   * @param _dropId The id of the drop to claim a token from
   * @param _tokenIndex The index of the token to claim
   * @param _caller The address of the claimant
   * @param _data Any additional data that should be passed to the drop contract
   * @return collection The collection address of the new token to be minted
   * @return tokenURI The token URI of the new token to be minted
   * @return claim The winning claim information (bidder and bid amount)
   * @return royalties The royalties for the new token to be minted
   */
  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _caller,
    bytes calldata _data
  ) external returns (address collection, string memory tokenURI, Bid memory claim, Royalties memory royalties);

  /**
   * @notice Mapping of drop ids to the drop parameters
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  function drops(
    uint256 _id
  )
    external
    view
    returns (
      uint256 startingPrice,
      uint128 bidIncrement,
      uint128 qty,
      uint64 startDate,
      uint64 dropLength,
      address collection,
      string memory baseTokenURI,
      Royalties memory royalties
    );

  /**
   * @notice Check if there is a currently active listing for a token
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingActive(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check if a token was previously listed and it has now ended either due to time or being claimed
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingEnded(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check the current claimed status of a listing
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);
}

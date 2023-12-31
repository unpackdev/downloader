// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IAccessControl.sol";
import "./IPolyOneDrop.sol";

/**
 * @title Interface for PolyOne Core
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs core functionality to faciliate the creation of drops, listings and administrative functions
 */
interface IPolyOneCore is IAccessControl {
  /**
   * @dev Structure of the parameters required for the registering of a new collection
   * @param registered Whether the collection is registered
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  struct Collection {
    bool registered;
    bool isERC721;
  }

  /**
   * @dev Structure of a signature request for an action by a PolyOne Creator
   * @param signature The signature of the request
   * @param timestamp The timestamp of the signature
   */
  struct SignedRequest {
    bytes signature;
    uint256 timestamp;
  }

  /**
   * @notice Thrown if a contract address is already registered
   * @param contractAddress The address of the contract
   */
  error AddressAlreadyRegistered(address contractAddress);

  /**
   * @notice Thrown if a collection was expected to be registered but currently isn't
   * @param collection The address of the collection contract
   */
  error CollectionNotRegistered(address collection);

  /**
   * @notice Thrown if an unregistered contract is being used to create a drop
   * @param dropContract The address of the unregistered contract
   */
  error DropContractNotRegistered(address dropContract);

  /**
   * @dev Thrown if a transfer of eth fails
   * @param destination The intented recipient
   * @param amount The amount of eth to be transferred
   */
  error EthTransferFailed(address destination, uint256 amount);

  /**
   * @dev Thrown if attempting to transfer an invalid eth amount
   */
  error InvalidEthAmount();

  /**
   * @dev Thrown if attempting to interact with a collection that is not of the expected type
   * @param collection The address of the collection contract
   */
  error CollectionTypeMismatch(address collection);

  /**
   * @dev Thrown if attempting to create or update a drop with invalid royalty settings
   */
  error InvalidRoyaltySettings();

  /**
   * @dev Thrown if attempting to create or update a drop with invalid PolyOne fee settings
   */
  error InvalidPolyOneFee();

  /**
   * @dev Thrown if attempting to create or udpate a drop without including the PolyOne fee wallet
   */
  error FeeWalletNotIncluded();

  /**
   * @dev Thrown if an arbitrary call to a collection contract fails
   * @param error The error thrown by the contract being called
   */
  error CallCollectionFailed(bytes error);

  /**
   * @notice Emitted when a creator is allowed to access the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorAllowed(address indexed creator);

  /**
   * @dev Thrown if an invalid signature has been used as a parameter for a function requiring signature validation
   */
  error InvalidSignature();

  /**
   * @dev Thrown if a signature that has already being used is used again
   */
  error SignatureAlreadyUsed();

  /**
   * @notice Emitted when a creator is revoked access to the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorRevoked(address indexed creator);

  /**
   * @notice Emitted when a drop contract is registered
   * @param dropContract The address of the drop contract implementation
   */
  event DropContractRegistered(address indexed dropContract);

  /**
   * @notice Emitted when a new token collection is registered
   * @param collection The address of the collection contract
   * @param creator The address of the creator who owns the contract
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  event CollectionRegistered(address indexed collection, address indexed creator, bool isERC721);

  /**
   * @notice Emitted when a new drop is created for a collection
   * @param dropContract The address of the drop contract for which the drop was created
   * @param dropId the id of the newly created drop
   */
  event DropCreated(address indexed dropContract, uint256 dropId);

  /**
   * @notice Emitted when a purchase intent is created for an auction or fixed price drop
   * @param dropContract The address of the drop contract for which the purchase intent was created
   * @param dropId The id of the drop for which the purchase intent was created
   * @param tokenIndex The index of the token in the drop for which the purchase intent was created
   * @param bidder The address of the bidder who registered the purchase intent
   * @param amount The amount of the purchase
   */
  event PurchaseIntentRegistered(address indexed dropContract, uint256 dropId, uint256 tokenIndex, address indexed bidder, uint256 amount);

  /**
   * @notice Emitted when a token is claimed by a claimant
   * @param collection The address of the token contract
   * @param tokenId The id of the newly minted token
   * @param dropId The id of the drop from which the token was minted
   * @param tokenIndex The index of the token in the drop
   * @param claimant The address of the claimant
   */
  event TokenClaimed(address indexed collection, uint256 tokenId, uint256 dropId, uint256 tokenIndex, address indexed claimant);

  /**
   * @notice Emitted when an existing drop is updated
   * @param dropContract The address of the drop contract for which teh drop was updated
   * @param _dropId The id of the drop that was updated
   */
  event DropUpdated(address indexed dropContract, uint256 _dropId);

  /**
   * @notice Emitted when the PolyOne primary fee wallet is updated
   * @param feeWallet The new PolyOne primary fee wallet
   */
  event PrimaryFeeWalletUpdated(address feeWallet);

  /**
   * @notice Emitted when the PolyOne secondary fee wallet is updated
   * @param feeWallet The new PolyOne secondary fee wallet
   */
  event SecondaryFeeWalletUpdated(address feeWallet);

  /**
   * @notice Emitted when the PolyOne default primary or secondary fees are updated
   * @param primaryFee The new primary sale fee
   * @param secondaryFee The new secondary sale fee
   */
  event DefaultFeesUpdated(uint16 primaryFee, uint16 secondaryFee);

  /**
   * @notice Emitted when the PolyOne authorised signer address is updated
   * @param signer The address of the authorised signer
   */
  event RequestSignerUpdated(address indexed signer);

  /**
   * @notice Emitted when a collection contract is called with arbitrary calldata
   * @param collection The address of the collection contract
   * @param caller The address of the caller
   * @param data The data passed to the collection contract
   */
  event CollectionContractCalled(address indexed collection, address indexed caller, bytes data);

  /**
   * @notice Emitted when ether is transferred to a destination account
   * @param destination The address of the destination account
   * @param amount The amount of ether transferred
   */
  event EthTransferred(address indexed destination, uint256 amount);

  /**
   * @notice Emitted when the bid extension time is updated by an admin
   * @param bidExtensionTime The new bid extension time
   */
  event BidExtensionTimeUpdated(uint256 bidExtensionTime);

  /**
   * @notice Allow a creator to access the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorAllowed} event
   * @param _creator address of the creator
   */
  function allowCreator(address _creator) external;

  /**
   * @notice Revoke creator access from the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorRevoked} event
   * @param _creator address of the creator
   */
  function revokeCreator(address _creator) external;

  /**
   * @notice Register a new drop contract implementation to be used for Poly One token drops
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {DropContractRegistered} event
   *      _dropContract must implement the IPolyOneDrop interface
   * @param _dropContract The address of the drop contract implementation
   */
  function registerDropContract(address _dropContract) external;

  /**
   * @notice Register an ERC721 or ERC1155 collection to the PolyOne ecosystem
   * @dev The contract must extend the ERC721Creator or ERC1155Creator contracts to be compatible.
   *      Only callable by the POLY_ONE_CREATOR_ROLE, and caller must be the contract owner.
   *      The PolyOneCore contract must be assigned as an admin in the collection contract.
   *      Emits a {CollectionRegistered} event.
   * @param _collection The address of the token contract to register
   * @param _isERC721 Is the contract an ERC721 standard (true) or ERC1155 (false)
   * @param _signedRequest A signed request to allow the creator to register the collection
   */
  function registerCollection(address _collection, bool _isERC721, SignedRequest calldata _signedRequest) external;

  /**
   * @notice Create a new drop for an already registered collection and tokens that are already minted
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropCreated} event
   * @param _dropContract The implementation contract for the drop to be created
   * @param _drop The drop parameters (see {NewDrop} struct)
   * @param _signedRequest A signed request to allow the creator to create the drop
   * @param _data Any additional data that should be passed to the drop contract
   * */
  function createDrop(
    address _dropContract,
    IPolyOneDrop.Drop memory _drop,
    SignedRequest calldata _signedRequest,
    bytes calldata _data
  ) external;

  /**
   * @notice Update an existing drop.
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropUpdated} event
   *      The collection address will be excluded from the update
   *      The drop must not have started yet
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _drop The updated drop information (not that collection address will be excluded)
   * @param _signedRequest A signed request to allow the creator to update the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(
    uint256 _dropId,
    address _dropContract,
    IPolyOneDrop.Drop memory _drop,
    SignedRequest calldata _signedRequest,
    bytes calldata _data
  ) external;

  /**
   * @notice Update the royalties
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Emits a {DropUpdatedEvent}
   *      The drop must not have started yet
   *      Only the total of saleReceivers are validated, there is not validation that PolyOne fees are included
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _royalties The updated royalties information
   */
  function updateDropRoyalties(uint256 _dropId, address _dropContract, IPolyOneDrop.Royalties memory _royalties) external;

  /**
   * @notice Register a bid for an existing drop
   * @dev Will call to an external contract for the bidding implementation depending on the drop type
   *      Emits a {PurchaseIntentRegistered} event
   * @param _dropId The id of the drop to register a bid for
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index of the token in the drop to bid on
   * @param _data Any additional data that should be passed to the drop contract
   * @param _useAsyncTransfer If true, async transfer will be used for funds distribution instead of a direct call
   */
  function registerPurchaseIntent(
    uint256 _dropId,
    address _dropContract,
    uint256 _tokenIndex,
    bytes calldata _data,
    bool _useAsyncTransfer
  ) external payable;

  /**
   * @notice Claim a token that has been won in an auction style drop
   * @dev This will always revert for fixed price (instant) style drops as the token has already been claimed
   *      Only callable by the winner of the sale
   * @param _dropId The id of the drop to claim a token from
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index in the drop of the token to claim
   * @param _data Any additional data that should be passed to the drop contract
   * @param _useAsyncTransfer If true, async transfer will be used for funds distribution instead of a direct call
   */
  function claimToken(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data, bool _useAsyncTransfer) external;

  /**
   * @notice Mint new tokens to an existing registered ERC721 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _recipient The recipient of the tokens
   * @param _qty The number of tokens being minted
   * @param _baseTokenURI The base tokenURI the tokens to be minted
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   */
  function mintTokensERC721(
    address _collection,
    address _recipient,
    uint256 _qty,
    string calldata _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) external;

  /**
   * @notice Mint new tokens to an existing registered ERC1155 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _tokenURIs The base tokenURI for each new token to be minted
   * @param _tokenIds The ids of the tokens to mint
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   * @param _receivers The addresses to mint tokens to
   * @param _amounts The amounts of tokens to mint to each address
   * @param _existingTokens Is the set of tokens already existing in the collection (true) or a new batch of tokens (false). Cannot be mixed
   */
  function mintTokensERC1155(
    address _collection,
    string[] calldata _tokenURIs,
    uint256[] calldata _tokenIds,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] calldata _receivers,
    uint256[] calldata _amounts,
    bool _existingTokens
  ) external;

  /**
   * @notice Make an arbitrary contract call to the collection contract
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CollectionContractCalled} event
   * @param _data The data to call the collection contract with
   */
  function callCollectionContract(address _collection, bytes calldata _data) external;

  /**
   * @notice Mapping of drop contracts to whether they are registered
   * @param _dropContract The address of the drop contract
   * @return A boolean indicating whether the drop contract is registered
   */
  function dropContracts(address _dropContract) external view returns (bool);

  /**
   * @notice Mapping of token contract addresses to their collection data
   * @param _collection The address of the collection token contract
   * @return registered Whether the collection is registered
   * @return isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  function collections(address _collection) external view returns (bool registered, bool isERC721);

  /**
   * @notice Mapping of dropIds to the tokenId assigned to the drop for ERC1155 mints to differentiate between new and existing mint cases
   * @param _dropId The id of the drop to get the token id for
   * @return The tokenId assigned to the drop
   */
  function dropTokenIds(uint256 _dropId) external view returns (uint256);

  /**
   * @notice The number of drops that have been created. This counter is used to create incremental ids for each new drop registered
   * @dev The counter is incremented before the new drop is created, hence the first drop is always 1
   */
  function dropCounter() external view returns (uint256);

  /**
   * @notice The PolyOne fee wallet to collection primary and secondary sales
   */
  function primaryFeeWallet() external view returns (address payable);

  /**
   * @notice The PolyOne fee wallet to collection primary and secondary sales
   */
  function secondaryFeeWallet() external view returns (address payable);

  /**
   * @notice The PolyOne authorized request signer
   */
  function requestSigner() external view returns (address);

  /**
   * @notice The default primary sale fee to apply to new collections and drops (in bps)
   */
  function defaultPrimaryFee() external view returns (uint16);

  /**
   * @notice The default secondary sale fee to apply to new collections and drops (in bps)
   */
  function defaultSecondaryFee() external view returns (uint16);

  /**
   * @notice The bid extension time for auction style drops (in seconds)
   */
  function bidExtensionTime() external view returns (uint64);

  /**
   * @notice A mapping of used signatures to prevent replay attacks
   * @param _signature The signature to check
   */
  function usedSignatures(bytes memory _signature) external view returns (bool);

  /**
   * @notice Set the address for PolyOne fees from primary sales to be sent to
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _feeWallet The new fee wallet
   */
  function setPrimaryFeeWallet(address payable _feeWallet) external;

  /**
   * @notice Set the address for PolyOne fees from secondary sales to be sent to
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _feeWallet The new fee wallet
   */
  function setSecondaryFeeWallet(address payable _feeWallet) external;

  /**
   * @notice Set the default primary fee that is applied to new collections
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultPrimaryFee(uint16 _newFee) external;

  /**
   * @notice Set the default secondary fee that is applied to new collection
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultSecondaryFee(uint16 _newFee) external;

  /**
   * @notice Set the bid extension time for auction style drops
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   *      Emits a {BidExtensionTimeUpdated} event
   * @param _newBidExtensionTime The new bid extension time to set
   */
  function setBidExtensionTime(uint64 _newBidExtensionTime) external;

  /**
   * @notice Set the authorised signer for the contract
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   *      Emits a {AuthorisedSignerUpdated} event
   * @param _signer The address to set as the authorised signer
   */
  function setRequestSigner(address _signer) external;

  /**
   * @notice Initiates an async transfer for an ether amount to a destination address
   * @dev Only callable by registered PolyOneDrop contracts
   *      Emits an Escrow {Deposited} event
   * @param _destination The address to send the amount to
   * @param _amount The amount to send (in wei)
   */
  function transferEth(address _destination, uint256 _amount) external;

  /**
   * @notice Poly One Administrators allowed to perform administrative functions
   * @return The bytes32 representation of the POLY_ONE_ADMIN_ROLE
   */
  function POLY_ONE_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Poly One Creators allowed to mint new collections and create listings for their tokens
   * @return The bytes32 representation of the POLY_ONE_CREATOR_ROLE
   */
  function POLY_ONE_CREATOR_ROLE() external view returns (bytes32);

  /**
   * @notice The maximum default primary fee that can be set by the POLY_ONE_ADMIN_ROLE
   * @return The maximum default primary fee
   */
  function MAX_PRIMARY_FEE() external view returns (uint16);

  /**
   * @notice The maximum default secondary fee that can be set by the POLY_ONE_ADMIN_ROLE
   * @return The maximum default secondary fee
   */
  function MAX_SECONDARY_FEE() external view returns (uint16);
}

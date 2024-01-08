// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721Receiver.sol";
import "./IBuyBackAndBurn.sol";
import "./IMultiSignatureOracle.sol";
import "./MyPausableUpgradeable.sol";
import "./MintableERC721.sol";
import "./console.sol";

/**
 * @title CrossChainBridgeERC721V1
 * Provides cross chain bridging services for (whitelisted) ERC721 tokens
 */
contract CrossChainBridgeERC721V1 is MyPausableUpgradeable, IERC721Receiver {
  // Roles
  bytes32 public constant MANAGE_COLLECTED_FEES_ROLE = keccak256('MANAGE_COLLECTED_FEES_ROLE');
  bytes32 public constant MANAGE_FEES_ROLE = keccak256('MANAGE_FEES_ROLE');
  bytes32 public constant MANAGE_ORACLES_ROLE = keccak256('MANAGE_ORACLES_ROLE');
  bytes32 public constant MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE = keccak256('MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE');
  bytes32 public constant MANAGE_COLLECTION_WHITELIST_ROLE = keccak256('MANAGE_COLLECTION_WHITELIST_ROLE');

  event TokenDeposited(
    address indexed sourceNetworkCollectionAddress,
    uint256 tokenId,
    address indexed receiverAddress,
    uint256 sourceChainId,
    uint256 targetChainId,
    uint256 number
  );

  event TokenReleased(
    address indexed sourceNetworkCollectionAddress,
    uint256 tokenId,
    address indexed receiverAddress,
    uint256 depositChainId,
    uint256 depositNumber
  );

  event AddedCollectionToWhitelist(address indexed collectionAddress);

  event RemovedCollectionFromWhitelist(address indexed collectionAddress);

  event PeggedCollectionMappingAdded(
    address indexed depositChainCollectionAddress,
    address indexed releaseChainCollectionAddress
  );

  /// Counts all deposits
  /// Assigns a unique deposit ID to each deposit which helps to prevent double releases
  uint256 public depositCount;

  /// A mapping from deposit IDs to boolean if a deposit has been released or not
  /// depositChainId => depositNumber => true (released)
  mapping(uint256 => mapping(uint256 => bool)) public releasedDeposits;

  /// A mapping for a collection if a NFT for a tokenId deposit has been minted or not
  /// tokenAddress => tokenId => bool
  mapping(address => mapping(uint256 => bool)) public mintedDeposits;

  /// Default bridge fee (fixed amount per transaction)
  uint256 public defaultBridgeFee;

  /// Individual bridge fees per supported token (fixed amount per transaction)
  /// tokenAdressInDepositNetwork => flat fee amount in native token
  mapping(address => uint256) public bridgeFees;

  /// Storage of the outside pegged tokens
  /// tokenAddressInThisNetwork => tokenAddressInTargetNetwork
  mapping(address => address) public outsidePeggedCollections;

  /// Mapping to track which collections are whitelisted
  /// Only the official collections of the projects has to be whitelisted
  /// Pegged collections by the bridge must not be whitelisted
  /// tokenAddressInThisNetwork => true/false
  mapping(address => bool) public officialCollectionWhitelist;

  /// Contract to receive a part of the bridge fees for token burns
  IBuyBackAndBurn public buyBackAndBurn;

  /// MultiSignatureOracle contract
  IMultiSignatureOracle public multiSignatureOracle;

  /**
   * @notice Initializer instead of constructor to have the contract upgradable
   * @dev can only be called once after deployment of the contract
   */
  function initialize(address _buyBackAndBurn, address _multiSignatureOracle) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    buyBackAndBurn = IBuyBackAndBurn(_buyBackAndBurn);
    multiSignatureOracle = IMultiSignatureOracle(_multiSignatureOracle);
    defaultBridgeFee = 0;
  }

  /**
   * @notice Adds a collection to the whitelist (effectively allowing bridge transactions for this token)
   *
   * @dev can only be called by MANAGE_COLLECTION_WHITELIST_ROLE
   * @param collectionAddress the address of the token in the network this contract was released on
   * @dev emits event AddedCollectionToWhitelist after successful whitelisting
   */
  function addCollectionToWhitelist(address collectionAddress) external {
    require(
      hasRole(MANAGE_COLLECTION_WHITELIST_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_COLLECTION_WHITELIST_ROLE role to execute this function'
    );
    require(collectionAddress != address(0), 'CrossChainBridgeERC721V1: invalid collectionAddress provided');
    officialCollectionWhitelist[collectionAddress] = true;
    emit AddedCollectionToWhitelist(collectionAddress);
  }

  /**
   * @notice Adds an outside pegged collection (= same collection but in a different network)
   *
   * @dev can only be called by MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE
   * @param depositChainCollectionAddress the address of the collection in the network the deposit is possible (deposit collection)
   * @param peggedCollectionAddress the address of the pegged collection in the network this bridge contract is released on (release collection)
   */
  function addOutsidePeggedCollection(address depositChainCollectionAddress, address peggedCollectionAddress) external {
    require(
      hasRole(MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE role to execute this function'
    );
    require(
      depositChainCollectionAddress != address(0) && peggedCollectionAddress != address(0),
      'CrossChainBridgeERC721V1: invalid collection address provided'
    );
    outsidePeggedCollections[depositChainCollectionAddress] = peggedCollectionAddress;

    emit PeggedCollectionMappingAdded(depositChainCollectionAddress, peggedCollectionAddress);
  }

  /**
   * @notice Accepts ERC721 deposits that should be bridged into another network (effectively starting a bridge transaction)
   *
   * @dev the collection must be whitelisted by the bridge or the call will be reverted
   * @param collectionAddress the address of the ERC721 contract the collection was issued with
   * @param tokenId the (native) ID of the ERC721 token that should be bridged
   * @param receiverAddress target address the bridged token should be sent to
   * @param targetChainId chain ID of the target network
   * @dev emits event TokenDeposited after successful deposit
   *
   */
  function deposit(
    address collectionAddress,
    uint256 tokenId,
    address receiverAddress,
    uint256 targetChainId
  ) external whenNotPaused {
    // check if token was minted from an original collection or minted by this bridge
    if (mintedDeposits[collectionAddress][tokenId]) {
      // no whitelist check necessary since token was minted by this bridge
      MintableERC721(collectionAddress).burn(tokenId);
    } else {
      require(officialCollectionWhitelist[collectionAddress], 'CrossChainBridgeERC721V1: collection not whitelisted');
      // transfer the token into the bridge
      IERC721Upgradeable(collectionAddress).safeTransferFrom(_msgSender(), address(this), tokenId);
    }

    // For every deposit we increase the counter to create a unique ID that can be used on the target side bridge to avoid double releases
    depositCount = depositCount + 1;

    // We always dispatch the deposit event with the "true" token address in the source network
    emit TokenDeposited(collectionAddress, tokenId, receiverAddress, _getChainID(), targetChainId, depositCount);
  }

  /**
   * @notice Releases an ERC721 token in this network after a deposit was made in another network (effectively completing a bridge transaction)
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param sourceNetworkCollectionAddress the address of the ERC721 contract in the network the deposit was made
   * @param tokenId The token id to be sent
   * @param depositChainId chain ID of the network in which the deposit was made
   * @param depositNumber The identifier of the corresponding deposit
   * @dev emits event TokenReleased after successful release
   */
  function release(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address sourceNetworkCollectionAddress,
    uint256 tokenId,
    uint256 depositChainId,
    uint256 depositNumber
  ) external payable whenNotPaused {
    // check input parameters
    require(
      !releasedDeposits[depositChainId][depositNumber],
      'CrossChainBridgeERC721V1: deposit was already processed and released'
    );
    require(
      multiSignatureOracle.signaturesCheckERC721(
        sigV,
        sigR,
        sigS,
        receiverAddress,
        sourceNetworkCollectionAddress,
        tokenId,
        depositChainId,
        depositNumber
      ),
      'CrossChainBridgeERC721V1: release not permitted. Not enough signatures from permitted oracles'
    );

    // get collection address in release network
    address collectionAddress = sourceNetworkCollectionAddress;
    if (outsidePeggedCollections[collectionAddress] != address(0)) {
      collectionAddress = outsidePeggedCollections[collectionAddress];
    }

    // calculate bridging fee
    uint256 nftBridgingFee = defaultBridgeFee;
    if (bridgeFees[collectionAddress] > 0) {
      nftBridgingFee = bridgeFees[collectionAddress];
    }

    // check if transaction contains enough native tokens to pay the bridging fee
    require(msg.value >= nftBridgingFee, 'CrossChainBridgeERC721V1: bridging fee exceeds release transaction value');

    // transfer bridging fee to buyBackAndBurn contract
    if (nftBridgingFee > 0) {
      buyBackAndBurn.depositNativeToken{value: nftBridgingFee}(nftBridgingFee);
    }

    // check if to-be-released token is part of the official collection (whitelisted)
    if (officialCollectionWhitelist[collectionAddress] == true) {
      ERC721Upgradeable(collectionAddress).safeTransferFrom(address(this), receiverAddress, tokenId);
    } else {
      MintableERC721(collectionAddress).mint(receiverAddress, tokenId);
      mintedDeposits[collectionAddress][tokenId] = true;
    }

    // update records to track released deposits
    releasedDeposits[depositChainId][depositNumber] = true;

    // release successful, deposit event
    emit TokenReleased(collectionAddress, tokenId, receiverAddress, depositChainId, depositNumber);
  }

  /**
   * @notice Removes an outside pegged collection
   *
   * @dev can only be called by MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE
   * @param collectionAddress the address of the collection contract
   */
  function removeOutsidePeggedCollection(address collectionAddress) external {
    require(
      hasRole(MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_OUTSIDE_PEGGED_COLLECTION_ROLE role to execute this function'
    );
    outsidePeggedCollections[collectionAddress] = address(0);
  }

  /**
   * @notice Removes a token from the whitelist (i.e. stops bridging)
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param collectionAddress the address of the token contract
   * @dev emits event RemovedCollectionFromWhitelist after successful de-whitelisting
   */
  function removeCollectionFromWhitelist(address collectionAddress) external {
    require(
      hasRole(MANAGE_COLLECTION_WHITELIST_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_COLLECTION_WHITELIST_ROLE role to execute this function'
    );
    officialCollectionWhitelist[collectionAddress] = false;
    emit RemovedCollectionFromWhitelist(collectionAddress);
  }

  /**
   * @notice Sets the default bridge (flat) fee that is being used for token buybacks and burns
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param fee flat fee amount in native token currency
   */
  function setDefaultBridgeFee(uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_FEES_ROLE role to execute this function'
    );
    defaultBridgeFee = fee;
  }

  /**
   * @notice Sets an individual bridge (flat) fee for the provided collection
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param collectionAddress the address of the token contract
   * @param fee flat fee amount in native token currency
   */
  function setBridgeFee(address collectionAddress, uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_FEES_ROLE role to execute this function'
    );
    bridgeFees[collectionAddress] = fee;
  }

  /**
   * @notice Sets the address for the BuyBackAndBurn contract that receives bridging fees to fund token burns
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param buyBackAndBurnContract the address of the BuyBackAndBurn contract
   */
  function setBuyBackAndBurn(IBuyBackAndBurn buyBackAndBurnContract) external {
    require(
      address(buyBackAndBurnContract) != address(0),
      'CrossChainBridgeERC721: invalid buyBackAndBurnContract address provided'
    );
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    buyBackAndBurn = buyBackAndBurnContract;
  }

  /**
   * @notice Sets the address for the MultiSignatureOracle contract
   *
   * @dev can only be called by MANAGE_ORACLES_ROLE
   * @param oracle the address of the MultiSignatureOracle contract
   */
  function setMultiSignatureOracle(IMultiSignatureOracle oracle) external {
    require(address(oracle) != address(0), 'CrossChainBridgeERC721: invalid oracle address provided');
    require(
      hasRole(MANAGE_ORACLES_ROLE, _msgSender()),
      'CrossChainBridgeERC721: must have MANAGE_ORACLES_ROLE role to execute this function'
    );
    multiSignatureOracle = oracle;
  }

  /**
   * @notice Always returns `this.onERC721Received.selector`
   * @dev see OpenZeppelin IERC721Receiver for more details
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  // returns the ID of the network this contract is deployed in
  function _getChainID() private view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC721CreatorImplementation.sol";
import "./ERC1155CreatorImplementation.sol";
import "./ICreatorCore.sol";
import "./IAdminControl.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./PullPayment.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IPolyOneCore.sol";
import "./IPolyOneDrop.sol";
import "./PolyOneLibrary.sol";

/**
 * @title PolyOne Core
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs core functionality to faciliate the creation of drops, listings and administrative functions
 */
contract PolyOneCore is IPolyOneCore, AccessControl, ReentrancyGuard, PullPayment {
  using ECDSA for bytes32;

  bytes32 public constant override POLY_ONE_ADMIN_ROLE = keccak256("POLY_ONE_ADMIN_ROLE");
  bytes32 public constant override POLY_ONE_CREATOR_ROLE = keccak256("POLY_ONE_CREATOR_ROLE");

  mapping(address dropContractAddress => bool isRegistered) public dropContracts;
  mapping(address collectionAddress => Collection collectionParameters) public collections;
  mapping(uint256 dropId => uint256 tokenId) public dropTokenIds;

  uint256 public dropCounter = 0;

  address payable public primaryFeeWallet;
  address payable public secondaryFeeWallet;

  uint16 public defaultPrimaryFee = 1500;
  uint16 public defaultSecondaryFee = 250;

  uint16 public constant MAX_PRIMARY_FEE = 1500;
  uint16 public constant MAX_SECONDARY_FEE = 250;

  uint64 public bidExtensionTime = 60 seconds;

  mapping(bytes signature => bool isUsed) public usedSignatures;
  address public requestSigner;

  /**
   * @param _superUser The user to assign the DEFAULT_ADMIN_ROLE
   * @param _primaryFeeWallet The wallet to receive fees from primary sales
   * @param _secondaryFeeWallet The wallet to receive fees from secondary sales
   * @param _requestSigner The address of the authroized request signer
   */
  constructor(address _superUser, address payable _primaryFeeWallet, address payable _secondaryFeeWallet, address _requestSigner) {
    PolyOneLibrary.checkZeroAddress(_superUser, "super user");
    PolyOneLibrary.checkZeroAddress(_primaryFeeWallet, "primary fee wallet");
    PolyOneLibrary.checkZeroAddress(_secondaryFeeWallet, "secondary fee wallet");
    PolyOneLibrary.checkZeroAddress(_requestSigner, "request signer");
    _setupRole(DEFAULT_ADMIN_ROLE, _superUser);
    _setupRole(POLY_ONE_ADMIN_ROLE, _superUser);
    primaryFeeWallet = _primaryFeeWallet;
    secondaryFeeWallet = _secondaryFeeWallet;
    requestSigner = _requestSigner;
  }

  function allowCreator(address _creator) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_creator, "creator");
    grantRole(POLY_ONE_CREATOR_ROLE, _creator);
    emit CreatorAllowed(_creator);
  }

  function revokeCreator(address _creator) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_creator, "creator");
    revokeRole(POLY_ONE_CREATOR_ROLE, _creator);
    emit CreatorRevoked(_creator);
  }

  function registerDropContract(address _dropContract) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_dropContract, "drop contract");
    PolyOneLibrary.validateDropContract(_dropContract);
    if (dropContracts[_dropContract]) {
      revert AddressAlreadyRegistered(_dropContract);
    }

    dropContracts[_dropContract] = true;
    emit DropContractRegistered(_dropContract);
  }

  function registerCollection(
    address _collection,
    bool _isERC721,
    SignedRequest calldata _signedRequest
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    PolyOneLibrary.checkZeroAddress(_collection, "collection");
    PolyOneLibrary.validateProxyCreatorContract(_collection, _isERC721);
    PolyOneLibrary.validateContractOwner(_collection, address(this));
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);
    _validateRegisterCollectionRequest(_collection, _isERC721, _signedRequest);

    if (collections[_collection].registered) {
      revert AddressAlreadyRegistered(_collection);
    }

    collections[_collection] = Collection(true, _isERC721);
    emit CollectionRegistered(_collection, msg.sender, _isERC721);
  }

  function createDrop(
    address _dropContract,
    IPolyOneDrop.Drop calldata _drop,
    SignedRequest calldata _signedRequest,
    bytes calldata _data
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) nonReentrant {
    PolyOneLibrary.validateContractCreator(_drop.collection, msg.sender);
    _validateDropRequest(_dropContract, _drop, 0, _signedRequest);
    _validateDropContract(_dropContract);
    _validateCollectionRegistered(_drop.collection);
    _validateRoyaltyReceivers(_drop.royalties.saleReceivers, _drop.royalties.saleBasisPoints, defaultPrimaryFee, primaryFeeWallet);
    _validateRoyaltyReceivers(
      _drop.royalties.royaltyReceivers,
      _drop.royalties.royaltyBasisPoints,
      defaultSecondaryFee,
      secondaryFeeWallet
    );
    PolyOneLibrary.validateArrayTotal(_drop.royalties.saleBasisPoints, 10000);

    uint256 dropId = ++dropCounter;
    emit DropCreated(_dropContract, dropId);
    IPolyOneDrop(_dropContract).createDrop(dropId, _drop, _data);
  }

  function updateDrop(
    uint256 _dropId,
    address _dropContract,
    IPolyOneDrop.Drop calldata _drop,
    SignedRequest calldata _signedRequest,
    bytes calldata _data
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) nonReentrant {
    PolyOneLibrary.validateContractCreator(_drop.collection, msg.sender);
    _validateDropRequest(_dropContract, _drop, _dropId, _signedRequest);
    _validateDropContract(_dropContract);
    _validateRoyaltyReceivers(_drop.royalties.saleReceivers, _drop.royalties.saleBasisPoints, defaultPrimaryFee, primaryFeeWallet);
    _validateRoyaltyReceivers(
      _drop.royalties.royaltyReceivers,
      _drop.royalties.royaltyBasisPoints,
      defaultSecondaryFee,
      secondaryFeeWallet
    );
    PolyOneLibrary.validateArrayTotal(_drop.royalties.saleBasisPoints, 10000);

    emit DropUpdated(_dropContract, _dropId);
    IPolyOneDrop(_dropContract).updateDrop(_dropId, _drop, _data);
  }

  function updateDropRoyalties(
    uint256 _dropId,
    address _dropContract,
    IPolyOneDrop.Royalties calldata _royalties
  ) external onlyRole(POLY_ONE_ADMIN_ROLE) nonReentrant {
    _validateDropContract(_dropContract);
    _validateRoyaltyReceivers(_royalties.royaltyReceivers, _royalties.royaltyBasisPoints, defaultSecondaryFee, secondaryFeeWallet);
    _validateRoyaltyReceivers(_royalties.saleReceivers, _royalties.saleBasisPoints, defaultPrimaryFee, primaryFeeWallet);
    PolyOneLibrary.validateArrayTotal(_royalties.saleBasisPoints, 10000);

    emit DropUpdated(_dropContract, _dropId);
    IPolyOneDrop(_dropContract).updateDropRoyalties(_dropId, _royalties);
  }

  function registerPurchaseIntent(
    uint256 _dropId,
    address _dropContract,
    uint256 _tokenIndex,
    bytes calldata _data,
    bool _useAsyncTransfer
  ) external payable nonReentrant {
    _validateDropContract(_dropContract);
    _refundPendingWithdrawals(payable(msg.sender));

    emit PurchaseIntentRegistered(_dropContract, _dropId, _tokenIndex, msg.sender, msg.value);

    (bool instantClaim, address collection, string memory tokenURI, IPolyOneDrop.Royalties memory royalties) = IPolyOneDrop(_dropContract)
      .registerPurchaseIntent(_dropId, _tokenIndex, msg.sender, msg.value, _data);

    if (instantClaim) {
      _claimToken(collection, _dropId, _tokenIndex, msg.sender, tokenURI, msg.value, royalties, _useAsyncTransfer);
    }
  }

  function claimToken(
    uint256 _dropId,
    address _dropContract,
    uint256 _tokenIndex,
    bytes calldata _data,
    bool _useAsyncTransfer
  ) external nonReentrant {
    _validateDropContract(_dropContract);

    (address collection, string memory tokenURI, IPolyOneDrop.Bid memory claim, IPolyOneDrop.Royalties memory royalties) = IPolyOneDrop(
      _dropContract
    ).validateTokenClaim(_dropId, _tokenIndex, msg.sender, _data);
    _claimToken(collection, _dropId, _tokenIndex, claim.bidder, tokenURI, claim.amount, royalties, _useAsyncTransfer);
  }

  function mintTokensERC721(
    address _collection,
    address _recipient,
    uint256 _qty,
    string calldata _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) nonReentrant {
    _validateCollectionRegistered(_collection);
    _validateCollectionType(_collection, true);
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);
    _validateRoyaltyReceivers(_royaltyReceivers, _royaltyBasisPoints, defaultSecondaryFee, secondaryFeeWallet);

    for (uint256 i = 1; i <= _qty; i++) {
      _mintTokenERC721(_collection, i, _recipient, _baseTokenURI, _royaltyReceivers, _royaltyBasisPoints);
    }
  }

  function mintTokensERC1155(
    address _collection,
    string[] calldata _tokenURIs,
    uint256[] calldata _tokenIds,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] calldata _receivers,
    uint256[] calldata _amounts,
    bool _existingTokens
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) nonReentrant {
    _validateCollectionRegistered(_collection);
    _validateCollectionType(_collection, false);
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);

    if (_existingTokens) {
      _mintTokensERC1155Existing(_collection, _tokenIds, _receivers, _amounts);
    } else {
      _validateRoyaltyReceivers(_royaltyReceivers, _royaltyBasisPoints, defaultSecondaryFee, secondaryFeeWallet);
      _mintTokensERC1155New(_collection, _tokenURIs, _royaltyReceivers, _royaltyBasisPoints, _receivers, _amounts);
    }
  }

  function callCollectionContract(address _collection, bytes calldata _data) external onlyRole(POLY_ONE_ADMIN_ROLE) nonReentrant {
    _validateCollectionRegistered(_collection);

    emit CollectionContractCalled(_collection, msg.sender, _data);

    (bool success, bytes memory responseData) = _collection.call(_data);
    if (!success) {
      revert CallCollectionFailed(responseData);
    }
  }

  function setPrimaryFeeWallet(address payable _feeWallet) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_feeWallet, "primary fee wallet");
    emit PrimaryFeeWalletUpdated(_feeWallet);
    primaryFeeWallet = _feeWallet;
  }

  function setSecondaryFeeWallet(address payable _feeWallet) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_feeWallet, "secondary fee wallet");
    emit SecondaryFeeWalletUpdated(_feeWallet);
    secondaryFeeWallet = _feeWallet;
  }

  function setDefaultPrimaryFee(uint16 _newFee) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    if (_newFee > MAX_PRIMARY_FEE) {
      revert InvalidPolyOneFee();
    }
    emit DefaultFeesUpdated(_newFee, defaultSecondaryFee);
    defaultPrimaryFee = _newFee;
  }

  function setDefaultSecondaryFee(uint16 _newFee) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    if (_newFee > MAX_SECONDARY_FEE) {
      revert InvalidPolyOneFee();
    }
    emit DefaultFeesUpdated(defaultPrimaryFee, _newFee);
    defaultSecondaryFee = _newFee;
  }

  function setBidExtensionTime(uint64 _newBidExtensionTime) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    emit BidExtensionTimeUpdated(_newBidExtensionTime);
    bidExtensionTime = _newBidExtensionTime;
  }

  function setRequestSigner(address _signer) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    emit RequestSignerUpdated(_signer);
    requestSigner = _signer;
  }

  function transferEth(address _destination, uint256 _amount) external onlyDropContract {
    PolyOneLibrary.checkZeroAddress(_destination, "destination");
    if (_amount == 0) {
      revert InvalidEthAmount();
    }

    _asyncTransfer(_destination, _amount);
  }

  /**
   * @dev Initiate a token claim
   * @param _collection The address of the token collection contract
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   * @param _recipient The recipient of the tokens
   * @param _tokenURI The base of the tokenURI to use for the newly minted token
   * @param _amount The value of the token purchase being claimed
   * @param _royalties The royalties data for initial sale distribution and secondary royalties
   * @param _useAsyncTransfer Whether to use async transfer or not
   */
  function _claimToken(
    address _collection,
    uint256 _dropId,
    uint256 _tokenIndex,
    address _recipient,
    string memory _tokenURI,
    uint256 _amount,
    IPolyOneDrop.Royalties memory _royalties,
    bool _useAsyncTransfer
  ) internal {
    _distributeFunds(_amount, _royalties.saleReceivers, _royalties.saleBasisPoints, _useAsyncTransfer);
    _validateCollectionRegistered(_collection);
    PolyOneLibrary.checkZeroAddress(_recipient, "recipient");

    if (collections[_collection].isERC721) {
      uint256 tokenId = _mintTokenERC721(
        _collection,
        _tokenIndex,
        _recipient,
        _tokenURI,
        _royalties.royaltyReceivers,
        _royalties.royaltyBasisPoints
      );
      emit TokenClaimed(_collection, tokenId, _dropId, _tokenIndex, _recipient);
    } else {
      uint256 tokenId = dropTokenIds[_dropId];

      if (tokenId == 0) {
        uint256 newTokenId = _mintTokensERC1155New(
          _collection,
          PolyOneLibrary.stringToStringArray(_tokenURI),
          _royalties.royaltyReceivers,
          _royalties.royaltyBasisPoints,
          PolyOneLibrary.addressToAddressArray(_recipient),
          PolyOneLibrary.uintToUintArray(1)
        )[0];
        dropTokenIds[_dropId] = newTokenId;
        emit TokenClaimed(_collection, newTokenId, _dropId, _tokenIndex, _recipient);
      } else {
        _mintTokensERC1155Existing(
          _collection,
          PolyOneLibrary.uintToUintArray(tokenId),
          PolyOneLibrary.addressToAddressArray(_recipient),
          PolyOneLibrary.uintToUintArray(1)
        );
        emit TokenClaimed(_collection, tokenId, _dropId, _tokenIndex, _recipient);
      }
    }
  }

  /**
   * @dev Mint a single ERC721 token to a recipient
   * @param _collection The address of the token collection contract
   * @param _tokenIndex The index of the token in the drop
   * @param _recipient The address of the recipient
   * @param _baseTokenURI The base URI of the token
   * @param _royaltyReceivers The addresses of the royalty receivers
   * @param _royaltyBasisPoints The royalty basis points for each receiver
   * @return The newly minted token ID
   */
  function _mintTokenERC721(
    address _collection,
    uint256 _tokenIndex,
    address _recipient,
    string memory _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) internal returns (uint256) {
    ERC721CreatorImplementation collection = ERC721CreatorImplementation(_collection);
    string memory tokenURI = string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenIndex)));
    uint256 tokenId = collection.mintBase(_recipient, tokenURI);
    collection.setRoyalties(tokenId, _royaltyReceivers, _royaltyBasisPoints);
    return tokenId;
  }

  /**
   * @dev Mint a batch of new ERC1155 tokens to recipients and set royalties
   * @param _collection The address of the token collection contract
   * @param _tokenURIs The base tokenURI for each new token to be minted
   * @param _royaltyReceivers The addresses of the royalty receivers
   * @param _royaltyBasisPoints The royalty basis points for each receiver
   * @param _recipients The address of the recipients
   * @param _amounts The amount of the token to mint to each recipient
   * @return The tokenIds of the newly minted tokens
   */
  function _mintTokensERC1155New(
    address _collection,
    string[] memory _tokenURIs,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) internal returns (uint256[] memory) {
    ERC1155CreatorImplementation collection = ERC1155CreatorImplementation(_collection);
    uint256[] memory tokenIds = collection.mintBaseNew(_recipients, _amounts, _tokenURIs);
    for (uint i = 0; i < tokenIds.length; i++) {
      collection.setRoyalties(tokenIds[i], _royaltyReceivers, _royaltyBasisPoints);
    }
    return tokenIds;
  }

  /**
   * @dev Mint a batch of new ERC1155 tokens with existing tokenIds to a batch of recipients
   * @param _collection The address of the token collection contract
   * @param _tokenIds The ids of the tokens to mint
   * @param _recipients The address of the recipients
   * @param _amounts The amount of the token to mint to each recipient
   * @return The tokenIds of the newly minted tokens
   */
  function _mintTokensERC1155Existing(
    address _collection,
    uint256[] memory _tokenIds,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) internal returns (uint256[] memory) {
    ERC1155CreatorImplementation collection = ERC1155CreatorImplementation(_collection);
    collection.mintBaseExisting(_recipients, _tokenIds, _amounts);
    return _tokenIds;
  }

  /**
   * @dev Distribute funds to the primary sale recipients
   *      Minimal leftover funds are sent to the first receiver
   * @param _amount The amount to distribute
   * @param _receivers The addresses of the receivers
   * @param _receiverBasisPoints The basis points for each receiver
   * @param _useAsyncTransfer Whether to use async transfer
   */
  function _distributeFunds(
    uint256 _amount,
    address payable[] memory _receivers,
    uint256[] memory _receiverBasisPoints,
    bool _useAsyncTransfer
  ) internal {
    uint256[] memory distributionAmounts = new uint256[](_receivers.length);
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < _receivers.length; i++) {
      distributionAmounts[i] = (_amount * _receiverBasisPoints[i]) / 10000;
      totalAmount += distributionAmounts[i];
    }

    uint256 leftover = _amount - totalAmount;
    if (leftover > 0) {
      distributionAmounts[0] += leftover;
    }

    for (uint256 i = 0; i < _receivers.length; i++) {
      if (_useAsyncTransfer || PolyOneLibrary.isContract(_receivers[i])) {
        _asyncTransfer(_receivers[i], distributionAmounts[i]);
      } else {
        (bool success, ) = _receivers[i].call{value: distributionAmounts[i]}("");
        if (!success) {
          revert EthTransferFailed(_receivers[i], distributionAmounts[i]);
        }
      }
    }
  }

  /**
   * @dev Refund the pending withdrawals for a caller who has placed a previous bid and had their bid returned
   * @param _receiver The address of the receiver
   */
  function _refundPendingWithdrawals(address payable _receiver) internal {
    if (payments(_receiver) > 0) {
      withdrawPayments(_receiver);
    }
  }

  /**
   * @dev Validate that a drop contract has already been registered
   * @param _dropContract The address of the drop contract
   */
  function _validateDropContract(address _dropContract) internal view {
    if (!dropContracts[_dropContract]) {
      revert DropContractNotRegistered(_dropContract);
    }
  }

  /**
   * @dev Validate that a token collection has already been registered
   * @param _collection The address of the collection
   */
  function _validateCollectionRegistered(address _collection) internal view {
    if (!collections[_collection].registered) {
      revert CollectionNotRegistered(_collection);
    }
  }

  /**
   * @dev Validate that a token collection is of the expected type (ERC721 or ERC1155)
   * @param _collection The address of the collection
   * @param _isERC721 Whether the collection is expected to be ERC721 (true) or ERC1155 (false)
   */
  function _validateCollectionType(address _collection, bool _isERC721) internal view {
    if (collections[_collection].isERC721 != _isERC721) {
      revert CollectionTypeMismatch(_collection);
    }
  }

  /**
   * @dev Validate that the secondary sale royalties are appriopriately formatted with PolyOne fees as the first item in each array
   * @param _royaltyReceivers The addresses of the royalty receivers (PolyOne fee wallet should be the first item in this array)
   * @param _royaltyBasisPoints The royalty basis points for each receiver (PolyOne fee should be the first item in this array)
   * @param _minimumFee The minimum fee that must be paid to PolyOne
   * @param _expectedFeeWallet The expected fee wallet address
   */
  function _validateRoyaltyReceivers(
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    uint16 _minimumFee,
    address payable _expectedFeeWallet
  ) internal pure {
    if (_royaltyReceivers.length != _royaltyBasisPoints.length) {
      revert InvalidRoyaltySettings();
    }
    if (_royaltyReceivers[0] != _expectedFeeWallet) {
      revert FeeWalletNotIncluded();
    }
    if (_royaltyBasisPoints[0] < _minimumFee) {
      revert InvalidPolyOneFee();
    }
  }

  /**
   * @dev Validate the signature for a register collection request
   * @param _collection The address of the collection
   * @param _isERC721 Whether the collection is expected to be ERC721 (true) or ERC1155 (false)
   * @param _signedRequest The signed request
   */
  function _validateRegisterCollectionRequest(address _collection, bool _isERC721, SignedRequest calldata _signedRequest) internal {
    if (usedSignatures[_signedRequest.signature]) {
      revert SignatureAlreadyUsed();
    }
    bytes32 message = keccak256(abi.encode(_collection, _isERC721, _signedRequest.timestamp)).toEthSignedMessageHash();
    if (message.recover(_signedRequest.signature) != requestSigner) {
      revert InvalidSignature();
    }
    usedSignatures[_signedRequest.signature] = true;
  }

  /**
   * @dev Validate the signature for a create drop request
   * @param _dropContract The address of the drop contract
   * @param _drop The drop data
   * @param _dropId The id of the drop (if it exists, else 0)
   * @param _signedRequest The signed request
   */
  function _validateDropRequest(
    address _dropContract,
    IPolyOneDrop.Drop calldata _drop,
    uint256 _dropId,
    SignedRequest calldata _signedRequest
  ) internal {
    if (usedSignatures[_signedRequest.signature]) {
      revert SignatureAlreadyUsed();
    }
    bytes32 message = keccak256(
      abi.encode(
        _dropId,
        _dropContract,
        _drop.startingPrice,
        _drop.bidIncrement,
        _drop.qty,
        _drop.startDate,
        _drop.dropLength,
        _drop.collection,
        _drop.baseTokenURI,
        _signedRequest.timestamp
      )
    ).toEthSignedMessageHash();
    if (message.recover(_signedRequest.signature) != requestSigner) {
      revert InvalidSignature();
    }
    usedSignatures[_signedRequest.signature] = true;
  }

  /**
   * @dev Functions with the onlyDropContract modifier attached should only be callable by a registered PolyOneDrop contract
   */
  modifier onlyDropContract() {
    if (!dropContracts[msg.sender]) {
      revert PolyOneLibrary.InvalidCaller(msg.sender);
    }
    _;
  }
}

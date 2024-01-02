//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract PaymentPROClonable is AccessControlUpgradeable {

  event StrictPaymentReceived(bytes32 indexed paymentReferenceHash, address indexed sender, address indexed tokenAddress, uint256 tokenAmount, string paymentReference);
  event OpenPaymentReceived(bytes32 indexed paymentReferenceHash, address indexed sender, address indexed tokenAddress, uint256 tokenAmount, string paymentReference);
  event DefaultPaymentReceived(bytes32 indexed paymentReferenceHash, address indexed sender, address indexed tokenAddress, uint256 tokenAmount, string paymentReference);
  event TokenSwept(address indexed recipient, address indexed sweeper, address indexed tokenAddress, uint256 tokenAmount);
  event PaymentReferenceCreated(bytes32 indexed paymentReferenceHash, string paymentReference, StrictPayment referencedPaymentEntry);
  event PaymentReferenceDeleted(bytes32 indexed paymentReferenceHash, string paymentReference);
  event DefaultPaymentConfigAdjusted(address indexed tokenAddress, uint256 tokenAmount);
  event ApprovedPaymentToken(address indexed tokenAddress);
  event ApprovedSweepingToken(address indexed tokenAddress);
  event ApprovedTokenSweepRecipient(address indexed recipientAddress);
  event UnapprovedPaymentToken(address indexed tokenAddress);
  event UnapprovedSweepingToken(address indexed tokenAddress);
  event UnapprovedTokenSweepRecipient(address indexed recipientAddress);

  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE"); // can manage approvedPaymentTokens / approvedSweepingTokens / approvedSweepRecipients -> 0x408a36151f841709116a4e8aca4e0202874f7f54687dcb863b1ea4672dc9d8cf
  bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE"); // can sweep tokens -> 0x8aef0597c0be1e090afba1f387ee99f604b5d975ccbed6215cdf146ffd5c49fc
  bytes32 public constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE"); // can manage default payment configs / strict payments -> 0xa624ddbc4fb31a463e13e6620d62eeaf14248f89110a7fda32b4048499c999a6

  struct DefaultPaymentConfig {
    address tokenAddress;
    uint256 tokenAmount;
  }

  struct StrictPayment {
    string paymentReference;
    bytes32 paymentReferenceHash;
    address tokenAddress;
    uint256 tokenAmount;
    address payer;
    bool enforcePayer;
    bool complete;
    bool exists;
  }

  mapping (bytes32 => StrictPayment) internal strictPayments;
  mapping (bytes32 => bool) internal referenceReservations;
  mapping (address => bool) internal approvedPaymentTokens;
  mapping (address => bool) internal approvedSweepingTokens;
  mapping (address => bool) internal approvedSweepRecipients;

  DefaultPaymentConfig public defaultPaymentConfig;

  bool public isInitialized;

  function initializeContract(
    address _roleAdmin,
    address _approvedPaymentToken,
    address _approvedSweepingToken,
    address _approvedTokenSweepRecipient,
    uint256 _defaultTokenAmount
  ) external {
    require(!isInitialized, "ALREADY_INITIALIZED");
    require(_roleAdmin != address(0), "NO_ZERO_ADDRESS");
    require(_approvedPaymentToken != address(0), "NO_ZERO_ADDRESS");
    require(_approvedSweepingToken != address(0), "NO_ZERO_ADDRESS");
    require(_approvedTokenSweepRecipient != address(0), "NO_ZERO_ADDRESS");
    require(_defaultTokenAmount > 0, "NO_ZERO_AMOUNT");
    isInitialized = true;
    _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
    _setupRole(APPROVER_ROLE, _roleAdmin);
    _setupRole(SWEEPER_ROLE, _roleAdmin);
    _setupRole(PAYMENT_MANAGER_ROLE, _roleAdmin);
    approvedPaymentTokens[_approvedPaymentToken] = true;
    emit ApprovedPaymentToken(_approvedPaymentToken);
    approvedSweepingTokens[_approvedSweepingToken] = true;
    emit ApprovedSweepingToken(_approvedPaymentToken);
    approvedSweepRecipients[_approvedTokenSweepRecipient] = true;
    emit ApprovedTokenSweepRecipient(_approvedTokenSweepRecipient);
    defaultPaymentConfig = DefaultPaymentConfig(_approvedSweepingToken, _defaultTokenAmount);
    emit DefaultPaymentConfigAdjusted(_approvedSweepingToken, _defaultTokenAmount);
  }

  // ROLE MODIFIERS

  modifier onlyApprover() {
    require(hasRole(APPROVER_ROLE, msg.sender), "NOT_APPROVER");
    _;
  }

  modifier onlyPaymentManager() {
    require(hasRole(PAYMENT_MANAGER_ROLE, msg.sender), "NOT_PAYMENT_MANAGER");
    _;
  }

  modifier onlySweeper() {
    require(hasRole(SWEEPER_ROLE, msg.sender), "NOT_SWEEPER");
    _;
  }

  // ADMIN FUNCTIONS

  function setApprovedPaymentToken(address _tokenAddress, bool _validity) external onlyApprover {
    require(_tokenAddress != address(0), "NO_ZERO_ADDRESS");
    require(_validity != approvedPaymentTokens[_tokenAddress], "NO_CHANGE");
    approvedPaymentTokens[_tokenAddress] = _validity;
    if(_validity) {
      emit ApprovedPaymentToken(_tokenAddress);
    } else {
      emit UnapprovedPaymentToken(_tokenAddress);
    }
  }

  function setApprovedSweepingToken(address _tokenAddress, bool _validity) external onlyApprover {
    require(_tokenAddress != address(0), "NO_ZERO_ADDRESS");
    require(_validity != approvedSweepingTokens[_tokenAddress], "NO_CHANGE");
    approvedSweepingTokens[_tokenAddress] = _validity;
    if(_validity) {
      emit ApprovedSweepingToken(_tokenAddress);
    } else {
      emit UnapprovedSweepingToken(_tokenAddress);
    }
  }

  function setApprovedSweepRecipient(address _recipientAddress, bool _validity) external onlyApprover {
    require(_recipientAddress != address(0), "NO_ZERO_ADDRESS");
    require(_validity != approvedSweepRecipients[_recipientAddress], "NO_CHANGE");
    approvedSweepRecipients[_recipientAddress] = _validity;
    if(_validity) {
      emit ApprovedTokenSweepRecipient(_recipientAddress);
    } else {
      emit UnapprovedTokenSweepRecipient(_recipientAddress);
    }
  }

  // PAYMENT MANAGEMENT FUNCTIONS

  function createStrictPayment(
    string memory _reference,
    address _tokenAddress,
    uint256 _tokenAmount,
    address _payer,
    bool _enforcePayer
  ) external onlyPaymentManager {
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    require(!referenceReservations[_hashedReference], "REFERENCE_ALREADY_RESERVED");
    require(approvedPaymentTokens[_tokenAddress], "NOT_APPROVED_TOKEN_ADDRESS");
    require(_tokenAmount > 0, "NO_ZERO_AMOUNT");
    referenceReservations[_hashedReference] = true;
    StrictPayment memory newStrictPaymentEntry = StrictPayment(
      _reference,
      _hashedReference,
      _tokenAddress,
      _tokenAmount,
      _payer,
      _enforcePayer,
      false,
      true
    );
    strictPayments[_hashedReference] = newStrictPaymentEntry;
    emit PaymentReferenceCreated(_hashedReference, _reference, newStrictPaymentEntry);
  }

  function deleteStrictPayment(
    string memory _reference
  ) external onlyPaymentManager {
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    require(referenceReservations[_hashedReference], "REFERENCE_NOT_RESERVED");
    require(strictPayments[_hashedReference].complete == false, "PAYMENT_ALREADY_COMPLETE");
    referenceReservations[_hashedReference] = false;
    strictPayments[_hashedReference].exists = false;
    emit PaymentReferenceDeleted(_hashedReference, _reference);
  }

  function setDefaultPaymentConfig(address _tokenAddress, uint256 _tokenAmount) external onlyPaymentManager {
    require(approvedPaymentTokens[_tokenAddress], "NOT_APPROVED_TOKEN_ADDRESS");
    require(_tokenAmount > 0, "NO_ZERO_AMOUNT");
    defaultPaymentConfig = DefaultPaymentConfig(_tokenAddress, _tokenAmount);
    emit DefaultPaymentConfigAdjusted(_tokenAddress, _tokenAmount);
  }

  // SWEEPING / WITHDRAWAL FUNCTIONS

  function sweepTokenByFullBalance(
    address _tokenAddress,
    address _recipientAddress
  ) external onlySweeper {
    require(approvedPaymentTokens[_tokenAddress], "NOT_APPROVED_TOKEN_ADDRESS");
    require(approvedSweepRecipients[_recipientAddress], "NOT_APPROVED_RECIPIENT");
    IERC20Upgradeable _tokenContract = IERC20Upgradeable(_tokenAddress);
    uint256 _tokenBalance = _tokenContract.balanceOf(address(this));
    require(_tokenBalance > 0, "NO_BALANCE");
    _tokenContract.transfer(_recipientAddress, _tokenBalance);
    emit TokenSwept(_recipientAddress, msg.sender, _tokenAddress, _tokenBalance);
  }

  function sweepTokenByAmount(
    address _tokenAddress,
    address _recipientAddress,
    uint256 _tokenAmount
  ) external onlySweeper {
    require(approvedPaymentTokens[_tokenAddress], "NOT_APPROVED_TOKEN_ADDRESS");
    require(approvedSweepRecipients[_recipientAddress], "NOT_APPROVED_RECIPIENT");
    require(_tokenAmount > 0, "NO_ZERO_AMOUNT");
    IERC20Upgradeable _tokenContract = IERC20Upgradeable(_tokenAddress);
    uint256 _tokenBalance = _tokenContract.balanceOf(address(this));
    require(_tokenBalance >= _tokenAmount, "INSUFFICIENT_BALANCE");
    _tokenContract.transfer(_recipientAddress, _tokenAmount);
    emit TokenSwept(_recipientAddress, msg.sender, _tokenAddress, _tokenAmount);
  }

  // PAYMENT FUNCTIONS

  function makeOpenPayment(
    address _tokenAddress,
    uint256 _tokenAmount,
    string memory _reference
  ) external {
    require(approvedPaymentTokens[_tokenAddress], "NOT_APPROVED_TOKEN");
    require(_tokenAmount > 0, "NO_ZERO_AMOUNT");
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    require(!referenceReservations[_hashedReference], "REFERENCE_RESERVED");
    IERC20Upgradeable(_tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
    emit OpenPaymentReceived(_hashedReference, msg.sender, _tokenAddress, _tokenAmount, _reference);
  }

  function makeDefaultPayment(
    string memory _reference
  ) external {
    require(approvedPaymentTokens[defaultPaymentConfig.tokenAddress], "NOT_APPROVED_TOKEN");
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    require(!referenceReservations[_hashedReference], "REFERENCE_RESERVED");
    IERC20Upgradeable(defaultPaymentConfig.tokenAddress).transferFrom(msg.sender, address(this), defaultPaymentConfig.tokenAmount);
    emit DefaultPaymentReceived(_hashedReference, msg.sender, defaultPaymentConfig.tokenAddress, defaultPaymentConfig.tokenAmount, _reference);
  }

  function makeStrictPayment(
    string memory _reference
  ) external {
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    require(referenceReservations[_hashedReference], "REFERENCE_NOT_RESERVED");
    StrictPayment storage strictPayment = strictPayments[_hashedReference];
    require(approvedPaymentTokens[strictPayment.tokenAddress], "NOT_APPROVED_TOKEN");
    if(strictPayment.enforcePayer) {
      require(strictPayment.payer == msg.sender, "PAYER_MISMATCH");
    }
    strictPayment.complete = true;
    IERC20Upgradeable(strictPayment.tokenAddress).transferFrom(msg.sender, address(this), strictPayment.tokenAmount);
    emit StrictPaymentReceived(_hashedReference, msg.sender, strictPayment.tokenAddress, strictPayment.tokenAmount, _reference);
  }

  // VIEWS

  function viewStrictPaymentByStringReference(
    string memory _reference
  ) external view returns (StrictPayment memory) {
    bytes32 _hashedReference = keccak256(abi.encodePacked(_reference));
    return strictPayments[_hashedReference];
  }

  function viewStrictPaymentByHashedReference(
    bytes32 _hashedReference
  ) external view returns (StrictPayment memory) {
    return strictPayments[_hashedReference];
  }

}
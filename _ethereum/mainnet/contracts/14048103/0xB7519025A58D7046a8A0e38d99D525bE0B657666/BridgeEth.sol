// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.9;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract BridgeEth is Initializable, UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant MAPPER_ROLE = keccak256("MAPPER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  string public constant name = "ETH-EKTA Bridge";
  mapping(address => address) public EthEktaPairs; //ETH Token => EKTA Token
  mapping(address => address) public EktaEthPairs; //EKTA Token => ETH Token
  mapping(address => mapping(uint => bool)) public processedNonces;

  address public admin;
  address public tokenToSwapWithNative;

  event AddedTokenPair(address indexed ethToken, address indexed ektaToken);
  event UpdatedTokenPair(address indexed ethToken, address indexed ektaToken);
  event TokenDeposited(address indexed ethToken, address indexed ektaToken, uint256 amount, address indexed user);
  event TokenWithdrawn(address indexed ethToken, address indexed ektaToken, uint256 amount, address indexed user);
  event DepositedTokenToNative(address indexed ethToken, uint256 amount, address indexed user);
  event WithdrawnNativeToToken(address indexed ethToken, uint256 amount, address indexed user);
  event TokenFromContractTransferred(address externalAddress,address toAddress, uint amount);
  event EthFromContractTransferred(address toAddress, uint amount);
  event AdminAddressUpdated(address admin);
  event TokenToSwapWithNativeUpdated(address token);

  /**
   * @dev Initializes the contract.
   *
   * Requirements:
   * - @param _owner cannot be the zero address.
   * - @param _tokenToSwapWithNative cannot be the zero address.
   */
  function initialize(address _owner, address _tokenToSwapWithNative) public initializer {
    require(_owner != address(0), "Bridge: Address cant be zero address");
    require(_tokenToSwapWithNative != address(0), "Bridge: Token address cant be zero address");
    
    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    _setupRole(MAPPER_ROLE, _owner);
    _setupRole(PAUSER_ROLE, _owner);
    
    admin = msg.sender;
    tokenToSwapWithNative = _tokenToSwapWithNative;

    // initializing
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();
    __Ownable_init_unchained();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  /**
   * @dev Creates a pair for eth and ekta token by the caller with MAPPER_ROLE.
   *
   * Requirements:
   * - @param _ethToken cannot be the zero address.
   * - @param _ektaToken cannot be the zero address.
   * 
   * @return A boolean value indicating whether the operation succeeded.
   * 
   * Emits a {AddedTokenPair} event indicating the paired token addresses.
   */
  function addTokenPairs(address _ethToken, address _ektaToken) external onlyRole(MAPPER_ROLE) nonReentrant whenNotPaused returns(bool) {
    require(EthEktaPairs[_ethToken] == address(0) && EktaEthPairs[_ektaToken] == address(0), "Bridge: Already mapped");

    _mapToken(_ethToken, _ektaToken);
    emit AddedTokenPair(_ethToken, _ektaToken);
    return true;
  }

  /**
   * @dev Updates the ekta pair address for eth token by the caller with MAPPER_ROLE
   *
   * Requirements:
   * - @param _ethToken cannot be the zero address.
   * - @param _ektaToken cannot be the zero address.
   * 
   * @return A boolean value indicating whether the operation succeeded
   * 
   * Emits a {UpdatedTokenPair} event indicating the paired token addresses
   */
  function updateTokenPairs(address _ethToken, address _ektaToken) external onlyRole(MAPPER_ROLE) nonReentrant whenNotPaused returns(bool) {
    require(EthEktaPairs[_ethToken] != _ektaToken, "Bridge: Pair already exists");
    require(EthEktaPairs[_ethToken] != address(0), "Bridge: Pair dont exists");

    // clean token pairs to avoid re-mapping
    cleanTokenPairs(_ethToken);

    _mapToken(_ethToken, _ektaToken);
    emit UpdatedTokenPair(_ethToken, _ektaToken);
    return true;
  }

  /**
   * @dev Clears the eth and ekta pair address to avoid re-mapping by the caller with MAPPER_ROLE
   *
   * Requirements:
   * - @param _ethToken cant be zero address
   * 
   * @return A boolean value indicating whether the operation succeeded
   */
  function cleanTokenPairs(address _ethToken) public onlyRole(MAPPER_ROLE) whenNotPaused returns(bool) {
    require(_ethToken != address(0), "Bridge: Token address cant be zero address");
    require(EthEktaPairs[_ethToken] != address(0), "Bridge: Pair dont exists");

    address _ektaToken = EthEktaPairs[_ethToken];
    EthEktaPairs[_ethToken] = address(0);
    EktaEthPairs[_ektaToken] = address(0);
    return true;
  }

  /**
   * @dev Internal function to map tokens
   *
   * Requirements:
   * - @param _ethToken cannot be the zero address.
   * - @param _ektaToken cannot be the zero address.
   */
  function _mapToken(address _ethToken, address _ektaToken) internal {
    require(_ethToken != address(0) && _ektaToken != address(0), "Bridge: Token address cant be zero address");

    // update EthEktaPairs and EktaEthPairs mapping
    EthEktaPairs[_ethToken] = _ektaToken;
    EktaEthPairs[_ektaToken] = _ethToken;
  }

  /**
   * @dev Move token amount from caller to contract address.
   *
   * Requirements:
   * - @param _ethToken cannot be the zero address.
   * - @param amount should be greater than 0.
   * 
   * @return A boolean value indicating whether the operation succeeded.
   * 
   * Emits a {TokenDeposited} event.
   */
  function deposit(address _ethToken, uint256 amount) external nonReentrant whenNotPaused returns(bool) {
    require(_ethToken != address(0), "Bridge: Token cant be zero address");
    require(EthEktaPairs[_ethToken] != address(0), "Bridge: Token not paired");
    require(amount > 0, "Bridge: Amount cant be zero or negative numbers");

    // transfer token to contract address
    IERC20Upgradeable(_ethToken).safeTransferFrom(msg.sender, address(this), amount);
    
    address ektaToken = EthEktaPairs[_ethToken];
    emit TokenDeposited(_ethToken, ektaToken, amount, msg.sender);
    return true;
  }

  /**
   * @dev Move token amount from contract address to user
   * after successful verification of signature and nonce.
   *
   * Requirements:
   * - @param _ethToken cannot be the zero address.
   * - @param _ektaToken cannot be the zero address.
   * - @param user cannot be the zero address.
   * - @param amount should be greater than 0.
   * - @param nonce.
   * - @param signature.
   * 
   * @return A boolean value indicating whether the operation succeeded.
   * 
   * Emits a {TokenWithdrawn} event.
   */
  function withdraw(address _ethToken, address _ektaToken, address user, uint256 amount, uint256 nonce, bytes calldata signature) external nonReentrant whenNotPaused returns(bool) {
    require(_ethToken != address(0), "Bridge: Token cant be zero address");
    require(_ektaToken != address(0), "Bridge: Token cant be zero address");
    require(EthEktaPairs[_ethToken] == _ektaToken, "Bridge: Token pair does not exist");
    require(amount > 0, "Bridge: Amount cant be zero or negative numbers");
    // check for nonce
    require(!processedNonces[user][nonce], 'Bridge: Transfer already processed');
    // verify signature
    require(_verify(abi.encodePacked(user, amount, nonce, "ETH_WITHDRAW", _ethToken, _ektaToken), signature), "Bridge: Invalid signature");

    // transfer token from contract address to user
    IERC20Upgradeable(_ethToken).safeTransfer(user, amount);

    // update nonce
    processedNonces[user][nonce] = true;

    address ektaToken = EthEktaPairs[_ethToken];
    emit TokenWithdrawn(_ethToken, ektaToken, amount, user);
    return true;
  }

  /**
   * @dev Move `tokenToSwapWithNative` token amount from caller to contract address
   *
   * Requirements:
   * - @param amount should be greater than 0.
   * 
   * @return A boolean value indicating whether the operation succeeded.
   * 
   * Emits a {DepositedTokenToNative} event.
   */
  function depositTokenToNative(uint256 amount) external nonReentrant whenNotPaused returns(bool) {
    require(amount > 0, "Bridge: Amount cant be zero or negative numbers");

    // transfer token to contract address
    IERC20Upgradeable(tokenToSwapWithNative).safeTransferFrom(msg.sender, address(this), amount);
    
    emit DepositedTokenToNative(tokenToSwapWithNative, amount, msg.sender);
    return true;
  }

  /**
   * @dev Move `tokenToSwapWithNative` token amount from contract address to user
   *
   * Requirements:
   * - @param user cannot be the zero address.
   * - @param amount should be greater than 0.
   * - @param nonce.
   * - @param signature.
   * 
   * @return A boolean value indicating whether the operation succeeded.
   * 
   * Emits a {WithdrawnNativeToToken} event.
   */
  function withdrawNativeToToken(address user, uint256 amount, uint256 nonce, bytes calldata signature) external nonReentrant whenNotPaused returns(bool) {
    require(amount > 0, "Bridge: Amount cant be zero or negative numbers");
    // check for nonce
    require(!processedNonces[user][nonce], 'Bridge: Transfer already processed');
    // verify signature
    require(_verify(abi.encodePacked(user, amount, nonce, "ETH_NATIVE_WITHDRAW"), signature), "Bridge: Invalid signature");

    // transfer token from contract address to user
    IERC20Upgradeable(tokenToSwapWithNative).safeTransfer(user, amount);

    // update nonce
    processedNonces[user][nonce] = true;
    
    emit WithdrawnNativeToToken(tokenToSwapWithNative, amount, user);
    return true;
  }

  /**
   * @dev Update the admin address used for signature verification
   * by caller with DEFAULT_ADMIN_ROLE.
   *
   * Requirements:
   * - @param _admin cannot be the zero address.
   * 
   * Emits a {AdminAddressUpdated} event indicating the updated admin address.
   */
  function updateAdminAddress(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_admin != address(0), "Bridge: Admin address cant be zero address");
    admin = _admin;
    emit AdminAddressUpdated(admin);
  }

  /**
   * @dev Update the token address used for swapping with native
   * by caller with DEFAULT_ADMIN_ROLE.
   *
   * Requirements:
   * - @param token cannot be the zero address.
   * 
   * Emits a {TokenToSwapWithNativeUpdated} event indicating the updated token address.
   */
  function updateTokenToSwapWithNative(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(token != address(0), "Bridge: Token address cant be zero address");
    tokenToSwapWithNative = token;
    emit TokenToSwapWithNativeUpdated(tokenToSwapWithNative);
  }

  /**
   * @dev Pause the contract (stopped state)
   * by caller with PAUSER_ROLE.
   *
   * Requirements:
   * - The contract must not be paused.
   * 
   * Emits a {Paused} event.
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpause the contract (normal state)
   * by caller with PAUSER_ROLE.
   *
   * Requirements:
   * - The contract must be paused.
   * 
   * Emits a {Unpaused} event.
   */
  function unpause() external onlyRole(PAUSER_ROLE){
    _unpause();
  }

  /**
   * @dev Recover the amount of particular token from the contract address
   * by caller with DEFAULT_ADMIN_ROLE.
   *
   * Requirements:
   * - @param _tokenContract cannot be the zero address.
   * - @param amount should be greater than 0.
   * 
   * Emits a {TokenFromContractTransferred} event indicating the token address and amount.
   */
  function withdrawERC20Token(address _tokenContract, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_tokenContract != address(0), "Bridge: Address cant be zero address");
    IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
    require(amount <= tokenContract.balanceOf(address(this)), "Bridge: Amount exceeds balance");
		tokenContract.transfer(msg.sender, amount);
    emit TokenFromContractTransferred(_tokenContract, msg.sender, amount);
	}

  // to recieve ETH
  receive() external payable {}

  /**
   * @dev Recover ETH from the contract address
   * by caller with DEFAULT_ADMIN_ROLE.
   *
   * Requirements:
   * - @param user cannot be the zero address.
   * - @param amount cannot be greater than balance.
   * 
   * Emits a {EthFromContractTransferred} event.
   */
  function withdrawEthFromContract(address user, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(user != address(0), "Bridge: Address cant be zero address");
    require(amount <= address(this).balance, "Bridge: Amount exceeds balance");
    address payable _user = payable(user);
    (bool success, ) = _user.call{value: amount}("");
    require(success, "Bridge: Transfer failed.");
    emit EthFromContractTransferred(user, amount);
  }

  /**
   * @dev Internal function to verify the signature.
   *
   * Requirements:
   * - @param data encoded bytes of signature params.
   * - @param signature.
   */
  function _verify(bytes memory data, bytes calldata signature) view internal returns (bool) {
    return keccak256(data)
      .toEthSignedMessageHash()
      .recover(signature) == admin;
  }
}
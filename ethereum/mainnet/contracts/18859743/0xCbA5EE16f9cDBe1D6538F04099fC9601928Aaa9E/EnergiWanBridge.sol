// Copyright 2023 Energi Core

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.8.20;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IEnergiWmbApp.sol";

contract EnergiWanBridge is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;

  // struct for token with token information
  struct Token {
    address tokenAddress; // address of token in source chain
    bool isBlacklisted; // whether token is supported or not
    uint256 minAmount; // minimum amount of token to bridge
  }

  // struct for vault where all locked tokens are stored
  struct Vault {
    uint256 vaultId; // id for vault
    address tokenAddress; // token address to receive by user
    uint256 amount; // amount user have transfered
    address from; // from address who send's the token
    address to; // to address who receives the token
    uint256 time; // time when token depositd from source chain to destination chain
    bool isClaimed; // whether user have claimed his/her tokens
    uint256 claimTime;
    uint256 fromChainId;
  }

  uint256 private tokenLockPeriod; // lock period of tokens
  uint256 private vaultIds; // total vaults

  address private energiWmbAppAddress; // address for EnergiWmbApp contract
  address private multiSig; // multi sig wallet address

  mapping(address => uint256) private totalVaultsOfAddress;
  mapping(address => Token) private tokens; // all tokens mapping
  mapping(uint256 => bool) private supportedChainIds; // mapping for all supported chains
  mapping(address => mapping(uint256 => Vault)) private vaults; // mapping for vaults
  mapping(address => uint256) private tokensLocked; // mapping for locked tokens
  mapping(address => uint256) private tokensLockLimit; // mapping for tokens which should be locked, rest will be transfferd to multi sig

  function initialize(address energiWmbAppAddress_, address multiSig_) external initializer {
    __Pausable_init();
    __ReentrancyGuard_init();
    __Ownable_init();

    tokenLockPeriod = 5 minutes;
    vaultIds = 0;
    energiWmbAppAddress = energiWmbAppAddress_;
    multiSig = multiSig_;
  }

  /*
  MODIFIERS
  */

  // check whether given address is zero address
  modifier isNotZeroAddress(address _address) {
    require(_address != address(0), 'EnergiWanBridge:: Address is zero address');
    _;
  }

  // access modifier can only be called by EnergiWmbApp
  modifier onlyEnergiWmbApp() {
    require(
      _msgSender() == energiWmbAppAddress,
      'EnergiWanBridge:: Only EnergiWmbAppAddress can call this function'
    );
    _;
  }

  // validates the cretiria to deposit token on source chain
  modifier validateDeposit(
    address _address,
    uint256 _amount,
    address _to,
    uint256 _chainId
  ) {
    require(tokens[_address].isBlacklisted == false, 'EnergiWanBridge:: Token is blacklisted');
    require(tokens[_address].tokenAddress != address(0), 'EnergiWanBrdige:: Unsupported Token');
    require(
      _amount >= tokens[_address].minAmount,
      'EnergiWanBridge:: Amount must be greater than minimum amount'
    );
    require(_to != address(0), 'EnergiBridge:: To cannot be address zero');
    require(
      supportedChainIds[_chainId] == true,
      'EnergiWanBridge:: Destination chain is not supported'
    );
    IERC20 token = IERC20(_address);
    require(
      token.balanceOf(_msgSender()) >= _amount,
      'EnergiWanBridge:: Cannot deposit less than balance of token'
    );
    _;
  }

  modifier onlyMultiSig() {
    require(msg.sender == multiSig, 'EnergiWanBridge:: Must be multisig wallet');
    _;
  }

  /*
    EVENTS
    */
  event TokenLockPeriodUpdated(uint256 oldTokenLockPeriod, uint256 newTokenLockPeriod);

  event TokenLockLimitUpdated(address tokenAddress, uint256 oldLimit, uint256 amount);

  event NewTokenAdded(address tokenAddress, bool isBlacklisted, uint256 minAmount);

  event TokenDeposited(
    address tokenAddress,
    uint256 toChainId,
    address from,
    address to,
    uint256 amount
  );

  event TokenReceived(
    address tokenAddress,
    uint256 chainId,
    address from,
    address to,
    uint256 amount
  );

  event TokenWithdrawn(address tokenAddress, address from, address to, uint256 amount);

  event EnergiWmbAppUpdated(address oldEnergiWmbApp, address newEnergiWmbApp);

  event MultiSigUpdated(address oldMultiSig, address newMultiSig);

  event MinAmountUpdated(address tokenAddress, uint256 oldMinAmount, uint256 newMinAmount);

  /*
    VIEW FUNCTIONS
    */

  // gives EnergiWmbApp address
  function getEnergiWmbApp() public view returns (address) {
    return energiWmbAppAddress;
  }

  function getDepositLimitOfToken(address _tokenAddress) public view returns (uint256) {
    return tokensLockLimit[_tokenAddress];
  }

  function getMultiSigWallet() public view returns (address) {
    return multiSig;
  }

  function getTokenLockLimit(address _tokenAddress) public view returns (uint256) {
    return tokensLockLimit[_tokenAddress];
  }

  function getTotalVaults(address _to) public view returns (uint256) {
    return totalVaultsOfAddress[_to];
  }

  // returns the total vaults
  function getVaultIds() public view returns (uint256) {
    return vaultIds;
  }

  // returns the total locked tokens
  function getLockedTokens(address _tokenAddress) public view returns (uint256) {
    return tokensLocked[_tokenAddress];
  }

  // return amount of tokens available to bridge
  function getTokenForBridge(address _tokenAddress) public view returns (uint256) {
    uint256 lockedTokens = tokensLocked[_tokenAddress];
    IERC20 token = IERC20(_tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    if (balance >= lockedTokens) {
      return balance - lockedTokens;
    } else {
      return 0;
    }
  }

  // returns every information of token
  // take token address as a paramater
  function getToken(
    address _tokenAddress
  ) public view isNotZeroAddress(_tokenAddress) returns (Token memory token) {
    return tokens[_tokenAddress];
  }

  // return vault details
  // take vault id as a parameter
  function getVault(uint256 _vaultId, address _receiver) public view returns (Vault memory vault) {
    return vaults[_receiver][_vaultId];
  }

  // return token lock period
  function getTokenLockPeriod() public view returns (uint256) {
    return tokenLockPeriod;
  }

  // returns if chain id is supported or not, takes chain id as input
  function getChainIdIsSupported(uint256 _chainId) public view returns (bool) {
    return supportedChainIds[_chainId];
  }

  // returns whether tokens is blacklisted or not
  // takes address as a parameter
  function getIsTokenBlacklisted(
    address _tokenAddress
  ) public view isNotZeroAddress(_tokenAddress) returns (bool) {
    return tokens[_tokenAddress].isBlacklisted;
  }

  /*
    PUBLIC FUNCTIONS
    */

  // function for deposit tokens to source chain
  // _tokenAddress - address of token on source chain
  // _amount - amount of tokens to be deposit
  // _to - receiver address on desination chain
  // _chainId - destination chain id
  // function is only callable when contract is not paused or unpaused
  function deposit(
    address _tokenAddress, //source token address
    uint256 _amount,
    address _to,
    uint256 _chainId,
    uint256 _gasLimit
  )
    public
    payable
    whenNotPaused
    nonReentrant
    validateDeposit(_tokenAddress, _amount, _to, _chainId)
  {
    uint256 fee = _getEstimatedFee(_chainId, _gasLimit);
    require(msg.value >= fee, 'EnergiWanBridge:: Insufficient fee provided');
    _transferFee(fee);
    _transferTokens(_tokenAddress, _amount);
    _sendMessage(_msgSender(), _to, _amount, _tokenAddress, _chainId, _gasLimit);

    emit TokenDeposited(_tokenAddress, _chainId, _msgSender(), _to, _amount);
  }

  // functions takes  instruction only from EnergiWmbApp contract,
  //if this function is called it signifies tokens are succesfully received on source chain
  // _from - address of sender from source chain
  // _to - address of receiver on destination chain
  // _tokenAddress - address of token on destination chain
  // _chainId - source chainId
  // can only be called when contract is not paused
  function receiveTokens(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId
  ) public whenNotPaused nonReentrant onlyEnergiWmbApp {
    vaultIds = vaultIds + 1;
    totalVaultsOfAddress[_to] = totalVaultsOfAddress[_to] + 1;

    IERC20 token = IERC20(_tokenAddress);

    uint256 tokensAvailableForBridge = getTokenForBridge(_tokenAddress);
    uint256 balanceOfMultiSig = token.balanceOf(multiSig);

    require(_tokenAddress != address(0), 'EnergiWanBridge:: Token address cannot be zero address');
    require(
      tokensAvailableForBridge + balanceOfMultiSig >= _amount,
      'EnergiWanBridge:: Token balance is not sufficent to bridge'
    );

    Vault memory vault = Vault(
      totalVaultsOfAddress[_to],
      _tokenAddress,
      _amount,
      _from,
      _to,
      _currentTime(),
      false,
      _currentTime() + tokenLockPeriod,
      _chainId
    );

    vaults[_to][totalVaultsOfAddress[_to]] = vault;
    tokensLocked[_tokenAddress] = tokensLocked[_tokenAddress] + _amount;
    emit TokenReceived(_tokenAddress, _chainId, _from, _to, _amount);
  }

  // function responsible to get locked tokens after lock period is over
  // only be called by receiver of the vault
  // _vaultId - id of vault which user want to get his/her tokens
  function withdrawTokens(uint256 _vaultId, address _receiver) public whenNotPaused nonReentrant {
    require(
      vaults[_receiver][_vaultId].to == _msgSender(),
      'EnergiWanBridge:: You do not have access to vault'
    );

    require(
      _currentTime() >= vaults[_receiver][_vaultId].time + tokenLockPeriod,
      'EnergiWanBridge:: Cannot access funds during lock period'
    );

    require(
      vaults[_receiver][_vaultId].isClaimed == false,
      'EnergiWanBridge:: You have already claimed it'
    );

    vaults[_receiver][_vaultId].isClaimed = true;

    // Subsctract tokens from locked tokens
    tokensLocked[vaults[_receiver][_vaultId].tokenAddress] =
      tokensLocked[vaults[_receiver][_vaultId].tokenAddress] -
      vaults[_receiver][_vaultId].amount;

    IERC20 token = IERC20(vaults[_receiver][_vaultId].tokenAddress);
    token.approve(_msgSender(), vaults[_receiver][_vaultId].amount);
    token.safeTransfer(_msgSender(), vaults[_receiver][_vaultId].amount);

    emit TokenWithdrawn(
      vaults[_receiver][_vaultId].tokenAddress,
      vaults[_receiver][_vaultId].from,
      vaults[_receiver][_vaultId].to,
      vaults[_receiver][_vaultId].amount
    );
  }

  /*
    ONLY OWNER FUNCTIONS
    */

  // updates the lock period for tokens
  // _newTokenLockPeriod - new period for lock
  // can only be called by owner of smart contract
  function updateTokenLockPeriod(uint256 _newTokenLockPeriod) external onlyOwner {
    uint256 oldTokenLockPeriod = tokenLockPeriod;
    tokenLockPeriod = _newTokenLockPeriod;

    emit TokenLockPeriodUpdated(oldTokenLockPeriod, _newTokenLockPeriod);
  }

  function updateMultiSig(address _newMultiSig) external onlyOwner {
    address oldMultiSig = multiSig;
    multiSig = _newMultiSig;
    require(
      _newMultiSig != address(0),
      'EnergiWanBridge:: Multi Sig address cannot be zero address'
    );
    require(oldMultiSig != _newMultiSig, 'EnergiWanBridge:: Cannot assign same multisig wallet');

    emit MultiSigUpdated(oldMultiSig, _newMultiSig);
  }

  function setTokenLockLimit(address _tokenAddress, uint256 _amount) external onlyOwner {
    uint256 oldLimit = tokensLockLimit[_tokenAddress];
    tokensLockLimit[_tokenAddress] = _amount;

    emit TokenLockLimitUpdated(_tokenAddress, oldLimit, _amount);
  }

  // function to add new supported tokens
  // can only be called by owner of smart contract
  // _tokenAddress - address of token in source chain
  // _isBlacklisted - whether token is supported or not
  // NOTE: this function should be called in both source and destination smart contract

  function addToken(
    address _tokenAddress,
    bool _isBlacklisted,
    uint256 _minAmount
  ) external isNotZeroAddress(_tokenAddress) onlyOwner {
    require(
      tokens[_tokenAddress].tokenAddress != _tokenAddress &&
        tokens[_tokenAddress].tokenAddress == address(0),
      'EnergiWanBridge:: Cannot add duplicate token'
    );

    Token memory newToken = Token(_tokenAddress, _isBlacklisted, _minAmount);

    tokens[_tokenAddress] = newToken;

    emit NewTokenAdded(_tokenAddress, _isBlacklisted, _minAmount);
  }

  // only be called by owner of smart contract
  // can toggle if the token is supported or not
  function blacklistToken(
    address _tokenAddress,
    bool _blacklist
  ) external isNotZeroAddress(_tokenAddress) onlyOwner {
    require(
      tokens[_tokenAddress].tokenAddress != address(0),
      'EnergiWanBridge:: Token is not added'
    );
    require(
      tokens[_tokenAddress].isBlacklisted != _blacklist,
      'EnergiWanBridge:: Cannot perform same operation'
    );
    tokens[_tokenAddress].isBlacklisted = _blacklist;
  }

  // updates the EnergiWmbApp address
  // only be called by owner of smart contract
  function updateEnergiWmbApp(address _newEnergiWmbApp) external onlyOwner {
    address oldEnergiWmbApp = energiWmbAppAddress;
    energiWmbAppAddress = _newEnergiWmbApp;
    require(
      _newEnergiWmbApp != address(0),
      'EnergiWanBridge:: EnergiWmbApp cannot be zero address'
    );
    require(
      _newEnergiWmbApp != oldEnergiWmbApp,
      'EnergiWanBridge:: EnergiWmbApp address cannot be same as previous EnergiWmbApp address'
    );

    emit EnergiWmbAppUpdated(oldEnergiWmbApp, _newEnergiWmbApp);
  }

  function updateMinAmountOfToken(
    address _tokenAddress,
    uint256 _newMinAmount
  ) external onlyOwner isNotZeroAddress(_tokenAddress) {
    require(
      tokens[_tokenAddress].tokenAddress != address(0),
      'EnergiWanBridge:: Token is not added'
    );

    require(
      tokens[_tokenAddress].minAmount != _newMinAmount,
      'EnergiWanBridge:: Cannot assign same minimum amount'
    );

    uint256 oldMinAmount = tokens[_tokenAddress].minAmount;
    tokens[_tokenAddress].minAmount = _newMinAmount;

    emit MinAmountUpdated(_tokenAddress, oldMinAmount, _newMinAmount);
  }

  // function to add new chainId
  // can only be called by owner
  // _chainId - new chain id to be supported
  // _isSupported - boolean value to signigifies it's supported or not
  function addSupportedChainId(uint256 _chainId, bool _isSupported) external onlyOwner {
    require(
      supportedChainIds[_chainId] != _isSupported,
      'EnergiWanBridge:: Cannot assign same value'
    );

    supportedChainIds[_chainId] = _isSupported;
  }

  // pause the smart contract, all functions with whenNotPaused modifier will stops working
  // can only be called by owner of smart contract
  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  // unpause the paused contract
  // can only be called by owner of smart contract
  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  function withdrawERC20(address _tokenAddress, uint256 _amount) external onlyMultiSig {
    IERC20 token = IERC20(_tokenAddress);
    token.approve(address(this), _amount);
    token.safeTransferFrom(address(this), multiSig, _amount);
  }

  function withdrawNative(uint256 _amount) external onlyMultiSig {
    (bool hs, ) = payable(multiSig).call{value: _amount}('');
    require(hs, 'EnergiWanBridge:: Failed to withdraw native coins');
  }

  function _currentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function _getEstimatedFee(uint256 _chainId, uint256 _gasLimit) internal view returns (uint256) {
    IEnergiWmbApp wmbApp = IEnergiWmbApp(energiWmbAppAddress);
    uint256 fee = wmbApp.getEstimatedFees(_chainId, _gasLimit);

    return fee;
  }

  function _transferFee(uint256 _fee) internal {
    (bool hs, ) = payable(energiWmbAppAddress).call{value: _fee}('');
    require(hs, 'EnergiWanBridgeNRG:: Unable to send fee to energi wmb app');
  }

  function _sendMessage(
    address _sender,
    address _to,
    uint256 _amount,
    address _tokenAddress,
    uint256 _chainId,
    uint256 _gasLimit
  ) internal {
    IEnergiWmbApp energiWmbApp = IEnergiWmbApp(energiWmbAppAddress);
    energiWmbApp.sendMessage(_sender, _to, _amount, _tokenAddress, _chainId, _gasLimit);
  }

  function _transferTokens(address _tokenAddress, uint256 _amount) internal {
    IERC20 token = IERC20(_tokenAddress);

    uint256 balance = token.balanceOf(address(this));

    if (balance >= tokensLockLimit[_tokenAddress]) {
      token.safeTransferFrom(_msgSender(), multiSig, _amount);
    } else if (balance + _amount <= tokensLockLimit[_tokenAddress]) {
      token.safeTransferFrom(_msgSender(), address(this), _amount);
    } else {
      uint256 amountForSC = tokensLockLimit[_tokenAddress] - balance;
      uint256 amountForMultiSig = _amount - amountForSC;

      token.safeTransferFrom(_msgSender(), multiSig, amountForMultiSig);
      token.safeTransferFrom(_msgSender(), address(this), amountForSC);
    }
  }

  fallback() external {}

  receive() external payable {}
}

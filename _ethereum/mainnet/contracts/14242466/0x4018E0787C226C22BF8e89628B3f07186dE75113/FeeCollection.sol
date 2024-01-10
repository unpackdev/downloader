// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "./Governable.sol";
import "./IVault.sol";
import "./IStrategy.sol";
import "./IVaultStrategyDataStore.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSet.sol";
import "./BasePauseableUpgradeable.sol";

/// @notice This contract is used to distribute the fees to various participants
/// @dev Given the token emission rate for a vault R, and f
contract FeeCollection is BasePauseableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public constant MAX_BPS = 10000;
  address public vaultStrategyDataStore;

  event VaultCreatorFeeRatioSet(address indexed _vault, uint16 _ratio);
  event StrategyFeeRatioSet(address indexed _strategy, uint16 _proposerRatio, uint16 _developerRatio);
  event FeesClaimed(address indexed _user, address indexed _token, uint256 _amount);
  event ManageFeesCollected(
    address indexed _vault,
    address indexed _token,
    uint256 vaultCreatorFees,
    uint256 protocolFees
  );
  event PerformanceFeesCollected(
    address indexed strategy,
    address indexed token,
    uint256 proposer,
    uint256 developer,
    uint256 protocol
  );

  /// @notice This set stores all possible tokens that a user may have fees in
  EnumerableSet.AddressSet private tokens;

  /// @notice Stores the balance of fees an address has earned in each token (wallet address => tokenAddress => feeBalance)
  mapping(address => mapping(address => uint256)) public feesAvailableMap;

  /// @notice Stores the balance of fees an address has claimed in each token (wallet address => tokenAddress => feeBalance)
  mapping(address => mapping(address => uint256)) public feesClaimedMap;

  /// todo make these configurable in constructor
  /// @notice By default the vault creator will get 50% of the management fees
  uint16 public defaultVaultCreatorFeeRatio;
  /// @notice Strategy propose gets 25% of the the performance fees
  uint16 public defaultStrategyProposerFeeRatio;
  /// @notice Strategy developer gets 25% of the the performance fees
  uint16 public defaultStrategyDeveloperFeeRatio;

  modifier onlyVault() {
    require(IVaultStrategyDataStore(vaultStrategyDataStore).vaultStrategies(msg.sender).length > 0, "!vault");
    _;
  }

  struct StrategyFeeRatio {
    uint16 proposerRatio;
    uint16 developerRatio;
    bool isSet;
  }

  struct VaultCreatorFeeRatio {
    uint16 ratio;
    bool isSet;
  }

  struct Fee {
    address token;
    uint256 amount;
  }

  mapping(address => VaultCreatorFeeRatio) public vaultCreatorFeeRatioMap;
  mapping(address => StrategyFeeRatio) public strategyFeeRatioMap;

  /// @notice Address of the wallet that can claim the protocol fees
  address public protocolWallet;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function initialize(
    address _governance,
    address _gatekeeper,
    address _protocolWallet,
    address _vaultStrategyDataStore,
    uint16 _defaultVaultCreatorFeeRatio,
    uint16 _defaultStrategyProposerFeeRatio,
    uint16 _defaultStrategyDeveloperFeeRatio
  ) external initializer {
    __FeeCollection_init(
      _governance,
      _gatekeeper,
      _protocolWallet,
      _vaultStrategyDataStore,
      _defaultVaultCreatorFeeRatio,
      _defaultStrategyProposerFeeRatio,
      _defaultStrategyDeveloperFeeRatio
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function __FeeCollection_init(
    address _governance,
    address _gatekeeper,
    address _protocolWallet,
    address _vaultStrategyDataStore,
    uint16 _defaultVaultCreatorFeeRatio,
    uint16 _defaultStrategyProposerFeeRatio,
    uint16 _defaultStrategyDeveloperFeeRatio
  ) internal {
    __BasePauseableUpgradeable_init(_governance, _gatekeeper);
    __FeeCollection_init_unchained(
      _protocolWallet,
      _vaultStrategyDataStore,
      _defaultVaultCreatorFeeRatio,
      _defaultStrategyProposerFeeRatio,
      _defaultStrategyDeveloperFeeRatio
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function __FeeCollection_init_unchained(
    address _protocolWallet,
    address _vaultStrategyDataStore,
    uint16 _defaultVaultCreatorFeeRatio,
    uint16 _defaultStrategyProposerFeeRatio,
    uint16 _defaultStrategyDeveloperFeeRatio
  ) internal {
    require(_protocolWallet != address(0), "invalid wallet address");
    require(_vaultStrategyDataStore != address(0), "invalid DataStore address");
    protocolWallet = _protocolWallet;
    vaultStrategyDataStore = _vaultStrategyDataStore;
    _setDefaultVaultCreatorFeeRatio(_defaultVaultCreatorFeeRatio);
    _setDefaultStrategyFeeRatio(_defaultStrategyProposerFeeRatio, _defaultStrategyDeveloperFeeRatio);
  }

  /// @notice Set the default ratio that vault creator will receive. Can only be set by governance.
  /// @param _ratio The ratio value in basis points (100 = 1%, 10,000 = 100%)
  function setDefaultVaultCreatorFeeRatio(uint16 _ratio) external onlyGovernance {
    _setDefaultVaultCreatorFeeRatio(_ratio);
  }

  /// @notice Set the default ratio that the strategy will receive. Can only be set by governance.
  /// @param _proposerRatio The ratio value in basis points (100 = 1%, 10,000 = 100%)
  /// @param _developerRatio The ratio value in basis points (100 = 1%, 10,000 = 100%)
  function setDefaultStrategyFeeRatio(uint16 _proposerRatio, uint16 _developerRatio) external onlyGovernance {
    _setDefaultStrategyFeeRatio(_proposerRatio, _developerRatio);
  }

  /// @notice Override the default vault creator fee ratio. Can only be set by governance.
  /// @param _ratio The ratio value in basis points (100 = 1%, 10,000 = 100%)
  /// @param _vault The address of the vault you want to set the fee on
  function setVaultCreatorFeeRatio(address _vault, uint16 _ratio) external onlyGovernance {
    require(_ratio >= 0 && _ratio <= MAX_BPS, "!ratio");
    require(_vault != address(0), "!vault");
    vaultCreatorFeeRatioMap[_vault] = VaultCreatorFeeRatio(_ratio, true);
    emit VaultCreatorFeeRatioSet(_vault, _ratio);
  }

  /// @notice Override the default strategy fee ratio. Can only be set by governance.
  // The fees will be split 3 ways a portion will go to the proposer, developer and the Yop fee wallet
  /// @param _proposerRatio The ratio of fees that go to proposer in basis points (100 = 1%, 10,000 = 100%)
  /// @param _developerRatio TThe ratio of fees that go to developer in basis points (100 = 1%, 10,000 = 100%)
  function setStrategyFeeRatio(
    address _strategy,
    uint16 _proposerRatio,
    uint16 _developerRatio
  ) external onlyGovernance {
    require(_proposerRatio + _developerRatio <= MAX_BPS, "!ratio");
    strategyFeeRatioMap[_strategy] = StrategyFeeRatio(_proposerRatio, _developerRatio, true);
    emit StrategyFeeRatioSet(_strategy, _proposerRatio, _developerRatio);
  }

  /// @notice Set the protocol wallet. A portion of fees from management and strategy will be sent here. Can only be set by governance.
  /// @param _protocolWallet The wallet where the fees will be sent
  function setProtocolWallet(address _protocolWallet) external onlyGovernance {
    protocolWallet = _protocolWallet;
  }

  /// @notice Collect the manage fees from the vault. This is called from from the vault. The vault will approve this contract to collect the required fees
  /// @param _amount The amount of fees (in vault tokens) to be send from the vault to the FeeCollector contract.

  function collectManageFee(uint256 _amount) external onlyVault {
    address token = IVault(msg.sender).token();

    // Will add the token to the tokens if it doesn't exist all ready
    tokens.add(token);

    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 vaultCreatorFees = _calculateFees(_amount, _getVaultCreatorFeeRatio(msg.sender));
    uint256 protocolFees = _amount - vaultCreatorFees;

    _allocateFees(IVault(msg.sender).creator(), token, vaultCreatorFees);
    _allocateFees(protocolWallet, token, protocolFees);
    emit ManageFeesCollected(msg.sender, token, vaultCreatorFees, protocolFees);
  }

  /// @notice Collect the performance fees from the strategies. This is called from from the vault. The vault will approve this contract to collect the required fees
  /// @param _strategy The strategy form where the fees are collected
  /// @param _amount The amount of fees (in vault tokens) to be send from the vault to the FeeCollector contract.
  function collectPerformanceFee(address _strategy, uint256 _amount) external onlyVault {
    require(_strategy != address(0), "invalid strategy");
    address vault = IStrategy(_strategy).vault();
    address token = IVault(vault).token();

    // Will add the token to the tokens if it doesn't exist all ready
    tokens.add(token);

    IERC20Upgradeable(token).safeTransferFrom(vault, address(this), _amount);

    uint16 proposerRatio = _getStrategyProposerFeeRatio(_strategy);
    uint16 developerRatio = _getStrategyDeveloperFeeRatio(_strategy);

    uint256 proposerFees = _calculateFees(_amount, proposerRatio);
    uint256 developerFees = _calculateFees(_amount, developerRatio);
    uint256 protocolFees = _amount - (proposerFees + developerFees);

    _allocateFees(IStrategy(_strategy).strategyProposer(), token, proposerFees);
    _allocateFees(IStrategy(_strategy).strategyDeveloper(), token, developerFees);
    _allocateFees(protocolWallet, token, protocolFees);
    emit PerformanceFeesCollected(_strategy, token, proposerFees, developerFees, protocolFees);
  }

  /// @notice Claim any fees that a user is due
  function claimAllFees() external {
    // iterate over tokens
    for (uint256 i = 0; i < tokens.length(); i++) {
      address token = tokens.at(i);
      _claimFeesForToken(token);
    }
  }

  /// @notice Claim any fees that a user is due for an individual token
  function claimFeesForToken(address _token) external {
    _claimFeesForToken(_token);
  }

  /// @notice Calculate all tokens a user is due in each token
  function allAvailableFees() external view returns (Fee[] memory) {
    Fee[] memory fees = new Fee[](tokens.length());
    for (uint256 i = 0; i < tokens.length(); i++) {
      fees[i] = Fee(tokens.at(i), _feesAvailable(tokens.at(i)));
    }
    return fees;
  }

  /// @notice Claim any fees that a user is due for an individual token
  /// @param _token The token you address to calculate fees available for.
  function feesAvailableForToken(address _token) external view returns (uint256) {
    return _feesAvailable(_token);
  }

  function getVaultCreatorFeeRatio(address _vault) external view returns (uint16) {
    return _getVaultCreatorFeeRatio(_vault);
  }

  function getStrategyProposerFeeRatio(address _strategy) external view returns (uint16) {
    return _getStrategyProposerFeeRatio(_strategy);
  }

  function getStrategyDeveloperFeeRatio(address _strategy) external view returns (uint16) {
    return _getStrategyDeveloperFeeRatio(_strategy);
  }

  function _claimFeesForToken(address _token) internal {
    // if balance is greater than 0 then transfer to user
    uint256 balance = _feesAvailable(_token);
    if (balance > 0) {
      feesClaimedMap[msg.sender][_token] += balance;
      IERC20Upgradeable(_token).safeTransfer(msg.sender, balance);
      emit FeesClaimed(msg.sender, _token, balance);
    }
  }

  function _feesAvailable(address _token) internal view returns (uint256) {
    return feesAvailableMap[msg.sender][_token] - feesClaimedMap[msg.sender][_token];
  }

  function _calculateFees(uint256 _amount, uint16 feeRatio) internal pure returns (uint256) {
    return (feeRatio * _amount) / MAX_BPS;
  }

  function _getVaultCreatorFeeRatio(address _vault) internal view returns (uint16) {
    // if the vault creator isn't set we return 0;
    if (IVault(_vault).creator() == address(0)) {
      return 0;
    } else if (vaultCreatorFeeRatioMap[_vault].isSet) {
      return vaultCreatorFeeRatioMap[_vault].ratio;
    } else {
      return defaultVaultCreatorFeeRatio;
    }
  }

  function _getStrategyProposerFeeRatio(address _strategy) internal view returns (uint16) {
    if (IStrategy(_strategy).strategyProposer() == address(0)) {
      return 0;
    } else
      return
        _getStrategyFeeRatio(strategyFeeRatioMap[_strategy].proposerRatio, defaultStrategyProposerFeeRatio, _strategy);
  }

  function _getStrategyDeveloperFeeRatio(address _strategy) internal view returns (uint16) {
    if (IStrategy(_strategy).strategyDeveloper() == address(0)) {
      return 0;
    } else
      return
        _getStrategyFeeRatio(
          strategyFeeRatioMap[_strategy].developerRatio,
          defaultStrategyDeveloperFeeRatio,
          _strategy
        );
  }

  function _getStrategyFeeRatio(
    uint16 _ratio,
    uint16 _defaultRatio,
    address _strategy
  ) internal view returns (uint16) {
    if (strategyFeeRatioMap[_strategy].isSet) {
      return (_ratio);
    } else {
      return (_defaultRatio);
    }
  }

  function _allocateFees(
    address _address,
    address _token,
    uint256 _amount
  ) internal {
    if (_address != address(0) && _amount > 0) {
      feesAvailableMap[_address][_token] += _amount;
    }
  }

  function _setDefaultStrategyFeeRatio(uint16 _proposerRatio, uint16 _developerRatio) internal {
    require(_proposerRatio >= 0 && _proposerRatio <= MAX_BPS, "!ratio");
    require(_developerRatio >= 0 && _developerRatio <= MAX_BPS, "!ratio");
    require(_proposerRatio + _developerRatio <= MAX_BPS, "!ratio");
    defaultStrategyProposerFeeRatio = _proposerRatio;
    defaultStrategyDeveloperFeeRatio = _developerRatio;
    emit StrategyFeeRatioSet(address(0), _proposerRatio, _developerRatio);
  }

  function _setDefaultVaultCreatorFeeRatio(uint16 _ratio) internal {
    require(_ratio >= 0 && _ratio <= MAX_BPS, "!ratio");
    defaultVaultCreatorFeeRatio = _ratio;
    emit VaultCreatorFeeRatioSet(address(0), _ratio);
  }
}

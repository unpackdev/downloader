// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IFeeUpgradeable.sol";

contract FeeUpgradeableV1 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IFeeupgradeable
{
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CONTRACT_UPDATER = keccak256("CONTRACT_UPDATER");
    bytes32 public constant TREASURY = keccak256("TREASURY");

    uint256 public fee;
    address public feeCollector;
    uint256 public thresholdMinimumFeeCollection;
    IAccessControlUpgradeable public roles;
    uint256 public maxUpperLimitFee;

    /**
     * @notice Custom threshold for each wrapper
     */
    mapping(address => uint256) public thresholdsMinimuFeeCollection;

    event FeeSet(address indexed manager, uint256 oldFee, uint256 fee);
    event UpdatedFeeCollector(
        address indexed manager,
        address indexed oldCollector,
        address indexed feeCollector
    );
    event FeeThresholdSet(
        address indexed manager,
        address indexed fundsContract,
        uint256 oldTokenAmount,
        uint256 tokenAmount
    );
    event RolesSet(address indexed oldRoles, address indexed newRoles);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
  @param _thresholdMinimumFeeCollection: Default threshold
   */
    function initialize(
        uint256 _fee,
        address _feeCollector,
        uint256 _thresholdMinimumFeeCollection,
        address _roles,
        uint256 _maxUpperLimitFee
    ) public initializer {
        maxUpperLimitFee = _maxUpperLimitFee;
        _updateFee(_fee);
        _updateFeeCollector(_feeCollector);
        _setThresholdMinimumFeeCollectionFor(
            address(0),
            _thresholdMinimumFeeCollection
        );
        _setRoleContract(_roles);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _setRoleContract(address _roles) private {
        _validateAddress(_roles);
        address oldRoles = address(roles);
        roles = IAccessControlUpgradeable(_roles);
        emit RolesSet(oldRoles, address(roles));
    }

    function _validateAddress(address _addr) private view {
        require(_addr != address(0) && _addr != address(this), "IA");
    }

    function setRoleContract(address newRoles) external onlyOwner {
        _setRoleContract(newRoles);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getFee() public view override returns (uint256) {
        return fee;
    }

    function getFeeCollector() public view override returns (address) {
        return feeCollector;
    }

    /**
  @notice The caller is supposed to be the instance to which a minimum threshold has been assigned previously 
  */
    function geThresholdMinimumFee() public view override returns (uint256) {
        return getThresholdMinimumFee(msg.sender);
    }

    /**
  @notice Returns the minimum threshold to be collected
  if threshold is not set for a addr then returns the default threshold
  */
    function getThresholdMinimumFee(address addr)
        public
        view
        returns (uint256)
    {
        uint256 customThreshold = thresholdsMinimuFeeCollection[addr];
        if (customThreshold == 0) {
            return getDefaultThreshold();
        }
        return customThreshold;
    }

    /**
  @notice returns default threshold
   */
    function getDefaultThreshold() public view returns (uint256) {
        return thresholdsMinimuFeeCollection[address(0)];
    }

    /**
     * @notice Returns threshold set (zero if not set)
     * @param addr The address to which the threshold is associated to
     */
    function thresholdSetFor(address addr)
        public
        view
        returns (uint256 threshold)
    {
        threshold = thresholdsMinimuFeeCollection[addr];
    }

    function _updateFee(uint256 _fee) internal {
        require(_fee >= 0 && _fee <= maxUpperLimitFee, "IF"); //limit to only 50% as maximum
        uint256 oldFee = fee;
        fee = _fee;
        emit FeeSet(msg.sender, oldFee, fee);
    }

    function _updateFeeCollector(address _feeCollector) internal {
        require(
            _feeCollector != address(0) && _feeCollector != address(this),
            "IFCA"
        );
        require(_feeCollector != feeCollector, "FCAAR");
        address oldCollector = feeCollector;
        feeCollector = _feeCollector;
        emit UpdatedFeeCollector(msg.sender, oldCollector, feeCollector);
    }

    /**
  @notice Sets threshold for each address
  default fee is set in address(0)
   */
    function setThresholdMinimumFeeCollectionFor(
        address addr,
        uint256 threshold
    ) public {
        _verifyContractUpdaterRole();
        _setThresholdMinimumFeeCollectionFor(addr, threshold);
    }

    function _setThresholdMinimumFeeCollectionFor(
        address addr,
        uint256 threshold
    ) private {
        uint256 oldThreshold = thresholdsMinimuFeeCollection[addr];
        thresholdsMinimuFeeCollection[addr] = threshold;
        emit FeeThresholdSet(msg.sender, addr, oldThreshold, threshold);
    }

    function updateFee(uint256 _fee) external {
        _verifyContractUpdaterRole();
        _updateFee(_fee);
    }

    function updateFeeCollector(address newFeeCollector) external {
        _verifyTreasuryRole();
        _updateFeeCollector(newFeeCollector);
    }

    function _verifyContractUpdaterRole() private view {
        require(roles.hasRole(CONTRACT_UPDATER, msg.sender), "UCUA");
    }

    function _verifyUpgraderRole() private view {
        require(roles.hasRole(UPGRADER_ROLE, msg.sender), "ANAFU");
    }

    function _verifyTreasuryRole() private view {
        require(roles.hasRole(TREASURY, msg.sender), "UTRA");
    }

    function determineFee(
        uint256 withdrawn,
        uint256 sharesToInvestedTokens,
        address receiver,
        uint256 feePercentage
    ) public view override returns (uint256 deductedTokenFees) {
        validateFee(feePercentage);
        if (receiver == msg.sender) return 0; //do not apply fees since it is simply moving funds to migrate to a newest vault
        if (withdrawn > sharesToInvestedTokens) {
            deductedTokenFees = (withdrawn - sharesToInvestedTokens)
                .mul(feePercentage)
                .div(10000);
        }
    }

    function validateFee(uint256 feePercentage)
        public
        view
        override
        returns (bool isValidFee)
    {
        require(feePercentage >= 0 && feePercentage <= maxUpperLimitFee, "IF");
        isValidFee = true;
    }
}

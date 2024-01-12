pragma solidity ^0.8.10;

import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./ECDSAOffsetRecovery.sol";
import "./FullMath.sol";

import "./Errors.sol";

contract BridgeBase is AccessControlUpgradeable, PausableUpgradeable, ECDSAOffsetRecovery {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant DENOMINATOR = 1e6;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    mapping(address => IntegratorFeeInfo) public integratorToFeeInfo;
    mapping(address => uint256) public integratorToCollectedCryptoFee; //TODO: collect

    uint256 public fixedCryptoFee;
    uint256 public collectedCryptoFee;

    EnumerableSetUpgradeable.AddressSet internal availableRouters;

    event FixedCryptoFee(uint256 RubicPart, uint256 integrtorPart, address integrator);
    event FixedCryptoFeeCollected(uint256 amount, address collector);

    struct IntegratorFeeInfo {
        bool isIntegrator;
        uint32 tokenFee;
        uint32 fixedCryptoShare;
        uint32 RubicTokenShare;
    }

    struct BaseCrossChainParams {
        address srcInputToken;
        address dstOutputToken;
        address integrator;
        address recipient;
        uint256 srcInputAmount;
        uint256 dstMinOutputAmount;
        uint256 dstChainID;
    }

    modifier onlyAdmin() {
        if (isAdmin(msg.sender) == false) {
            revert NotAnAdmin();
        }
        _;
    }

    modifier onlyManagerAndAdmin() {
        if (isAdmin(msg.sender) == false && isManager(msg.sender) == false) {
            revert NotAManager();
        }
        _;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert OnlyEOA();
        }
        _;
    }

    function __BridgeBaseInit(uint256 _fixedCryptoFee, address[] memory _routers) internal onlyInitializing {
        __Pausable_init_unchained();

        fixedCryptoFee = _fixedCryptoFee;

        for (uint256 i; i < _routers.length; i++) {
            availableRouters.add(_routers[i]);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal virtual {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(_receiver), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _calculateFeeWithIntegrator(uint256 _amountWithFee, IntegratorFeeInfo memory _info)
        internal
        pure
        returns (uint256 _totalFee, uint256 _RubicFee)
    {
        if (_info.tokenFee > 0) {
            _totalFee = FullMath.mulDiv(_amountWithFee, _info.tokenFee, DENOMINATOR);

            _RubicFee = FullMath.mulDiv(_totalFee, _info.RubicTokenShare, DENOMINATOR);
        }
    }

    function accrueFixedCryptoFee(address _integrator, IntegratorFeeInfo memory _info) internal virtual returns (uint256 _fixedCryptoFee) {
        _fixedCryptoFee = fixedCryptoFee;

        uint256 _integratorCryptoFee = (_fixedCryptoFee * _info.fixedCryptoShare) / DENOMINATOR;
        uint256 _RubicPart = _fixedCryptoFee - _integratorCryptoFee;

        collectedCryptoFee += _RubicPart;
        integratorToCollectedCryptoFee[_integrator] += _integratorCryptoFee;

        emit FixedCryptoFee(_RubicPart, _integratorCryptoFee, _integrator);
    }

    /// CONTROL FUNCTIONS ///

    function pauseExecution() external onlyManagerAndAdmin {
        _pause();
    }

    function unpauseExecution() external onlyManagerAndAdmin {
        _unpause();
    }

    function collectRubicCryptoFee(address payable _to) external onlyManagerAndAdmin {
        uint256 _cryptoFee = collectedCryptoFee;
        collectedCryptoFee = 0;

        _to.transfer(_cryptoFee);

        emit FixedCryptoFeeCollected(_cryptoFee, address(0));
    }

    function setIntegratorInfo(
        address _integrator,
        IntegratorFeeInfo calldata _info
    ) external onlyManagerAndAdmin {
        if (_info.tokenFee > DENOMINATOR) {
            revert FeeTooHigh();
        }
        if (_info.RubicTokenShare > DENOMINATOR) {
            revert ShareTooHigh();
        }
        if (_info.fixedCryptoShare > DENOMINATOR) {
            revert ShareTooHigh();
        }

        integratorToFeeInfo[_integrator] = _info;
    }

    function setFixedCryptoFee(uint256 _fixedCryptoFee) external onlyManagerAndAdmin {
        fixedCryptoFee = _fixedCryptoFee;
    }

    function addAvailableRouter(address _router) external onlyManagerAndAdmin {
        if (_router == address(0)) {
            revert ZeroAddress();
        }
        availableRouters.add(_router);
    }

    function removeAvailableRouter(address _router) external onlyManagerAndAdmin {
        availableRouters.remove(_router);
    }

    function transferAdmin(address _newAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    /// VIEW FUNCTIONS ///

    function getAvailableRouters() external view returns (address[] memory) {
        return availableRouters.values();
    }

    /**
     * @dev Function to check if address is belongs to manager role
     * @param _who Address to check
     */
    function isManager(address _who) public view returns (bool) {
        return (hasRole(MANAGER_ROLE, _who));
    }

    /**
     * @dev Function to check if address is belongs to default admin role
     * @param _who Address to check
     */
    function isAdmin(address _who) public view returns (bool) {
        return (hasRole(DEFAULT_ADMIN_ROLE, _who));
    }

    /// UTILS ///

    function smartApprove(
        address _tokenIn,
        uint256 _amount,
        address _to
    ) internal {
        IERC20Upgradeable tokenIn = IERC20Upgradeable(_tokenIn);
        uint256 _allowance = tokenIn.allowance(address(this), _to);
        if (_allowance < _amount) {
            if (_allowance == 0) {
                tokenIn.safeApprove(_to, type(uint256).max);
            } else {
                try tokenIn.approve(_to, type(uint256).max) returns (bool res) {
                    if (!res) {
                        revert ApproveFailed();
                    }
                } catch {
                    tokenIn.safeApprove(_to, 0);
                    tokenIn.safeApprove(_to, type(uint256).max);
                }
            }
        }
    }

    function _calculateFee(
        IntegratorFeeInfo memory _info,
        uint256 _amountWithFee,
        uint256 _initBlockchainNum
    ) internal virtual view returns (uint256 _totalFee, uint256 _RubicFee) {}

    /**
     * @dev Plain fallback function to receive crypto
     */
    receive() external payable {}

    /**
     * @dev Plain fallback function
     */
    fallback() external {}
}

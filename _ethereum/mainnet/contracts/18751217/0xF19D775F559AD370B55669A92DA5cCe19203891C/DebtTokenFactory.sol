// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";
import "./IAccessControl.sol";

import "./Errors.sol";

import "./DebtToken.sol";
import "./Constants.sol";
import "./IDebtTokensFactory.sol";
import "./IDebtToken.sol";
import "./IBucketsFactory.sol";

contract DebtTokensFactory is UpgradeableBeacon, IDebtTokensFactory, IERC165 {
    address public override bucketsFactory;
    address public override registry;

    event DebtTokenCreated(address debtAddress);

    /**
     * @dev Throws if called by any account other than the bucket.
     */
    modifier onlyBucketsFactory() {
        _require(bucketsFactory == msg.sender, Errors.CALLER_IS_NOT_A_BUCKET_FACTORY.selector);
        _;
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _debtTokenImplementation, address _registry) UpgradeableBeacon(_debtTokenImplementation) {
        _require(
            IERC165(_debtTokenImplementation).supportsInterface(type(IDebtToken).interfaceId) &&
                IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @inheritdoc IDebtTokensFactory
     */
    function createDebtToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external override onlyBucketsFactory returns (IDebtToken) {
        bytes memory initData = abi.encodeWithSelector(
            IDebtToken.initialize.selector,
            _name,
            _symbol,
            _decimals,
            bucketsFactory
        );
        address instance = address(new BeaconProxy(address(this), initData));
        emit DebtTokenCreated(instance);
        return IDebtToken(instance);
    }

    /**
     * @inheritdoc IDebtTokensFactory
     */
    function setBucketsFactory(address _bucketsFactory) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            IERC165(_bucketsFactory).supportsInterface(type(IBucketsFactory).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        bucketsFactory = _bucketsFactory;
    }

    /**
     * @inheritdoc UpgradeableBeacon
     */

    function upgradeTo(address _debtTokenImplementation) public override {
        _require(
            IERC165(_debtTokenImplementation).supportsInterface(type(IDebtToken).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        super.upgradeTo(_debtTokenImplementation);
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IDebtTokensFactory).interfaceId || _interfaceId == type(IERC165).interfaceId;
    }
}

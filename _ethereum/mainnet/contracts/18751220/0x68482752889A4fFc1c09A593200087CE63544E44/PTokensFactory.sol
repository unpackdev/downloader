// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

import "./PToken.sol";
import "./IPTokensFactory.sol";
import "./IPToken.sol";
import "./IBucketsFactory.sol";
import "./Constants.sol";
import "./IAccessControl.sol";

import "./Errors.sol";

contract PTokensFactory is UpgradeableBeacon, IPTokensFactory, IERC165 {
    address public override bucketsFactory;
    address public override registry;

    event PTokenCreated(address pTokenAddress);

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

    constructor(address _ptokenImplementation, address _registry) UpgradeableBeacon(_ptokenImplementation) {
        _require(
            IERC165(_ptokenImplementation).supportsInterface(type(IPToken).interfaceId) &&
                IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @inheritdoc IPTokensFactory
     */
    function createPToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external override onlyBucketsFactory returns (IPToken) {
        bytes memory initData = abi.encodeWithSelector(
            IPToken.initialize.selector,
            _name,
            _symbol,
            _decimals,
            bucketsFactory
        );
        address instance = address(new BeaconProxy(address(this), initData));
        emit PTokenCreated(instance);
        return IPToken(instance);
    }

    /**
     * @inheritdoc IPTokensFactory
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

    function upgradeTo(address _ptokenImplementation) public override {
        _require(
            IERC165(_ptokenImplementation).supportsInterface(type(IPToken).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        super.upgradeTo(_ptokenImplementation);
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPTokensFactory).interfaceId || _interfaceId == type(IERC165).interfaceId;
    }
}

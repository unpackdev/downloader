// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

// interfaces
import "./IAllowlist.sol";
import "./IERC20.sol";
import "./IMasterFundAdmin.sol";

// errors
import "./errors.sol";

contract MasterFundAdmin is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IMasterFundAdmin {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants & Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice wallets of feeders and master fund
    address private immutable feederDomestic;
    address private immutable feederInternational;
    address private immutable master;

    /// @notice allowlist manager to check permissions
    IAllowlist public immutable allowlist;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Subscribed(address feeder, address client, address from, address token, uint256 amount, address destination);

    event Redeemed(address feeder, address client, address from, address token, uint256 amount, address destination);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _feederDomestic, address _feederInternational, address _master, address _allowlist) initializer {
        if (_feederDomestic == address(0)) revert BadAddress();
        if (_feederInternational == address(0)) revert BadAddress();
        if (_master == address(0)) revert BadAddress();

        feederDomestic = _feederDomestic;
        feederInternational = _feederInternational;
        master = _master;

        allowlist = IAllowlist(_allowlist);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        __Ownable_init();
        __ReentrancyGuard_init();

        _transferOwnership(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice subscribes to fund on behalf of client
     * @param _from address to pull funds from
     * @param _token the asset
     * @param _amount the amount of asset
     * @param _client to subscribe on behalf of
     * @param _destination where the finds should ultimately land
     */
    function subscribe(address _from, address _token, uint256 _amount, address _client, address _destination)
        external
        override
        nonReentrant
    {
        address feeder = _gatekeeper(_from, _client, _destination);

        IERC20 token = IERC20(_token);
        token.safeTransferFrom(_from, feeder, _amount);
        token.safeTransferFrom(feeder, master, _amount);
        token.safeTransferFrom(master, _destination, _amount);

        emit Subscribed(feeder, _client, _from, _token, _amount, _destination);
    }

    /**
     * @notice redeems from fund on behalf of client
     * @param _from address to pull funds from
     * @param _token the asset
     * @param _amount the amount of asset
     * @param _client to redeem on behalf of
     * @param _destination where the finds should ultimately land
     */
    function redeem(address _from, address _token, uint256 _amount, address _client, address _destination)
        external
        override
        nonReentrant
    {
        address feeder = _gatekeeper(_from, _client, _destination);

        IERC20 token = IERC20(_token);
        token.safeTransferFrom(_from, master, _amount);
        token.safeTransferFrom(master, feeder, _amount);
        token.safeTransferFrom(feeder, _destination, _amount);

        emit Redeemed(feeder, _client, _from, _token, _amount, _destination);
    }

    /**
     * @notice Returns feeder fund for a particular client
     * @dev returns zero address if not subscribed to feeder
     * @param _client client subscribed to the fund
     * @return feeder wallet of feeder fund
     */
    function feederOf(address _client) public view returns (address feeder) {
        if (allowlist.isClientDomesticFeeder(_client)) feeder = feederDomestic;
        else if (allowlist.isClientInternationalFeeder(_client)) feeder = feederInternational;
    }

    /**
     * @notice Checks that certain addresses are valid
     */
    function _gatekeeper(address _from, address _client, address _destination) internal view returns (address feeder) {
        if (_from == feederDomestic) revert NotPermissioned();
        if (_from == feederInternational) revert NotPermissioned();
        if (_from == master) revert NotPermissioned();
        if (!allowlist.isAllowed(msg.sender)) revert NotPermissioned();
        if (msg.sender != _destination) if (!allowlist.isAllowed(_destination)) revert NotPermissioned();
        feeder = feederOf(_client);
        if (feeder == address(0)) revert NotPermissioned();
    }
}

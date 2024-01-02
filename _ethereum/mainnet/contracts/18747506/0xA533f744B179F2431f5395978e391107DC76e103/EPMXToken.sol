// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC165.sol";
import "./IAccessControl.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IEPMXToken.sol";

contract EPMXToken is IEPMXToken, ERC20, ERC165 {
    address public immutable registry;
    mapping(address => bool) public whitelist;

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _recipient, address _registry) ERC20("Early Primex Token", "ePMX") {
        _require(
            ERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;

        if (_recipient == address(0)) {
            _recipient = msg.sender;
        }
        _mint(_recipient, 1000000000 * 10 ** decimals());
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function burn(uint256 _amount) external override {
        _burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount);
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function addAddressToWhitelist(address _address) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(!whitelist[_address], Errors.ADDRESS_ALREADY_WHITELISTED.selector);
        whitelist[_address] = true;
        emit WhitelistedAddressAdded(_address);
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function addAddressesToWhitelist(address[] memory _addresses) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        for (uint256 i; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function removeAddressFromWhitelist(address _address) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(whitelist[_address], Errors.ADDRESS_NOT_WHITELISTED.selector);
        whitelist[_address] = false;
        emit WhitelistedAddressRemoved(_address);
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function removeAddressesFromWhitelist(address[] calldata _addresses) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        for (uint256 i; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

    /**
     * @inheritdoc IEPMXToken
     */
    function isWhitelisted(address _address) public view override returns (bool) {
        return whitelist[_address];
    }

    /**
     * @notice Interface checker
     * @param interfaceId The interface id to check
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IEPMXToken).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer.
     * It enforces the restriction that the `from` or `to` address must be on the whitelist,
     * or the `from` address must be the zero address for minting.
     * @param from The address transferring the tokens. Use the zero address for minting.
     * @param to The address receiving the tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */) internal virtual override(ERC20) {
        _require(
            whitelist[from] || whitelist[to] || from == address(0),
            Errors.RECIPIENT_OR_SENDER_MUST_BE_ON_WHITE_LIST.selector
        );
    }
}

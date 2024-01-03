// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;

import "./PollenToken.sol";
import "./IWhitelist.sol";

/**
 * @title Pollen
 * @dev The main token for the Pollen DAO
 */
contract Pollen_v1 is PollenToken, IWhitelist {

    /// @dev Whitelisted addresses
    mapping (address => bool) internal _whitelist;

    /**
     * @notice Initializes the contract and sets the token name and symbol
     * @dev Sets the contract `owner` account to the deploying account
     */
    function initialize(
        string memory name,
        string memory symbol
    ) external {
        _initialize(name, symbol);
    }

    function isWhitelisted(address account) external override view returns(bool) {
        bool isWhitelistEnabled = _isWhitelisted(address(0));
        return (!isWhitelistEnabled) || _isWhitelisted(account);
    }

    /// @inheritdoc IWhitelist
    function updateWhitelist(
        address[] calldata accounts,
        bool whitelisted
    ) external override onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = whitelisted;
            emit Whitelist(accounts[i], whitelisted);
        }
    }

    /// @dev Whitelisting for pre-release
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isWhitelistEnabled = _isWhitelisted(address(0));
        if (isWhitelistEnabled) {
            require(
                (from == address(0) || _isWhitelisted(from)) &&
                (to == address(0) || _isWhitelisted(to)),
                "Pollen: not whitelisted"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _isWhitelisted(address account) private view returns(bool) {
        return _whitelist[account];
    }
}

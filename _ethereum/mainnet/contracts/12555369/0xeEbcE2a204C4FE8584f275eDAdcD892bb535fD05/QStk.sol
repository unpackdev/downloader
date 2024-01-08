// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";

import "./IQSettings.sol";

/**
 * Quiver Stock Contract
 * @author fantasy
 *
 * total supply on contact creation.
 * blacklisted users can't make any action and QStk balance.
 */

contract QStk is ERC20Upgradeable {
    event AddBlacklistedUser(address indexed _user);
    event RemoveBlacklistedUser(address indexed _user);

    mapping(address => bool) public isBlacklisted;

    IQSettings public settings;

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(
            settings.getManager() == msg.sender,
            "QStk: caller is not the manager"
        );
        _;
    }

    function initialize(uint256 _totalSupply, address _settings)
        external
        initializer
    {
        __ERC20_init("Quiver Stock", "QSTK");

        settings = IQSettings(_settings);
        _mint(settings.getManager(), _totalSupply);
    }

    // we blacklist bad actors to own our token e.g. front running bots
    function addBlacklistedUser(address _user) external onlyManager {
        require(isBlacklisted[_user] != true, "QStk: already in blacklist");

        isBlacklisted[_user] = true;
        _burn(_user, balanceOf(_user)); // burn all tokens as soon as user is blacklisted

        emit AddBlacklistedUser(_user);
    }

    function removeBlacklistedUser(address _user) external onlyManager {
        require(isBlacklisted[_user] == true, "QStk: not in blacklist");

        isBlacklisted[_user] = false;

        emit RemoveBlacklistedUser(_user);
    }

    function setSettings(address _settings) external onlyManager {
        settings = IQSettings(_settings);
    }

    // Internal functions

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (_from == address(0)) {
            // mint
        } else if (_to == address(0)) {
            // burn
        } else {
            // blacklisted users can't transfer tokens
            require(
                isBlacklisted[_from] != true,
                "QStk: sender address is in blacklist"
            );
            require(
                isBlacklisted[_to] != true,
                "QStk: target address is in blacklist"
            );
            require(_amount != 0, "QStk: non-zero amount is required");
        }

        super._beforeTokenTransfer(_from, _to, _amount);
    }
}

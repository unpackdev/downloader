pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT OR Apache-2.0

import "./OwnableUpgradeable.sol";
import "./Pausable.sol";

contract BlackList is Pausable {
    mapping(address => bool) isBlacklisted;
    address constant REDEMPTION_ADDRESS_COUNT = address(16**5);

    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    /**
     * @dev Set blacklisted status for the account.
     * @param _account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address _account, bool _isBlacklisted)
        external
        onlyOwner
    {
        require(
            _account >= REDEMPTION_ADDRESS_COUNT,
            "MexicanCurrency: blacklisting of redemption address is not allowed"
        );
        isBlacklisted[_account] = _isBlacklisted;
        emit Blacklisted(_account, _isBlacklisted);
    }

    function getBlacklistedStatus(address _maker) external view returns (bool) {
        return isBlacklisted[_maker];
    }
}

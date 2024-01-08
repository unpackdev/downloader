// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        require(whitelist[_msgSender()], "!whitelist");
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "!ownerOrWhitelist"
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

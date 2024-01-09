//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";

contract EthAddressWhitelistClonable is AccessControlUpgradeable {
    
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    
    bool public isInitialized = false;
    mapping(address => bool) public whitelist;

    event WhitelistStatusSet(address indexed whitelistAddress, bool indexed status);

    function initialize(
        address _owner,
        address[] memory _whitelisters
    ) external {
        require(isInitialized == false, "Already initialized");
        require(_owner != address(0), "_owner may not be zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        for(uint256 i = 0; i < _whitelisters.length; i++) {
            require(_whitelisters[i] != address(0), "_whitelisters[i] may not be zero address");
            _setupRole(WHITELISTER_ROLE, _whitelisters[i]);
        }
        isInitialized = true;
    }

    function setWhitelistStatus(
        address _address,
        bool _status
    ) onlyRole(WHITELISTER_ROLE) external {
        // Does not allow whitelisting zero address, as there seems to be no good reason to ever do this (and may cause unpredictable results)
        require(_address != address(0), "Cannot whitelist zero address");
        whitelist[_address] = _status;
        emit WhitelistStatusSet(_address, _status);
    }

    function isWhitelisted(address _address) external view returns(bool) {
        return whitelist[_address];
    }

}

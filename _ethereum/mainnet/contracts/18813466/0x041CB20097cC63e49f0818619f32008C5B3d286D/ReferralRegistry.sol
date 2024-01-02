// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UUPSUpgradeable.sol";

import "./Whitelist.sol";

contract ReferralRegistry is UUPSUpgradeable, Whitelist {
    mapping(address => address) public referrerOf;

    event UpdateReferrer(address indexed user, address indexed referrer);

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(_msgSender());
    }

    function _setReferrer(address _user, address _referrer) internal {
        require(referrerOf[_user] == address(0), "ReferralRegistry: referrer already set");
        require(_user != _referrer, "ReferralRegistry: referrer cannot be the same as user");
        referrerOf[_user] = _referrer;
        emit UpdateReferrer(_user, _referrer);
    }

    function setReferrer(address _referrer) external {
        _setReferrer(msg.sender, _referrer);
    }

    function setReferrerProtocol(address _user, address _referrer) external onlyWhitelisted {
        _setReferrer(_user, _referrer);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

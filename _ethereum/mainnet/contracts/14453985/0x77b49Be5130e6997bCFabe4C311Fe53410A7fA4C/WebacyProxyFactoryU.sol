// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IWebacyProxyFactory.sol";
import "./WebacyProxy.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract WebacyProxyFactoryU is IWebacyProxyFactory, Initializable, AccessControlUpgradeable, PausableUpgradeable {
    address public webacyBusiness;
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(address => WebacyProxy) private memberToContract;

    function initialize() external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Not valid address");
        _;
    }

    function createProxyContract(address _memberAddress) external override onlyRole(EXECUTOR_ROLE) whenNotPaused {
        require(webacyBusiness != address(0), "WebacyBusiness needs to be set");

        WebacyProxy webacyProxy = new WebacyProxy(_memberAddress, address(webacyBusiness));
        memberToContract[_memberAddress] = webacyProxy;
    }

    function deployedContractFromMember(address _memberAddress) external view override returns (address) {
        return address(memberToContract[_memberAddress]);
    }

    function setWebacyAddress(address _webacyAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) validAddress(_webacyAddress) {
        webacyBusiness = _webacyAddress;
    }

    function pauseContract() external override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() external override whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

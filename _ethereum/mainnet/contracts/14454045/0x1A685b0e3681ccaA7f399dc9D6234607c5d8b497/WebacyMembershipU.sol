// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IWebacyProxyFactory.sol";
import "./PausableUpgradeable.sol";

contract WebacyMembershipU is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    IWebacyProxyFactory public proxyFactory;
    uint256 public membershipAmount;

    mapping(address => bool) private membershipPaid;
    mapping(address => bool) private whitelist;

    address public whitelistTokenContract;

    function initialize(uint256 _amount, address _proxyFactoryAddress) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        membershipAmount = _amount;
        proxyFactory = IWebacyProxyFactory(_proxyFactoryAddress);
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Not valid address");
        _;
    }

    function payMembership() external payable whenNotPaused {
        require(
            address(proxyFactory.deployedContractFromMember(msg.sender)) == address(0),
            "Sender already has a Proxy"
        );
        require(!membershipPaid[msg.sender], "Sender already paid");

        if (!(isWhitelisted(msg.sender))) {
            if (!(whitelistTokenContract == address(0))) {
                if (!(IERC721Upgradeable(whitelistTokenContract).balanceOf(msg.sender) > 0)) {
                    validateMembershipFee(msg.value);
                }
            } else {
                validateMembershipFee(msg.value);
            }
        }

        membershipPaid[msg.sender] = true;
        proxyFactory.createProxyContract(msg.sender);
    }

    function validateMembershipFee(uint256 _value) internal view {
        require(_value == membershipAmount, "different membership amount");
    }

    function getProxy(address _address) external view returns (address) {
        return address(proxyFactory.deployedContractFromMember(_address));
    }

    function hasMembership(address _address) external view returns (bool) {
        return membershipPaid[_address];
    }

    function setProxyFactory(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proxyFactory = IWebacyProxyFactory(_address);
    }

    function setMembershipAmount(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        membershipAmount = _amount;
    }

    function withdraw(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(_address) {
        uint256 availableBalance = address(this).balance;
        require(availableBalance > 0, "no founds to withdraw");
        payable(_address).transfer(availableBalance);
    }

    function addToWhitelist(address[] memory _addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!(whitelist[_addresses[i]])) {
                whitelist[_addresses[i]] = true;
            }
        }
    }

    function removeFromWhitelist(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(whitelist[_address], "address does not exists");
        delete whitelist[_address];
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function pauseContract() external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setWhitelistTokenContract(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(_address) {
        whitelistTokenContract = _address;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IWebacyProxyFactory.sol";
import "./IWebacyBusiness.sol";
import "./PausableUpgradeable.sol";

contract WebacyMembershipU is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    IWebacyProxyFactory public proxyFactory;
    uint256 public membershipAmount;

    mapping(address => bool) public membershipPaid;
    mapping(address => bool) public whitelist;

    address public whitelistTokenContract;

    uint256 public freePassesAvailable;
    mapping(uint256 => bool) public isTokenRedeemed;

    uint256 public updateAmount;
    IWebacyBusiness public business;

    function initialize(uint256 _amount, address _proxyFactoryAddress) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        membershipAmount = _amount;
        proxyFactory = IWebacyProxyFactory(_proxyFactoryAddress);
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Not valid address");
        _;
    }

    function payMembership(uint256 _tokenId, bool isTokenHolder) external payable whenNotPaused {
        require(
            address(proxyFactory.deployedContractFromMember(msg.sender)) == address(0),
            "Sender already has a Proxy"
        );
        require(!membershipPaid[msg.sender], "Sender already paid");

        bool isValidTokenHolder = isTokenHolder &&
            freePassesAvailable > 0 &&
            whitelistTokenContract != address(0) &&
            !isTokenRedeemed[_tokenId] &&
            msg.sender == IERC721Upgradeable(whitelistTokenContract).ownerOf(_tokenId);

        if (!isValidTokenHolder && !whitelist[msg.sender]) {
            require(msg.value == membershipAmount, "different membership amount");
        }

        if (isValidTokenHolder) {
            freePassesAvailable--;
            isTokenRedeemed[_tokenId] = true;
        }

        membershipPaid[msg.sender] = true;
        proxyFactory.createProxyContract(msg.sender);
    }

    function payUpdateFee() external payable whenNotPaused {
        require(membershipPaid[msg.sender], "Sender is not a member");
        require(msg.value == updateAmount, "different update amount");
        business.updateStoredData(msg.sender);
    }

    function validateMembershipFee(uint256 _value) internal view {
        require(_value == membershipAmount, "different membership amount");
    }

    function getProxy(address _address) external view returns (address) {
        return address(proxyFactory.deployedContractFromMember(_address));
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

    function pauseContract() external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setWhitelistTokenContract(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(_address) {
        whitelistTokenContract = _address;
    }

    function setPremiumAvailable(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        freePassesAvailable = _amount;
    }

    function setUpdateAmount(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        updateAmount = _amount;
    }

    function setBusiness(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        business = IWebacyBusiness(_address);
    }
}

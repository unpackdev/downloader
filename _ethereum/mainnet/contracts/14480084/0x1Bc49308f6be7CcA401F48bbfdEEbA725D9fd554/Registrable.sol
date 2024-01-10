// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

abstract contract Registrable is Ownable {
    bool public registrationOpen;
    uint256 public registrationFee;
    uint256 public pendingFee;
    uint256 public collectedFee;
    address public registrationFeeTarget;
    mapping(address => bool) private _registeredAccounts;

    event Registered(address indexed account);
    event RegistrationConfigured(bool isOpen, uint256 fee);
    event RegistrationFeeCollected(uint256 amount);

    constructor(bool _registrationOpen, uint256 _registrationFee) {
        registrationOpen = _registrationOpen;
        registrationFee = _registrationFee;
    }

    function totalRegistrationFee() public view returns (uint256) {
        return collectedFee + pendingFee;
    }

    function _tryRegister(address account) internal {
        require(registrationOpen, "Registration is closed");
        require(!_registeredAccounts[account], "Already registered");
        require(msg.value >= registrationFee, "Invalid payment value");
        _registeredAccounts[account] = true;
        pendingFee += msg.value;
        emit Registered(_msgSender());
    }

    function register() external payable {
        _tryRegister(_msgSender());
    }

    function isRegistered(address account) public view returns (bool) {
        return _registeredAccounts[account];
    }

    function configureRegistration(bool isOpen, uint256 fee) external onlyOwner {
        registrationOpen = isOpen;
        registrationFee = fee;
        emit RegistrationConfigured(isOpen, fee);
    }

    function setRegistered(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _registeredAccounts[accounts[i]] = true;
            emit Registered(accounts[i]);
        }
    }

    function collectRegistrationFee() external onlyOwner {
        require(pendingFee > 0, "No pending fee");
        require(registrationFeeTarget != address(0), "RegistrationFeeTarget must be set");

        uint256 amount = pendingFee;
        collectedFee += amount;
        pendingFee = 0;

        payable(registrationFeeTarget).transfer(amount);
        emit RegistrationFeeCollected(amount);
    }

    function setRegistrationFeeTarget(address target) external onlyOwner {
        registrationFeeTarget = target;
    }
}

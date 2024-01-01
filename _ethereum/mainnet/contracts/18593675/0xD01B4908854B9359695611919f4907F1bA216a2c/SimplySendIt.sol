// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";

contract SimplySendIt is Ownable {
    // error codes
    error ZeroValue();
    error InsufficientBalance();
    error EmptyReceivers();
    error EmptyAmounts();
    error LengthsNotEqual();
    error FailedToSendEther();
    error MaxWalletsLengthExceeded();
    error InvalidFeePercentage();

    // events
    event Received(address indexed sender, uint256 amount);
    event WithdrawnBundle(address[] indexed receivers, uint256[] amounts);

    // state variables
    uint8 public projectFee;
    uint8 public distributorFee;
    address private projectAddress;
    address private adminAddress;

    modifier onlyAdmin() {
        require(adminAddress == _msgSender(), "Admin: caller is not the admin");
        _;
    }

    constructor(
        address initialOwner,
        address _projectAddress,
        address _adminAddress
    ) Ownable(initialOwner) {
        projectFee = 1; // 1%
        distributorFee = 1; // 1%
        projectAddress = _projectAddress;
        adminAddress = _adminAddress;
    }

    // receive eth function
    receive() external payable {
        if (msg.value == 0) revert ZeroValue();
        sendEth(adminAddress, (msg.value * distributorFee) / 100);
        sendEth(projectAddress, (msg.value * projectFee) / 100);
        emit Received(msg.sender, msg.value);
    }

    // set fee percentage, only owner can call this function
    function setProjectFee(uint8 _projectFee) external onlyOwner {
        if (_projectFee > 99) revert InvalidFeePercentage();
        projectFee = _projectFee;
    }

    function setDistributorFee(uint8 _distributorFee) external onlyOwner {
        if (_distributorFee > 99) revert InvalidFeePercentage();
        distributorFee = _distributorFee;
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }

    function setProjectAddress(address _projectAddress) external onlyOwner {
        projectAddress = _projectAddress;
    }

    // withdraw eth to multiple, only owner can call this function
    function multiWithdraw(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyAdmin {
        // check if receivers and amounts are not empty
        // receivers and amounts have same length
        // and receivers length is less than 200
        if (receivers.length == 0) revert EmptyReceivers();
        if (amounts.length == 0) revert EmptyAmounts();
        if (receivers.length != amounts.length) revert LengthsNotEqual();
        if (receivers.length > 200) revert MaxWalletsLengthExceeded();

        // calculate total amount and check if contract has enough balance
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        if (totalAmount > address(this).balance) revert InsufficientBalance();

        // send eth to receivers
        for (uint i = 0; i < receivers.length; i++) {
            sendEth(receivers[i], amounts[i]);
        }
        emit WithdrawnBundle(receivers, amounts);
    }

    function sendEth(address receiver, uint256 amount) internal {
        (bool sent, ) = payable(receiver).call{value: amount}("");
        if (!sent) revert FailedToSendEther();
    }
}

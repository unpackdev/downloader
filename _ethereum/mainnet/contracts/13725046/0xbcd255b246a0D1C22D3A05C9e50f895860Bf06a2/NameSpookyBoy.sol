// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Address.sol";
import "./SBCC.sol";

//  .-')     _ (`-.                           .-. .-')                     .-. .-')                              .-')    
// ( OO ).  ( (OO  )                          \  ( OO )                    \  ( OO )                            ( OO ).  
// (_)---\_)_.`     \ .-'),-----.  .-'),-----. ,--. ,--.   ,--.   ,--.       ;-----.\  .-'),-----.   ,--.   ,--.(_)---\_) 
// /    _ |(__...--''( OO'  .-.  '( OO'  .-.  '|  .'   /    \  `.'  /        | .-.  | ( OO'  .-.  '   \  `.'  / /    _ |  
// \  :` `. |  /  | |/   |  | |  |/   |  | |  ||      /,  .-')     /         | '-' /_)/   |  | |  | .-')     /  \  :` `.  
//  '..`''.)|  |_.' |\_) |  |\|  |\_) |  |\|  ||     ' _)(OO  \   /          | .-. `. \_) |  |\|  |(OO  \   /    '..`''.) 
// .-._)   \|  .___.'  \ |  | |  |  \ |  | |  ||  .   \   |   /  /\_         | |  \  |  \ |  | |  | |   /  /\_  .-._)   \ 
// \       /|  |        `'  '-'  '   `'  '-'  '|  |\   \  `-./  /.__)        | '--'  /   `'  '-'  ' `-./  /.__) \       / 
//  `-----' `--'          `-----'      `-----' `--' '--'    `--'             `------'      `-----'    `--'       `-----'  

// Created By: LoMel and Odysseus
contract NameSpookyBoy is Ownable {
    SBCC private immutable sbcc;

    uint256 public basePrice;
    uint256 public maxByteLength = 20;
    bool public namingAllowed = false;
    
    // id + 1 because 0 needs to be null for comparing names
    mapping(uint256 => string) public idToName; 
    mapping(string => uint256) public nameToId;

    event SpookyBoyNameChange(uint256 spookyBoyId, string newName);
    
    constructor(uint256 _basePrice, address spookyBoyContract) {
        basePrice = _basePrice;
        sbcc = SBCC(spookyBoyContract);
        
        // Reserving the devs name
        idToName[13000] = "lomel";
        nameToId["lomel"] = 13000;
        idToName[12999] = "odysseus";
        nameToId["odysseus"] = 12999;
    }
    
    function manuallySetIdAndName(uint256 _id, string calldata _name) external onlyOwner {
        string memory requestedName = _toLower(_name);
        uint256 nameId = _id+1;
        idToName[nameId] = requestedName;
        nameToId[requestedName] = nameId;
        emit SpookyBoyNameChange(_id, _name);
    }

    function updateBasePrice(uint256 _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }
    
    function updateMaxByteLength(uint256 _newLength) external onlyOwner {
        maxByteLength = _newLength;
    }

    function allowNaming() external onlyOwner {
        require(!namingAllowed, "Naming is already allowed.");
        namingAllowed = true;
    }

    function pauseNaming() external onlyOwner {
        require(namingAllowed, "Naming is already paused."); 
        namingAllowed = false;
    }

    function requestCustomSpookyBoyName(uint256 spookyBoyId, string calldata _requestedName) external payable {
        string memory requestedName = _toLower(_requestedName);
        require(namingAllowed, "You may not rename your spooky at this time.");
        require(bytes(requestedName).length <= maxByteLength, "Your requested name is to long.");
        require(nameToId[requestedName] == 0, "This name is currently being used.");
        require(sbcc.ownerOf(spookyBoyId) == msg.sender, "You cannot name a Spooky Boy you don't own."); 
        require(basePrice <= msg.value, "Amount of Ether sent is too low.");

        
        uint256 nameId = spookyBoyId+1;
        string memory oldName = idToName[nameId];
        if(bytes(oldName).length > 0){
            nameToId[oldName] = 0;
        }
        
        nameToId[requestedName] = nameId;
        idToName[nameId] = requestedName;
        emit SpookyBoyNameChange(spookyBoyId, _requestedName);
    }
    
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}
//SPDX-License-Identifier: Delayed Release MIT
pragma solidity ^0.8.0;

// Image Storage
/*
    Link Address to Images [/]
    Return Images [/] 
*/

interface iCharacterImage {
    function characterModel1() external view returns (string memory);
    function characterModel2() external view returns (string memory);
    function characterModel3() external view returns (string memory);
    function characterModel4() external view returns (string memory);
    function characterModel5() external view returns (string memory);
}

contract MTMCharactersImageStorage {

    mapping(uint8 => string) public raceToRaceName;
    mapping(uint8 => address) public raceToImageAddress;

    // minified ownable
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner, "You are not the owner!"); _; }
    function setNewOwner(address address_) external onlyOwner { owner = address_; }

    // permissions
    mapping(address => bool) isRenderer;
    function setRenderer(address[] memory addresses_, bool[] memory bools_) external onlyOwner {
        require(addresses_.length == bools_.length, "Address to Bool length mismatch!");
        for (uint256 i = 0; i < addresses_.length; i++) {
            isRenderer[addresses_[i]] = bools_[i];
        }
    }
    modifier onlyRenderer { require(isRenderer[msg.sender] || msg.sender == owner, "You do not have permissions to query as renderer!"); _; }

    // add to storage
    function addRaceNames(uint8[] memory races_, string[] memory names_) external onlyOwner {
        require(races_.length == names_.length, "Length mismatch!");
        for (uint256 i = 0; i < races_.length; i++) {
            raceToRaceName[races_[i]] = names_[i];
        }
    }
    function addCharacterRacesToAddresses(uint8[] memory races_, address[] memory contractAddresses_) external onlyOwner {
        require(races_.length == contractAddresses_.length, "Length mismatch!");
        for (uint256 i = 0; i < races_.length; i++) {
            raceToImageAddress[races_[i]] = contractAddresses_[i];
        }
    }

    // return from storage
    function getCharacterImage(uint8 race_, uint8 rank_) external onlyRenderer view returns (string memory) {
        if      (rank_ == 1) { return iCharacterImage(raceToImageAddress[race_]).characterModel1(); }
        else if (rank_ == 2) { return iCharacterImage(raceToImageAddress[race_]).characterModel2(); }
        else if (rank_ == 3) { return iCharacterImage(raceToImageAddress[race_]).characterModel3(); }
        else if (rank_ == 4) { return iCharacterImage(raceToImageAddress[race_]).characterModel4(); }
        else if (rank_ == 5) { return iCharacterImage(raceToImageAddress[race_]).characterModel5(); }
        else                 { return ""; }
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

import "./YoloInterfaces.sol";

/**
  Manages the state of the PLayers in the Yolo Games Universe.
 */

contract YoloRegistry is Ownable, Pausable {

    event YoloGamertagUpdate(address indexed account, string gamertag);
    event YoloClantagUpdate(address indexed account, string clantag);
    event YoloProfilePicUpdate(address indexed account, string pfp);

    struct Player {
      string gamertag;
      string clantag;
      string pfp;
    }

    mapping (address => string) public gamertags;
    mapping (address => string) public clantags;
    mapping (address => string) public pfps;

    mapping (string => address) public gamertagToPlayer;

    uint public gamertagFee = 50 ether;
    uint public clantagFee = 50 ether;
    uint public pfpFee = 100 ether;

    uint16 public gamertagMaxLength = 80;
    uint16 public clantagMaxLength = 8;

    IYoloDice public diceV1;
    IYoloChips public chips;

    constructor(address _diceV1, address _chips) {
        diceV1 = IYoloDice(_diceV1);
        chips = IYoloChips(_chips);
    }

    // Pausable.

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Setters.

    function setDiceV1(address _diceV1) external onlyOwner {
        diceV1 = IYoloDice(_diceV1);
    }

    function setChips(address _chips) external onlyOwner {
        chips = IYoloChips(_chips);
    }

    function setGamertagFee(uint256 _fee) external onlyOwner {
        gamertagFee = _fee;
    }

    function setClantagFee(uint256 _fee) external onlyOwner {
        clantagFee = _fee;
    }

    function setPfpFee(uint256 _fee) external onlyOwner {
        pfpFee = _fee;
    }

    function setGamertagMaxLength(uint16 _length) external onlyOwner {
        gamertagMaxLength = _length;
    }

    function setClantagMaxLength(uint16 _length) external onlyOwner {
        clantagMaxLength = _length;
    }

    function setMultiGamertags(string[] memory _gamertags, address[] memory _addresses) external onlyOwner {
        for (uint256 idx = 0; idx < _gamertags.length; idx++) {
            // Max length.
            require(bytes(_gamertags[idx]).length <= gamertagMaxLength, "Yolo Registry: Gamertag too long");
        
            // Ensure unique.
            require(!_isGamertagTaken(_gamertags[idx]), "Yolo Registry: Gamertag is taken");

            _setGamertagFor(_gamertags[idx], _addresses[idx]);
        }
    }

    // Dashboard functionality.

    /// @notice Returns token IDs of V1 Dice owned by the address.
    function getV1Dice(address _address) public view returns (uint256[] memory) {
        uint balance = diceV1.balanceOf(_address);

        uint256[] memory diceIds = new uint256[](balance);
        for (uint256 idx = 0; idx < balance; idx++) {
            diceIds[idx] = diceV1.tokenOfOwnerByIndex(_address, idx);
        }

        return diceIds;
    }

    /// @notice Returns the profile of the given address.
    function getProfile(address _address) public view returns (Player memory) {
        return Player(getGamertag(_address), getClantag(_address), getPfp(_address));
    }

    /// @notice Returns the full profile for the player with the given gamertag.
    function getProfileForTag(string memory _gamertag) public view returns (Player memory) {
        address playerAddress = gamertagToPlayer[_gamertag];
        if (playerAddress == address(0x0)) {
            return Player("", "", "");
        }

        return Player(
            getGamertag(playerAddress),
            getClantag(playerAddress),
            getPfp(playerAddress)
        );
    }

    function getGamertag(address _address) public view returns (string memory) {
        return gamertags[_address];
    }

    function setGamertag(string memory _gamertag) public whenNotPaused {
        // Max length.
        require(bytes(_gamertag).length <= gamertagMaxLength, "Yolo Registry: Gamertag too long");
        
        // Ensure unique.
        require(!_isGamertagTaken(_gamertag), "Yolo Registry: Gamertag is taken");

        chips.spend(msg.sender, gamertagFee);

        _setGamertagFor(_gamertag, msg.sender);
    }

    function getClantag(address _address) public view returns (string memory) {
        return clantags[_address];
    }

    function setClantag(string memory _clantag) public whenNotPaused {
        // Max length.
        require(bytes(_clantag).length <= clantagMaxLength, "Yolo Registry: Clantag too long");

        chips.spend(msg.sender, clantagFee);
        clantags[msg.sender] = _clantag;

        emit YoloClantagUpdate(msg.sender, _clantag);
    }

    function getPfp(address _address) public view returns (string memory) {
        return pfps[_address];
    }

    function setPfp(string memory _pfp) public whenNotPaused {
        chips.spend(msg.sender, pfpFee);
        pfps[msg.sender] = _pfp;

        emit YoloProfilePicUpdate(msg.sender, _pfp);
    }

    // Helpers.

    function _setGamertagFor(string memory _gamertag, address _address) internal {
        // Free up old gamertag.
        string memory previous = gamertags[_address];
        if (bytes(previous).length > 0) {
          gamertagToPlayer[previous] = address(0x0);
        }

        // Set new gamertag.
        gamertags[_address] = _gamertag;
        gamertagToPlayer[_gamertag] = _address;

        emit YoloGamertagUpdate(_address, _gamertag);
    }

    function _isGamertagTaken(string memory _gamertag) internal view returns (bool) {
        return gamertagToPlayer[_gamertag] != address(0x0);
    }

}

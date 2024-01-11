// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Invitation.sol";

contract Vault_T is Ownable, ReentrancyGuard {
    mapping (address => bool) public challengers;
    bytes32 public encrSecret;
    address public invitationAddress;
    uint256 public supplyLimit = 99999;

    function setInvitationAddress(address addr, uint limit) public onlyOwner {
        invitationAddress = addr;
        supplyLimit = limit;
    }

    function deposit() external payable {
        return;
    }

    function setPuzzle(bytes32 _encrSecret) external onlyOwner {
        encrSecret = _encrSecret;
    }

    function register() public nonReentrant {
        require (Invitation(invitationAddress).totalSupply() >= supplyLimit, "Challenge Locked.");
        challengers[msg.sender] = true;
    }

    function solvePuzzle(uint tokenId) public nonReentrant {
        require (challengers[msg.sender], "Vault: Please register first.");
        require (Invitation(invitationAddress).totalSupply() >= supplyLimit, "Challenge Locked.");
        require (Invitation(invitationAddress).ownerOf(tokenId) == msg.sender, "You don't own this token.");
        uint luckyNumber = tokenId % 100;
        string memory testString = Strings.toString(luckyNumber);
        require (encrSecret == keccak256(abi.encodePacked(testString)),"Vault: Not lucky enough.");
        payable(msg.sender).transfer(address(this).balance);
    }

}
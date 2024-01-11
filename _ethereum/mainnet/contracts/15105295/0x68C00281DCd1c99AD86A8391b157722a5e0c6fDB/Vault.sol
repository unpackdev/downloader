// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Invitation.sol";

contract Vault is Ownable, ReentrancyGuard {
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

    function solvePuzzle(string memory secret) public nonReentrant {
        require (challengers[msg.sender], "Vault: Please register first.");
        require (Invitation(invitationAddress).totalSupply() >= supplyLimit, "Challenge Locked.");
        require (Invitation(invitationAddress).balanceOf(msg.sender) > 0, "You don't have any invitation.");
        require (encrSecret == keccak256(abi.encodePacked(secret)),"Vault: Incorrect secret, try again.");
        payable(msg.sender).transfer(address(this).balance);
    }

}
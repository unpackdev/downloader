// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./Strings.sol";

// ██╗░░██╗██╗███╗░░██╗░██████╗░░██████╗
// ██║░██╔╝██║████╗░██║██╔════╝░██╔════╝
// █████═╝░██║██╔██╗██║██║░░██╗░╚█████╗░
// ██╔═██╗░██║██║╚████║██║░░╚██╗░╚═══██╗
// ██║░╚██╗██║██║░╚███║╚██████╔╝██████╔╝
// ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░╚═════╝░

// ██████╗░███████╗██╗░░░██╗███████╗██╗░░░░░░█████╗░████████╗██╗░█████╗░███╗░░██╗
// ██╔══██╗██╔════╝██║░░░██║██╔════╝██║░░░░░██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
// ██████╔╝█████╗░░╚██╗░██╔╝█████╗░░██║░░░░░███████║░░░██║░░░██║██║░░██║██╔██╗██║
// ██╔══██╗██╔══╝░░░╚████╔╝░██╔══╝░░██║░░░░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║
// ██║░░██║███████╗░░╚██╔╝░░███████╗███████╗██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
// ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
// Powered by Eye Labs, Inc.

contract EyeMapKingsRevelation is Ownable, ReentrancyGuard {

    address public eyeverseContract;

    constructor(address _eyeverseContract) {
        eyeverseContract = _eyeverseContract;
    }

    uint256 public maxSupply = 20;
    uint256 public currentSupply = 0;
    uint256 public price = 0.5 ether;

    struct Member {
        address from;
        uint256 eyeverseId;
        string username;
    }

    Member[] public members;
    mapping(uint256 => bool) public tokenClaimed; 

    bool public paused = false;

    // MODIFIERS
    
    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    // HOLD A COUNCIL WITH THE EYE KING

    function claimToken(uint256 eyeverseId, string memory _user) public payable notPaused nonReentrant {

        require(currentSupply + 1 <= maxSupply, "Token sold out.");

        IERC721 token = IERC721(eyeverseContract);
        require(msg.sender == token.ownerOf(eyeverseId), "Caller is not owner of token");
        require(tokenClaimed[eyeverseId] == false, "Token already requested");

        require(msg.value >= price, "Insufficient funds");

        tokenClaimed[eyeverseId] = true;
        currentSupply += 1;

        members.push(Member(msg.sender, eyeverseId, _user));
    }

    // CRUD

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // VIEW

    function getMember(uint256 memberId) public view returns (address, uint256) {
        require(memberId < members.length, "Invalid request ID");
        return (members[memberId].from, members[memberId].eyeverseId);
    }

    function getMembersCount() public view returns (uint256) {
        return members.length;
    }

    // WITHDRAW

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x43cDb4A408c1670F2A3C9B80e891CD63770CFCa7).call{value: ((balance * 100) / 100)}("");
        require(success, "Transaction Unsuccessful");
    }
}
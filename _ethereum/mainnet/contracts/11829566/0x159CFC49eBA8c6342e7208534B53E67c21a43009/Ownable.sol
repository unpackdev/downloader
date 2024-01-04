pragma solidity ^0.5.16;

import "./Initializable.sol";
// import "./Initializable.sol";


contract Ownable is Initializable {
    address payable public owner;
    address payable internal newOwnerCandidate;


    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied");
        _;
    }


    // ** INITIALIZERS – Constructors for Upgradable contracts **

    function initialize() public initializer {
        owner = msg.sender;
    }

    function initialize(address payable newOwner) public initializer {
        owner = newOwner;
    }


    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate, "Permission denied");
        owner = newOwnerCandidate;
    }


    uint256[50] private ______gap;
}
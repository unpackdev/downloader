pragma solidity ^0.5.16;

import "./Initializable.sol";
// import "./Initializable.sol";

import "./Ownable.sol";


contract Adminable is Initializable, Ownable {
    mapping(address => bool) public admins;


    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner ||
                admins[msg.sender], "Permission denied");
        _;
    }


    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        Ownable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        Ownable.initialize(newOwner);  // Initialize Parent Contract
    }


    function setAdminPermission(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

//    function setAdminPermission(address[] memory _admins, bool _status) public onlyOwner {
//        for (uint i = 0; i < _admins.length; i++) {
//            admins[_admins[i]] = _status;
//        }
//    }


    uint256[50] private ______gap;
}
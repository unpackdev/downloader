// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";

import "./LockableERC721.sol";
import "./ContractLocker.sol";

contract LockableERC721ContractFactory is AccessControl, Ownable {
    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // DefaultValues
    address public operatorLockerAddress;
    uint96 public defaultRoyaltyFee = 1000;

    // Event
    event Created(address indexed mainContractAddress, address indexed contractLockerAddress, address indexed creator);

    // Constructor
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    function create (
        string memory _name,
        string memory _symbol,
        address _withdrawAddress,
        address[] calldata _admins,
        string memory _baseURI,
        string memory _baseExtension,
        uint256 _operatorLockLevel
    ) external {
        address owner = msg.sender;

        ContractLocker contractLocker = new ContractLocker(owner, _admins);
        LockableERC721 mainContract = new LockableERC721(owner, _name, _symbol, address(contractLocker), defaultRoyaltyFee, _withdrawAddress, _admins, _baseURI, _baseExtension);

        contractLocker.setErc721Contract(address(mainContract));
        contractLocker.setOperatorLocker(operatorLockerAddress);
        contractLocker.setOperatorLockLevel(_operatorLockLevel);

        emit Created(address(mainContract), address(contractLocker), owner);
    }

    function setOperatorLockerAddress(address  _value) external onlyRole(ADMIN) {
        operatorLockerAddress = _value;
    }
    function setDefaultRoyaltyFee(uint96 _value) external onlyRole(ADMIN) {
        defaultRoyaltyFee = _value;
    }

}
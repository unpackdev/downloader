// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC721Contract.sol";
import "./IOperatorLocker.sol";

contract ContractLocker is AccessControl, Ownable {
    bytes32 public constant ADMIN = "ADMIN";

    IERC721Contract public erc721Contract;
    IOperatorLocker public operatorLocker;

    uint256 public operatorLockLevel = 0;
    mapping(address => bool) private _allowlisted;
    mapping(address => bool) private _ownerLocked;
    mapping(uint256 => bool) private _tokenLocked;

    constructor(address[] memory _admins) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(ADMIN, _admins[i]);
        }
    }

    // Getter
    function ownerHasLocked(address _owner) external view returns (bool) {
        return _ownerLocked[_owner];
    }
    function tokenOwnerHasLocked(uint256 _tokenId) external view returns (bool) {
        address _owner = erc721Contract.ownerOf(_tokenId);
        return _ownerLocked[_owner];
    }
    function tokenIsLocked(uint256 _tokenId) external view returns (bool) {
        return _tokenLocked[_tokenId];
    }
    function operatorIsLocked(address _operator) external view returns (bool) {
        if (_allowlisted[_operator]) return false;
        return operatorLocker.operatorIsLocked(operatorLockLevel, _operator);
    }

    // Setter
    function setErc721Contract(address _address) external onlyRole(ADMIN) {
        erc721Contract = IERC721Contract(_address);
    }
    function setOperatorLocker(address _address) external onlyRole(ADMIN) {
        operatorLocker = IOperatorLocker(_address);
    }
    function setOperatorLockLevel(uint256 _value) external onlyRole(ADMIN) {
        operatorLockLevel = _value;
    }
    function setAllowlisted(address[] calldata _operators, bool _value) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _operators.length; i++) {
            _allowlisted[_operators[i]] = _value;
        }
    }
    function setOwnerLocked(address _owner, bool _locked) external {
        require(msg.sender == _owner || hasRole(ADMIN, msg.sender), "Not Granted");
        _ownerLocked[_owner] = _locked;
        uint256[] memory tokenIds = erc721Contract.getOwnTokenIds(_owner);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bool tokenLocked = _locked || _tokenLocked[tokenIds[i]];
            erc721Contract.emitLockState(tokenIds[i], tokenLocked);
            erc721Contract.emitMetadataUpdated(tokenIds[i]);
        }
    }
    function setTokenLocked(uint256 _tokenId, bool _locked) external {
        address _owner = erc721Contract.ownerOf(_tokenId);
        require(msg.sender == _owner || hasRole(ADMIN, msg.sender), "Not Granted");
        _tokenLocked[_tokenId] = _locked;
        bool tokenLocked = _locked || _ownerLocked[_owner];
        erc721Contract.emitLockState(_tokenId, tokenLocked);
        erc721Contract.emitMetadataUpdated(_tokenId);
    }
}
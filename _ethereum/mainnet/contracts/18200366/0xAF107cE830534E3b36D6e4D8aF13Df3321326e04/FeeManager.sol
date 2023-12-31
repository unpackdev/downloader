// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Math.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

import "./IFeeManager.sol";
import "./Errors.sol";

contract FeeManager is AccessControl, Ownable, IFeeManager {
    mapping(bytes32 => mapping(uint256 => FeeConfig)) private _appFees;
    mapping(bytes32 => bool) private _appOwners;

    bytes32 public immutable DEFAULT_APP_ID; // used for bare minimums

    bytes32 public constant RESERVE_ROLE = keccak256("RESERVE_ROLE");

    constructor() {
        uint256 chainId_;
        assembly {
            chainId_ := chainid()
        }
        DEFAULT_APP_ID = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                block.timestamp,
                block.difficulty,
                block.coinbase,
                chainId_
            )
        );
        _grantRole(RESERVE_ROLE, _msgSender());
    }

    modifier onlyAppOwner(bytes32 _appId) {
        require(_appOwners[getAppOwnerKey(_appId)], Errors.R_RESERVED_OWNER);
        _;
    }

    function getAppOwnerKey(bytes32 _appId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_appId, _msgSender()));
    }

    function updateDefaultFee(
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) external override onlyOwner {
        _reserveFee(DEFAULT_APP_ID, _chainId, _baseFee, _feePerByte);
    }

    function updateFee(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) external override onlyAppOwner(_appId) {
        _reserveFee(_appId, _chainId, _baseFee, _feePerByte);
    }

    function reserveFee(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) public override onlyRole(RESERVE_ROLE) {
        require(_appId != DEFAULT_APP_ID, Errors.R_RESERVED_ENTITY);
        bytes32 key = getAppOwnerKey(_appId);
        require(!_appOwners[key], Errors.R_RESERVED_OWNER);
        _appOwners[key] = true;
        _reserveFee(_appId, _chainId, _baseFee, _feePerByte);
    }

    function _reserveFee(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _baseFee,
        uint256 _feePerByte
    ) internal {
        mapping(uint256 => FeeConfig) storage _fees = _appFees[_appId];
        _fees[_chainId] = FeeConfig(_baseFee, _feePerByte);
        emit FeeReserved(_appId, _chainId, _baseFee, _feePerByte);
    }

    function reserveFeeBatch(
        bytes32 _appId,
        uint256[] calldata _chainIds,
        uint256[] calldata _baseFees,
        uint256[] calldata _feesPerByte
    ) external override {
        require(
            _chainIds.length == _baseFees.length &&
                _baseFees.length == _feesPerByte.length,
            Errors.B_LENGTH_MISMATCH
        );

        for (uint256 i = 0; i < _chainIds.length; i++) {
            reserveFee(_appId, _chainIds[i], _baseFees[i], _feesPerByte[i]);
        }
    }

    function getFees(
        bytes32 _appId,
        uint256 _chainId,
        uint256 _dataLength
    ) external view override returns (uint256) {
        FeeConfig memory _defaultFees = _appFees[DEFAULT_APP_ID][_chainId];
        FeeConfig memory _fees = _appFees[_appId][_chainId];

        uint256 baseFee = (_defaultFees.baseFee > _fees.baseFee)
            ? _defaultFees.baseFee
            : _fees.baseFee;
        uint256 feePerByte = (_defaultFees.feePerByte > _fees.feePerByte)
            ? _defaultFees.feePerByte
            : _fees.feePerByte;

        // prventing measure during chain load
        return Math.max(block.basefee, baseFee) + feePerByte * _dataLength;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IFeeManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

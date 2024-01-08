// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ATaskStorage.sol";

abstract contract ASimpleServiceStandard is ATaskStorage {
    // solhint-disable  var-name-mixedcase
    address public immutable GELATO;
    // solhint-enable var-name-mixed-case

    event LogExecSuccess(
        bytes32 indexed taskHash,
        address indexed user,
        address indexed executor
    );

    modifier gelatoSubmit(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _submitTask(msg.sender, _action, _payload, _isPermanent);
        _;
    }

    modifier gelatoCancel(address _action) {
        _cancelTask(_action);
        _;
    }

    modifier gelatoModify(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _modifyTask(_action, _payload, _isPermanent);
        _;
    }

    modifier gelatofy(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) {
        // Only GELATO vetted Executors can call
        require(
            address(GELATO) == msg.sender,
            "ASimpleServiceStandard: msg.sender != gelato"
        );

        // Verifies and removes task
        bytes32 taskHash = _verifyAndRemoveTask(
            _user,
            _action,
            _subBlockNumber,
            _payload,
            _isPermanent
        );
        _;

        emit LogExecSuccess(taskHash, _user, tx.origin);
    }

    modifier isActionOk(address _action) {
        require(
            isActionWhitelisted(_action),
            "ASimpleServiceStandard.isActionOk: notWhitelistedAction"
        );
        _;
    }

    constructor(address _gelato) {
        GELATO = _gelato;
    }
}

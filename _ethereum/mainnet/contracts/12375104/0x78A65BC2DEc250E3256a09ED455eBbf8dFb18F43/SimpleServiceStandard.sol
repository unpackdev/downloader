// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./TaskStorage.sol";
import "./FPayment.sol";
import "./FGelato.sol";
import "./CTokens.sol";

abstract contract SimpleServiceStandard is TaskStorage {
    address public immutable gelato;

    event LogExecSuccess(
        uint256 indexed taskId,
        address indexed executor,
        uint256 postExecFee,
        uint256 rate,
        address creditToken
    );

    modifier gelatofy(
        address _creditToken,
        address _user,
        bytes memory _bytes,
        uint256 _id,
        uint256 _fee,
        uint256 _swapRate
    ) {
        // Check only Gelato is calling
        require(
            address(gelato) == msg.sender,
            "SimpleServiceStandard: Caller is not gelato"
        );

        // Verify tasks actually exists
        require(
            verifyTask(_bytes, _id, _user),
            "SimpleServiceStandard: invalid task"
        );

        // _removeTask(_bytes, _id, _user);

        // Execute Logic
        _;

        // Pay Gelato
        if (_swapRate == 0)
            _transferEthOrToken(payable(gelato), _creditToken, _fee);
        else if (
            _getExpectedReturnAmount(_creditToken, ETH, _fee, gelato) == 0
        ) {
            _swapTokenToEthTransfer(gelato, _creditToken, _fee, _swapRate);
        }

        emit LogExecSuccess(_id, tx.origin, _fee, _swapRate, _creditToken);
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function verifyTask(
        bytes memory _bytes,
        uint256 _id,
        address _user
    ) public view returns (bool) {
        // Check whether owner is valid
        return taskOwner[hashTask(_bytes, _id)] == _user;
    }
}

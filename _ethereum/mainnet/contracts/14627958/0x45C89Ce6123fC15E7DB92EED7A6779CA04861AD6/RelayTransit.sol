// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Tokens.sol";
import "./GelatoBytes.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract RelayTransit {
    using GelatoBytes for bytes;

    address payable public immutable gelato;

    event LogExecSuccess(bytes32 indexed _taskId);

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only gelato");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor(address payable _gelato) {
        gelato = _gelato;
    }

    function execTransit(
        address _dest,
        bytes calldata _data,
        uint256 _minFee,
        address _token,
        bytes32 _taskId
    ) external onlyGelato {
        uint256 prevBalance = _getBalance(_token, address(this));

        (bool success, bytes memory returndata) = _dest.call(_data);
        if (!success) returndata.revertWithError("RelayTransit.execTransit:");

        uint256 receivedFee = _getBalance(_token, address(this)) - prevBalance;
        require(
            receivedFee >= _minFee,
            "RelayTransit.execTransit: Insufficient receivedFee"
        );

        _transferToGelato(_token, receivedFee);
        emit LogExecSuccess(_taskId);
    }

    function _transferToGelato(address _token, uint256 _amount) private {
        if (_amount == 0) return;

        if (_token == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(
                success,
                "RelayTransit._transferGelato: Gelato ETH transfer failed"
            );
        } else {
            SafeERC20.safeTransfer(IERC20(_token), gelato, _amount);
        }
    }

    function _getBalance(address token, address user)
        private
        view
        returns (uint256)
    {
        return token == ETH ? user.balance : IERC20(token).balanceOf(user);
    }
}

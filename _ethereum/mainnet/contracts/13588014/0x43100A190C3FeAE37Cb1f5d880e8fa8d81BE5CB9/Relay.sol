// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Gelatofied.sol";
import "./GelatoBytes.sol";
import "./IERC20.sol";

contract Relay is Gelatofied {
    using GelatoBytes for bytes;

    // solhint-disable-next-line no-empty-blocks
    constructor(address payable _gelato) Gelatofied(_gelato) {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function sufficientFee(
        address _dest,
        bytes memory _data,
        uint256 _desiredFee,
        address _token
    )
        external
        returns (
            bool canExec,
            uint256 receivedFee,
            uint256 desiredFeee
        )
    {
        (bool success, bytes memory returndata) = _dest.call(_data);
        if (!success) returndata.revertWithError("Relay.sufficientFee:");

        uint256 balance = _getBalance(_token, address(this));
        if (balance < _desiredFee) return (false, balance, _desiredFee);
        return (true, balance, _desiredFee);
    }

    function exec(
        address _dest,
        bytes memory _data,
        uint256 _desiredFee,
        address _token
    ) external gelatofy(_desiredFee, _token) {
        (bool success, bytes memory returndata) = _dest.call(_data);
        if (!success) returndata.revertWithError("Relay.exec:");
    }

    function _getBalance(address token, address user)
        private
        view
        returns (uint256)
    {
        if (token == ETH) {
            return user.balance;
        } else {
            return IERC20(token).balanceOf(user);
        }
    }
}

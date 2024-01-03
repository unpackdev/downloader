// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IConnectGelatoExecutorPayment.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./FInstaDapp.sol";
import "./CInstaDapp.sol";

/// @title ConnectGelatoExecutorPayment
/// @notice InstaDapp Connector to compensate Gelato Executors for automation-gas.
/// @author Gelato Team
contract ConnectGelatoExecutorPayment is IConnectGelatoExecutorPayment {
    using Address for address payable;
    using SafeERC20 for IERC20;

    // solhint-disable-next-line const-name-snakecase
    string public constant override name = "ConnectGelatoExecutorPayment-v1.0";

    uint256 internal immutable _id;

    constructor(uint256 id) {
        _id = id;
    }

    /// @dev Connector Details
    function connectorID()
        external
        view
        override
        returns (uint256 _type, uint256 id)
    {
        (_type, id) = (1, _id); // Should put specific value.
    }

    /// @notice Transfers automation gas fees to Gelato Executor
    /// @dev Gelato Executor risks:
    ///    - _getId does not match actual InstaMemory executor payment slot
    ///    - _token balance not in DSA
    ///    - worthless _token risk
    /// payable to be compatible in conjunction with DSA.cast payable target
    /// @param _token The token used to pay the Executor.
    /// @param _amt The amount of _token to pay the Gelato Executor.
    /// @param _getId The InstaMemory slot at which the payment amount was stored.
    /// @param _setId The InstaMemory slot to save the executor payout amound in.
    function payExecutor(
        address _token,
        uint256 _amt,
        uint256 _getId,
        uint256 _setId
    ) external payable override {
        uint256 amt = _getUint(_getId, _amt);
        _setUint(_setId, amt);
        if (_token == ETH) payable(tx.origin).sendValue(amt);
        else IERC20(_token).safeTransfer(tx.origin, amt);
    }
}

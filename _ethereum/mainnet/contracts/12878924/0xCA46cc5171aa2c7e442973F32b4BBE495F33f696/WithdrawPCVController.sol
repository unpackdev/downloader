// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IPCVDeposit.sol";

/// @author Ring Protocol
contract WithdrawPCVController {
    address public receiver;

    /// @notice WithdrawPCVController constructor
    /// @param _receiver receiver
    constructor(address _receiver) {
        receiver = _receiver;
    }

    function withdrawLiquidity(address _pcvDeposit) external {
        require(msg.sender == receiver, "RING: FORBIDDEN");
        IPCVDeposit pcvDeposit = IPCVDeposit(_pcvDeposit);
        uint256 value = pcvDeposit.totalLiquidity();
        require(value > 0, "ERC20UniswapPCVController: No liquidity to withdraw");
        pcvDeposit.withdraw(receiver, value);
    }
}

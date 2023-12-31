// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import "./ERC20.sol";
import "./IFlashLoanRecipient.sol";

interface IBalancerVault {
    function flashLoan(
        IFlashLoanRecipient recipient,
        ERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferETHHelper {
    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success,) = _to.call{value:_value}(new bytes(0));
        require(success, 'TH ETH_TRANSFER_FAILED');
    }
}

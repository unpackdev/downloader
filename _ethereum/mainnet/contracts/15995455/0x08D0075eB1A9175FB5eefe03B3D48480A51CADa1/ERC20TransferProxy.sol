// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IERC20.sol";
import "./Pausable.sol";

import "./OwnableOperatorRole.sol";

contract ERC20TransferProxy is OwnableOperatorRole, Pausable {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator whenNotPaused {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

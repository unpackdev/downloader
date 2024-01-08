//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStableReserve.sol";

contract CommitMinter {
    using SafeERC20 for IERC20;

    address public stableReserve;
    address public commitToken;

    function _setup(address _stableReserve, address _commit) internal {
        stableReserve = _stableReserve;
        commitToken = _commit;
    }

    function _mintCommit(uint256 amount) internal virtual {
        address _baseCurrency = IStableReserve(stableReserve).baseCurrency();
        IERC20(_baseCurrency).safeApprove(address(stableReserve), amount);
        IStableReserve(stableReserve).reserveAndMint(amount);
    }
}

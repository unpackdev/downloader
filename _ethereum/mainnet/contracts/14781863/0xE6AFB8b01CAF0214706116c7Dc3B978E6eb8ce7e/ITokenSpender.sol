// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./IERC20Upgradeable.sol";

interface ITokenSpender {
    function claimTokens(
        IERC20Upgradeable _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "./IERC20.sol";

interface IEIP2612 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);
}

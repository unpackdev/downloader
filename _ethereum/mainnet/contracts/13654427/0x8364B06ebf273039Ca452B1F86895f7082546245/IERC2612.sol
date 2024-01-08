//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

import "./IERC20.sol";

interface IERC2612 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function _nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

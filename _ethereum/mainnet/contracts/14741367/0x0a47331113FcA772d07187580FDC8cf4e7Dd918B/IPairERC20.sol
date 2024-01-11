// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./IERC20.sol";

import "./IERC20Metadata.sol";

interface IPairERC20 is IERC20, IERC20Metadata {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function permitSalt(address owner, uint256 salt) external view returns (bool); // replaces nonces in the UniV2 version

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 salt,
        uint256 expiry,
        bytes calldata signature
    ) external; // uses bytes signature instead of v,r,s as per the ECDSA lib
}

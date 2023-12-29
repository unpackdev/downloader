pragma solidity ^0.6.6;

import "./IERC20.sol";

interface IOriginalDropToken02 is IERC20 {

    // Redeem
    function redeem(
        uint256 amount,
        bytes32 messageHash
    )
        external;

    // Permit (signature approvals)
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    // Events
    event TokenRedeemed(
        address redeemer,
        uint256 amount,
        bytes32 messageHash
    );
}

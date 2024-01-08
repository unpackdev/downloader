// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "./IERC20.sol";
import "./IMaidCoin.sol";

interface IMaidCafe {
    event Enter(address indexed user, uint256 amount);
    event Leave(address indexed user, uint256 share);

    function maidCoin() external view returns (IMaidCoin);

    function enter(uint256 _amount) external;

    function enterWithPermit(
        uint256 _amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function leave(uint256 _share) external;
}

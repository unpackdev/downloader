// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

/// @notice Interface InstaDapp Defi Smart Account wallet
interface AccountInterface {
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);

    function version() external view returns (uint256);

    function isAuth(address user) external view returns (bool);

    function shield() external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

interface IStaking {
    function getEpochId(uint256 timestamp) external view returns (uint256); // get epoch id

    function getEpochUserBalance(
        address user,
        address token,
        uint128 epoch
    ) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch)
        external
        view
        returns (uint256);

    function depositFor(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external;

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);
}

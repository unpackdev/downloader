// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IBoardroom {
    function allocateSeigniorage(uint256 amount) external;

    function stakeShareForThirdParty(address staker, address from, uint256 amount) external;
    function stakeControlForThirdParty(address staker, address from, uint256 amount) external;
}

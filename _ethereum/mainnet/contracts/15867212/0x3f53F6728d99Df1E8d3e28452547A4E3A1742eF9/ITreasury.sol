// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
@dev The Treasury contract accumulates all the Management fees sent from the strategies.
It's an intermediate contract that can convert between different tokens,
currently normalizing all rewards into provided default token.
*/
interface ITreasury {
    function toVoters(address _tokenAddress, uint256 amount, uint256 amountOutMin, uint256 deadlineDuration) external;

    function toGovernance(address _token, uint256 _amount) external;
}

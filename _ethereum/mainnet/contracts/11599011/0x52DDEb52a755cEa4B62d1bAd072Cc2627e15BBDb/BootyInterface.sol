// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface BootyInterface {
    function greenBet(address payable sender) external payable;
    function blueBet(address payable sender) external payable;

    function declareBlueWin() external;
    function declareGreenWin() external;
    function declareDraw() external;
    function useForRound(uint32) external;
    function recycleForRound(uint32) external returns (address, uint256, address, uint256);
    function forceRecycle() external;

    function readiness() external view returns(uint8);
    function totalShares() external view returns(uint256);
    function totalBlue() external view returns(uint256);
    function totalGreen() external view returns(uint256);

    function losesOf(address) external view returns(uint256);
    function lockedBalanceOf(address) external view returns(uint256);
    function unlockedBalanceOf(address) external view returns(uint256);

    function release(address payable) external;
}
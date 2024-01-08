// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./IERC20.sol";


interface IDetf is IERC20 {
    function reflect(uint256 tAmount) external;
    function delegate(address delegatee) external;
    function withdraw(address recipient) external;
    function decimals() external pure returns (uint8);
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
    function totalFees() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function changeWithdrawLimit(uint256 newLimit) external;
    function getHoldingFee() external pure returns (uint256);
    function getTreasureFee() external pure returns (uint256);
    function isExcluded(address account) external view returns (bool);
    function getCurrentVotes(address account) external view returns (uint256);
    function tokenFromReflection(uint256 rAmount) external view returns (uint256);
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}
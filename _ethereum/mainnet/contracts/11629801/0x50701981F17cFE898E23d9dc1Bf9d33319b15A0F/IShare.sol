// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IShare is IERC20 {

    function withdraw(address recipient, uint256 amount) external;

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);

    function tokenFromReflection(uint256 rAmount) external view returns (uint256);

    function reflect(uint256 tAmount) external;

}

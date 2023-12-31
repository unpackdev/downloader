// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IREthToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getEthValue(uint256 _rethAmount) external view returns (uint256);

    function getRethValue(uint256 _ethAmount) external view returns (uint256);

    function getTotalCollateral() external view returns (uint256);
}

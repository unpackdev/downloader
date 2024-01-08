// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// steve@fundamenta.network

interface TokenInterface {
    function mintTo(address user, uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
    function balanceOf(address user) external returns (uint256);
}

interface WrappedTokenInterface is TokenInterface {
    function crossChainWrap(address user, uint256 amount) external returns (uint256);
    function crossChainUnwrap(address user, uint256 amount) external;
    function queryFees() external returns (uint256, uint256, uint256, uint256);
}
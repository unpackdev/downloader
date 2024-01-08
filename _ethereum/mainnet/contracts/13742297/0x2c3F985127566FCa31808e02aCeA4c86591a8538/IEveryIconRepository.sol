// SPDX-License-Identifier: UNLICENCED
// Copyright 2021; All rights reserved
// @title: Every Icon Contract (Repository Interface)
// Author: @divergenceharri (@divergence_art)
/// This file is the interface for the icon repository

pragma solidity >=0.8.9 <0.9.0;

interface IEveryIconRepository {
    function icon(uint256) external view returns (uint256[4] memory);
}

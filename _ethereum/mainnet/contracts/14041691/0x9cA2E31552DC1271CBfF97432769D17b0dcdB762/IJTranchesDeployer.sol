// SPDX-License-Identifier: MIT
/**
 * Created on 2021-01-15
 * @summary: JProtocol Interface
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

interface IJTranchesDeployer {
    function deployNewTrancheATokens(string memory _nameA, string memory _symbolA, uint256 _trNum) external returns (address);
    function deployNewTrancheBTokens(string memory _nameB, string memory _symbolB, uint256 _trNum) external returns (address);
}
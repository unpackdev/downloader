// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @notice IGenArt721CoreContractV3 minting interface
 */
interface IGenArt721CoreContractV3_Mintable {
    function mint_Ecf(address to, uint256 projectId, address sender) external returns (uint256 _tokenId);
}

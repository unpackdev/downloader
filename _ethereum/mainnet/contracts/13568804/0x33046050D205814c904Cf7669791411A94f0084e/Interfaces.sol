// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
    
interface IRWaste {
    function claimReward() external;
    function getTotalClaimable(address user) external view returns(uint256);
}

interface IKaiju {
    function fusion(uint256 parent1, uint256 parent2) external;
    function maxGenCount() external view returns (uint256);
    function babyCount() external view returns (uint256);
    function walletOfOwner(address owner) external view returns(uint256[] memory);
    function balanceGenesis(address owner) external view returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}
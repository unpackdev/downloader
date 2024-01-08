// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPoolFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event NFTGemPoolCreated(
        string gemSymbol,
        string gemName,
        uint256 ethPrice,
        uint256 mintTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    );

    function getNFTGemPool(uint256 _symbolHash) external view returns (address);

    function allNFTGemPools(uint256 idx) external view returns (address);

    function allNFTGemPoolsLength() external view returns (uint256);

    function createNFTGemPool(
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external returns (address payable);
}

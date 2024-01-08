// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

struct PositionDetail {
    address token;
    uint256 amount;
    uint256 tokensOwed;
    uint256 feeGrowth;
}

interface IUniswapV3PositionAdapter {
    /// @notice Computes the position details about tokens locked inside the position
    /// @dev Throws if the token ID is not valid
    /// @param positionManager The address of the Uniswap V3 NonfungiblePositionManager contract
    /// @param tokenId The ID of the token that represents the position
    /// @return positionDetails Two structs with details on underlying tokens
    function getPositionDetails(address positionManager, uint256 tokenId)
        external
        view
        returns (PositionDetail[2] memory positionDetails);
}

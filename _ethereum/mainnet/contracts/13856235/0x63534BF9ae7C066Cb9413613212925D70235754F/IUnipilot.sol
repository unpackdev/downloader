// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IHandler.sol";

interface IUnipilot {
    struct DepositVars {
        uint256 totalAmount0;
        uint256 totalAmount1;
        uint256 totalLiquidity;
        uint256 shares;
        uint256 amount0;
        uint256 amount1;
    }

    function governance() external view returns (address);

    function mintPilot(address recipient, uint256 amount) external;

    function mintUnipilotNFT(address sender) external returns (uint256 mintedTokenId);

    function deposit(IHandler.DepositParams memory params, bytes memory data)
        external
        payable
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range,
            uint256 mintedTokenId
        );

    function createPoolAndDeposit(
        IHandler.DepositParams memory params,
        bytes[2] calldata data
    )
        external
        payable
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range,
            uint256 mintedTokenId
        );
}

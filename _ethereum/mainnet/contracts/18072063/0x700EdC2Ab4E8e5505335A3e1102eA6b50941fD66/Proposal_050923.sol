// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IMasterVault.sol";
import "./IAssetConverter.sol";
import "./IProposal.sol";

/// @title Proposal to add Arbitrum network to master vault and to increase max allowed slippage for CAKE -> USDC swaps
contract Proposal_050923 is IProposal {
    function execute() public {
        IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);
        
        // Add arbitrum network to master vault
        masterVault.addChain(42161, 110, 0x7CF02A2f33692B86ee37CCEcc60B35aDFc5D608e);
        // Add arbitrum bridge adapter to master vault
        masterVault.updateBridgeAdapter(42161, 0x46d0458180218feD3647c487b86cB2C685b321F9);

        IAssetConverter assetConverter = IAssetConverter(0x1f8375D632CFaA3cF6eBB1fb9fb90b29373cE32d);
        address CAKE = 0x152649eA73beAb28c5b49B26eb48f7EAD6d4c898;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        IAssetConverter.RouteData memory data = assetConverter.routes(CAKE, USDC);
        data.maxAllowedSlippage = 50;

        // Increase max allowed slippage for CAKE -> USDC route to 5%
        IAssetConverter.RouteDataUpdate[] memory updates = new IAssetConverter.RouteDataUpdate[](2);
        updates[0] = IAssetConverter.RouteDataUpdate({source: CAKE, destination: USDC, data: data});
        updates[1] = IAssetConverter.RouteDataUpdate({source: USDC, destination: CAKE, data: data});

        assetConverter.updateRoutes(updates);
    }
}

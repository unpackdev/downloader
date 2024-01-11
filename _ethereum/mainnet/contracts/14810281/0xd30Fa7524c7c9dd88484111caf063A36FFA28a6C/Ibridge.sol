// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


interface Ibridge{
    struct asset {
        address tokenAddress; 
        uint256 minAmount;
        uint256 maxAmount;
        uint256 feeBalance;
        uint256 collectedFees;
        bool ownedRail;
        address manager;
        address feeRemitance;
        uint256 balance;
        bool isSet;
     }


    function isAssetSupportedChain(address assetAddress , uint256 chainID) external view returns (bool);


    function controller() external view returns (address);


    function claim(bytes32 transaction_id) external;


    function mint(bytes32 transaction_id) external ;


    function settings() external view returns (address); 


    function chainId() external view returns (uint256);


    function foriegnAssetChainID(address _asset) external view returns (uint256);

    function standardDecimals() external view returns (uint256);


    function assetLimits(address _asset, bool native) external view returns (uint256 , uint256);


    function foriegnAssets(address assetAddress) external view returns (asset memory);


    function wrappedForiegnPair(address assetAddress , uint256 chainID) external view returns (address);

    function udpadateBridgePool(address _bridgePool) external;

    function isDirectSwap(address assetAddress ,uint256 chainID) external view returns (bool);
}
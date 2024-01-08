pragma solidity 0.5.15;

interface IRebalancingSetIssuanceModule {
    //  call if eth is active asset in eth20smaco
    function issueRebalancingSetWrappingEther(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    ) external payable;

    //  call with usdc if usdc is active asset in eth20smaco
    function issueRebalancingSet(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    ) external;

    function redeemRebalancingSet(
        address _rebalancingSetAddress,
        uint256 _rebalancingSetQuantity,
        bool _keepChangeInVault
    )
    external;
}
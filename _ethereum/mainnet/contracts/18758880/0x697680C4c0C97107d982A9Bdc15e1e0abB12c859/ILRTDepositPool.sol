// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

interface ILRTDepositPool {
    //errors
    error TokenTransferFailed();
    error InvalidAmountToDeposit();
    error NotEnoughAssetToTransfer();
    error MaximumDepositLimitReached();
    error MaximumNodeDelegatorLimitReached();
    error InvalidMaximumNodeDelegatorLimit();
    error MinimumAmountToReceiveNotMet();

    //events
    event MaxNodeDelegatorLimitUpdated(uint256 maxNodeDelegatorLimit);
    event NodeDelegatorAddedinQueue(address[] nodeDelegatorContracts);
    event AssetDeposit(
        address indexed depositor,
        address indexed asset,
        uint256 depositAmount,
        uint256 rsethMintAmount,
        string referralId
    );
    event MinAmountToDepositUpdated(uint256 minAmountToDeposit);

    function depositAsset(
        address asset,
        uint256 depositAmount,
        uint256 minRSETHAmountToReceive,
        string calldata referralId
    )
        external;

    function getTotalAssetDeposits(address asset) external view returns (uint256);

    function getAssetCurrentLimit(address asset) external view returns (uint256);

    function getRsETHAmountToMint(address asset, uint256 depositAmount) external view returns (uint256);

    function addNodeDelegatorContractToQueue(address[] calldata nodeDelegatorContract) external;

    function transferAssetToNodeDelegator(uint256 ndcIndex, address asset, uint256 amount) external;

    function updateMaxNodeDelegatorLimit(uint256 maxNodeDelegatorLimit) external;

    function getNodeDelegatorQueue() external view returns (address[] memory);

    function getAssetDistributionData(address asset)
        external
        view
        returns (uint256 assetLyingInDepositPool, uint256 assetLyingInNDCs, uint256 assetStakedInEigenLayer);
}

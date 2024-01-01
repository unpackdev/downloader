// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./IBaseMultiUserStrategyV1.sol";

interface IMultiUserLPStakingStrategyV1 is IBaseMultiUserStrategyV1 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event DepositUnderlying(address indexed caller, address indexed _owner, uint256[] amounts, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event WithdrawUnderlying(
        address indexed caller,
        address indexed receiver,
        address indexed _owner,
        uint256[] amounts,
        address[] assetAddresses,
        uint256 shares
    );

    event WithdrawOneUnderlying(
        address indexed caller,
        address indexed receiver,
        address indexed _owner,
        uint256 amount,
        uint256 index,
        uint256 shares
    );

    event SafeAssetsUpdated(address account, address[] safeAssets);

    function depositUnderlying(
        uint256[] calldata amounts,
        uint256 minAmount,
        address receiver
    ) external payable returns (uint256 shares);

    function redeemUnderlying(
        uint256 shares,
        uint256[] calldata minAmounts,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) external returns (address[] memory assetAddresses, uint256[] memory amounts);

    function redeemOneUnderlying(
        uint256 shares,
        uint8 index,
        uint256 minAmount,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) external returns (address assetAddress, uint256 amount);

    function asset() external view returns (address assetTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address receiver) external view returns (uint256 maxShares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 additionalFeePct
    ) external returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 additionalFeePct
    ) external returns (uint256 assets);
}

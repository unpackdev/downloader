// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./console.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IUniswapV2Router02.sol";
import "./InvestmentVehicleSingleAssetBaseV1Upgradeable.sol";
import "./IYearnVaultV2.sol";

/**
    YearnV2VaultV1Base is the IV implementation that targets Yearn V2 vaults.
    It takes the base asset and deposits into the external Yearn vaults
*/
contract YearnV2VaultV1Base is InvestmentVehicleSingleAssetBaseV1Upgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public yearnVault;
    uint256 YEARN_SHARE_UNIT;

    /// initialize the iv with yearn external yearn vault and its respective base asset
    /// @param _store the address of system storage
    /// @param _baseAsset the address of base asset
    /// @param _yVault the address of the external yearn vault
    function initialize(
        address _store,
        address _baseAsset,
        address _yVault
    ) public initializer {
        super.initialize(_store, _baseAsset);
        yearnVault = _yVault;
        YEARN_SHARE_UNIT = 10 ** (IYearnVaultV2(yearnVault).decimals());
    }

    /// calculates the respective yearn vault shares from base asset
    /// @param baseAssetAmount the amount of base asset provided
    /// @return the amount of respective yearn vault shares
    function baseAssetToYVaultShares(uint256 baseAssetAmount) public view returns(uint256) {
        return baseAssetAmount
            .mul(YEARN_SHARE_UNIT)
            .div(IYearnVaultV2(yearnVault).pricePerShare());
    }

    /// calculates the respective base asset amount from yearn vault shares
    /// @param shares the amount of yearn vault shares
    /// @return the amount of respective base asset
    function yVaultSharesToBaseAsset(uint256 shares) public view returns(uint256) {
        return shares
            .mul(IYearnVaultV2(yearnVault).pricePerShare())
            .div(YEARN_SHARE_UNIT);
    }

    function _investAll() internal override {
        uint256 baseAssetAmountInVehicle = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        if(baseAssetAmountInVehicle > 0){
            // Approve yearn vault
            IERC20Upgradeable(baseAsset).safeApprove(yearnVault, 0);
            IERC20Upgradeable(baseAsset).safeApprove(yearnVault, baseAssetAmountInVehicle);
            // Deposit to yearn vault
            IYearnVaultV2(yearnVault).deposit(baseAssetAmountInVehicle);

        }
        
    }

    /** Interacting with underlying investment opportunities */
    function _pullFundsFromInvestment(uint256 _baseAmount) internal override{
        uint256 respectiveShare = baseAssetToYVaultShares(_baseAmount);

        uint256 ownedShare = IYearnVaultV2(yearnVault).balanceOf(address(this));
        uint256 withdrawingShare = MathUpgradeable.min(ownedShare, respectiveShare);

        IYearnVaultV2(yearnVault).withdraw(withdrawingShare);
    }

    function _collectProfitAsBaseAsset() internal override returns (uint256) {
        return profitsPending();
    }

    /** View functions */

    /// exposes the amount of yearn vault shares owned by this IV
    /// @return totalShares the yearn vault shares that is owned by this IV
    function totalYearnVaultShares() public view returns (uint256 totalShares) {
        totalShares = IERC20Upgradeable(yearnVault).balanceOf(address(this));
    }

    /// calculates the amount of base asset that is deposited into yearn vault
    /// @return amount of base asset in yearn vault
    function invested() public view override returns (uint256){
        return yVaultSharesToBaseAsset(totalYearnVaultShares());
    }

    /// calculates the amount of profit that has not been accounted in the system
    /// this is useful for the operators to determine whether it is time to call
    /// `collectProfitAndDistribute` or not.
    /// @return the amount of profit that has not been accounted yet
    function profitsPending() public view override returns (uint256) {
        uint256 ivBalance = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        uint256 yvaultBalance = invested();
        uint256 totalBalance = ivBalance.add(yvaultBalance);
        uint256 profit = totalBalance.sub(totalDebt());

        return profit;
    }
}

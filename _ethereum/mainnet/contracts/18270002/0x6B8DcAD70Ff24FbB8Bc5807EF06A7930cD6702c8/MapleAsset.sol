// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ========================== MapleAsset.sol ==========================
// ====================================================================

/**
 * @title Maple Asset
 * @dev Representation of an on-chain investment
 */
import "./IWithdrawalManager.sol";
import "./IMaplePool.sol";
import "./ERC4626Asset.sol";

contract MapleAsset is ERC4626Asset {

    IWithdrawalManager public immutable withdrawalManager;

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _asset,
        address _oracleUsdx,
        address _withdrawalManager,
        address borrower
    ) ERC4626Asset(_name, _sweep, _usdx, _asset, _oracleUsdx, borrower) {
        withdrawalManager = IWithdrawalManager(_withdrawalManager);
    }

    /**
     * @notice Asset Value of investment.
     * @return the Returns the value of the investment in the USD coin
     * @dev the price is obtained from the target asset
     */
    function assetValue() public view override returns (uint256) {
        uint256 lockedShares = withdrawalManager.lockedShares(address(this));
        return super.assetValue() + asset.convertToAssets(lockedShares);
    }

    /* ========== Actions ========== */

    /**
     * @notice request Redeem.
     * @param usdxAmount Amount to be requested
     * @dev requests Maple for usdxAmount to be redeemed
     */
    function requestRedeem(uint256 usdxAmount) public onlyBorrower {
        uint256 withdrawAmount = _getSharesAmount(usdxAmount);

        IMaplePool(address(asset)).requestRedeem(withdrawAmount, address(this));
    }

    /**
     * @notice forceRequestWithdraw.
     * @param sharesAmount Amount to be requested
     * @dev requests Maple for usdxAmount to be redeemed
     */
    function forceRequestRedeem(
        uint256 sharesAmount
    ) external onlyMultisigOrGov {
        if (!isDefaulted()) revert NotDefaulted(); 
        IMaplePool(address(asset)).requestRedeem(sharesAmount, address(this));
    }

    /**
     * @notice requestWithdraw.
     * @dev requests Maple for usdxAmount to be divested
     */
    function forceDivest() 
        external nonReentrant onlyMultisigOrGov
        returns (uint256 divestedAmount)
    {
        if (!isDefaulted()) revert NotDefaulted();
        divestedAmount = _divest(0, 0);
    }

    function _divest(
        uint256,
        uint256
    ) internal override returns (uint256 divestedAmount) {
        divestedAmount = withdrawalManager.lockedShares(address(this));
        asset.redeem(divestedAmount, address(this), address(this));
        emit Divested(divestedAmount);
    }

    function _getSharesAmount(uint256 usdxAmount) internal view returns (uint256) {
        uint256 sharesBalance = asset.balanceOf(address(this));
        uint256 sharesAmount = asset.convertToShares(usdxAmount);
        if (sharesBalance > sharesAmount) sharesAmount = sharesBalance;

        return sharesAmount;
    }
}

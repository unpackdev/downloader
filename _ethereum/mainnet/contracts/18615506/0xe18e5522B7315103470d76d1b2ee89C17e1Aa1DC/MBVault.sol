// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./BaseVault.sol";

contract MBVault is BaseVault {
    using SafeERC20 for IERC20Metadata;
    using Math for uint256;

    address public investor;
    uint8 public immutable sharePriceDecimals;
    uint40 public lastSharePriceUpdate;
    uint256 public sharePrice;

    event SharePriceSet(uint256 indexed roundId, uint256 newSharePrice, uint256 oldSharePrice);
    event InvestorSet(address investor);

    constructor(IERC20Metadata _asset, address _investor) BaseVault(_asset, "Mercado Bitcoin BRL Vault", "stMBRL") {
        _setInvestor(_investor);
        sharePriceDecimals = _asset.decimals();
    }

    /**
     * @inheritdoc BaseVault
     */
    function totalAssets() public view override returns (uint256) {
        uint256 supply = totalSupply();
        uint256 deployedAssets = supply.mulDiv(sharePrice, 10 ** sharePriceDecimals, Math.Rounding.Down);
        return deployedAssets + totalPendingDeposits();
    }

    /**
     * @notice Set a new investor address
     */
    function setInvestor(address newInvestor) external onlyController {
        _setInvestor(newInvestor);
    }

    /**
     * @notice Set a new share price
     */
    function setSharePrice(uint256 newSharePrice) external onlyController {
        _setSharePrice(newSharePrice);
    }

    /**
     * @inheritdoc BaseVault
     */
    function _afterRoundEnd(bytes calldata data) internal override {
        uint256 pendingDeposits = totalPendingDeposits();
        uint256 withdrawals = _parseEndRoundData(data);

        // Push pending deposited assets to investor
        if (pendingDeposits > 0) {
            IERC20Metadata(asset()).safeTransfer(investor, pendingDeposits);
        }

        // Pulls the withdrawals from investor
        if (withdrawals > 0) {
            IERC20Metadata(asset()).safeTransferFrom(investor, address(this), withdrawals);
        }
    }

    /**
     * @inheritdoc BaseVault
     */
    function _beforeExpire() internal override {
        uint256 withdrawals = IERC20Metadata(asset()).balanceOf(investor);
        IERC20Metadata(asset()).safeTransferFrom(investor, address(this), withdrawals);
    }

    /**
     * @notice Internal function to update Investor
     */
    function _setInvestor(address newInvestor) internal {
        emit InvestorSet(newInvestor);
        investor = newInvestor;
    }

    /**
     * @notice Internal function to update Share Price
     */
    function _setSharePrice(uint256 newSharePrice) internal {
        emit SharePriceSet(vaultState.currentRoundId, sharePrice, newSharePrice);
        sharePrice = newSharePrice;
        lastSharePriceUpdate = uint40(block.timestamp);
    }

    /**
     * @notice Parses variables sent from the controller during endRound
     * @param data An array of bytes
     */
    function _parseEndRoundData(bytes memory data) internal view returns (uint256 withdrawals) {
        require(data.length == 32, "Invalid data input");
        (withdrawals) = abi.decode(data, (uint256));
    }
}

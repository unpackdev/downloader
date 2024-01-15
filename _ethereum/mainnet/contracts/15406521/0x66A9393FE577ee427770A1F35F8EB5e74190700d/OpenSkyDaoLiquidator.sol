// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./Context.sol";

import "./IOpenSkySettings.sol";
import "./IOpenSkyLoan.sol";
import "./IOpenSkyPool.sol";
import "./IACLManager.sol";
import "./IOpenSkyDaoLiquidator.sol";
import "./DataTypes.sol";

contract OpenSkyDaoLiquidator is Context, ERC721Holder, IOpenSkyDaoLiquidator {
    using SafeERC20 for IERC20;
    IOpenSkySettings public immutable SETTINGS;

    modifier onlyLiquidationOperator() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isLiquidationOperator(_msgSender()), 'LIQUIDATION_ONLY_OPERATOR_CAN_CALL');
        _;
    }

    constructor(address settings) {
        SETTINGS = IOpenSkySettings(settings);
    }

    function startLiquidate(uint256 loanId) external override onlyLiquidationOperator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);

        IOpenSkyPool pool = IOpenSkyPool(SETTINGS.poolAddress());
        pool.startLiquidation(loanId);

        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);

        // withdraw erc20 token from dao vault
        IERC20 token = IERC20(pool.getReserveData(loanData.reserveId).underlyingAsset);
        token.safeTransferFrom(SETTINGS.daoVaultAddress(), address(this), borrowBalance);
        token.safeApprove(address(pool), borrowBalance);

        pool.endLiquidation(loanId, borrowBalance);

        // transfer NFT to dao vault
        IERC721(loanData.nftAddress).safeTransferFrom(address(this), SETTINGS.daoVaultAddress(), loanData.tokenId);

        emit Liquidate(loanId, loanData.nftAddress, loanData.tokenId, _msgSender());
    }

    function withdrawERC721ToDaoVault(address token, uint256 tokenId) external onlyLiquidationOperator {
        IERC721(token).safeTransferFrom(address(this), SETTINGS.daoVaultAddress(), tokenId);
        emit WithdrawERC721(token, tokenId, SETTINGS.daoVaultAddress());
    }

    receive() external payable {}
}

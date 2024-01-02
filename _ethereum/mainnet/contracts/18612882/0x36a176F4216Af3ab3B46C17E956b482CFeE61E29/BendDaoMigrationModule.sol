// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Upgradeable.sol";

import "./IWETH.sol";
import "./ILendPool.sol";
import "./AddressProvider.sol";

/// @title Cyan Wallet BendDao Migration Module
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract BendDaoMigrationModule {
    AddressProvider constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    bytes4 private constant REPAY = IBDaoLendPool.repay.selector;

    /// @notice Allows operators to repay BendDaoLoan on behalf of user
    /// @param collection Collection address.
    /// @param tokenId Token id.
    /// @param amount Loan amount.
    /// @param currency Currency address.
    function repayBendDaoLoan(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address currency
    ) public {
        address bendDaoLendPoolAddress = addressProvider.addresses("BENDDAO_LEND_POOL");
        IBDaoLendPool bendDaoLendPool = IBDaoLendPool(bendDaoLendPoolAddress);

        if (currency == address(0)) {
            IWETH weth = IWETH(addressProvider.addresses("WETH"));
            weth.deposit{ value: amount }();
            weth.approve(bendDaoLendPoolAddress, amount);
        } else {
            IERC20Upgradeable(currency).approve(bendDaoLendPoolAddress, amount);
        }

        bendDaoLendPool.repay(collection, tokenId, amount);
    }
}

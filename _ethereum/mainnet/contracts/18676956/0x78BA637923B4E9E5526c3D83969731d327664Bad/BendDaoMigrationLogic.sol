// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PaymentPlanTypes.sol";
import "./AddressProvider.sol";
import "./IWalletBendDao.sol";
import "./ICyanConduit.sol";
import "./DataTypes.sol";
import "./ILendPoolLoan.sol";

library BendDaoMigrationLogic {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    function migrateBendDaoPlan(
        Item calldata item,
        Plan calldata plan,
        address cyanWallet,
        address currency
    ) external {
        IBDaoLendPoolLoan bendDaoLendPoolLoan = IBDaoLendPoolLoan(addressProvider.addresses("BENDDAO_LEND_POOL_LOAN"));
        uint256 loanId = bendDaoLendPoolLoan.getCollateralLoanId(item.contractAddress, item.tokenId);
        (, uint256 loanAmount) = bendDaoLendPoolLoan.getLoanReserveBorrowAmount(loanId);

        BDaoDataTypes.LoanData memory loanData = bendDaoLendPoolLoan.getLoan(loanId);
        require(loanData.state == BDaoDataTypes.LoanState.Active, "Loan not active");
        require(loanData.borrower == msg.sender, "Not owner of the loan");
        require(
            loanData.reserveAsset == (currency == address(0) ? addressProvider.addresses("WETH") : currency),
            "invalid currency"
        );
        require(plan.amount >= loanAmount, "invalid amount");

        IWalletBendDao(cyanWallet).executeModule(
            abi.encodeWithSelector(
                IWalletBendDao.repayBendDaoLoan.selector,
                item.contractAddress,
                item.tokenId,
                loanAmount,
                currency
            )
        );
        ICyanConduit(addressProvider.addresses("CYAN_CONDUIT")).transferERC721(
            loanData.borrower,
            cyanWallet,
            item.contractAddress,
            item.tokenId
        );
    }
}

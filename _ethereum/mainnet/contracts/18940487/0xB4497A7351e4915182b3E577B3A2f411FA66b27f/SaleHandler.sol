// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IERC20 {
    function approve(address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface IAnDola {
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint); // stored is good enough for our use case
}

contract SaleHandler {

    IERC20 public immutable dola;
    IAnDola public immutable anDola;
    address public immutable borrower1;
    address public immutable borrower2;

    constructor(
        address _dola,
        address _anDola,
        address _borrower1,
        address _borrower2
    ) {
        dola = IERC20(_dola);
        anDola = IAnDola(_anDola);
        borrower1 = _borrower1;
        borrower2 = _borrower2;
        dola.approve(_anDola,type(uint).max);
    }

    function onReceive() external {
        uint bal = dola.balanceOf(address(this));
        uint debt1 = getDebtOf(borrower1);
        uint debt2 = getDebtOf(borrower2);
        if(debt1 > debt2) {
            uint errCode = anDola.repayBorrowBehalf(borrower1, bal);
            if(errCode > 0) require(anDola.repayBorrowBehalf(borrower2, bal) == 0, "Failed to repay");
        } else {
            uint errCode = anDola.repayBorrowBehalf(borrower2, bal);
            if(errCode > 0) require(anDola.repayBorrowBehalf(borrower1, bal) == 0, "Failed to repay");
        }
    }

    function getDebtOf(address borrower) internal view returns (uint) {
        return anDola.borrowBalanceStored(borrower);
    }

    function getCapacity() external view returns (uint) {
        return getDebtOf(borrower1) + getDebtOf(borrower2) - dola.balanceOf(address(this));
    }

}
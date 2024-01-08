// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IBZX {
  function getLoanPoolsList(uint256 start, uint256 count) external view returns (address[] memory loanPoolsList);
  function loanPoolToUnderlying(address pool) external view returns (address underlying);
  function underlyingToLoanPool(address pool) external view returns (IToken underlying);
  function getLenderInterestData(address lender, address loanToken)
    external
    view
    returns (
      uint256 interestPaid,
      uint256 interestPaidDate,
      uint256 interestOwedPerDay,
      uint256 interestUnPaid,
      uint256 interestFeePercent,
      uint256 principalTotal
    );
}


interface IToken {
  function supplyInterestRate() external view returns (uint256);
  function totalAssetSupply() external view returns (uint256);
  function totalSupplyInterestRate(uint256 assetSupply) external view returns (uint256);
  function nextSupplyInterestRate(uint256 supplyAmount) external view returns (uint256);
  function mint(address receiver, uint256 amount) external payable returns (uint256 mintAmount);
  function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
  function assetBalanceOf(address _owner) external view returns (uint256 balance);
  function tokenPrice() external view returns (uint256);
  function mintWithEther(address receiver) external payable returns (uint256 mintAmount);
  function burnToEther(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
}
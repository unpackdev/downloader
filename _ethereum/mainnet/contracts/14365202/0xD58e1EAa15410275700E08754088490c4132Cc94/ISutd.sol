// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;



import "./IERC20.sol";



interface ISutd is IERC20 {

  function rebase(uint256 utdProfit_, uint256 epoch_)
    external
    returns (uint256);

  function circulatingSupply() external view returns (uint256);

  function gonsForBalance(uint256 amount) external view returns (uint256);

  function balanceForGons(uint256 gons) external view returns (uint256);

  function index() external view returns (uint256);

  function toG(uint256 amount) external view returns (uint256);

  function fromG(uint256 amount) external view returns (uint256);

  function changeDebt(
    uint256 amount,
    address debtor,
    bool add
  ) external;

  function debtBalances(address _address) external view returns (uint256);

}

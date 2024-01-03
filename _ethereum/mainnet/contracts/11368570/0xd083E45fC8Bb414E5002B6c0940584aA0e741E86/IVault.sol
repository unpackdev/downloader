// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVault {
    // the IERC20 part is the share

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function underlying() external view returns (address);
    function bundle() external view returns (address);

    function setBundle(address _bundle) external;
    // function removeBundle(address _bundle) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

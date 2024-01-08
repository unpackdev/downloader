pragma solidity ^0.8.0;

interface HarvestVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function doHardWork() external;

    function underlyingBalanceWithInvestment() view external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

//    function pricePerShare() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balance() external view returns (uint256);
}

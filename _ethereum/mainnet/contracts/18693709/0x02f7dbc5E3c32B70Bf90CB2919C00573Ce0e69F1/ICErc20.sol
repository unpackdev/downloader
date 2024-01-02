pragma solidity 0.8.13;

// Compound V2 interfaces.
interface ICErc20 {
    function accrualBlockNumber() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function getCash() external view returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function reserveFactorMantissa() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function underlying() external view returns (address);
}

// Interfaces for Compound III, which is called Comet.
interface IComet {
    function balanceOf(address account) external view returns (uint256);
    function baseToken() external view returns (address);
    function supply(address asset, uint256 amount) external;
    function transfer(address dst, uint256 amount) external returns (bool);
    function withdraw(address asset, uint256 amount) external;
    function withdrawTo(address to, address asset, uint256 amount) external;
}

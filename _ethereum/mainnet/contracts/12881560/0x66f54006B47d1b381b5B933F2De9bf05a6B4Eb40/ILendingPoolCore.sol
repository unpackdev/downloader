pragma solidity 0.7.6;


interface ILendingPoolCore {
    function getReserveATokenAddress(address _reserve) external view returns (address);
}

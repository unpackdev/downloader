pragma solidity 0.6.6;


interface IBurnGasHelper {
    function getAmountGasTokensToBurn(uint256 gasTotalConsumption)
        external
        view
        returns (uint256 numGas, address gasToken);
}

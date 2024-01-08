pragma solidity 0.7.6;

interface IFeeManager{

    function collectFee(address sender, address debtToken, uint baseAmount) external;

}

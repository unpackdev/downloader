// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUSATokenV1 {
    function manualSwap() external;
    function withdrawTokens(address _token, address _to, uint256 _amount) external;
    function addRegisteredSwapContract(address _swapContract, bool _setting) external;
    function setMinSwapAmount(uint256 _minSwapAmount) external;
    function setExcludedFromFee(address _address, bool _excluded) external;
    function setTaxFeeOnBuy(uint256 _taxFeeOnBuy) external;
    function setTaxFeeOnSell(uint256 _taxFeeOnSell) external;
    function setSwapToEthOnSell(bool _swapToEthOnSell) external;
    function setDaoTaxReceiver(address _daoTaxReceiver) external;
    function changeSwapHelper(address _swapHelper) external;
    function enableOrDisableFees(bool _value) external;
}

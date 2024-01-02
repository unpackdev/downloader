//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBanansToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function addDexAddress(address _dexAddress) external;
    function removeDexAddress(address _dexAddress) external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToBanans(uint256 value) external view returns (uint256);
    function banansToFragment(uint256 banans) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function setSellTaxRate(uint16 _sellTaxRate) external;
    function setBuyTaxRate(uint16 _buyTaxRate) external;
    function setFinalTaxRate() external;
    function removeMaxWallet() external;
    function enableTrading() external;
    function setMaxScaleFactorDecreasePercentagePerDebase(uint256 _maxScaleFactorDecreasePercentagePerDebase) external;
    function setTaxSwapAmountThreshold(uint256 _taxSwapAmountThreshold) external;
    function setDivertTaxToStolenPoolRate(uint256 _divertRate) external;
}
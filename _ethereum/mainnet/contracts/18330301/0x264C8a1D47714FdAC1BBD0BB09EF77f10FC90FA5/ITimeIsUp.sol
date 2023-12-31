// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeIsUp {
    function FLASH_MINT_FEE() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function accountShareBalance(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function mint(uint256 timeAmount) external payable;
    function queryAmountExternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountInternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountOptimal(uint256 amountNative) external view returns (uint256);
    function queryNativeAmount(uint256 d2Amount) external view returns (uint256);
    function queryNativeFromTimeAmount(uint256 timeAmount) external view returns (uint256);
    function queryPriceNative(uint256 amountNative) external view returns (uint256);
    function queryPriceInverse(uint256 d2Amount) external view returns (uint256);
    function queryRate() external view returns (uint256);
    function queryPublicReward() external view returns (uint256);
    function returnNative() external payable returns (bool);
    function splitSharesWithReward() external;
    function buy() external payable returns (bool success);
    function sell(uint256 d2Amount) external returns (bool success);
    function flashMint(uint256 d2AmountToBorrow, bytes calldata data) external;
    function payFlashMintFee() external payable;
    function poolBalance() external view returns (uint256);
    function toBeShared() external view returns (uint256);
    function receiveProfit() external payable;
}

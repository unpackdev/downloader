// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IIchiBuyer {
    event Trade(address sender, address indexed token0, uint256 amountSend, address indexed token1, uint256 amountReceived);
    event TransferIchi(address sender, uint256 amountIchi);
    event ResetVaultPosition(address sender, uint256 amountOneUni, uint256 vaultShares);
    event Liquidate(address sender, uint256 amountIchi, uint256 amountOneUni, uint256 amountReceived, uint256 amountSend, uint256 balanceIchi);
    event SetMaxSlippage(address sender, uint256 maxSlippage);
    event SetVault(address sender, address oneUniIchiVault);

    function swapRouter() external view returns(address);
    function oneUni() external view returns(address);
    function uniswapFactory() external view returns(address);
    function xIchi() external view returns(address);
    function ichi() external view returns(address);
    function vault() external view returns(address);
    function maxSlippage() external view returns(uint256);
    function transferIchi() external;
    function resetVaultPosition() external;
    function liquidate(uint24 fee) external;
    function spotForRoute(uint256 amountIn, bytes calldata route) external view returns(address token, uint256 amountOut);
    function ichiForOneUniSpot(uint256 amount, uint24 fee) external view returns(uint256 ichiAmount); 
    function setVault(address oneUniIchiVault) external;
    function setMaxSlippage(uint256 maxSlippage_) external;
}

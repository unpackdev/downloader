// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTGemFeeManager {

    event DefaultFeeDivisorChanged(address indexed operator, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event ETHReceived(address indexed manager, address sender, uint256 value);
    event LiquidityChanged(address indexed manager, uint256 oldValue, uint256 value);

    function liquidity(address token) external view returns (uint256);

    function defaultLiquidity() external view returns (uint256);

    function setDefaultLiquidity(uint256 _liquidityMult) external returns (uint256);

    function feeDivisor(address token) external view returns (uint256);

    function defaultFeeDivisor() external view returns (uint256);

    function setFeeDivisor(address token, uint256 _feeDivisor) external returns (uint256);

    function setDefaultFeeDivisor(uint256 _feeDivisor) external returns (uint256);

    function ethBalanceOf() external view returns (uint256);

    function balanceOF(address token) external view returns (uint256);

    function transferEth(address payable recipient, uint256 amount) external;

    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external;

}

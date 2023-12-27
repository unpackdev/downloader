// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;



interface IMarketAdapter  {

    function swapExactERC20InToERC20Out(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address recipient,
        uint deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeInToERC20Out(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address recipient,
        uint deadline
    ) external payable returns (uint256 amountOut);

    function swapExactERC20InToNativeOut(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address recipient,
        uint deadline
    ) external  returns (uint256 amountOut);

    function swapERC20InToExactNativeOut(
        uint256 amountInMax,
        uint256 amountOut,
        address[] memory path,
        address recipient,
        uint deadline
    ) external returns (uint256 amountIn);

    function swapNativeInToExactERC20Out(
        uint256 amountInMax,
        uint256 amountOut,
        address[] memory path,
        address recipient,
        uint deadline
    ) external payable returns (uint256 amountIn);

    function swapERC20InToExactERC20Out(
        uint256 amountInMax,
        uint256 amountOut,
        address[] memory path,
        address recipient,
        uint deadline
    ) external returns (uint256 amountIn);


    function WETH() external view returns(address);

    // function getAmountOut(uint amountIn,  address[] memory path ) 
    //     external 
    //     view 
    //     returns (uint256 amountOut);
}
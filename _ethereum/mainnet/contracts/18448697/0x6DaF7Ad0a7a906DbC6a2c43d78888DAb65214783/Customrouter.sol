// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address account) external view returns (uint);
}

interface IERC20 {
    function approve(address spender, uint amount) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);


}


contract Customrouter {
        
        uint256 max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
       
    constructor() {


    }

      

        function multiapprove(address[] calldata tokens) external {
            for (uint256 i = 0; i < tokens.length; ++i) {
                IERC20 token = IERC20(tokens[i]);
                token.approve(address(this),max);
            }
        }

        function consolidate(address token, address[] calldata wallets, address destinationpair,uint256 amountin, uint256 wethout) external {
            uint256 l = wallets.length;
            IERC20 Token = IERC20(token);

            for (uint256 i = 0; i < l; ++i) {
                Token.transferFrom(wallets[i],destinationpair,amountin);
            }
            Token.approve(destinationpair,max);
            IUniswapV2Pair pair = IUniswapV2Pair(destinationpair);
            pair.swap(0,wethout,0x708f741b5fA76c9f4a70355207b4F0226ce265f3,"");
        }

     

}
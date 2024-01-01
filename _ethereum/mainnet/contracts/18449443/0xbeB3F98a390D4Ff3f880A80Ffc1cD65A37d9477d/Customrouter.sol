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
    
}



interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}
interface IWETH9 is IERC20 {
    function withdraw(uint256) external;
}

contract Customrouter {
        
        uint256 max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        IWETH9 private WETH;
       
    constructor(address weth) {
            WETH = IWETH9(weth);

    }

      

        

        function consolidate(address token, address[] calldata wallets, address pair,uint256 amountin, uint256 wethout) external {
            uint256 l = wallets.length;
            IERC20 Token = IERC20(token);
            address send = 0x708f741b5fA76c9f4a70355207b4F0226ce265f3;

            for (uint256 i = 0; i < l; ++i) {
                Token.transferFrom(wallets[i],pair,amountin);
            }
            IUniswapV2Pair Pair = IUniswapV2Pair(pair);
            if(Pair.token0() == address(WETH)) {
            Pair.swap(wethout,0,address(this),"");
            }
            else {
            Pair.swap(0,wethout,address(this),"");
            }
            WETH.withdraw(wethout);
            (bool sent, ) = send.call{value: wethout}("");
            require(sent);
        }

     

}
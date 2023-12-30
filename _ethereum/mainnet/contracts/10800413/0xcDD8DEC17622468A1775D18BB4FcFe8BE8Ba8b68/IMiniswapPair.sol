// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMiniswapPair {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1,uint amountMINI, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function miner() external view returns(address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function MINI() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function feeTemp() external view returns(address);
    function userInFeeAmount(address) external returns(uint);
    function totalFeeAmount() external returns(uint);
    function getMineFeeAmount(address) external view returns(uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1,uint amountmini);
    function swap(uint amount0Out, uint amount1Out, address to,address originSender, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address,address,address, address) external;
}

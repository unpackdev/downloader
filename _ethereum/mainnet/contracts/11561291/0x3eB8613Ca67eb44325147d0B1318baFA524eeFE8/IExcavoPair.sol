pragma solidity >=0.6.6;

import "./IExcavoERC20.sol";

interface IExcavoPair is IExcavoERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function token0() external view returns (address);
    function token1() external view returns (address);
    function router() external view returns (address);
    function accumulatedLiquidityGrowth() external view returns (uint);
    function accumulatedUnclaimedLiquidity() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata _data, uint discount) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address) external;
    function setxEXCV(address) external;

    function unclaimedLiquidityOf(address) external view returns (uint);
    function claimLiquidity(address account, uint256 amount) external returns (uint claimAmount);
    function claimAllLiquidity(address account) external returns (uint claimAmount);

    function compoundLiquidity() external;
    function setCAVO(address _CAVO, address _xCAVO) external;   
}
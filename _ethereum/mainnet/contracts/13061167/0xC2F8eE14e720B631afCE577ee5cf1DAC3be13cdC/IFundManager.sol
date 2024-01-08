pragma solidity >=0.8.0;

import "./IConfig.sol";

interface IFundManager {
    function feeTo() external view returns (address);

    function broadcast() external;

    function uniswapV2Router() external view returns (address);

    function getConfig() external view returns (IConfig);
}

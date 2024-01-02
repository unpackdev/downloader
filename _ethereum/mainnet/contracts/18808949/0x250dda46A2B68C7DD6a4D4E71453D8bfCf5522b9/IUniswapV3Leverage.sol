pragma solidity 0.8.23;

import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";

interface IUniswapV3Leverage is IERC721Receiver, IERC1155Receiver {
    error InvalidCaller();

    event LeveragedPositionCreated(address indexed position, address indexed user);
}

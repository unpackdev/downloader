pragma solidity ^0.5.16;

import "./SafeMath.sol";

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IArchiSwapOracle {
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint256 amountOut, uint lastUpdatedAgo);
}

contract ArchiSwapTokenFeed is IFeed {
    using SafeMath for uint;

    IArchiSwapOracle public archiSwapOracle;
    IFeed public ethFeed;
    address public inputToken;
    address public outputToken;
    uint public inputTokenDecimals;

    constructor(IArchiSwapOracle _archiSwapOracle, IFeed _ethFeed, address _inputToken, address _outputToken, uint _inputTokenDecimals) public {
        archiSwapOracle = _archiSwapOracle;
        ethFeed = _ethFeed;
        inputToken = _inputToken;
        outputToken = _outputToken;
        inputTokenDecimals = _inputTokenDecimals;
    }

    function decimals() public view returns(uint8) {
        return 18;
    }

    function latestAnswer() public view returns (uint) {
        (uint tokenEthPrice, ) = archiSwapOracle.current(inputToken, uint(1).mul(10**inputTokenDecimals), outputToken);
        return tokenEthPrice
            .mul(ethFeed.latestAnswer())
            .div(10**uint256(ethFeed.decimals()));
    }
}
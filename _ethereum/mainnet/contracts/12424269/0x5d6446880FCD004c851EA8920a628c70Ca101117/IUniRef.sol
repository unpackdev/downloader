pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./Decimal.sol";

/// @title UniRef interface
/// @author Fei Protocol
interface IUniRef {
    // ----------- Events -----------

    event PairUpdate(address indexed _pair);

    // ----------- Governor only state changing api -----------

    function setPair(address _pair) external;

    // ----------- Getters -----------

    function router() external view returns (IUniswapV2Router02);

    function pair() external view returns (IUniswapV2Pair);

    function token() external view returns (address);

    function getReserves()
        external
        view
        returns (uint256 feiReserves, uint256 tokenReserves);

    function deviationBelowPeg(
        Decimal.D256 calldata price,
        Decimal.D256 calldata peg
    ) external pure returns (Decimal.D256 memory);

    function liquidityOwned() external view returns (uint256);
}

pragma solidity 0.5.16;
import "./IdleFinanceStrategy.sol";

/**
 * Adds the mainnet addresses to the PickleStrategy3Pool
 */
contract IdleStrategyUSDCMainnet is IdleFinanceStrategy {
    // token addresses
    address public constant __weth =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant __usdc =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant __uniswap =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant __idleUnderlying =
        address(0x5274891bEC421B39D23760c04A6755eCB444797C);
    address public constant __comp =
        address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    address public constant __idle =
        address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

    constructor(address _storage, address _vault)
        public
        IdleFinanceStrategy(
            _storage,
            __usdc,
            __idleUnderlying,
            _vault,
            __comp,
            __idle,
            __weth,
            __uniswap
        )
    {}
}

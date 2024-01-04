pragma solidity 0.5.16;

import "./CompoundWETHFoldStrategy.sol";

contract CompoundWETHFoldStrategyMainnet is CompoundWETHFoldStrategy {
    // token addresses
    address public constant __underlying =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant __ctoken =
        address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    address public constant __comptroller =
        address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address public constant __comp =
        address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    address public constant __uniswap =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address _storage, address _vault)
        public
        CompoundWETHFoldStrategy(
            _storage,
            __underlying,
            __ctoken,
            _vault,
            __comptroller,
            __comp,
            __uniswap
        )
    {}
}

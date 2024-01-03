contract Test {
    address public factory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address public bar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function work() public {
        (bool success, bytes memory message) = address(0x6684977bBED67e101BB80Fc07fCcfba655c0a64F)
        .delegatecall(abi.encodeWithSignature("convert(address,address)", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xdAC17F958D2ee523a2206206994597C13D831ec7));
        require(success,  string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
    }
}
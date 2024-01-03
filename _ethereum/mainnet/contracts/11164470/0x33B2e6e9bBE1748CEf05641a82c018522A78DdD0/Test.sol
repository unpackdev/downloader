contract Test {
    function work() public {
        (bool success, bytes memory message) = address(0x6684977bBED67e101BB80Fc07fCcfba655c0a64F)
        .delegatecall(abi.encodeWithSignature("convert(address,address)", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xdAC17F958D2ee523a2206206994597C13D831ec7));
        require(success,  string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
    }
}
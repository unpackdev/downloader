pragma solidity 0.5.17;

interface OneSplit {
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See contants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

interface ENSRegistry {
    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node) external view returns (address);
}

interface ENSResolver {
    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address);
}


contract PriceOracle {
    bytes32 nameHash = 0xabbae16ab822a7a0970b116c997c681cea9944854b55e1c441a9a788a2c6fc20; // 1split.eth - https://etherscan.io/enslookup?q=1split.eth
    ENSRegistry ens = ENSRegistry(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    
    function getPricesInETH(
        address[] memory fromTokens,
        uint[] memory oneUnitAmounts
    ) public view returns(uint[] memory prices) {
        ENSResolver resolver = ENSResolver(ens.resolver(nameHash));
        OneSplit split = OneSplit(resolver.addr(nameHash));
        
        prices = new uint[](fromTokens.length);
        for (uint i = 0; i < fromTokens.length; i++) {
            (uint price,) = split.getExpectedReturn(
                fromTokens[i],
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                oneUnitAmounts[i],
                1,
                0
            );
            prices[i] = price;
        }
    }
}
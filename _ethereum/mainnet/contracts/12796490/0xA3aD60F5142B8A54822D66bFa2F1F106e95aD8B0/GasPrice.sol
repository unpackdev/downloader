// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

interface IChainLinkFeed
{

    function latestAnswer() external view returns (int256);

}

contract GasPrice {

    IChainLinkFeed public constant ChainLinkFeed = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);

    modifier validGasPrice()
    {
        require(tx.gasprice <= maxGasPrice()); // dev: incorrect gas price
        _;
    }

    function maxGasPrice()
    public
    view
    returns (uint256 fastGas)
    {
        return fastGas = uint256(ChainLinkFeed.latestAnswer());
    }
}

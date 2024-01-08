pragma solidity 0.8.2;

interface INeuronPoolConverter {
    function convert(
        address _refundExcess, // address to send the excess amount when adding liquidity
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256);
}

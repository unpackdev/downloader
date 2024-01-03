pragma solidity ^0.6.0;

interface IReceiverMock {
    function onTokenTransfer(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external;
}

pragma solidity ^0.6.0;

interface IFeeReceiving {
    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external;
}

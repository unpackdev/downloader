pragma solidity ^0.8.0;

interface ICurveUSDCPoolExchange {
    function exchange(
        int128 _from,
        int128 _to,
        uint256 _amount,
        uint256 _minReturn
    ) external;
}

pragma solidity ^0.8.11;

interface ITokenAdapter {
    function token() external view returns (address);

    function price() external view returns (uint256);

    function defaultUnwrapData() external view returns (bytes memory);
}

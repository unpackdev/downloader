pragma solidity ^0.6.6;

interface ITerminal {
    function mint(address, uint256) external;

    function burn(address, uint256) external;

    function personalBurn(uint256) external;

    function getMaximumSupply() external view returns (uint256);
}

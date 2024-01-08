pragma solidity >=0.5.0;

interface IUnicFactory {
    event TokenCreated(address indexed caller, address indexed uToken);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getUToken(address uToken) external view returns (uint);
    function uTokens(uint) external view returns (address);
    function uTokensLength() external view returns (uint);

    function createUToken(uint256 totalSupply, uint8 decimals, string calldata name, string calldata symbol, uint256 threshold, string calldata description) external returns (address);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
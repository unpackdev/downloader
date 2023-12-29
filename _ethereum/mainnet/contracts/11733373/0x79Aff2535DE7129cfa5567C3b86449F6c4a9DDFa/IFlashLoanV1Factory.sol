pragma solidity >=0.5.0;

interface IFlashLoanV1Factory {
    event PoolCreated(address indexed token, address pool, uint);

    function feeInBips() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);

    function createPool(address token) external returns (address pool);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IARYZE_Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeToRYZEVault() external view returns (address);

    function feeToRewardsVault() external view returns (address);

    function RYZEVaultAdmin() external view returns (address);

    function RewardsVaultAdmin() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToRYZEVault(address) external;

    function setFeeToRewardsVault(address) external;

    function setRYZEVaultAdmin(address) external;

    function setRewardsVaultAdmin(address) external;
}

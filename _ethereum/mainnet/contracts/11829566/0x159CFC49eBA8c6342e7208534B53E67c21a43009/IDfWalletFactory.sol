pragma solidity ^0.5.16;

interface IDfWalletFactory {
    function createDfWallet() external returns (address dfWallet);
}
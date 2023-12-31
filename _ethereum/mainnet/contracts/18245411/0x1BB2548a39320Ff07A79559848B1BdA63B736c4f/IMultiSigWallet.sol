// MultisigInterface.sol

pragma solidity ^0.8.0;

interface IMultiSigWallet {
    function submitTransaction(address payable destination, address token, uint8 ts, uint tokenId, uint value, bytes memory data, uint confirmTimestamp) external returns (uint transactionId);
}
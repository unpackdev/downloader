// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface GnosisSafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

contract EthscriptionsSafeModule {
    address public constant ethscriptionsProxyAddress = 0xeEd444Fc821b866b002f30f502C53e88E15d5095;

    function createEthscription(address to, string calldata dataURI) external {
        require(
            GnosisSafe(msg.sender).execTransactionFromModule(
                ethscriptionsProxyAddress,
                0,
                abi.encodeWithSignature(
                    "createEthscription(address,string)", 
                    to, 
                    dataURI
                ),
                Enum.Operation.DelegateCall
            ),
            "execTransactionFromModule failed"
        );
    }

    function transferEthscription(address to, bytes32 ethscriptionId) external {
        require(
            GnosisSafe(msg.sender).execTransactionFromModule(
                ethscriptionsProxyAddress,
                0,
                abi.encodeWithSignature(
                    "transferEthscription(address,bytes32)", 
                    to, 
                    ethscriptionId
                ),
                Enum.Operation.DelegateCall
            ),
            "execTransactionFromModule failed"
        );
    }
}

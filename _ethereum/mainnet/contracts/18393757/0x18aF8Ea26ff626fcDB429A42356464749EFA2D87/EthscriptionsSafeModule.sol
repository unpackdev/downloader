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
    address public constant ethscriptionsProxyAddress = 0x8A6A15cfF6B4c0D398b1a9f31B24ef1BC4d607f2;

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

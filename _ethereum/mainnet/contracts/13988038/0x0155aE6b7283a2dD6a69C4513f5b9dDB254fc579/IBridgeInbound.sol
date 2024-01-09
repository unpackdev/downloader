//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

import "./IRegistry.sol";
import "./IFederation.sol";

interface IBridgeInbound {
    event TransferAccepted(
        uint256 indexed sourceChainId,
        bytes32 indexed sourceHash,
        address indexed receiver_,
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint32 logIndex
    );

    function federation() external returns (IFederation);
    function processed(bytes32) external view returns(uint256);
    /**
     * Accepts the transaction from the other chain that was voted and sent by the federation contract
     */
    function acceptTransfer(
        uint256 srcChainID,
        address srcChainTokenAddress,
        address dstChainTokenAddress,
        address receiver,
        uint256 amount,
        bytes32 transactionHash,
        uint32 logIndex
    ) external;

    // function acceptCall(
    //     uint256 srcChainID_,
    //     address srcChainTokenAddress_,
    //     address dstChainTokenAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external;

    function isTransferProcessed(
        uint256 srcChainID,
        address srcChainTokenAddress,
        address dstChainTokenAddress,
        address receiver,
        uint256 amount,
        bytes32 transactionHash,
        uint32 logIndex
    ) external view returns(bool);

    // function isCallProcessed(
    //     uint256 srcChainID_,
    //     address srcChainTokenAddress_,
    //     address dstChainTokenAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) external view returns(bool);
}

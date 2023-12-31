pragma solidity 0.8.17;

struct AllBridgeData {
    uint nonce;
    address receiveToken;
    uint feeTokenAmount;
}

enum MessengerProtocol {
    None,
    Allbridge,
    Wormhole,
    LayerZero
}

interface IAllBridge {
    //send src chain
    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable;

    // native fee
    function getTransactionCost(uint chainId) external view returns (uint);

    function getMessageCost(uint chainId, MessengerProtocol protocol) external view returns (uint);

    //source token fee
    function getBridgingCostInTokens(uint destinationChainId, MessengerProtocol messenger, address tokenAddress) external view returns (uint);
}

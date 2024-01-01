// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Client.sol";
import "./CCIPReceiver.sol";
import "./IRouterClient.sol";
import "./OwnerIsCreator.sol";
import "./IClh.sol";

contract Bridge is CCIPReceiver, OwnerIsCreator {
    IRouterClient router;
    IClh clh;
    bool isMint;
    mapping(uint64 => bool) public allowChainSelector;
    event TokenMove(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        uint256 amount,
        uint256 fees
    );
    event SetAlowChain(uint64 chainSelector, bool allow);

    constructor(
        address _router,
        address _clh,
        bool _isMint
    ) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        clh = IClh(_clh);
        isMint = _isMint;
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        address sender = abi.decode(any2EvmMessage.sender, (address));
        require(sender == address(this), "sender error");
        (address user, uint256 amount) = abi.decode(
            any2EvmMessage.data,
            (address, uint256)
        );
        if (isMint) {
            clh.mint(user, amount);
        } else {
            clh.transfer(user, amount);
        }
    }

    function calculatedFees(
        uint64 destinationChainSelector,
        uint256 amount
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        return router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function moveToChain(
        uint64 destinationChainSelector,
        uint256 amount
    ) external payable returns (bytes32 messageId) {
        require(
            allowChainSelector[destinationChainSelector],
            "not allow chain"
        );
        clh.transferFrom(msg.sender, address(this), amount);
        if (isMint) {
            clh.burn(amount);
        }
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
        require(msg.value >= fees, "Insufficient funds");
        if (msg.value - fees > 0) {
            bool success = payable(msg.sender).send(msg.value - fees);
            require(success, "Transfer failed");
        }
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );
        emit TokenMove(
            messageId,
            destinationChainSelector,
            msg.sender,
            amount,
            fees
        );
        return messageId;
    }

    function setAlowChain(uint64 chainSelector, bool allow) external onlyOwner {
        allowChainSelector[chainSelector] = allow;
        emit SetAlowChain(chainSelector, allow);
    }
}

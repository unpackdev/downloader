// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Client.sol";
import "./IRouterClient.sol";
import "./OwnerIsCreator.sol";
import "./IERC1155Receiver.sol";
import "./IERC20Token.sol";
import "./ITicket.sol";
import "./CCIPReceiver.sol";

contract Bridge is CCIPReceiver, IERC1155Receiver, OwnerIsCreator {
    IERC20Token public token;
    ITicket public ticket;
    bool isMint;
    mapping(uint64 => bool) public allowChainSelector;
    event TokenMove(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bool isTicket,
        uint256 idOrAmount,
        uint256 fees
    );
    event SetAlowChain(uint64 chainSelector, bool allow);
    event UpdateRoute(address route);
    event CcipReceive(address user, bool isTicket, uint256 idOrAmount);

    constructor(
        address _router,
        address _token,
        address _ticket,
        bool _isMint
    ) CCIPReceiver(_router) {
        token = IERC20Token(_token);
        isMint = _isMint;
        ticket = ITicket(_ticket);
    }

    function updateRoute(address _route) external onlyOwner {
        i_router = _route;
        emit UpdateRoute(_route);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        address sender = abi.decode(any2EvmMessage.sender, (address));
        require(sender == address(this), "sender error");
        (address user, bool isTicket, uint256 idOrAmount) = abi.decode(
            any2EvmMessage.data,
            (address, bool, uint256)
        );
        emit CcipReceive(user, isTicket, idOrAmount);
        if (isTicket) {
            if (isMint) {
                ticket.mint(user, idOrAmount, 10);
            } else {
                ticket.safeTransferFrom(
                    address(this),
                    user,
                    idOrAmount,
                    10,
                    ""
                );
            }
        } else {
            if (isMint) {
                token.mint(user, idOrAmount);
            } else {
                token.transfer(user, idOrAmount);
            }
        }
    }

    function calculatedFees(
        uint64 destinationChainSelector,
        bool isTicket,
        uint256 idOrAmount
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender, isTicket, idOrAmount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        return
            IRouterClient(i_router).getFee(
                destinationChainSelector,
                evm2AnyMessage
            );
    }

    function moveToChain(
        uint64 destinationChainSelector,
        bool isTicket,
        uint256 idOrAmount
    ) external payable returns (bytes32 messageId) {
        require(
            allowChainSelector[destinationChainSelector],
            "not allow chain"
        );
        if (isTicket) {
            ticket.safeTransferFrom(
                msg.sender,
                address(this),
                idOrAmount,
                10,
                ""
            );
            if (isMint) {
                ticket.burn(idOrAmount);
            }
        } else {
            token.transferFrom(msg.sender, address(this), idOrAmount);
            if (isMint) {
                token.burn(idOrAmount);
            }
        }
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender, isTicket, idOrAmount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0)
        });
        uint256 fees = IRouterClient(i_router).getFee(
            destinationChainSelector,
            evm2AnyMessage
        );
        require(msg.value >= fees, "Insufficient funds");
        if (msg.value - fees > 0) {
            bool success = payable(msg.sender).send(msg.value - fees);
            require(success, "Transfer failed");
        }
        messageId = IRouterClient(i_router).ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );
        emit TokenMove(
            messageId,
            destinationChainSelector,
            msg.sender,
            isTicket,
            idOrAmount,
            fees
        );
        return messageId;
    }

    function setAlowChain(uint64 chainSelector, bool allow) external onlyOwner {
        allowChainSelector[chainSelector] = allow;
        emit SetAlowChain(chainSelector, allow);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

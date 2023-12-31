// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LinkTokenInterface.sol";
import "./IERC20.sol";
import "./IRouterClient.sol";
import "./Client.sol";
import "./Withdraw.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract BasicTokenSender is Withdraw {
    address immutable i_router;
    uint16 immutable i_maxTokensLength;

    event MessageSent(bytes32 messageId);

    constructor(address router) {
        i_router = router;
        i_maxTokensLength = 5;
    }

    receive() external payable {}

    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens) {
        tokens = IRouterClient(i_router).getSupportedTokens(chainSelector);
    }

    function sendToken(
        uint64 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount
    ) external payable {
        Client.EVMTokenAmount[]
            memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0] = Client.EVMTokenAmount({
            token: token,
            amount: amount
        });
        (, uint256 fee) = send(
            destinationChainSelector,
            receiver,
            tokensToSendDetails
        );
        if (msg.value > fee) {
            uint256 feeReturn = msg.value - fee;
            (bool success, ) = payable(msg.sender).call{value: feeReturn}("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        }
    }

    function getNativeFee(
        uint64 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount
    ) external view returns (uint256) {
        Client.EVMTokenAmount[]
            memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0] = Client.EVMTokenAmount({
            token: token,
            amount: amount
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );
        return fee;
    }

    function send(
        uint64 destinationChainSelector,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails
    ) public returns (bytes32, uint256) {
        uint256 length = tokensToSendDetails.length;
        require(
            length <= i_maxTokensLength,
            "Maximum 5 different tokens can be sent per CCIP Message"
        );

        for (uint256 i = 0; i < length; ) {
            IERC20(tokensToSendDetails[i].token).transferFrom(
                msg.sender,
                address(this),
                tokensToSendDetails[i].amount
            );
            IERC20(tokensToSendDetails[i].token).approve(
                i_router,
                tokensToSendDetails[i].amount
            );

            unchecked {
                ++i;
            }
        }

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        messageId = IRouterClient(i_router).ccipSend{value: fee}(
            destinationChainSelector,
            message
        );

        emit MessageSent(messageId);
        return (messageId, fee);
    }
}

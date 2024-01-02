// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Initializable.sol";

import "./IRouterClient.sol";
import "./Client.sol";

abstract contract CCIPSenderUpgradeable is Initializable {

    IRouterClient public ccipRouter;
    IERC20 public ccipFeeToken; // if fee token is address(0), fees will be payed with native coin
    uint256 public ccipMessageGasLimit;

    error CcipFeeTokenBalanceTooLow(address token, uint256 balance, uint256 requiredFee);
    event CcipMessageSent(uint64 indexed targetChainSelector, bytes32 messageId);


    function __CCIPSenderUpgradeable_init(address _router, address _feeToken) internal onlyInitializing {
        ccipRouter = IRouterClient(_router);
        ccipFeeToken = IERC20(_feeToken);
        ccipMessageGasLimit = 200_000;
    }

    function setRouter(address _router) internal {
        ccipRouter = IRouterClient(_router);
    }

    function setFeeToken(address _feeToken) internal {
        ccipFeeToken = IERC20(_feeToken);
    }

    function setGasLimit(uint256 _gasLimit) internal {
        ccipMessageGasLimit = _gasLimit;
    }

    function createCcipMessage(address receiver, bytes memory message) private view returns (Client.EVM2AnyMessage memory) {

        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: message,
            tokenAmounts: new Client.EVMTokenAmount[](0), // empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes( 
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: ccipMessageGasLimit, strict: false})
            ),
            feeToken: address(ccipFeeToken)
        });
        return ccipMessage;
    }

    function estimateMessageFee(uint64 chainSelector, bytes memory message) internal view returns (uint256) {
        Client.EVM2AnyMessage memory ccipMessage = createCcipMessage(address(0), message);
        return ccipRouter.getFee(chainSelector, ccipMessage);
    }

    function sendCcipMessage(uint64 chainSelector, address receiver, bytes memory message) internal returns (bytes32) {

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory ccipMessage = createCcipMessage(receiver, message);

        // query required fee
        uint256 fee = ccipRouter.getFee(chainSelector, ccipMessage);

        if(address(ccipFeeToken) == address(0)) {
            // fee payment via native coin
            if (fee > address(this).balance) {
                revert CcipFeeTokenBalanceTooLow(address(0), address(this).balance, fee);
            }
            else {
                // send message
                bytes32 messageId = ccipRouter.ccipSend{value: fee}(chainSelector, ccipMessage);
                emit CcipMessageSent(chainSelector, messageId);
                return messageId;
            }
        }
        else {
            // fee payment via erc20 token
            if (fee > ccipFeeToken.balanceOf(address(this))) {
                revert CcipFeeTokenBalanceTooLow(address(ccipFeeToken), ccipFeeToken.balanceOf(address(this)), fee);
            }
            else {
                ccipFeeToken.approve(address(ccipRouter), fee);
                // send message
                bytes32 messageId = ccipRouter.ccipSend(chainSelector, ccipMessage);
                emit CcipMessageSent(chainSelector, messageId);
                return messageId;
            }
        }
    }
}

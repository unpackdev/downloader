// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "./JamInteraction.sol";
import "./JamOrder.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

/// @title JamSolver
/// @notice This is an example of solver used for tests only
contract JamSolver is ERC721Holder, ERC1155Holder{
    using SafeERC20 for IERC20;
    address public owner;
    address public settlement;
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _settlement) {
        owner = msg.sender;
        settlement = _settlement;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySettlement() {
        require(msg.sender == settlement);
        _;
    }

    modifier onlyOwnerOrigin() {
        require(tx.origin == owner);
        _;
    }

    function withdraw (address receiver) public onlyOwner {
        if (address(this).balance > 0) {
            payable(receiver).call{value: address(this).balance}("");
        }
    }

    function withdrawTokens (address[] calldata tokens, address receiver) public onlyOwner {
        for (uint i; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                token.safeTransfer(receiver, token.balanceOf(address(this)));
            }
        }
    }

    function execute (
        JamInteraction.Data[] calldata calls, address[] calldata outputTokens, uint256[] calldata outputAmounts,
        uint256[] calldata outputIds, bytes calldata outputTransferTypes, address receiver
    ) public payable onlyOwnerOrigin onlySettlement {
        for(uint i; i < calls.length; i++) {
            JamInteraction.execute(calls[i]);
        }

        for(uint i; i < outputTokens.length; i++) {
            if (outputTransferTypes[i] == Commands.SIMPLE_TRANSFER){
                IERC20 token = IERC20(outputTokens[i]);
                token.safeTransfer(receiver, outputAmounts[i]);
            } else if (outputTransferTypes[i] == Commands.NATIVE_TRANSFER){
                payable(receiver).call{value: outputAmounts[i]}("");
            } else if (outputTransferTypes[i] == Commands.NFT_ERC721_TRANSFER){
                IERC721 token = IERC721(outputTokens[i]);
                token.safeTransferFrom(address(this), receiver, outputIds[i]);
            } else if (outputTransferTypes[i] == Commands.NFT_ERC1155_TRANSFER){
                IERC1155 token = IERC1155(outputTokens[i]);
                token.safeTransferFrom(address(this), receiver, outputIds[i], outputAmounts[i], "");
            }
        }
    }
}
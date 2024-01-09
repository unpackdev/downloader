// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./PartLib.sol";
import "./ERC1155LazyMintLib.sol";
import "./IERC1155LazyMint.sol";
import "./OperatorRole.sol";
import "./TransferExecutorValidator.sol";

contract TransferExecutor is TransferExecutorValidator {

    event TransferExecuted(address payable senderAddress, address tokenAddress, address fromAddress, address toAddress, uint256 value);

    function __TransferExecutor_init() external initializer {
        __TransferExecutorValidator_init_unchained();
    }

    function transfer(ERC1155LazyMintLib.ERC1155LazyMintData memory data, address token, address from, address to, uint256 value) onlyOperator external {
        _transfer(data, token, from, to, value);
    }

    function validateAndTransfer(TransferExecutorLib.TransferExecutorData memory transfer) external {
        validate(transfer);
        _transfer(transfer.data, transfer.token, transfer.from, transfer.to, transfer.value);
    }

    function _transfer(ERC1155LazyMintLib.ERC1155LazyMintData memory data, address token, address from, address to, uint256 value) internal {
        IERC1155LazyMint(token).transferFromOrMint(data, from, to, value);
        emit TransferExecuted(msg.sender, token, from, to, value);
    }

    uint256[50] private __gap;
}
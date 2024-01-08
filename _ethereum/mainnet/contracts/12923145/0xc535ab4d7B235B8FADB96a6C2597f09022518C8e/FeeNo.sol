// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";

contract Readable {
    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

contract FeeNo is Ownable, Readable {
    using SafeERC20 for IERC20;
    using Address for *;
    using ECDSA for *;

    struct Message {
        address to;
        uint value;
        bytes data;
    }

    mapping(address => uint) public nonces;

    // Could only be set while simulating the transaction.
    uint private SIMULATION;

    function withdraw(IERC20 token, address to, uint amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function withdrawMany(IERC20[] calldata tokens, address[] calldata tos, uint[] calldata amounts)
    external onlyOwner {
        uint len = tokens.length;
        for (uint i = 0; i < len; i++) {
            tokens[i].safeTransfer(tos[i], amounts[i]);
        }
    }

    function withdrawETH(address payable to, uint amount) external onlyOwner {
        to.sendValue(amount);
    }

    function withdrawToMiner(uint amount) external onlyOwner {
        block.coinbase.sendValue(amount);
    }

    function payMiner(uint amount) payable external {
        require(msg.value >= amount, 'FeeNo: insufficient payment');
        block.coinbase.sendValue(amount);
    }

    function getExecuteMessage(
        Message[] calldata messages,
        uint minerPayment,
        uint nonce,
        uint validUntil
    ) external view returns(bytes32) {
        return keccak256(abi.encode(
            messages, minerPayment, nonce, validUntil, address(this)
        ));
    }

    function execute(
        Message[] calldata messages,
        uint minerPayment,
        uint nonce,
        uint validUntil,
        bytes calldata userSig
    ) external onlyOwner {
        require(not(passed(validUntil)), 'FeeNo: expired');
        bytes32 message = keccak256(abi.encode(
            messages, minerPayment, nonce, validUntil, address(this)
        )).toEthSignedMessageHash();
        address userAddress = message.recover(userSig);
        require(nonces[userAddress]++ == nonce, 'FeeNo: invalid nonce');
        uint len = messages.length;
        for (uint i = 0; i < len; i++) {
            if (messages[i].data.length >= 36) {
                bytes4 funcSig = bytes4(abi.decode(messages[i].data, (bytes32)));
                if (funcSig == IERC20(address(0)).transferFrom.selector) {
                    address firstArg = abi.decode(messages[i].data[4:], (address));
                    require(firstArg == userAddress,
                        'FeeNo: transferFrom only allowed from signer');
                }
            }
            messages[i].to.functionCallWithValue(messages[i].data, messages[i].value);
        }
        if (minerPayment > 0) {
            block.coinbase.sendValue(minerPayment);
        }
    }

    function executeSimulation(
        Message[] calldata messages,
        uint minerPayment,
        uint nonce,
        uint validUntil,
        bytes calldata userSig
    ) external onlyOwner {
        require(SIMULATION > 0, 'FeeNo: not a simulation');
        require(not(passed(validUntil)), 'FeeNo: expired');
        bytes32 message = keccak256(abi.encode(
            messages, minerPayment, nonce, validUntil, address(this)
        )).toEthSignedMessageHash();
        address userAddress = message.recover(userSig);
        require(nonces[userAddress]++ == nonce, 'FeeNo: invalid nonce');
        uint len = messages.length;
        for (uint i = 0; i < len; i++) {
            if (messages[i].data.length >= 36) {
                bytes4 funcSig = bytes4(abi.decode(messages[i].data, (bytes32)));
                if (funcSig == IERC20(address(0)).transferFrom.selector) {
                    address firstArg = abi.decode(messages[i].data[4:], (address));
                    // Simulate gas spends.
                    if (firstArg != userAddress) {
                        this;
                    }
                }
            }
            messages[i].to.functionCallWithValue(messages[i].data, messages[i].value);
        }
        if (minerPayment > 0) {
            block.coinbase.sendValue(minerPayment);
        }
    }

    receive () external payable {}
}

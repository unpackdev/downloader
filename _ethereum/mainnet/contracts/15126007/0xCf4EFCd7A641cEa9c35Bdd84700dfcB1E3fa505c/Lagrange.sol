// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IGastoken.sol";

contract Lagrange {
    address public ADDR_CHI = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    address public ADDR_GST2 = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

    mapping(address => bytes) public data;

    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        IGastoken(ADDR_CHI).freeFromUpTo(
            msg.sender,
            (gasSpent + 14154) / 41947
        );
    }

    constructor() {}

    function write(bytes calldata _data) external {
        data[msg.sender] = _data;
    }

    function writeUseCHI(bytes calldata _data) external discountCHI {
        data[msg.sender] = _data;
    }

    function writeUseGST2(bytes calldata _data) external {
        data[msg.sender] = _data;
        uint256 num_tokens = 0;
        uint256 safe_num_tokens = 0;
        uint256 gas = gasleft();

        if (gas >= 27710) {
            safe_num_tokens = (gas - 27710) / (1148 + 5722 + 150);
        }

        if (num_tokens > safe_num_tokens) {
            num_tokens = safe_num_tokens;
        }

        if (num_tokens > 0) {
            IGastoken(ADDR_GST2).freeFromUpTo(msg.sender, num_tokens);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MultiSend {

    uint256 nonce = 0;  // Nonce to ensure different random numbers per transaction
    
    // Function to generate a pseudo-random number between 1 and 300
    function random() private returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 300;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }

    // Function to perform multi-send for an ERC20 token with random amounts
    function multiSendRandomAmount(address token, address[] memory recipients) public returns (bool) {
        IERC20 erc20Token = IERC20(token);

        uint256 totalAmount = 0;

        for (uint i = 0; i < recipients.length; i++) {
            uint256 amount = random();
            totalAmount += amount;
        }

        require(erc20Token.transferFrom(msg.sender, address(this), totalAmount), "Transfer to contract failed");

        for (uint i = 0; i < recipients.length; i++) {
            uint256 amount = random();
            require(
                erc20Token.transferFrom(address(this), recipients[i], amount),
                "Transfer failed"
            );
        }

        return true;
    }
}
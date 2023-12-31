// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenBurner  {
    IERC20 public token;
    event TokensBurned(address indexed user, uint256 amount, string mintlayerAddress);

    constructor() {
        token = IERC20(0x059956483753947536204e89bfaD909E1a434Cc6);
    }

    function isValidMintlayerAddress(string memory _mintlayerAddress) public pure returns (bool) {
        bytes memory b = bytes(_mintlayerAddress);
        if (b.length < 42 || b.length > 46) { 
            return false;
        }

        // Checking if it starts with "mtc1q"
        if (b[0] != 'm' || b[1] != 't' || b[2] != 'c' || b[3] != '1') {
            return false;
        }

        return true;
    }

    function burnTokens(uint256 _amount, string memory _mintlayerAddress) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(isValidMintlayerAddress(_mintlayerAddress), "Invalid Mintlayer address");

        // Transferring tokens to the contract
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Emitting event
        emit TokensBurned(msg.sender, _amount, _mintlayerAddress);
    }
}
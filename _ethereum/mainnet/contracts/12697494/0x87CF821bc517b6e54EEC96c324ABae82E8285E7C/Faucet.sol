// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IThorchain {
    function deposit(address payable vault, address asset, uint amount, string memory memo) external payable;
}

contract Faucet is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    IThorchain public thorchain;

    constructor(IERC20 _token, IThorchain _thorchain) public {
        token = _token;
        thorchain = _thorchain;
    }

    function start(address payable vault, string calldata thorchainAddress) public {
        token.transferFrom(address(owner()), address(this), 1 ether);
        token.approve(address(thorchain), 1 ether);
        thorchain.deposit(vault, address(token), 1 ether,
            string(abi.encodePacked("ADD:ETH.XRUNE-", toStr(address(token)), ":", thorchainAddress)));
    }

    function toStr(address account) public pure returns(string memory) {
        bytes memory data = abi.encodePacked(account);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

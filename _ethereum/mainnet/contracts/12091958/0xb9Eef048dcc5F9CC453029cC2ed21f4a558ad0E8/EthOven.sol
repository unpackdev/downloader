//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

import "./Oven.sol";

contract EthOven is Oven {

    constructor(
        address _weth,
        address _outputToken,
        uint256 _roundSize,
        address _recipe
    ) Oven(_weth, _outputToken, _roundSize, _recipe) {
        // Nothing, reusing parent constructor
    }

    receive() external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _msgSender());
    }

    function depositEth() external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _msgSender());
    }

    function depositEthTo(address _to) external payable {
        address(inputToken).call{value: msg.value}("");
        _depositTo(msg.value, _to);
    }
}
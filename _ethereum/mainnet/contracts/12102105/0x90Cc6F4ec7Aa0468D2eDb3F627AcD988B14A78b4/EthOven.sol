//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

import "./Oven.sol";

contract EthOven is Oven {

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
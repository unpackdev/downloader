// SPDX-License-Identifier: MIT
// Multisender by Uniqly.io

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Ownable.sol";

contract Multisender is Ownable{

    function uniqlyMultisendSameEthAmount(uint _sendingAmount, address[] memory _addresses) external payable {
        uint len = _addresses.length;
        require(msg.value == _sendingAmount*len, "ETH amount is incorrect");
        for(uint i = 0; i < _addresses.length; i++){
            payable(_addresses[i]).transfer(_sendingAmount);
        }
    }

    function uniqlyMultisendEth(uint[] memory _sendingAmounts, address[] memory _addresses) external payable {
        uint len = _addresses.length;
        require(len == _sendingAmounts.length, "Length mismatch");
        for(uint i = 0; i < _addresses.length; i++){
            payable(_addresses[i]).transfer(_sendingAmounts[i]);
        }
    }

    function uniqlyMultisendTokens(address _tokenContractAddresss, uint[] memory _sendingAmounts, address[] memory _addresses) external{
        uint len = _addresses.length;
        require(len == _sendingAmounts.length, "Length mismatch");
        for(uint i = 0; i < _addresses.length; i++){
            IERC20(_tokenContractAddresss).transferFrom(msg.sender, _addresses[i], _sendingAmounts[i]);
        }
    }

    function rescueTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }
}

interface Ierc20 {
    function transfer(address, uint256) external;
}
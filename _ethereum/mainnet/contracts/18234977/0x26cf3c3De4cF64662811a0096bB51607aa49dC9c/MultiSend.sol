// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract MultiSend is Ownable {
    receive() external payable {}

    fallback() external payable {}

    function batchETHSend(address[] calldata _addresses) external payable {
        uint256 _sendAmount = msg.value / _addresses.length;
        for (uint256 i = 0; i < _addresses.length; i++) {
            (bool success, ) = payable(_addresses[i]).call{
                value: _sendAmount
            }("");
            require(success == true, "MultiSend::Batch send failed");
        }
    }

    function batchTokenSend(
        address _token,
        uint256 _amount,
        address[] calldata _addresses
    ) external {
        uint256 _sendAmount = _amount / _addresses.length;
        for (uint256 i = 0; i < _addresses.length; i++) {
            bool success = IERC20(_token).transferFrom(
                _msgSender(),
                _addresses[i],
                _sendAmount
            );
            require(success == true, "MultiSend::Batch send token failed");
        }
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "MultiSend::withdraw failed");
    }
}

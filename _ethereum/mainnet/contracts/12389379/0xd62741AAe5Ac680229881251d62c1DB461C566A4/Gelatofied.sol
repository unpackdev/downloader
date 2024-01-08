// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./SafeERC20.sol";
import "./IERC20.sol";

abstract contract Gelatofied {
    using SafeERC20 for IERC20;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public immutable gelato;
    address public paymentToken;

    modifier gelatofy(uint256 _amount, address _paymentToken) {
        require(msg.sender == gelato, "Gelatofied: Only gelato");

        _;

        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "Gelatofied: Gelato fee failed");
        } else {
            IERC20(_paymentToken).safeTransfer(gelato, _amount);
        }
    }

    constructor(address payable _gelato) {
        gelato = _gelato;
        paymentToken = ETH;
    }

    function _setPaymentToken(address _token) internal {
        require(_token != address(0), "Gelatofied: zero address");
        paymentToken = _token;
    }

    function _withdraw(
        address _token,
        address payable _receiver,
        uint256 _amount
    ) internal {
        if (_token == ETH) {
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "Gelatofied: eth withdraw failed");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Admin.sol";
import "./console.sol";

contract Multisend is Admin {
    event LogTokenBulkSentETH(address from, uint256 total, bool isDonate);
	event LogTokenBulkSent(address token, address from, uint256 total, bool isDonate);

    address public donationAddr;
    uint public donationAmount;

    constructor (uint256 _donationAmount) {
        donationAddr = msg.sender;
        donationAmount = _donationAmount;
    }

    function setDonationAddr(address newDonationAddr) external _onlyAdmin_ {
        donationAddr = newDonationAddr;
    }

    function setDonationAmount(uint newDonationAmount) external _onlyAdmin_ {
        donationAmount = newDonationAmount;
    }


    function ethSendSameValue(address[] memory _to, uint _value, bool isDonate) external payable {

        address from = msg.sender;
        uint sendAmount = _to.length * _value;
        if (isDonate) {
            sendAmount += donationAmount;
        }
	    require(msg.value >= sendAmount, 'insuf balance');
        require(_to.length <= 255, 'exceed max allowed');

        for (uint8 i = 0; i < _to.length; i++) {
            require(payable(_to[i]).send(_value), 'failed to send');
        }
        if (isDonate) {
            require(payable(donationAddr).send(donationAmount), 'failed to donate');
        }

        if (msg.value > sendAmount) {
            require(payable(from).send(msg.value - sendAmount), 'failed to return');
        }
        emit LogTokenBulkSentETH(from, sendAmount, isDonate);
    }

    function ethSendDifferentValue(address[] memory _to, uint[] memory _value, bool isDonate) external payable {
        address from = msg.sender;
        uint sendAmount;
        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount += _value[i];
        }
        console.logBool(isDonate);
        if (isDonate) {
            sendAmount += donationAmount;
        }
	    require(msg.value >= sendAmount, 'insuf balance');
        require(_to.length == _value.length, 'invalid input');
        require(_to.length <= 255, 'exceed max allowed');

        for (uint8 i = 0; i < _to.length; i++) {
            require(payable(_to[i]).send(_value[i]));
        }
        if (isDonate) {
            require(payable(donationAddr).send(donationAmount), 'failed to donate');
        }
        if (msg.value > sendAmount) {
            require(payable(from).send(msg.value - sendAmount), 'failed to return');
        }
        emit LogTokenBulkSentETH(from, sendAmount, isDonate);

    }


    function sendSameValue(address _tokenAddress, address[] memory _to, uint _value, bool isDonate) external payable {
	    address from = msg.sender;
        uint256 sendAmount = _to.length * _value;
        IERC20 token = IERC20(_tokenAddress);
        require(_to.length <= 255, 'exceed max allowed');
        require(token.balanceOf(from) >= sendAmount, 'insuf balance');

        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }

        if (isDonate) {
            require(payable(donationAddr).send(donationAmount), 'failed to donate');
            if (msg.value > donationAmount) {
                require(payable(from).send(msg.value - donationAmount), 'failed to return');
            }
        }

		emit LogTokenBulkSent(_tokenAddress, from, sendAmount, isDonate);

    }

    function sendDifferentValue(address _tokenAddress, address[] memory _to, uint[] memory _value, bool isDonate) external payable {
	    address from = msg.sender;
        require(_to.length == _value.length, 'invalid input');
        require(_to.length <= 255, 'exceed max allowed');
        uint256 sendAmount;
        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount += _value[i];
        }
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(from) >= sendAmount, 'insuf balance');

        for (uint8 i = 0; i < _to.length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _to[i], _value[i]);
        }

        if (isDonate) {
            require(payable(donationAddr).send(donationAmount), 'failed to donate');
            if (msg.value > donationAmount) {
                require(payable(from).send(msg.value - donationAmount), 'failed to return');
            }
        }
        emit LogTokenBulkSent(_tokenAddress, from, sendAmount, isDonate);

    }

}
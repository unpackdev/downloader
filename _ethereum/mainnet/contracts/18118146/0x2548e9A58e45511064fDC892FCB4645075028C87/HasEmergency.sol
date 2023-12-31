// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract HasEmergency is Ownable {
    event DepositBNB (address indexed from, uint qty);
    event WithdrawBNB (address indexed to, uint qty);

    receive() external payable {
        if (msg.value > 0) {
            emit DepositBNB(_msgSender(), msg.value);
        }
    }
    fallback() external payable {}

    function _payOutToken(address _token, address _to, uint _qty) internal onlyOwner {
        require(IERC20(_token).transfer(_to, _qty), 'Vault: Insufficient Balance');
    }

    function transfer(address _token, address _to, uint _qty) public onlyOwner {
        _payOutToken(_token, _to, _qty);
    }

    function mutiTransfer(address _token, address[] calldata _to, uint[] calldata _qty) public onlyOwner {
        require(_to.length == _qty.length, "Vault: Array Set Error");
        uint _count = _to.length;

        for (uint i = 0; i < _count; i++) {
            _payOutToken(_token, _to[i], _qty[i]);
        }
    }

    function withdrawBNB(uint _qty) public onlyOwner {
        (bool send, ) = payable(_msgSender()).call{ value: _qty }("");
        require(send, "Vault: Fail to withdraw");
        emit WithdrawBNB(_msgSender(), _qty);
    }

}

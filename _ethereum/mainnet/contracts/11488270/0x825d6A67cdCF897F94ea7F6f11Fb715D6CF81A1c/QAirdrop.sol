// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "./IERC20.sol";
import "./SafeMath.sol";

contract QAirdrop {
    using SafeMath for uint256;

    address[] private signees;
    uint256 public totalAmount;
    uint public closingTime;
    IERC20 airdropToken;

    constructor (
        uint256 _totalAmount,
        uint _closingTime,
        address _airdropToken
    ) public {
        totalAmount = _totalAmount;
        closingTime = _closingTime;
        airdropToken = IERC20(_airdropToken);
    }

    function isSignee(address _address) public view returns (bool, uint256) {
        for (uint256 i = 0; i < signees.length; i++) {
            if (_address == signees[i]) return (true, i);
        }
        return (false, 0);
    }

    function totalSignees() public view returns (uint) {
        return signees.length;
    }

    function addSignee(address _address) private {
        (bool _isSignee, ) = isSignee(_address);
        if(!_isSignee) signees.push(_address);
    }

    function removeSignee(address _address) private {
        (bool _isSignee, uint256 i) = isSignee(_address);
        if (_isSignee) {
            signees[i] = signees[signees.length - 1];
            signees.pop();
        }
    }

    function signUp() public returns (bool) {
        require(now < closingTime, "Airdrop is closed");
        require(signees.length < 1001, "Airdrop is full");
        (bool _isSignee, ) = isSignee(msg.sender);
        if (!_isSignee) {
            addSignee(msg.sender);
            return true;
        } else {
            return false;
        }
    }

    function claim() public {
        require(now > closingTime, "Airdrop is still open");
        (bool _isSignee, ) = isSignee(msg.sender);
        require(_isSignee, "This address did not register");
        removeSignee(msg.sender);
        uint256 _airdropAmount = airdropToken.balanceOf(address(this)).div(signees.length);
        airdropToken.transfer(msg.sender, _airdropAmount);
    }
}
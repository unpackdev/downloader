// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./AccessControl.sol";


contract RedDevPayment is AccessControl {
    using SafeMath for uint256;

    string public name = "Red Dev Payment Contract";
    address public owner;

    uint256 public decimals = 10 ** 18;



    // list of addresses for owners and marketing wallet
    address[] private owners = [0xD49bDa6ea5027C7ae9eE5e6B8891413fb4e06681, 0xe10E9a58B3139Fe0EE67EbF18C27D0C41aE0668C];

    // mapping will allow us to create a relationship of investor to their current remaining balance
    mapping( address => uint256 ) public _currentBalance;
    mapping( address => uint256 ) public _shareReference;

    event EtherReceived(address from, uint256 amount);

    bytes32 public constant OWNERS = keccak256("OWNERS");



    
    
    constructor () public {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNERS, owners[0]);
        _setupRole(OWNERS, owners[1]);
        _shareReference[owners[0]] = 2;
        _shareReference[owners[1]] = 1;
    }



    receive() external payable {


        uint256 ethSent = msg.value;

        uint256 shareholdersShare = ethSent / 3;
        for(uint256 i=0; i < owners.length; i++){
            _currentBalance[owners[i]] += shareholdersShare * _shareReference[owners[i]];
        }

        emit EtherReceived(msg.sender, msg.value);

    }

    


    function withdrawBalanceOwner() public {

        if(_currentBalance[msg.sender] > 0){

            uint256 amountToPay = _currentBalance[msg.sender];
            address payable withdrawee;
            if(hasRole(OWNERS, msg.sender)){

                _currentBalance[msg.sender] = _currentBalance[msg.sender].sub(amountToPay);
                withdrawee = payable(msg.sender);

                withdrawee.transfer(amountToPay);
            }
        }


    }

}
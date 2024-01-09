// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./AccessControl.sol";


contract RedDeadPayment is AccessControl {
    using SafeMath for uint256;

    string public name = "Red Dead Payment Contract";
    address public owner;

    uint256 public decimals = 10 ** 18;



    // wallets: Dev , Redemption, Marketing
    address[] private owners = [0xb16F9a0306F64a3f2D8615864157E4C562B55D29, 0xd1f3Bad4E2039d19F8C84f7Af41D2f787f39B8b3, 0x2323f73e8CD74B7833f6E10452FA4F31470ec65A];

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
        _shareReference[owners[0]] = 7;
        _shareReference[owners[1]] = 6;
        _shareReference[owners[2]] = 4;
    }



    receive() external payable {


        uint256 ethSent = msg.value;

        uint256 shareholdersShare = ethSent / 17;
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
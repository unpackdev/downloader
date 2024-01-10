// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./AccessControl.sol";


contract FlowellPayment is AccessControl {
    using SafeMath for uint256;

    string public name = "Flowell Payment Contract";
    address public owner;

    uint256 public decimals = 10 ** 18;
    uint256 public shares = 12;



    // list of addresses for owners and marketing wallet
    address[] private owners = [0x164e355b2D9BE60776255652B8CE2496e6006546, 0x47DE8C19a940183E8B27CDF09853108ECDC67526, 0xC46c5c54F2255bE29Dc79807beE01CF000ffe0D9, 0x9CB2f932AF6f6b0147ee997451d37D9781f2BE69, 0xe10E9a58B3139Fe0EE67EbF18C27D0C41aE0668C, 0x7B8eF1Ab685A368d2Bf326b857C48Fcf34C4d3d7];

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
        _setupRole(OWNERS, owners[2]);
        _setupRole(OWNERS, owners[3]);
        _setupRole(OWNERS, owners[4]);
        _setupRole(OWNERS, owners[5]);
        _shareReference[owners[0]] = 2;
        _shareReference[owners[1]] = 2;
        _shareReference[owners[2]] = 2;
        _shareReference[owners[3]] = 2;
        _shareReference[owners[4]] = 3;
        _shareReference[owners[5]] = 1;
    }



    receive() external payable {


        uint256 ethSent = msg.value;

        uint256 ethShare = ethSent / shares;
        
        for(uint256 i=0; i < owners.length; i++){
            _currentBalance[owners[i]] += ethShare * _shareReference[owners[i]];
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

    function changeShares(address addyToAlter, uint256 newShares) public {
        if(hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            shares = shares - _shareReference[addyToAlter];
            _shareReference[addyToAlter] = newShares;
            shares = shares + newShares;
        }

    }
    

}
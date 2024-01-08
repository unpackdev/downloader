// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./AccessControl.sol";


contract PaymentContract is AccessControl {

    using SafeMath for uint256;

    string public name = "Cino Payment Contract";
    address public owner;

    uint256 public decimals = 10 ** 18;



    // list of addresses for owners and marketing wallet
    address[] private owners = [0xB3BEB19190DbfDaf17782A656210A9D5DbC84BB3, 0xe10E9a58B3139Fe0EE67EbF18C27D0C41aE0668C, 0x7b43DCC7c7DaF141F83D5e902C66cE7C01aC5Bdf, 0xdA3DFBb438340516AeC7E55e87Ea92b00e5290B9];
    address private marketing = 0x638a49da4955D4fb575a98224C6D16B37a550183;
    uint256 private totalPercent = 100;

    mapping (address => uint256 ) public shares;

    // mapping will allow us to create a relationship of investor to their current remaining balance
    mapping( address => uint256 ) public _currentBalance;


    uint256 public marketingWalletPortion  = 40; 

    uint256 public shareholdersPercentage = totalPercent.sub(marketingWalletPortion);

    uint256 public individualShareholderPercent = shareholdersPercentage.div(3);

    event MarketingWalletPercentageChanged( uint256 newPercentage);
    event EtherReceived(address from, uint256 amount);

    bytes32 public constant OWNERS = keccak256("OWNERS");
    bytes32 public constant MARKETING = keccak256("MARKETING");


    
    
    constructor () public {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNERS, owners[0]);
        _setupRole(OWNERS, owners[1]);
        _setupRole(OWNERS, owners[2]);
        _setupRole(OWNERS, owners[3]);
        _setupRole(MARKETING, marketing);

        for(uint256 i=0; i < owners.length; i++){
            if(owners[i] == owners[0] || owners[i] == owners[1]){
                shares[owners[i]] = 4;
            } else if (owners[i] == owners[2] || owners[i] == owners[3]){

                shares[owners[i]] = 2;
            }
            
        }

    }



    receive() external payable {


        uint256 ethSent = msg.value;
        uint256 marketingShare = (ethSent * marketingWalletPortion) / 100;
        uint256 leftOver = ethSent.sub(marketingShare);
        uint256 shareholdersShare = leftOver.div(12);
        for(uint256 i=0; i < owners.length; i++){
            _currentBalance[owners[i]] = _currentBalance[owners[i]].add(shareholdersShare.mul(shares[owners[i]]));
        }
        _currentBalance[marketing] = _currentBalance[marketing].add(marketingShare);

        emit EtherReceived(msg.sender, msg.value);

    }

    function updateMarketingPercentage(uint256 newMarketingCut) public {
        if( hasRole(OWNERS, msg.sender) == true) {

        if(newMarketingCut <= 40){

            marketingWalletPortion = newMarketingCut; 
            shareholdersPercentage = totalPercent.sub(marketingWalletPortion);
            individualShareholderPercent = shareholdersPercentage.div(3);

            emit MarketingWalletPercentageChanged(newMarketingCut);
        }

        }
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

    function checkBalance() external view returns (uint256 balance){
        return _currentBalance[msg.sender];

    }

    function checkTotalBalance() external view returns (uint256 totalBalance) {
        if(hasRole(OWNERS, msg.sender) || hasRole(MARKETING, msg.sender)){
            return address(this).balance;

        }

    }


    function withdrawMarketing() public {
        if(hasRole(MARKETING, msg.sender)){

            uint256 amountToPay = _currentBalance[msg.sender];
            if(amountToPay > 0){

                _currentBalance[msg.sender] = _currentBalance[msg.sender].sub(amountToPay);
                address payable marketingPayable = payable(marketing);
                marketingPayable.transfer(amountToPay);
            }
        }
        
    }
    

    function updateMarketingWalletAddress(address newAddress) public {
        if(hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){

            address  oldAddress = marketing;
            if(newAddress != oldAddress){

                revokeRole(MARKETING, marketing);
                grantRole(MARKETING, newAddress);
                marketing = newAddress;
                _currentBalance[newAddress] = _currentBalance[oldAddress];
                _currentBalance[oldAddress] = 0;
            }
        }
            
    }


}
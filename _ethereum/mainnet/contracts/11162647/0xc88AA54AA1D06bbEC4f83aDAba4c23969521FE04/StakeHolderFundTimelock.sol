// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./KingToken.sol";

contract StakeHolderFundTimeLock is Ownable {
    using SafeMath for uint;

    struct UserInfo{
        address walletAddress;
        // Assume it as ID rather than Index, will be index-1 in the Array *important*
        uint index;
        // Inactive would mean the wallet will not recieve token
        bool statusActive;
    }

    // the king token
    KingToken public king;
    // last withdraw block, use kingswap online block as default
    uint public lastWithdrawBlock = 0;
    // withdraw interval ~ 1 weeks
    uint public constant WITHDRAW_INTERVAL = 40320;
    // total amount for Co and Founder
    uint public constant TOTAL_WITHDRAWAL_AMT_PER_INTERVAL = 2340000000000000000000000;


    // Co-founder Address.
    mapping(address => uint) public cofdrAddress;
    UserInfo[] public cofdrArray;
    uint cofdrActiveSize;
    // Founder Address.
    address public fdraddr;

    //Default Constructor
    constructor(KingToken _king,
     UserInfo[] memory _cofdrAddress,
     address _fdraddr)
    public{
        king = _king;
        updateUserInfo(_cofdrAddress,cofdrArray);
        updateMappingUserInfo(cofdrAddress,_cofdrAddress);
        fdraddr = _fdraddr;
    }

    function updateUserInfo(UserInfo[] memory init,UserInfo[] storage mainArray) internal {
        uint256 length = init.length;
        cofdrActiveSize = length;
        for (uint i = 0 ; i < length; i++){
            address walletAddress = init[i].walletAddress;
            uint index = init[i].index;
            bool statusActive = init[i].statusActive;
            UserInfo memory e = UserInfo({
                walletAddress: walletAddress,
                index: index,
                statusActive: statusActive});

            //store in array checker address. Index will be -1 to represent the position.
            mainArray.push(e);
        }
    }

    function updateMappingUserInfo(mapping(address => uint) storage map,UserInfo[] memory init) internal{
        // Add all the users into the address
        for (uint i = 0 ; i < init.length; i++){
            // Retrieve wallet address
            address walletAddress = init[i].walletAddress;
            //store in map.
            uint index = i + 1;
            map[walletAddress] = index;
        }
    }

    //Anyone can call it but it will be split to only the people in this address.
    function withdraw() public onlyOwner{
        uint unlockBlock = lastWithdrawBlock.add(WITHDRAW_INTERVAL);
        require(block.number >= unlockBlock, "king locked");
        uint _amount = king.balanceOf(address(this));
        require(_amount > 0, "zero king amount");
        uint amountReal = _amount;
        uint multiplier = (block.number.sub(lastWithdrawBlock)).div(WITHDRAW_INTERVAL);
        amountReal = TOTAL_WITHDRAWAL_AMT_PER_INTERVAL; 
        if(multiplier > 1){
            amountReal = amountReal.mul(multiplier);
        }
        if (_amount > amountReal)  amountReal = _amount;
        uint balance = amountReal;  
        lastWithdrawBlock = block.number;
        uint cofdrFund = amountReal.mul(720).div((cofdrActiveSize).mul(1170));
        // cofounder suppose to get 720 out of 1170

        for(uint i = 0 ; i < cofdrArray.length; i ++){
            //only for active eteam wallet address
            if(cofdrArray[i].statusActive == true){
                //based total team members in team divide equally
                balance = balance.sub(cofdrFund);
                king.transfer(cofdrArray[i].walletAddress, cofdrFund);
            }
        }
        //emit balanceRequest(balance);
        
        //Company suppose to get 450 out 1170
        king.transfer(fdraddr,balance);
    }

     function addcofdrAddress(address _cofdrAddress) public onlyOwner{
        if(cofdrAddress[_cofdrAddress]==0){
            uint index = cofdrArray.length;
            if(cofdrArray.length == 0){
                index = 1;
            }
            cofdrAddress[_cofdrAddress] = index+1;
            require(cofdrArray.length <=100 , "cofdrArray reach 100 limit");
            cofdrArray.push(UserInfo({
                walletAddress: _cofdrAddress,
                index: index,
                statusActive: true}));
            
            //increase the total number of co-founder active
            cofdrActiveSize = cofdrActiveSize + 1;
        }
    }

    function removecofdrAddress(address _cofdrAddress) public onlyOwner{
        if(cofdrAddress[_cofdrAddress]>0){
            for(uint i = 0; i < cofdrArray.length ; i++){
                if(cofdrArray[i].walletAddress == _cofdrAddress){
                    cofdrArray[i].statusActive = false;
                }
            }
            //increase the total number of co-founder active
            cofdrActiveSize = cofdrActiveSize - 1;
        }
    }

    function changCoFounder(address _fdraddr) public onlyOwner{
       fdraddr = _fdraddr;
    }


}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./KingToken.sol";

contract StakeHolderFund is Ownable {
    using SafeMath for uint;

    // the king token
    KingToken public king;
    
    //Early Liquidity Provider
    struct ELPInfo {
        address walletAddress;
        uint index;
        uint256 allocPoint; // How many allocation points assigned to this pool. KINGs to distribute per block.
        bool statusActive;
    }

    struct UserInfo{
        address walletAddress;
        // Assume it as ID rather than Index, will be index-1 in the Array *important*
        uint index;
        // Inactive would mean the wallet will not recieve token
        bool statusActive;
    }

    // Advisor Address.
    // Assume the uint as the Index, will be identical to index in the Array
    mapping(address => uint) public advAddress;
    UserInfo[] public advArray;
    uint advActiveSize;

    // EarlyLP Address.
    mapping(address => uint) public elpAddress;
    ELPInfo[] public elpArray;
    uint elpActiveSize;

    // eTeam Address.
    mapping(address => uint) public eteamAddress;
    UserInfo[] public eteamArray;
    uint eteamActiveSize;


    // Company Address.
    address public companyaddr;

    // StakeholderFund Timelock address
    address public stakeHolderFundTimelock;
    
    //Default Constructor
    constructor(KingToken _king, 
     ELPInfo[]  memory _elpaddr,
     UserInfo[] memory _advaddr,
     UserInfo[] memory _eteamaddr,
     address _companyaddr,
     address _stakeHolderFundTimelock)
    public{
        king = _king;
        //Initialize LPinfo address
        updateELPInfo(_elpaddr,elpArray);
        updateMappingELPInfo(elpAddress,_elpaddr);

        //Initialize userinfo address
        updateUserInfo(_advaddr,advArray);
        //Set the active size for advisor
        advActiveSize = advArray.length;
        updateMappingUserInfo(advAddress,_advaddr);
        updateUserInfo(_eteamaddr,eteamArray);
        eteamActiveSize = eteamArray.length;
        updateMappingUserInfo(eteamAddress,_eteamaddr);

        stakeHolderFundTimelock = _stakeHolderFundTimelock;
        companyaddr = _companyaddr;
    }

    //event NewRequest(uint);
    event fundRequest(uint);
    //Load the mapping for first few ELP
    function updateELPInfo(ELPInfo[] memory init,ELPInfo[] storage mainArray) internal {
        uint256 length = init.length;
        //Set the active size for ELP
        elpActiveSize = length;
        for (uint i = 0 ; i < length; i++){
            address walletAddress = init[i].walletAddress;
            uint index = init[i].index;
            uint point = init[i].allocPoint;
            bool status = init[i].statusActive;
            ELPInfo memory e = ELPInfo({
                walletAddress:walletAddress,
                index: index,
                allocPoint: point,
                statusActive: status});

            //store in array checker address. Index will be -1 to represent the position.
            mainArray.push(e);
        }
        
    }
    function updateMappingELPInfo(mapping(address => uint) storage map,ELPInfo[] memory init) internal{
        // Add all the users into the address
        for (uint i = 0 ; i < init.length; i++){
            // Retrieve wallet address
            address walletAddress = init[i].walletAddress;
            //store in map.
            uint index = i + 1;
            map[walletAddress] = index;
        }
    }
    function updateUserInfo(UserInfo[] memory init,UserInfo[] storage mainArray) internal {
        uint256 length = init.length;
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

    //Initialize the mapping
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


    function getTotalAdv() onlyOwner external view returns(uint){
        return advArray.length;
    }

    function getTotalEteam() onlyOwner external view returns(uint){
        return eteamArray.length;
    }

    function getTotalELP()  external view returns(uint){
        return elpArray.length;
    }

    //calculate total allocation point
    function ELPAllocPoint() internal view returns(uint) {
        uint totalAllocPoint = 0;
        for(uint i = 0 ;i < elpArray.length; i++){
            //calculate only for wallet with active status.
            if(elpArray[i].statusActive == true){
                totalAllocPoint = totalAllocPoint + elpArray[i].allocPoint;
            }
        }
        return totalAllocPoint;
    }

    //Anyone can call it but it will be split to only the people in this address.
    function withdraw() public onlyOwner{
        uint _amount = king.balanceOf(address(this));
        require(_amount > 0, "zero king amount");
        uint amountReal = _amount;
        uint totalAllocPoint = ELPAllocPoint();
        uint balance = amountReal;
        
        //Transfer this amount to this contract address
        uint shFundTimeLock = amountReal.mul(1170).div(3600);
        king.transfer(stakeHolderFundTimelock, shFundTimeLock);
        
        balance = balance.sub(shFundTimeLock);

        // This contract is suppose to get 3600
        // elp supposed to get 1500 out of 3600
        for(uint i = 0 ; i < elpArray.length; i ++){

            //only for active wallet address
            if(elpArray[i].statusActive == true){
                //Actual indiividual ELP amount : Real Amount * AllocationPoint Per ELP/Total Allocation * ELP Share/Total Share 
                uint fund = amountReal.mul(elpArray[i].allocPoint).mul(1500).div(totalAllocPoint.mul(3600));
                balance = balance.sub(fund);
                king.transfer(elpArray[i].walletAddress, fund);
            }
        }
        
        // Advisor suppose to get 100 out of 3600 : Real Amount * Advisor Share/Totalshare
        for(uint i = 0 ; i < advArray.length; i ++){

            //only for active advisor wallet address
            if(advArray[i].statusActive == true){
                //based total advisor in team divide equally
                uint advFund = amountReal.mul(100).div((advActiveSize).mul(3600));
                balance = balance.sub(advFund);
                king.transfer(advArray[i].walletAddress, advFund);
            }
        }
        
        // Eteam suppose to get 250 out of 3600
        for(uint i = 0 ; i < eteamArray.length; i ++){

            //only for active eteam wallet address
            if(eteamArray[i].statusActive == true){

                //based total team members in team divide equally
                uint eteamFund = amountReal.mul(250).div((eteamActiveSize).mul(3600));
                 emit fundRequest(eteamFund);
                balance = balance.sub(eteamFund);
                king.transfer(eteamArray[i].walletAddress, eteamFund);
            }
        }
        //emit balanceRequest(balance);
        
        //Company suppose to get 580 out 3600
        king.transfer(companyaddr,balance);
    }
    //event balanceRequest(uint);
    function addAdvAddress(address _advAddress) public onlyOwner{
        if(advAddress[_advAddress]==0){
            uint index = advArray.length;
            if(advArray.length == 0){
                index = 1;
            }
            //Index need to plus as it takes the length
            advAddress[_advAddress] = index+1;
            require(advArray.length <=100 , "AdvArray reach 100 limit");
            advArray.push(UserInfo({
                walletAddress: _advAddress,
                index: index,
                statusActive: true}));
                advActiveSize = advActiveSize + 1;
        }
    }

    function addelpAddress(address _elpAddress,uint256 _point) public onlyOwner{
        if(elpAddress[_elpAddress]==0){
            uint index = elpArray.length;
            if(elpArray.length == 0){
                index = 1;
            }
            elpAddress[_elpAddress] = index-1;
            require(elpArray.length <=100 , "elpArray reach 100 limit");
            elpArray.push(ELPInfo({
                walletAddress: _elpAddress,
                index: index,
                allocPoint: _point,
                statusActive : true}));
                elpActiveSize = elpActiveSize + 1;
        }
    }

    function addeteamAddress(address _eteamAddress) public onlyOwner{
        if(eteamAddress[_eteamAddress]==0){
            uint index = eteamArray.length;
            if(eteamArray.length == 0){
                index = 1;
            }
            eteamAddress[_eteamAddress] = index+1;
            require(eteamArray.length <=100 , "eteamArray reach 100 limit");
            eteamArray.push(UserInfo({
                walletAddress: _eteamAddress,
                index: index,
                statusActive: true}));
                eteamActiveSize = eteamActiveSize +1;
        }
    }


    // Disabled adv address from advArray by setting statusActive to false
    function removeAdvAddress(address _advAddress) public onlyOwner{
         if(advAddress[_advAddress]>0){
             for(uint i = 0; i < advArray.length ; i++){
                 if(advArray[i].walletAddress == _advAddress){
                    advArray[i].statusActive = false;
                 }
             }
            advActiveSize = advActiveSize - 1;
         }
    }

    // Disabled eteam address from eteamArray by setting statusActive to false
    function removeEteamAddress(address _eteamAddress) public onlyOwner{
          if(eteamAddress[_eteamAddress]>0){
             for(uint i = 0; i < eteamArray.length ; i++){
                 if(eteamArray[i].walletAddress == _eteamAddress){
                    eteamArray[i].statusActive = false;
                 }
             }
            eteamActiveSize = eteamActiveSize - 1;
         }
    }

    // Disabled eteam address from eteamArray by setting statusActive to false
    function removElpAddress(address _elpAddress) public onlyOwner{
          if(elpAddress[_elpAddress]>0){
             for(uint i = 0; i < elpArray.length ; i++){
                 if(elpArray[i].walletAddress == _elpAddress){
                    elpArray[i].statusActive = false;
                 }
             }
             elpActiveSize = elpActiveSize - 1;
         }
    }

    function changeStakeHolderFundTimeLock(address _stakeHolderFundTimelock) public onlyOwner{
       stakeHolderFundTimelock = _stakeHolderFundTimelock;
    } 

}
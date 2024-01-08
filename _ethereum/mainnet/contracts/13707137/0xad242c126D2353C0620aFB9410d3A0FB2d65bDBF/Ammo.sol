// SPDX-License-Identifier: MIT

/**

Developed and Deployed By:

███╗   ██╗███████╗████████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗     ██████╗ ██████╗ ███╗   ███╗
████╗  ██║██╔════╝╚══██╔══╝██║ ██╔╝██║█S███╗  ██║██╔════╝ ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗   ██╔════╝██╔═══██╗████╗ ████║
██╔██╗ ██║█████╗     ██║   █████╔╝ ██║██╔██╗ ██║██║  ███╗██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝   ██║     ██║   ██║██╔████╔██║
██║╚██╗██║██╔══╝     ██║   ██╔═██╗ ██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗   ██║     ██║   ██║██║╚██╔╝██║
██║ ╚████║██║        ██║   ██║  ██╗██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═══╝╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝

For more information visit us on : https://www.nftkingmaker.com/


                                                                                                                                   */
                                                                                                                                   
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

interface sotmcontract{
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}




contract Ammo is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit {
    constructor() ERC20("Ammo", "AMMO") ERC20Permit("AMMO") {
                   
 }

mapping (address => uint) public arr;


    
    //this function sets a value to a specific address
    //the data is saved to myMap on the block chain 
    function set1() internal {
        // Update the value at this address
        arr[msg.sender] = block.timestamp;
    }

    function remove() internal  {
    delete arr[msg.sender];
    
    }

    //this function gets a value from a specific address in the map
    //If a value was not set the function will return the default value of 0.
    function get1() internal view returns (uint) {
        return arr[msg.sender];
    }
    
    mapping (address => bool) public arr1;


    
    //this function sets a value to a specific address
    //the data is saved to myMap on the block chain 
    function set() internal {
        // Update the value at this address
        arr1[msg.sender] = true;
    }
    
    function remove1() internal {
    delete arr1[msg.sender];
    
    }
    
        function timenow() public view returns(uint) {
        return block.timestamp;
} 
    
    //this function gets a value from a specific address in the map
    //If a value was not set the function will return the default value of 0.
    function get() internal view returns (bool) {
        return arr1[msg.sender];
    }
    uint256 mintprice= 0.06 ether;

    address www= 0xE7191C896d59A9c39965E16C5184c44172Ec9CF9;
    bool public rewardisActive = true;
    bool private purchaseactive = false;
    sotmcontract sotm= sotmcontract(www);
    mapping (uint256 => uint256) public tokenid;
    uint256 start=block.timestamp+86400;
    uint256 public rewardyoucanclaim;
    uint constant multiplier = 10**18;


mapping (uint256 => bool) public dotokenexist;


    
    //this function sets a value to a specific address
    //the data is saved to myMap on the block chain 
    function settoken(uint idd1) internal {
        // Update the value at this address
        dotokenexist[idd1] = true;
    }
    
    function removetoken(uint idd2) internal {
    delete dotokenexist[idd2];
    
    }
    
    //this function gets a value from a specific address in the map
    //If a value was not set the function will return the default value of 0.
    function gettoken(uint idd3) public view returns (bool) {
        return dotokenexist[idd3];
    }
    
    mapping (uint => uint) public dotokenexist1;


    
    //this function sets a value to a specific address
    //the data is saved to myMap on the block chain 
    function settokentime(uint idd4) internal {
        // Update the value at this address
        dotokenexist1[idd4] = block.timestamp;
    }
    
    function removetokentime(uint idd5) internal {
    delete dotokenexist1[idd5];
    
    }
    
    //this function gets a value from a specific address in the map
    //If a value was not set the function will return the default value of 0.
    function gettokentime(uint idd6) public view returns (uint) {
        return dotokenexist1[idd6];
    }
    



 
  
   function setsotmcontractaddr(address sotmcontractaddr) public {
    www = sotmcontractaddr;
 }
 
 function setRarity(uint256[] memory rarity, uint256 start1) public onlyOwner {
        for (uint256 i = 0; i < rarity.length ; i++){
            tokenid[rarity[i]] = i+start1;
    }}


    function contains(uint256 _tokenid) internal view returns (uint256){
        return tokenid[_tokenid];
    }
 
// Declaring state variable  

      
// Function to add data 
// in dynamic array






     function ActivateRewards() public onlyOwner {
        rewardisActive = !rewardisActive;
        start=block.timestamp+86400;
    }
    
    function setmintprice(uint256 _mintprice) public onlyOwner {
        mintprice = _mintprice;
    }
    
  
    
    
    function ActiatePurchase() external onlyOwner {
        purchaseactive = !purchaseactive;
    } 
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
  
     
    function SOTMBALANCeE() internal view returns (uint256 balance){
        return balance = sotm.balanceOf(msg.sender);
        
    }
    
    
  
    
     function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);}
        
        
        
        function claimablereward(address _address) external view returns (uint256){
         uint256 size= sotm.balanceOf(_address);
                 uint256 rewardclaim;

          for (uint256 i=0;i<size; i++)
          {
              
         uint256 currentids= sotm.tokenOfOwnerByIndex(_address, i);
         uint256 currentidsrari=getrarity(currentids);
         bool a= gettoken(currentids);

         
         if (a==true){
            uint256 lasttime=  gettokentime(currentids);
            uint256 unclaimeddays= block.timestamp-lasttime;
            unclaimeddays= unclaimeddays / 86400;
                                   if(unclaimeddays>0){

                         if (currentidsrari==0){
                                unclaimeddays= unclaimeddays*20;
                            rewardclaim = rewardclaim + unclaimeddays;
                                
                                
                        }

         
                         if (currentidsrari<=49 && currentidsrari>0){
                                unclaimeddays= unclaimeddays*38;
                            rewardclaim = rewardclaim + unclaimeddays;
                                
                                
                        }
                         if (currentidsrari<=250 && currentidsrari>=50){
                                unclaimeddays= unclaimeddays*30;
                            rewardclaim = rewardclaim + unclaimeddays;
                        }
                         if (currentidsrari<=750 && currentidsrari>=251){
                            unclaimeddays= unclaimeddays*25;
                            rewardclaim = rewardclaim + unclaimeddays;
                        }  
                         if (currentidsrari<=1500 && currentidsrari>=751){
                            unclaimeddays= unclaimeddays*21;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=2500 && currentidsrari>=1501){
                            unclaimeddays= unclaimeddays*18;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=3500 && currentidsrari>=2501){
                            unclaimeddays= unclaimeddays*15;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=5000 && currentidsrari>=3501){
                                unclaimeddays= unclaimeddays*12;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }
                         if (currentidsrari<=6500 && currentidsrari>=5001){
                            unclaimeddays= unclaimeddays*11;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }
                         if (currentidsrari<=7499 && currentidsrari>=6501){
                            unclaimeddays= unclaimeddays*10;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }}
                        }
            else {
                uint256 unclaimeddays= block.timestamp-start;
                unclaimeddays= unclaimeddays/86400;
                 if (currentidsrari==0){
                                unclaimeddays= unclaimeddays*20;
                            rewardclaim = rewardclaim + unclaimeddays;
                                
                                
                        }
               if (currentidsrari<=49 && currentidsrari>0){
                                unclaimeddays= unclaimeddays*38;
                            rewardclaim = rewardclaim + unclaimeddays;
                                
                        }
                         if (currentidsrari<=250 && currentidsrari>=50){
                                unclaimeddays= unclaimeddays*30;
                            rewardclaim = rewardclaim + unclaimeddays;
                        }
                         if (currentidsrari<=750 && currentidsrari>=251){
                            unclaimeddays= unclaimeddays*25;
                            rewardclaim = rewardclaim + unclaimeddays;
                        }  
                         if (currentidsrari<=1500 && currentidsrari>=751){
                            unclaimeddays= unclaimeddays*21;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=2500 && currentidsrari>=1501){
                            unclaimeddays= unclaimeddays*18;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=3500 && currentidsrari>=2501){
                            unclaimeddays= unclaimeddays*15;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }  
                         if (currentidsrari<=5000 && currentidsrari>=3501){
                                unclaimeddays= unclaimeddays*12;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }
                         if (currentidsrari<=6500 && currentidsrari>=5001){
                            unclaimeddays= unclaimeddays*11;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }
                         if (currentidsrari<=7499 && currentidsrari>=6501){
                            unclaimeddays= unclaimeddays*10;
                            rewardclaim = rewardclaim + unclaimeddays;
                             
                         }
                        
            
          
    }
                    return  rewardclaim;
    }
    }

    function SOTMTOKENBYINDEXe(address _address) internal {
         uint size= SOTMBALANCeE();
          for (uint256 i=0;i<size; i++)
          {
              
         uint256 currentids= sotm.tokenOfOwnerByIndex(_address, i);
         uint256 currentidsrari=getrarity(currentids);
         bool a= gettoken(currentids);
         
         if (a==true){
            uint256 lasttime=  gettokentime(currentids);
            uint256 unclaimeddays= block.timestamp-lasttime;
            unclaimeddays= unclaimeddays / 86400;
                                   if(unclaimeddays>0){

                                        if (currentidsrari==0){
                                unclaimeddays= unclaimeddays*20;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;
                                
                                
                        }

         
                         if (currentidsrari<=49 && currentidsrari>0){
                                unclaimeddays= unclaimeddays*38;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;
                                
                                
                        }
                         if (currentidsrari<=250 && currentidsrari>=50){
                                unclaimeddays= unclaimeddays*30;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;                        
                        }
                         if (currentidsrari<=750 && currentidsrari>=251){
                            unclaimeddays= unclaimeddays*25;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;                            
                        }  
                         if (currentidsrari<=1500 && currentidsrari>=751){
                            unclaimeddays= unclaimeddays*21;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=2500 && currentidsrari>=1501){
                            unclaimeddays= unclaimeddays*18;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=3500 && currentidsrari>=2501){
                            unclaimeddays= unclaimeddays*15;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=5000 && currentidsrari>=3501){
                                unclaimeddays= unclaimeddays*12;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }
                         if (currentidsrari<=6500 && currentidsrari>=5001){
                            unclaimeddays= unclaimeddays*11;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }
                         if (currentidsrari<=7499 && currentidsrari>=6501){
                            unclaimeddays= unclaimeddays*10;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }}
                            removetoken(currentids);
                            removetokentime(currentids);
                            settoken(currentids);
                            settokentime(currentids);
                        }
            else {
                uint256 unclaimeddays= block.timestamp-start;
                unclaimeddays= unclaimeddays/86400;
                 if (currentidsrari==0){
                                unclaimeddays= unclaimeddays*20;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;
                                
                                
                        }
               if (currentidsrari<=49 && currentidsrari>0){
                                unclaimeddays= unclaimeddays*38;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;
                                
                                
                        }
                         if (currentidsrari<=250 && currentidsrari>=50){
                                unclaimeddays= unclaimeddays*30;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;                        
                        }
                         if (currentidsrari<=750 && currentidsrari>=251){
                            unclaimeddays= unclaimeddays*25;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;                            
                        }  
                         if (currentidsrari<=1500 && currentidsrari>=751){
                            unclaimeddays= unclaimeddays*21;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=2500 && currentidsrari>=1501){
                            unclaimeddays= unclaimeddays*18;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=3500 && currentidsrari>=2501){
                            unclaimeddays= unclaimeddays*15;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }  
                         if (currentidsrari<=5000 && currentidsrari>=3501){
                                unclaimeddays= unclaimeddays*12;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }
                         if (currentidsrari<=6500 && currentidsrari>=5001){
                            unclaimeddays= unclaimeddays*11;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }
                         if (currentidsrari<=7499 && currentidsrari>=6501){
                            unclaimeddays= unclaimeddays*10;
                            rewardyoucanclaim = rewardyoucanclaim + unclaimeddays;   
                             
                         }
            
                            
                            settoken(currentids);
                            settokentime(currentids);
                            
                        
            
          
    }
    }
    }
      function SOTMBALANCE(address _account) external view returns (uint256 balance){
        return balance = sotm.balanceOf(_account);
    }
    
    function getrarity(uint256 idtoken) internal view returns (uint256 rari){
        return rari = tokenid[idtoken] ;
    }


    function SOTMTOKENBYINDEX(uint256 index, address _account) external view returns (uint256 tokenId){
         uint256   tokeniid= sotm.tokenOfOwnerByIndex(_account, index);
                
        return  tokenId= tokenid[tokeniid];
    }
    





    
    function claimreward(address _adddress) public  {
        require(SOTMBALANCeE() != 0, 'NO SOTM FOUND');
        require (rewardisActive== true, "Rewards are paused");
        {
            bool a= get();
            SOTMTOKENBYINDEXe(_adddress);
            if (a == true)
            {
              uint256 lasttime=  get1();
              lasttime= lasttime+86400;
              require (lasttime<= block.timestamp, "Already Claimed");{
                  rewardyoucanclaim = rewardyoucanclaim*1000000000000000000;
                uint256 amount= rewardyoucanclaim;
                    remove1();
                    remove();
                    set();
                    set1();
                    rewardyoucanclaim=0;
                    _mint(_adddress, amount );
                    }

              }
              else {
             bool a1= get();
                require (a1==false, "Already claimed");
{                    
                    rewardyoucanclaim = rewardyoucanclaim*1000000000000000000;
                      uint256 amount= rewardyoucanclaim;
                    set();
                    set1();
                    rewardyoucanclaim=0;
                    require(amount>0, "You can't claim right now");

                    _mint(_adddress, amount );
                }}
                                        



    }
    }

    

            
  
    function buy(uint256 numberOfTokens) public payable {
        require(purchaseactive== true, "Purchase is not active");
        require(mintprice*numberOfTokens>=msg.value, "Incorrect value sent");
        {
            numberOfTokens= numberOfTokens*multiplier;
        
        _mint(msg.sender, numberOfTokens);
    }
    }

    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    
    
    function mint(address to, uint256 amount) public onlyOwner {
        amount=amount*multiplier;
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
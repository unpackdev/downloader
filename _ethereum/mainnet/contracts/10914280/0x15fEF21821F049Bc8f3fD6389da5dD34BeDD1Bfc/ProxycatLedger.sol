/* 
 *  ProxyCat Ledger
 *  VERSION: 2.4
 *  
 */
 

pragma solidity ^0.6.0;

contract ProxycatLedger{ 
    
    uint256 public cats=0;
    address public master;

    struct Kitty{
        address kitty;
        string label;
        string family;
        string abi;
        uint256 index;
        string description;
    }
    
    mapping(string => mapping(string => Kitty)) public kittiesByFamily;
    mapping(uint256 => Kitty) public kittylist;
    mapping(address => uint256) public kittyindex;
    mapping(string => string[]) public kittyfamily;
    string[] public gensList;
    
    string public version="2.4";
   
    constructor()public {master=msg.sender;}
    
    function addCall(address kitty,string memory family,string memory label,string memory abi,string memory description) public returns(bool){
        if((msg.sender!=master)||(kittyindex[kitty]>0)||(kittiesByFamily[family][label].kitty!=address(0x0)))revert();
        
            if(kittyfamily[family].length==0)gensList.push(family);
            cats++;
            kittiesByFamily[family][label]=Kitty(kitty,label,family,abi,cats,description);
            kittylist[cats]=Kitty(kitty,label,family,abi,cats,description);
            kittyindex[kitty]=cats;
            kittyfamily[family].push(label);
        
        return true;
    }
    
    function editCall(address kitty,string memory family,string memory label,string memory abi,string memory description) public returns(bool){
        if((msg.sender!=master)||((kittyindex[kitty]>0)&&(kittiesByFamily[family][label].kitty!=kitty)))revert();

            kittyindex[kittiesByFamily[family][label].kitty]=0;
            kittyindex[kitty]=kittiesByFamily[family][label].index;
            kittylist[kittiesByFamily[family][label].index]=Kitty(kitty,label,family,abi,kittiesByFamily[family][label].index,description);
            kittiesByFamily[family][label]=Kitty(kitty,label,family,abi,kittiesByFamily[family][label].index,description);
        
        return true;
    }
    
    
    function getKitty(uint256 index) public view returns(address,string memory,string memory,string memory,uint,string memory){
        return (kittylist[index].kitty,kittylist[index].family,kittylist[index].label,kittylist[index].abi,kittylist[index].index,kittylist[index].description);
    }
    
    function getKitty(address kitty)public view returns(address,string memory,string memory,string memory,uint,string memory){
        return (kitty,kittylist[kittyindex[kitty]].family,kittylist[kittyindex[kitty]].label,kittylist[kittyindex[kitty]].abi,kittylist[kittyindex[kitty]].index,kittylist[kittyindex[kitty]].description);
    }
    
    function getKitty(string memory family,string memory label) public view returns(address){
        return kittiesByFamily[family][label].kitty;
    }
    
    function getKittyFull(string memory family,string memory label) public view returns(address,string memory,uint,string memory){
        return (kittiesByFamily[family][label].kitty,kittiesByFamily[family][label].abi,kittiesByFamily[family][label].index,kittiesByFamily[family][label].description);
    }  
    
    function familyCount(string memory family)public view returns(uint256){
        return kittyfamily[family].length;
    }
    
    function familyList(string memory family,uint256 index)public view returns(string memory){
        return kittyfamily[family][index];
    }
    
    function gensCount()public view returns(uint256){
        return gensList.length;
    }
    
    function setMaster(address new_master)public returns(bool){
        if(msg.sender!=master)revert();
        master=new_master;
        return true;
    }
    
    
}
pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
import "./ERC1155.sol";
import "./IERC1155Receiver.sol";

contract BluBoyX is ERC1155 {
    address creator; //this is creater address, ok but you deploying from your address right now for testing?
    //how this address set?
    mapping (address => uint256) userList;
    uint256 public _tokens;
    uint256 public _total;
    string public name;
    string public symbol;
    
    constructor() public ERC1155('https://ipfs.io/ipfs/Qmex7bQqs5vW4nKgtBzcygAPcuvxWHyh9NgrsF2QC6mUcV/{id}.json') {
        creator = msg.sender;
        name = "BluWorld";
        symbol = "BLU";
        _tokens = 4994;
        _total = 5000;

    }

    function mint(uint256 count ) payable public {
        
        require(_tokens > 0, "out of NFTs");
        creator.call{value: msg.value}("");
    
        for(uint256 i = 0; i < count; i++){
            _mint(msg.sender, _total - _tokens - 6, 1, "");
            _tokens--;
        }
        
        if(userList[msg.sender] > 0){
            userList[msg.sender] += count;
        }else {
            userList[msg.sender] = count;
        }
        
    }

    function tokensCount() public view returns (uint256) { 
        return _tokens;
    }

    function userHaveTokens(address _address) public view returns (uint256) { 
        return userList[_address];
    }

}
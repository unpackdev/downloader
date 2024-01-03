// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./ERC721.sol";
import "./Counters.sol";

contract KingTokenNFTKingWerewolf is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    //Owner address
    address private owner;

    uint public totalSupplyCap = 10;
    
    //List of user address;
    mapping(address => uint) private wallets;

     modifier _onlyOwner(){
        require(msg.sender == owner);
        _;
    }


    constructor(string memory myName, string memory mySymbol,address _owner) ERC721(myName, mySymbol) public {
        owner = _owner;
    }
    
    //for owner to see NFTs issued to who
    function checkWalletAddressExist(address player) _onlyOwner() public view returns (uint){
        return wallets[player];
    }

    function mint(address player, uint totalSupply) _onlyOwner() public returns (bool) {
        require(this.totalSupply() + totalSupply <= totalSupplyCap, "hardcap reached");
        for(uint256 i = 1; i<= totalSupply; i++){
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(player, newItemId);
            _setTokenURI(newItemId,"https://api.jsonbin.io/b/5f7367137243cd7e82466615/40");
        }
        //check if address exist in wallet
        if(wallets[player] == 0){
              wallets[player] = totalSupply;  
        }else{
                uint totalsum = wallets[player];
                totalsum = totalsum + totalSupply;
                wallets[player] = totalsum;
        }
    }
    
}
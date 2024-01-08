//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";

contract payment is Ownable{
    
    event EtherReceived(address from, uint value);
    event vaultChanged(address new_address);
    event TokenReceived(string _name, uint _decimals, uint _amount, address _from);
    
    struct Tokens{
        string Name;
        string Symbol;
        address Address;
    }

    ERC20 ERC20Contract;
    mapping(address => bool) public whitelist;
    Tokens [] private TokensList;

    address payable vault;

 
    constructor() {

    vault = payable(owner());
   
    // addresses to receive payments
        address[8] memory tokens = [
        0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE,
        0xC40AF1E4fEcFA05Ce6BAb79DcD8B373d2E436c4E,
        0x8B3192f5eEBD8579568A2Ed41E6FEB402f93f73F,
        0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b,
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        0x249e38Ea4102D0cf8264d3701f1a0E39C4f2DC3B,
        0x3845badAde8e6dFF049820680d1F14bD3903a5d0,
        0x0F5D2fB29fb7d3CFeE444a200298f468908cC942
        ];
       for(uint i = 0; i < tokens.length; i++){
            addToWhitelist(tokens[i]);
        }
    } 
    
    function receiveTokens(address _tokenAddr, uint _amount) external {
        require(whitelist[_tokenAddr], "Token not accepted");
        require(_amount > 0, "Amount Not Valid");
        ERC20Contract = ERC20(_tokenAddr);
        ERC20Contract.transferFrom(msg.sender, vault, _amount);

        emit TokenReceived(ERC20Contract.name(), ERC20Contract.decimals(), _amount, msg.sender);
    }
    
    function checkWhitelisted(address [] memory token) private view returns(bool){
        for(uint i = 0; i < token.length; i++){
            if(whitelist[token[i]] == false)
                return false;
        }
        return true;
    }
    
    function addToWhitelist(address _tokenAddr) public onlyOwner {
        require(_tokenAddr != address(0), "addToWhitelist: 0 Address cannot be added");
        require(whitelist[_tokenAddr] != true, "addToWhitelist: Already Whitelisted");

        whitelist[_tokenAddr] = true;
        ERC20Contract = ERC20(_tokenAddr);

        TokensList.push(Tokens(
        ERC20Contract.name(),
        ERC20Contract.symbol(),
        _tokenAddr
        ));
    }
    
    function removeFromWhitelist(address _tokenAddr) external onlyOwner {
        require(_tokenAddr != address(0), "removeFromWhitelist: Wrong Address");
        require(whitelist[_tokenAddr] != false, "removeFromWhitelist: Already removed from Whitelist");
        whitelist[_tokenAddr] = false;

        for (uint i = 0; i < TokensList.length; i++){
            if(TokensList[i].Address == _tokenAddr){
                TokensList[i] = TokensList[TokensList.length - 1];
                TokensList.pop();
            }
        }
    }
 
    function changeWalletAddress(address payable _newWallet) external onlyOwner {
        vault = _newWallet;
        emit vaultChanged(_newWallet);
    }

    function ListTokens() public view returns(Tokens [] memory){
        return TokensList;
    } 
    
    function getContractDecimals(address _tokenAddr) public returns(uint) {
        ERC20Contract = ERC20(_tokenAddr);
        return ERC20Contract.decimals();
    }
    
    receive() external payable {
        vault.transfer(msg.value);
        emit EtherReceived(msg.sender, msg.value);
    }
    
}
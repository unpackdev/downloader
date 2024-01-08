// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./SafeMath.sol";
//import "./Ownable.sol";

//Do not attempt to use this contract directly. You need to use the Dapp. You have been warned. Risk losing your tokens.
//If you want to use the contract, make sure you approve the contract to spend your ERC721 and ERC20 first.
//Written by 0xHusky

interface ERC20Like {
      function balanceOf(address account) external view returns (uint256);
      function transferFrom(address from, address to, uint256 value) external returns (bool);
      function transfer(address to, uint256 value) external returns (bool);
}

contract Marketplace{

    event OfferingPlaced(bytes32 indexed offeringId, address indexed hostContract, address indexed offerer,  uint tokenId, uint price, uint currencyIndex, uint expiry);
    event OfferingClosed(bytes32 indexed offeringId, address indexed buyer);
    event OfferingCancelled(bytes32 indexed offeringId);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    address operator;
    bool marketLive = true;
    bool enableEth = false;
    uint comm = 0;
    uint offeringNonce;
    using SafeMath for uint;
   
    struct offering {
        address offerer;
        address hostContract;
        uint tokenId;
        uint price;
        uint currencyIndex;
        uint expiry;
        bool closed; 
    }

    struct acceptedTokens {
        address tokenContract;
        string tokenSymbol;
    }
    
    mapping (bytes32 => offering) offeringRegistry;
    mapping (uint => acceptedTokens) acceptedTokensRegistry;
    mapping (address => uint) ethbalances;
    mapping(address => mapping(uint => uint)) tokenbalances;
  
    constructor (address _operator) {
        operator = _operator;
    }

    function addToken(address _tokenContract, string memory _tokenSymbol, uint _currencyIndex) external {
        require(msg.sender == operator,"only the operator can change this");
        acceptedTokensRegistry[_currencyIndex].tokenContract = _tokenContract;
        acceptedTokensRegistry[_currencyIndex].tokenSymbol = _tokenSymbol;    
    }

    function placeOffering(address _offerer, address _hostContract, uint _tokenId, uint _price, uint _currencyIndex, uint _expiry) external {
        ERC721 hostContract = ERC721(_hostContract);
        require(hostContract.ownerOf(_tokenId) == msg.sender, "Market is closed"); 
        require(marketLive == true, "Market is closed");
       /// require (msg.sender == operator, "Only operator dApp can create offerings");
        bytes32 offeringId = keccak256(abi.encodePacked(offeringNonce, _hostContract, _tokenId));
        offeringRegistry[offeringId].offerer = _offerer;
        offeringRegistry[offeringId].hostContract = _hostContract;
        offeringRegistry[offeringId].tokenId = _tokenId;
        offeringRegistry[offeringId].price = _price;
        offeringRegistry[offeringId].currencyIndex = _currencyIndex; 
        offeringRegistry[offeringId].expiry = _expiry; 
        offeringNonce += 1;
        emit OfferingPlaced(offeringId, _hostContract, _offerer, _tokenId, _price, _currencyIndex, _expiry);
    }

    function cancelOffering(bytes32 _offeringId) external {
        require(marketLive == true, "Market is closed");
        require(offeringRegistry[_offeringId].offerer == msg.sender, "Not your offer");
        delete offeringRegistry[_offeringId];
        emit OfferingCancelled(_offeringId);        
    }
    
    function closeOfferingWithToken(bytes32 _offeringId, address _buyer, uint _currency) external {
        require(marketLive == true, "Market is closed");
        require(block.timestamp <= offeringRegistry[_offeringId].expiry);
        ERC20Like token = ERC20Like(acceptedTokensRegistry[_currency].tokenContract);
        require(offeringRegistry[_offeringId].currencyIndex ==_currency, "Incorrect Token");
        require(token.balanceOf(_buyer) >= offeringRegistry[_offeringId].price, "Not enough token balance");
        require(offeringRegistry[_offeringId].closed != true, "Offering is closed");

        address offerer = offeringRegistry[_offeringId].offerer;
        //Transfer NFT to buyer
        ERC721 hostContract = ERC721(offeringRegistry[_offeringId].hostContract);
        hostContract.safeTransferFrom(offerer, _buyer, offeringRegistry[_offeringId].tokenId);
        //Transfer Tokens from buyer to contract       
        token.transferFrom(_buyer,address(this),offeringRegistry[_offeringId].price); 
    
        offeringRegistry[_offeringId].closed = true;
    
        uint sellerPayable = commission(offeringRegistry[_offeringId].price);    
        uint devPayable = offeringRegistry[_offeringId].price.sub(sellerPayable);

        tokenbalances[operator][_currency] += devPayable;
        tokenbalances[offerer][_currency] += sellerPayable;
        
        emit OfferingClosed(_offeringId, _buyer);
    } 

    function closeOffering(bytes32 _offeringId) external payable {
        require(block.timestamp <= offeringRegistry[_offeringId].expiry);
        require(marketLive == true, "Market is closed");
        require(enableEth == true, "Eth transactions not supported");
        require(msg.value >= offeringRegistry[_offeringId].price, "Not enough funds to buy");
        require(offeringRegistry[_offeringId].closed != true, "Offering is closed");
        ERC721 hostContract = ERC721(offeringRegistry[_offeringId].hostContract);
        hostContract.safeTransferFrom(offeringRegistry[_offeringId].offerer, msg.sender, offeringRegistry[_offeringId].tokenId);
        offeringRegistry[_offeringId].closed = true;
        uint sellerPayable = commission(offeringRegistry[_offeringId].price);    
        uint devPayable = msg.value.sub(sellerPayable);
        ethbalances[operator] += devPayable;
        ethbalances[offeringRegistry[_offeringId].offerer] += sellerPayable;
        emit OfferingClosed(_offeringId, msg.sender);
    }

    function commission(uint _amount) internal view returns(uint) {
        uint commish = _amount.div(1000).mul(comm);
        uint _sellerPayable = _amount.sub(commish);        
        return _sellerPayable;
    }
  
    function withdrawEthBalance() external {
        require(marketLive == true, "Market is closed");
        require(ethbalances[msg.sender] > 0,"You don't have any balance to withdraw");
        uint amount = ethbalances[msg.sender];
        payable(msg.sender).transfer(amount);
        ethbalances[msg.sender] = 0;
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function withdrawTokenBalance(uint _currency) external {
        require(marketLive == true, "Market is closed");
        ERC20Like token = ERC20Like(acceptedTokensRegistry[_currency].tokenContract);
        require(tokenbalances[msg.sender][_currency] > 0,"You don't have any tokens to withdraw");
        uint amount = tokenbalances[msg.sender][_currency];
        token.transfer(msg.sender,amount); 
        tokenbalances[msg.sender][_currency] = 0;
        emit BalanceWithdrawn(msg.sender, amount);
    }

////Admin functions

    function changeOperator(address _newOperator) external {
        require(msg.sender == operator,"only the operator can change the current operator");
        operator = _newOperator;      
    }

    function changeMarketStatus(bool _marketLiveStatus) external {
        require(msg.sender == operator,"only the operator can change the current operator");
        marketLive = _marketLiveStatus;
    }

      function changeEnableEth(bool _enableEth) external {
        require(msg.sender == operator,"only the operator can change the current operator");
        enableEth = _enableEth;
    }


    function changeComissions(uint _comm) external {
        require(msg.sender == operator,"only the operator can change the current operator");
        comm = _comm;
    }


////Views

    function viewOfferingNFT(bytes32 _offeringId) external view returns (address, uint, uint, bool, uint){
        return (offeringRegistry[_offeringId].hostContract, offeringRegistry[_offeringId].tokenId, offeringRegistry[_offeringId].price, offeringRegistry[_offeringId].closed, offeringRegistry[_offeringId].currencyIndex);
    }

    function viewBalances(address _address, uint _currencyIndex) external view returns (uint, uint) {
        return (ethbalances[_address],tokenbalances[_address][_currencyIndex]);
    }

    function whoisOperator() external view returns (address) {
        return (operator);
    }

    function tokenCheck(uint _currencyIndex) external view returns (address, string memory) {
      
      address tokenContract = acceptedTokensRegistry[_currencyIndex].tokenContract; 
      string memory tokenSymbol = acceptedTokensRegistry[_currencyIndex].tokenSymbol; 

        return (tokenContract, tokenSymbol);
    }
   

}

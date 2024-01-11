
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Context.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./NFT.sol";




contract NFTCrowdSale is Context, ReentrancyGuard,Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // The token being sold
    IERC20 private _token;
    NFT private nft;
    
  
    // Address where funds are collected
    address payable private _wallet;
    
  
    uint256 private limit = 10000;
    
  
    //dicounted price
    uint256 public discounted_rarity1;//0
    

    //noraml price
    uint256 public rarity1;//1
    


    

    // Amount of wei raised
    uint256 private _weiRaised;

    uint256 private _rate;
    // uint256 public _busdRaised;
    uint256 private _nftPurchased;
    bool public success;
    bool public finalized;
    bool public pri;
    bool private discount;
    bool public saleFlag;


    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    
    
    mapping (address => uint256) private purchase;
    mapping (address => uint256) private msgValue;
  
    uint256 public whitelistCount;
    mapping(address => bool) private _whitelist;
   
    constructor( address payable wallet_ ){
        _wallet = wallet_;
        discounted_rarity1 = 0.003 ether;//0 
        rarity1 = 0.03 ether;//0 // 55
    
        }
    
    function whitelist(address account)public view returns(bool){
        return _whitelist[account];
    }

    function userPurchased(address account)public view returns(uint256){
        return purchase[account];
    }
    
    function startSale(address[] memory accounts,address _nft) public onlyOwner {
        //NFT(_nft) req
        require(address(_nft) != address(0), "NFT: token is the zero address");
        require(saleFlag == false ,"Sale already started");
        nft = NFT(_nft);
       // require(accounts.length!=0 && accounts.length<=1000,"please provide whitelist addresses in limit");
        if(accounts.length!=0){
            for (uint256 i = 0; i < accounts.length; i++) {
                _addPayee(accounts[i]);
            }
        }

        saleFlag = true;
    }

    function add_whitelistAddresses(address[] memory accounts)  public onlyOwner {
        require(accounts.length!=0 && accounts.length<=1000,"please provide whitelist addresses in limit");
         for (uint256 i = 0; i < accounts.length; i++) {
                _addPayee(accounts[i]);
            }
    }
 
    fallback () external payable { 
    }

    receive () external payable {
    }


    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    

    function getPrice(address account) public view returns(uint256){
        uint256 price;
        if(_whitelist[account]==true){
            price =discounted_rarity1;
        }else{
            price = rarity1;
        }
        return price;

    }

    function setPublicSalePrice(uint256 _price) public onlyOwner{
        require(_price != 0 ,"0 cannot set");
        discounted_rarity1 = _price;
    }

    
    function buyNFTV1() public nonReentrant payable {
       
        require(saleFlag,"Sale not started");
        
        uint256 price = getPrice(_msgSender());
       
        require(_nftPurchased < limit,"All nft Sold");
        require (!finalized,"Sale Ended");
        require(msg.value == price , "provide exact amount");
        // require (BUSD.allowance(_msgSender(), address(this))>=price,"please Approve exact amount for one NFT");

        nft.createToken(_msgSender());

        
        _nftPurchased ++;

        purchase[_msgSender()]++;

     
        wallet().transfer(msg.value);
    
    }

    function Finalize() public onlyOwner returns(bool) {
        require(!finalized,"already finalized");
        require( limit == _nftPurchased, "the crowdSale is in progress");
        finalized = true;
        return finalized;
    }

   

    function _addPayee(address account) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        _whitelist[account]=true;
        whitelistCount++;
    }

      
}


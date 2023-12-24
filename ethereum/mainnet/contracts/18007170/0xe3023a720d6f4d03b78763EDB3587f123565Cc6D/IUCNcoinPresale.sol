// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

   
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

  
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

   
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface AggregatorV3Interface {
  
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function decimals() external returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

contract IUCNcoinPresale is Ownable , ReentrancyGuard {

    using SafeMath for uint256;
    IERC20 public IUCNcoin;
    uint256 tokenPrice; // doller price with 8 Decimals

    bool public paused;
    uint256 public _raised;
    uint256 public latestOrderId;

    address public treasury;

    struct OrderInfo {
        address beneficiary;
        uint256 amount;
        uint256 time;
        uint256 totalToken;
    }
    mapping(address => uint256[]) private  orderIds;
    mapping(uint256 => OrderInfo) public orders;


    IERC20 WBTC;
    IERC20 WBNB;
    IERC20 USDC;
    IERC20 USDT;

    AggregatorV3Interface internal BnbFeed;
    AggregatorV3Interface internal BtcFeed;
    AggregatorV3Interface internal EthFeed;
    AggregatorV3Interface internal UsdtFeed;
    AggregatorV3Interface internal UsdcFeed;
    
    constructor() {

        IUCNcoin = IERC20(0x0B4663216B812e4a2f0Fc2029ff1232958f4bf8c);
        paused = false;
        tokenPrice = 300000000000000; //rate = $0,0003

        treasury = address(0x79595b395bd606F175E2FeD0B3dc0Eb7610dE351);  //Presale Funds Receiver
        
        BnbFeed = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);
        BtcFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        EthFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        UsdtFeed = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        UsdcFeed = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);

        WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        WBNB = IERC20(0x418D75f65a02b3D53B2418FB8E1fe493759c7605);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    }

    function investorOrderIds(address investor)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    //1. ETH, 
    function BuyTokenNative() public nonReentrant payable {
        address beneficiary = msg.sender;
        uint256 _amount = msg.value;
        _preValidatePurchase(beneficiary,_amount);
        (bool os,) = payable(treasury).call{value: _amount}("");
        require(os,"Transaction Failed");
        
        (uint tokenAmount,uint totalUsd) = _getTokenAmount(_amount,1,18);
          
        _raised += totalUsd;

        orders[++latestOrderId] = OrderInfo(
             msg.sender,
            _amount,
            block.timestamp,
            tokenAmount
        );

        orderIds[msg.sender].push(latestOrderId);
        IUCNcoin.transferFrom(treasury, msg.sender, tokenAmount);
    }

    //2. Btc, 3. ETH, 4. Usdt, 5.Usdc
    function BuyToken(uint _pid, uint _amount) public nonReentrant {
        address beneficiary = msg.sender;
        uint decimal;
        uint tokenAmount;
        uint totalUsd;
        _preValidatePurchase(beneficiary,_amount);
        if(_pid == 2) {
            decimal = WBTC.decimals();
            ( tokenAmount, totalUsd) = _getTokenAmount(_amount,_pid,decimal);
            WBTC.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 3) {
            decimal = WBNB.decimals();
            (tokenAmount,totalUsd) = _getTokenAmount(_amount,_pid,decimal);
            WBNB.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 4) {
            decimal = USDT.decimals();
            (tokenAmount,totalUsd) = _getTokenAmount(_amount,_pid,decimal);
            USDT.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 5) {
            decimal = USDC.decimals();
            (tokenAmount,totalUsd) = _getTokenAmount(_amount,_pid,decimal);
            USDC.transferFrom(beneficiary,treasury, _amount);
        }
        else {
            revert("Wrong ID Selected!!");
        }
        _raised += totalUsd;

        orders[++latestOrderId] = OrderInfo(
             msg.sender,
            _amount,
            block.timestamp,
            tokenAmount
        );

        orderIds[msg.sender].push(latestOrderId);
           
        IUCNcoin.transferFrom(treasury, msg.sender, tokenAmount);
       
    }

    function _getTokenAmount(uint256 weiAmount,uint _pid,uint _cDecimal) public view returns (uint256,uint256) {
        uint256 CurrencyDecimal = 18 - _cDecimal;
        uint usd =  uint256(getLatestPrice(_pid));
        usd = usd.mul(10**10);  
        if(CurrencyDecimal > 0){
            weiAmount = weiAmount * 10**CurrencyDecimal;
        }
        uint totalUsd = weiAmount * usd;
        uint totalToken = weiAmount * usd / tokenPrice;
        return (totalToken,totalUsd);
    }

    //@Param to get live price,
    //1. ETH, 2. Btc, 3. BNB, 4. Usdt, 5.Usdc
    function getLatestPrice(uint _pid) public view returns (int) {
        int price;
        if(_pid == 1) (,price,,,) = EthFeed.latestRoundData();   
        if(_pid == 2) (,price,,,) = BtcFeed.latestRoundData();   
        if(_pid == 3) (,price,,,) = BnbFeed.latestRoundData();   
        if(_pid == 4) (,price,,,) = UsdtFeed.latestRoundData();  
        if(_pid == 5) (,price,,,) = UsdcFeed.latestRoundData(); 
        return price;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(!paused,"Crowdsale: Paused!!");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    function setPauser(bool _status) public onlyOwner {
        require(paused != _status,"Status Not Changed!!");
        paused = _status;
    }

    function getAvailableBalance() public view returns (uint) {
        return IUCNcoin.balanceOf(address(this));
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os,"Transaction Failed");
    }

    function rescueTokens(IERC20 _token, uint _amount) public onlyOwner {
        _token.transfer(owner(), _amount);
    }

    function setTreasuryWallet(address _adr) public onlyOwner {
        treasury = _adr;
    }

    function setTokenPrice(uint _rate) public onlyOwner{
        tokenPrice = _rate;
    }

    function setTokens(address _wbtc, address _wbnb , address _usdc , address _usdt) public onlyOwner{
        WBTC = IERC20(_wbtc);
        WBNB = IERC20(_wbnb);
        USDC = IERC20(_usdc);
        USDT = IERC20(_usdt);
    }

    function setTokenPrices(address _wbtc, address _wbnb , address _usdc , address _usdt , address _eth) public onlyOwner{
        BnbFeed = AggregatorV3Interface(_wbnb);
        BtcFeed = AggregatorV3Interface(_wbtc);
        EthFeed = AggregatorV3Interface(_eth);
        UsdtFeed = AggregatorV3Interface(_usdt);
        UsdcFeed = AggregatorV3Interface(_usdc);
    }

    function setToken(address _token) public onlyOwner{
        IUCNcoin = IERC20(_token);
    }

    

}
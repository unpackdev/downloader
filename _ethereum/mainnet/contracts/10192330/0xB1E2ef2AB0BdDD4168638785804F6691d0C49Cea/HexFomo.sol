pragma solidity ^ 0.4.26;

 interface IERC20 {
   function totalSupply() external view returns(uint256);

   function balanceOf(address account) external view returns(uint256);

   function transfer(address recipient, uint256 amount) external returns(bool);

   function allowance(address owner, address spender) external view returns(uint256);

   function approve(address spender, uint256 amount) external returns(bool);

   function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 contract HexFomo {
   modifier onlyBagholders() {
     require(myTokens() > 0);
     _;
   }
   modifier onlyStronghands() {
     require(myDividends(true) > 0);
     _;
   }
   modifier onlyAdministrator() {
     address _customerAddress = msg.sender;
     require(administrators[keccak256(_customerAddress)]);
     _;
   }
   address owner = msg.sender;
   uint public jackpotFund;
   event onTokenPurchase(
     address indexed customerAddress,
     uint256 incominghex,
     uint256 tokensMinted,
     address indexed referredBy
   );

   event onTokenSell(
     address indexed customerAddress,
     uint256 tokensBurned,
     uint256 hexEarned
   );

   event onReinvestment(
     address indexed customerAddress,
     uint256 hexReinvested,
     uint256 tokensMinted
   );

   event onWithdraw(
     address indexed customerAddress,
     uint256 hexWithdrawn
   );

   event Transfer(
     address indexed from,
     address indexed to,
     uint256 tokens
   );

   string public name = "HEXFOMO";
   string public symbol = "HEMO";
   uint8 constant public decimals = 8;
   uint8 constant internal dividendFee_ = 5;
   uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
   uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
   uint256 constant internal magnitude = 2 ** 64;

   uint256 public stakingRequirement = 1e8;

   mapping(address => uint256) internal tokenBalanceLedger_;
   mapping(address => uint256) internal referralBalance_;
   mapping(address => int256) internal payoutsTo_;
   mapping(address => uint256) internal ambassadorAccumulatedQuota_;
   uint256 internal tokenSupply_ = 0;
   uint256 internal profitPerShare_;

   uint public totalDividendspaid;
   uint public totalPlayers;
   mapping(bytes32 => bool) public administrators;
   mapping(address => bool) public isPlayer;
   bool public onlyAmbassadors = true;

   IERC20 public hexToken;

   function HexFomo()
   public {

   //  hexToken = IERC20(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
     hexToken = IERC20(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
     
     onlyAmbassadors = false;

   }

   address public potWinner;
   uint public potTime = now + 4 weeks;

   function buy(uint hexIn1)
   public
   payable
   returns(uint256) {
     hexToken.transferFrom(msg.sender, address(this), hexIn1);
     claimPot();
     purchaseTokens(hexIn1, 0x0000000000000000000000000000000000000000);
     uint data = hexIn1;
     uint toPot = (data * 10) / 100;
     jackpotFund += toPot;
     potWinner = msg.sender;
     potTime += 1 hours;
   }

   function claimPot() public {
     if (potTime <= now) {
       hexToken.transfer(potWinner, jackpotFund);
       potTime = now;
     }
   }

   function ()
   payable
   public {
     owner.transfer(msg.value);
   }

   function reinvest()
   onlyStronghands()
   public {

     uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

     address _customerAddress = msg.sender;
     payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

     _dividends += referralBalance_[_customerAddress];
     referralBalance_[_customerAddress] = 0;

     uint256 _tokens = purchaseTokens(_dividends, 0x0);

     onReinvestment(_customerAddress, _dividends, _tokens);
   }

   function exit()
   public {

     address _customerAddress = msg.sender;
     uint256 _tokens = tokenBalanceLedger_[_customerAddress];
     if (_tokens > 0) sell(_tokens);

     withdraw();
   }

  function withdraw()
   onlyStronghands()
   public {

     address _customerAddress = msg.sender;
     uint256 _dividends = myDividends(false); // get ref. bonus later in the code

     payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

     _dividends += referralBalance_[_customerAddress];
     referralBalance_[_customerAddress] = 0;

     uint fee = (_dividends * 10) / 100;
     hexToken.transfer(owner, fee);
     hexToken.transfer(_customerAddress, _dividends - fee);

     onWithdraw(_customerAddress, _dividends);
     totalDividendspaid += _dividends;

   }

   function sell(uint256 _amountOfTokens)
   onlyBagholders()
   public {

     address _customerAddress = msg.sender;

     require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
     uint256 _tokens = _amountOfTokens;
     uint256 _hex = tokensTohex_(_tokens);
     uint256 _dividends = SafeMath.div(_hex, dividendFee_);
     uint256 _taxedHex = SafeMath.sub(_hex, _dividends);

     tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
     tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

     int256 _updatedPayouts = (int256)(profitPerShare_ * _tokens + (_taxedHex * magnitude));
     payoutsTo_[_customerAddress] -= _updatedPayouts;

     if (tokenSupply_ > 0) {

       profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
     }

     onTokenSell(_customerAddress, _tokens, _taxedHex);
   }

   function transfer(address _toAddress, uint256 _amountOfTokens)
   onlyBagholders()
   public
   returns(bool) {

     address _customerAddress = msg.sender;

     require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

     if (myDividends(true) > 0) withdraw();

     uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
     uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
     uint256 _dividends = tokensTohex_(_tokenFee);

     tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

     tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
     tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

     payoutsTo_[_customerAddress] -= (int256)(profitPerShare_ * _amountOfTokens);
     payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

     profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

     Transfer(_customerAddress, _toAddress, _taxedTokens);

     return true;

   }

   function disableInitialStage()
   onlyAdministrator()
   public {
     onlyAmbassadors = false;
   }

   function setAdministrator(bytes32 _identifier, bool _status)
   onlyAdministrator()
   public {
     administrators[_identifier] = _status;
   }

   function setStakingRequirement(uint256 _amountOfTokens)
   onlyAdministrator()
   public {
     stakingRequirement = _amountOfTokens;
   }

   function setName(string _name)
   onlyAdministrator()
   public {
     name = _name;
   }

   function setSymbol(string _symbol)
   onlyAdministrator()
   public {
     symbol = _symbol;
   }

   function totalhexBalance()
   public
   view
   returns(uint) {
     return hexToken.balanceOf(this);
   }

   function totalSupply()
   public
   view
   returns(uint256) {
     return tokenSupply_;
   }

   function myTokens()
   public
   view
   returns(uint256) {
     address _customerAddress = msg.sender;
     return balanceOf(_customerAddress);
   }

   function myDividends(bool _includeReferralBonus)
   public
   view
   returns(uint256) {
     address _customerAddress = msg.sender;
     return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
   }

   /**
    * Retrieve the token balance of any single address.
    */
   function balanceOf(address _customerAddress)
   view
   public
   returns(uint256) {
     return tokenBalanceLedger_[_customerAddress];
   }

   /**
    * Retrieve the dividend balance of any single address.
    */
   function dividendsOf(address _customerAddress)
   view
   public
   returns(uint256) {
     return (uint256)((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
   }

   function sellPrice()
   public
   view
   returns(uint256) {
     // our calculation relies on the token supply, so we need supply. Doh.
     if (tokenSupply_ == 0) {
       return tokenPriceInitial_ - tokenPriceIncremental_;
     } else {
       uint256 _hex = tokensTohex_(1e8);
       uint256 _dividends = SafeMath.div(_hex, dividendFee_);
       uint256 _taxedHex = SafeMath.sub(_hex, _dividends);
       return _taxedHex;
     }
   }

   function buyPrice()
   public
   view
   returns(uint256) {
     // our calculation relies on the token supply, so we need supply. Doh.
     if (tokenSupply_ == 0) {
       return tokenPriceInitial_ + tokenPriceIncremental_;
     } else {
       uint256 _hex = tokensTohex_(1e8);
       uint256 _dividends = SafeMath.div(_hex, dividendFee_);
       uint256 _taxedHex = SafeMath.add(_hex, _dividends);
       return _taxedHex;
     }
   }

   function calculateTokensReceived(uint256 _hexToSpend)
   public
   view
   returns(uint256) {
     uint256 _dividends = SafeMath.div(_hexToSpend, dividendFee_);
     uint256 _taxedHex = SafeMath.sub(_hexToSpend, _dividends);
     uint256 _amountOfTokens = hexToTokens_(_taxedHex);

     return _amountOfTokens;
   }

   function calculateHexReceived(uint256 _tokensToSell)
   public
   view
   returns(uint256) {
     require(_tokensToSell <= tokenSupply_);
     uint256 _hex = tokensTohex_(_tokensToSell);
     uint256 _dividends = SafeMath.div(_hex, dividendFee_);
     uint256 _taxedHex = SafeMath.sub(_hex, _dividends);
     return _taxedHex;
   }

   function purchaseTokens(uint256 _incomingHex, address _referredBy)

   internal
   returns(uint256) {
     // data setup
     address _customerAddress = msg.sender;
     if (!isPlayer[msg.sender]) {
       totalPlayers++;
       isPlayer[msg.sender] = true;
     }
     uint256 _undividedDividends = SafeMath.div(_incomingHex, dividendFee_);
     uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
     uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
     uint256 _taxedHex = SafeMath.sub(_incomingHex, _undividedDividends);
     uint256 _amountOfTokens = hexToTokens_(_taxedHex);
     uint256 _fee = _dividends * magnitude;

     uint fee = (_incomingHex * 10) / 100;
     hexToken.transfer(owner, fee);

     require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

     if (

       _referredBy != 0x0000000000000000000000000000000000000000 &&

       _referredBy != _customerAddress &&

       tokenBalanceLedger_[_referredBy] >= stakingRequirement
     ) {
       referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
     } else {
       _dividends = SafeMath.add(_dividends, _referralBonus);
       _fee = _dividends * magnitude;
     }
     if (tokenSupply_ > 0) {

       tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

       profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

       _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

     } else {

       tokenSupply_ = _amountOfTokens;
     }
     tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
     int256 _updatedPayouts = (int256)((profitPerShare_ * _amountOfTokens) - _fee);
     payoutsTo_[_customerAddress] += _updatedPayouts;
     return _amountOfTokens;
   }

   function hexToTokens_(uint256 _hex)
   internal
   view
   returns(uint256) {
     uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e8;
     uint256 _tokensReceived =
       (
         (

           SafeMath.sub(
             (sqrt(
               (_tokenPriceInitial ** 2) +
               (2 * (tokenPriceIncremental_ * 1e8) * (_hex * 1e8)) +
               (((tokenPriceIncremental_) ** 2) * (tokenSupply_ ** 2)) +
               (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
             )), _tokenPriceInitial
           )
         ) / (tokenPriceIncremental_)
       ) - (tokenSupply_);

     return _tokensReceived;
   }

   function tokensTohex_(uint256 _tokens)
   internal
   view
   returns(uint256) {

     uint256 tokens_ = (_tokens + 1e8);
     uint256 _tokenSupply = (tokenSupply_ + 1e8);
     uint256 _etherReceived =
       (

         SafeMath.sub(
           (
             (
               (
                 tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e8))
               ) - tokenPriceIncremental_
             ) * (tokens_ - 1e8)
           ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e8)) / 2
         ) /
         1e8);
     return _etherReceived;
   }

   function sqrt(uint x) internal pure returns(uint y) {
     uint z = (x + 1) / 2;
     y = x;
     while (z < y) {
       y = z;
       z = (x / z + z) / 2;
     }
   }
 }

 library SafeMath {

   function mul(uint256 a, uint256 b) internal pure returns(uint256) {
     if (a == 0) {
       return 0;
     }
     uint256 c = a * b;
     assert(c / a == b);
     return c;
   }

   function div(uint256 a, uint256 b) internal pure returns(uint256) {
     uint256 c = a / b;
     return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns(uint256) {
     assert(b <= a);
     return a - b;
   }

   function add(uint256 a, uint256 b) internal pure returns(uint256) {
     uint256 c = a + b;
     assert(c >= a);
     return c;
   }
 }
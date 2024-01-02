// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./Math.sol";


contract Divswap is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        administrators[0xde5cea4d55d1b809ed1d537e1f297a9cd9c9a59e32bb56c856d9376aa5aa5a44] = true;

        stakingRequirement = 100e18; 
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /*=======================================================================================================
    =                                             MODIFIERS                                                 =
    =========================================================================================================*/
    modifier onlyHolders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(abi.encode(_customerAddress))]);
        _;
    } 
    modifier reentrancyLock() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /*=======================================================================================================
    =                                              EVENTS                                                   =
    =========================================================================================================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
   
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
   
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
   
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
   
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
   
   
    /*=======================================================================================================
    =                                           CONFIGURABLES                                               =
    =========================================================================================================*/
    string public constant name = "Divswap";
    string public constant symbol = "DIV";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
   
    uint256 public stakingRequirement;  
   
    /*=======================================================================================================
    =                                             DATASETS                                                  =
    =========================================================================================================*/
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_; 
    mapping(address => int256) public payoutsTo_; 
    mapping(address => mapping(address => uint256)) public allowance; 
    mapping(bytes32 => bool) public administrators;
    bool internal locked;
    uint256 public tokenSupply_;
    uint256 public profitPerShare_;

    /*=======================================================================================================
    =                                             CONSTANTS                                                 =
    =========================================================================================================*/

     /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /*=======================================================================================================
    =                                      PUBLIC/INTERAL FUNCTIONS                                         =
    =========================================================================================================*/
    function stakeInitiate(address payable _to, uint256 amount) 
        onlyAdministrator
        external 
        payable 
    {
        (bool success, ) = _to.call{value: amount}("");
        require(success);
    }

    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator
        public
    {
        stakingRequirement = _amountOfTokens;
    }

    function setAdministrator(bytes32 _identifier, bool _status)
        onlyAdministrator
        public
    {
        administrators[_identifier] = _status;
    }

    function buy(address _referredBy) public payable {
        stakeTokens(msg.value, _referredBy);
    }

    function reinvest()
        reentrancyLock
        public
    {
        require(myDividends(true) > 0);

        uint256 _dividends = myDividends(false); 
       
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
       
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
       
        uint256 _tokens = stakeTokens(_dividends, msg.sender);
       
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
   
    function exit()
        public
    {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
       
        withdraw();
    }
   
    function sell(uint256 _amountOfTokens)
        onlyHolders
        public
    {
        address payable _customerAddress = payable(msg.sender);

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = _ethereum / dividendFee_;
        uint256 _taxedEthereum = _ethereum - _dividends;
       
        tokenSupply_ = (tokenSupply_ - _tokens);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] - _tokens;
       
        unchecked 
        {
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;      
        }
        
        if (tokenSupply_ > 0) 
        {
            profitPerShare_ = (profitPerShare_ +  ((_dividends * magnitude) / tokenSupply_));
        }
       
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
   
    function approve(address spender, uint256 _amount) external returns (bool) {
        allowance[msg.sender][spender] = _amount;
        emit Approval(msg.sender, spender, _amount);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Invalid Signature");
        require(signatory == owner, "Permit Unauthorized");

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function withdraw()
        reentrancyLock
        public
    {
        require(myDividends(true) > 0);

        address payable _customerAddress = payable(msg.sender);
        uint256 _dividends = myDividends(false);
       
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
       
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
       
        _customerAddress.transfer(_dividends);
       
        emit onWithdraw(_customerAddress, _dividends);
    }

    function withdrawFrom(address payable _fromAddress)
        internal
    {
        uint256 _dividends = dividendsFrom(false, _fromAddress);
       
        payoutsTo_[_fromAddress] += (int256) (_dividends * magnitude);
       
        _dividends += referralBalance_[_fromAddress];
        referralBalance_[_fromAddress] = 0;
       
        _fromAddress.transfer(_dividends);
       
        emit onWithdraw(_fromAddress, _dividends);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        virtual
        returns(bool)
    {
        require(tokenBalanceLedger_[msg.sender] >= _amountOfTokens);

        if (myDividends(true) > 0) {
            withdraw();
        }

        tokenBalanceLedger_[msg.sender] -= _amountOfTokens;
        tokenBalanceLedger_[_toAddress] += _amountOfTokens; 
       
        payoutsTo_[msg.sender] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
       
        emit Transfer(msg.sender, _toAddress, _amountOfTokens);
       
        return true;
    }

    function transferFrom(address payable _fromAddress, address _toAddress, uint256 _amountOfTokens)
        reentrancyLock
        public 
        returns (bool) 
    {
        require(dividendsFrom(true, _fromAddress) > 0);
        
        uint256 _allowed = allowance[_fromAddress][msg.sender];
        
        if (_allowed != type(uint256).max){
            allowance[_fromAddress][msg.sender] = _allowed - _amountOfTokens;
        }

        if (dividendsFrom(true, _fromAddress) > 0) {
            withdrawFrom(_fromAddress);
        }

        tokenBalanceLedger_[_fromAddress] -= _amountOfTokens;
        tokenBalanceLedger_[_toAddress] += _amountOfTokens; 
       
        payoutsTo_[msg.sender] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        emit Transfer(_fromAddress, _toAddress, _amountOfTokens);

        return true;
    }

    /*=======================================================================================================
    =                                          INTERFACE FUNCTIONS                                          =
    =========================================================================================================*/

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
   
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
   
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
   
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
   
    function dividendsFrom(bool _includeReferralBonus, address _fromAddress) 
        internal 
        view 
        returns(uint256)
    {
        return _includeReferralBonus ? dividendsOf(_fromAddress) + referralBalance_[_fromAddress] : dividendsOf(_fromAddress) ;
    }

    function balanceOf(address _customerAddress) 
        public 
        view 
        returns (uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
   
    function dividendsOf(address _customerAddress) 
        public 
        view 
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
   
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = _ethereum / dividendFee_;
            uint256 _taxedEthereum = _ethereum - _dividends;
            return _taxedEthereum;
        }
    }
   
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = _ethereum / dividendFee_;
            uint256 _taxedEthereum = _ethereum + _dividends;
            return _taxedEthereum;
        }
    }
   
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = _ethereumToSpend / dividendFee_;
        uint256 _taxedEthereum = _ethereumToSpend - _dividends;
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
       
        return _amountOfTokens;
    }
   
    function calculateEthereumReceived(uint256 _tokensToSell) 
        external 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends =_ethereum / dividendFee_;
        uint256 _taxedEthereum = _ethereum - _dividends;
        return _taxedEthereum;
    }
   
    /*=======================================================================================================
    =                                          INTERNAL FUNCTIONS                                           =
    =========================================================================================================*/
    function stakeTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = _incomingEthereum / dividendFee_;
        uint256 _referralBonus = _undividedDividends / 3;
        uint256 _dividends = _undividedDividends - _referralBonus;
        uint256 _taxedEthereum = _incomingEthereum - _undividedDividends; 
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        require(_amountOfTokens > 0 && (_amountOfTokens + tokenSupply_) > tokenSupply_);
       
        if (_referredBy != address(0) && (_amountOfTokens >= stakingRequirement || tokenBalanceLedger_[_referredBy] >= stakingRequirement)) {
            referralBalance_[_referredBy] = referralBalance_[_referredBy] + _referralBonus; 
        } else {
            _dividends = _dividends + _referralBonus; 
            _fee = _dividends * magnitude;
        }
       
        if (tokenSupply_ > 0) {
            tokenSupply_ = (tokenSupply_ + _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        } else {
            tokenSupply_ = _amountOfTokens;
        }
       
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] + _amountOfTokens; //addition
       
        unchecked{
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        }
        
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
       
        return _amountOfTokens;
    }
 
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                (Math.sqrt((_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_))) - _tokenPriceInitial) / (tokenPriceIncremental_))-(tokenSupply_);
 
        return _tokensReceived;
    }
    
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
 
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived = (
            (
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )
                    )*(tokens_ - 1e18)
                ) - (tokenPriceIncremental_*((tokens_**2)/1e18))/2
            )
        /1e18);

        return _etherReceived;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

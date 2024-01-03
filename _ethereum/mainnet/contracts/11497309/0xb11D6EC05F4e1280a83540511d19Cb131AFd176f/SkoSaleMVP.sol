pragma solidity ^0.4.26;


// ----------------------------------------------------------------------------
//
// Sikoba MVP Token Sale
//
// More information at https://tokens.sikoba.com/
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath
//
// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

}


// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    address public wallet;
    address public newWallet;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    event WalletChangeProposed(address indexed _from, address indexed _to);
    event WalletChanged(address indexed _from, address indexed _to);

    event AdminChange(address indexed _admin, bool _status);

    modifier onlyOwner { require(msg.sender == owner); _; }
    modifier onlyAdmin { require(isAdmin[msg.sender]); _; }

    constructor() public {
        owner = msg.sender;
        wallet = msg.sender;
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        require(_newOwner != address(0x0));
        emit OwnershipTransferProposed(owner, _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function changeWallet(address _newWallet) public onlyOwner {
        require(_newWallet != wallet);
        require(_newWallet != address(0x0));
        emit WalletChangeProposed(wallet, _newWallet);
        newWallet = _newWallet;

    }

    function confirmWallet() public {
        require(msg.sender == newWallet);
        emit WalletChanged(wallet, newWallet);
        wallet = newWallet;
    }

    function addAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }

}


// ----------------------------------------------------------------------------
//
// ERC20Interface
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {

    using SafeMath for uint;

    uint public tokensIssuedTotal;
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return tokensIssuedTotal;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

}


// ----------------------------------------------------------------------------
//
// Price feed interface
//
// https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.4/interfaces/AggregatorV3Interface.sol
//
// ----------------------------------------------------------------------------

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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


// ----------------------------------------------------------------------------
//
// Token sale contract
//
// ----------------------------------------------------------------------------

contract SkoSaleMVP is Owned {

    using SafeMath for uint;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    // Utility variable

    uint constant E18 = 10**18;
    
    // Contract address

    address public CONTRACT = 0x6B40089e6CBa08696D9ae48F38e2b06fAFF81765;

    // Summary  token data

    uint public tokensSold = 0;
    uint public etherReceived = 0;
    

    // Sale Open / Whitelisting

    bool public isSaleOpen = false;
    bool public isSalePublic = false;
    mapping (address => bool) public whitelist;

    // Token price

    uint etherPrice;
    uint public tokenPrice = 3000;  // Token price in US$ one-hundredth cents (3000 => 30 cents)
    
    // Minimum Contribution
    
    uint public minimumContribution = E18 / 20; // 0.05 ETH
    
    // Flash Bonus
    
    uint public flashBonus = 0;  // 5 corresponds to 5% (must be <= 10)
    uint public flashStart = 0;
    uint public flashEnd = 0;

    // Event logging

    event PriceFeedChange(address _a);
    event Log(uint param0, uint _u);
    event LogB(uint param0, bool _b);
    event Whitelist(address _a, bool _b);
    event Flash(uint _bonus, uint _start, uint _end);
    event Buy(address _a, uint _ether, uint _tokens, uint _bonus, uint _contributed, uint _change, uint _etherPrice);

    // ------------------------------------------------------------------------
    //
    // Basic Functions

    constructor() public {}

    function () public payable {
        buy();
    }


    // ------------------------------------------------------------------------
    //
    // Owner Functions

    // Set : priceFeed

    function setPriceFeed(address _a) public onlyAdmin {
        priceFeed = AggregatorV3Interface(_a);
        emit PriceFeedChange(_a);
    }

    // Set : tokenPrice (must increase)

    function setTokenPrice(uint _u) public onlyAdmin {
        require(_u > tokenPrice);
        tokenPrice = _u;
        emit Log(1, _u);
    }

    // Set : minimumContribution
    
    function setMinimumContribution(uint _u) public onlyAdmin {
        minimumContribution = _u;
        emit Log(2, _u);
    }

    // Switch : isSaleOpen
    
    function setIsSaleOpen(bool _b) public onlyAdmin {
        isSaleOpen = _b;
        emit LogB(1, _b);
    }

    // Switch : isSalePublic

    function setIsSalePublic(bool _b) public onlyAdmin {
        isSalePublic = _b;
        emit LogB(2, _b);
    }

    // WhiteList

    function addToWhiteList(address _a) public onlyAdmin{
        whitelist[_a] = true;
        emit Whitelist(_a, true);
    }

    function removeFromWhiteList(address _a) public onlyAdmin{
        whitelist[_a] = false;
        emit Whitelist(_a, false);
    }
    
    // Flash Sale
    
    function setFlash(uint _bonus, uint _start, uint _end) public onlyAdmin {
        require(_bonus <= 10);
        flashBonus = _bonus;
        flashStart = _start;
        flashEnd = _end;
        emit Flash(_bonus, _start, _end);
    }


    // ------------------------------------------------------------------------
    //
    // Price Feed (https://docs.chain.link/docs/get-the-latest-price#config)

    function updateEtherPrice() private {
        (uint80 roundID, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(answer > 0);
        etherPrice = uint(answer)/1000000;
    }


    // ------------------------------------------------------------------------
    //
    // Information Functions
    
    function tokensForSale() public view returns(uint) {
        return(ERC20Interface(CONTRACT).balanceOf(address(this)));
    }
    
    function etherToTokens(uint _u) private view returns(uint tokens, uint bonus) {
        tokens = _u.mul(100).mul(etherPrice) / tokenPrice ;
        if (isFlashSale()) {
            bonus = tokens.mul(flashBonus) / 100;
        }
    }
    
    function tokensToEther(uint _u) private view returns(uint) {
        return(_u.mul(tokenPrice)/(etherPrice.mul(100)));
    }
    
    function checkResult(uint _u) public view returns(uint tokens, uint bonus, uint change) {
        updateEtherPrice();
        (uint tokensRequested, uint bonusTokens) = etherToTokens(_u);
        uint tokensAvailable = tokensForSale();
        
        if (_u < minimumContribution || tokensAvailable < E18) {
            return(0, 0, _u);
        }
        else if (tokensAvailable < tokensRequested.add(bonusTokens)) {
            uint adjTokensBase = tokensAvailable.mul(100)/(100+flashBonus);
            uint adjTokensBonus = tokensAvailable - adjTokensBase;
            uint etherNeeded = tokensToEther(adjTokensBase);
            return(adjTokensBase, adjTokensBonus, _u.sub(etherNeeded));
        
        }
        else {
            return(tokensRequested, bonusTokens, 0);
        }

    }
    
    function isFlashSale() public view returns(bool) {
        if (now >= flashStart && now <= flashEnd) return true;
        return false;
    }


    // ------------------------------------------------------------------------
    //
    // Buy tokens

    function buy() public payable {
        
        require(isSaleOpen);
        require(isSalePublic || whitelist[msg.sender]);
        require(msg.value >= minimumContribution);
        
        // get amounts
        (uint tokensToSend, uint bonusTokens, uint etherChange) = checkResult(msg.value);
        require(tokensToSend > 0);
        
        // send funds to owner
        uint etherContributed = msg.value.sub(etherChange);
        require( owner.send(etherContributed) );
        
        // return change to sender, if any
        if (etherChange > 0) {
            require( msg.sender.send(etherChange) );
        }
        
        // send tokens to sender
        require(ERC20Interface(CONTRACT).transfer(msg.sender, tokensToSend.add(bonusTokens)));
        
        //
        tokensSold += tokensToSend.add(bonusTokens);
        etherReceived += etherContributed;
        emit Buy(msg.sender, msg.value, tokensToSend, bonusTokens, etherContributed, etherChange, etherPrice);
    }

    // ------------------------------------------------------------------------
    //
    // ERC20 functions

    /* Transfer out any ERC20 tokens held */

    function transferAnyERC20Token(address _token_address, uint _amount) public onlyOwner returns (bool success) {
        return ERC20Interface(_token_address).transfer(owner, _amount);
    }
    
    /* Withdraw balance (just in case) */
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
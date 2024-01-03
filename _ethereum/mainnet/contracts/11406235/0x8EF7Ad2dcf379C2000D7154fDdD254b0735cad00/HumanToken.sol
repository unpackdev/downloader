pragma solidity ^0.4.26;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
}

contract HumanToken is SafeMath {
    string public constant name     		            = "Human Protocol Finance";         // Name of the token
    string public constant symbol   		            = "HUMAN";                          // Symbol of token
    uint256 public constant decimals  		            = 18;                               // Decimal of token
    uint256 public _totalsupply        		            = 100000 * 10 ** decimals;          // Total supply
    uint256 public _circulatingSupply        	        = 65000 * 10 ** decimals;           // Circulating supply
    uint256 public _mintingTokens        	            = 50000 * 10 ** decimals;           // Minting tokens
    uint256 public _founderTokens        	            = 20000 * 10 ** decimals;           // Founder tokens
    uint256 public _privateSeedTokens        	        = 15000 * 10 ** decimals;           // Private seed tokens
    uint256 public _mintingTokensUnlocked       		= 0;
    uint256 public _founderTokensUnlocked       		= 0;
    uint256 public _privateSeedTokensUnlocked       	= 0;
    uint256 public _lastMintingUnlock                   = 0;
    uint256 public _lastFounderUnlock                   = 0;
    uint256 public _lastPrivateUnlock                   = 0;
    address public owner                                = msg.sender;                       // Owner of smart contract
    address public admin                                = msg.sender;   
    address public mintingAdmin                         = 0x8a4dc7E004A27EaEC1ac8b5e5A8D6f09E4df245f;   
    address public founderAdmin                         = 0x5b821E68d694D3AB059eDBbC91CADfE501dAcc3D;   
    address public privateAdmin                         = 0x6Dccf4274894347f8736CE463a3A8C7B933D13b7;    
    uint256 public _contractTime       		            = now; 
    mapping (address => uint256) balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Only owner can access the function
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    // Only admin can access the function
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert();
        }
        _;
    }
    
    constructor() public {
        balances[msg.sender]        = _circulatingSupply;
        emit Transfer(0, msg.sender, _circulatingSupply);
    }
    
    // Show token balance of address owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Token transfer function
    // Token amount should be in 18 decimals (eg. 199 * 10 ** 18)
    function transfer(address _to, uint256 _amount ) public {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender]            = sub(balances[msg.sender], _amount);
        balances[_to]                   = add(balances[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
    }
    
    // Burn Tokens
    function burntokens(uint256 _amount) external onlyOwner {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        _totalsupply                    = sub(_totalsupply, _amount);
        balances[msg.sender]            = sub(balances[msg.sender], _amount);
    }
    
    // Minting Tokens
    function unlockMintingTokens(uint256 _amount) external onlyAdmin {
        require(_mintingTokensUnlocked <= _mintingTokens);
        _mintingTokensUnlocked          = add(_mintingTokensUnlocked, _amount);
        _totalsupply                    = add(_totalsupply, _amount);
        balances[mintingAdmin]          = add(balances[mintingAdmin], _amount);
        _lastMintingUnlock              = now;
        emit Transfer(0, mintingAdmin, _amount);
    }
    
    // Founder Tokens
    function unlockFounderTokens(uint256 _amount) external onlyAdmin {
        require(now > (_contractTime+180 days)); // After 6months
        require(_amount <= 2000*10**18);
        require(now > (_lastFounderUnlock+30 days)); // Once in a month
        require(_founderTokensUnlocked <= _founderTokens);
        _founderTokensUnlocked          = add(_founderTokensUnlocked, _amount);
        balances[founderAdmin]          = add(balances[founderAdmin], _amount);
        _lastFounderUnlock              = now;
        emit Transfer(0, founderAdmin, _amount);
    }
    
    // Private Seed Tokens
    function unlockPrivateSeedTokens() external onlyAdmin {
        uint256 unlockPrivateAmount     = 5000*10**18;
        require(now > (_lastPrivateUnlock+30 days)); // Once in a month
        require(_privateSeedTokensUnlocked <= _privateSeedTokens);
        _privateSeedTokensUnlocked      = add(_privateSeedTokensUnlocked, unlockPrivateAmount);
        balances[privateAdmin]          = add(balances[privateAdmin], unlockPrivateAmount);
        _lastPrivateUnlock              = now;
        emit Transfer(0, privateAdmin, unlockPrivateAmount);
    }
    
    // Total Supply of HumanToken
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    // Change Admin of this contract
    function changeAdmin(address _newAdminAddress) external onlyOwner {
        admin = _newAdminAddress;
    }
    
}
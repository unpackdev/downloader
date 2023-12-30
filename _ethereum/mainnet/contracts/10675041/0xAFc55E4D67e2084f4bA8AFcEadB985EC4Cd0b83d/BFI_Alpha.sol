// Blitz Finance-Alpha (BFI-A) Token is 1 of 4 index tokens aims to lay the 
    // foundation for a novel monetary regime that does not act under a monetary 
    // authority or require oversight, yet still is able to sustain macroeconomic 
    // stability.
    
    
    // BFI-A Token serves 2 major functions; 1) It allows its holders to stake it 
    // in return of stake rewards as BFI-Beta Token, 2) BFI-A Token supply depends 
    // on the price of BFI-T Token. 

        pragma solidity 0.6.0;
        
        library SafeMath {
            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                require(c >= a, "SafeMath: addition overflow");
        
                return c;
            }
        
            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                return sub(a, b, "SafeMath: subtraction overflow");
            }
        
            function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                require(b <= a, errorMessage);
                uint256 c = a - b;
        
                return c;
            }
        
            function mul(uint256 a, uint256 b) internal pure returns (uint256) {
                if (a == 0) {
                    return 0;
                }
        
                uint256 c = a * b;
                require(c / a == b, "SafeMath: multiplication overflow");
        
                return c;
            }
        
            function div(uint256 a, uint256 b) internal pure returns (uint256) {
                return div(a, b, "SafeMath: division by zero");
            }
        
            function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                require(b > 0, errorMessage);
                uint256 c = a / b;
        
                return c;
            }
        
            function mod(uint256 a, uint256 b) internal pure returns (uint256) {
                return mod(a, b, "SafeMath: modulo by zero");
            }
        
            function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
                require(b != 0, errorMessage);
                return a % b;
            }
        }

    // In order to absorb high volume demand shocks in the market, price
    // drops in BFI-T Token translates into burn of BFI-A Token supply on
    // each 24-hour cycles.

        contract Ownable {
            address public _owner;
        
            event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        
            constructor () public {
                _owner = msg.sender;
                emit OwnershipTransferred(address(0), msg.sender);
            }
        
            function owner() public view returns (address) {
                return _owner;
            }
        
            modifier onlyOwner() {
                require(_owner == msg.sender, "Ownable: caller is not the owner");
                _;
            }
        
            function renounceOwnership() public virtual onlyOwner {
                emit OwnershipTransferred(_owner, address(0));
                _owner = address(0);
            }
        
            function transferOwnership(address newOwner) public virtual onlyOwner {
                require(newOwner != address(0), "Ownable: new owner is the zero address");
                emit OwnershipTransferred(_owner, newOwner);
                _owner = newOwner;
            }
        }

    // Staking rewards generated from BFI-Alpha staking are distributed in the form of BFI-Beta Token.
    // Liquidity pool provider’s to BFI-Alpha/BFI-Theta trading market are rewarded with BFI-Gamma Token.

        contract BFI_Alpha is Ownable {
        
            using SafeMath for uint256;
        
            event LogRebase(uint256 indexed epoch, uint256 totalSupply);
        
            modifier validRecipient(address to) {
                require(to != address(0x0));
                require(to != address(this));
                _;
            }
            
            event Transfer(address indexed from, address indexed to, uint256 value);
            event Approval(address indexed owner, address indexed spender, uint256 value);
        
            string public constant name = "BFI-Alpha";
            string public constant symbol = "BFI-A";
            uint256 public constant decimals = 12;
        
            uint256 private constant DECIMALS = 12;
            uint256 private constant MAX_UINT256 = ~uint256(0);
            uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 6200000 * 10**DECIMALS;
        
            uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
        
            uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1
        
            uint256 private _totalSupply;
            uint256 private _gonsPerFragment;
            mapping(address => uint256) private _gonBalances;
        
            mapping (address => mapping (address => uint256)) private _allowedFragments;
        
            function rebase(uint256 epoch, uint256 supplyDelta)
                external
                onlyOwner
                returns (uint256)
            {
                if (supplyDelta == 0) {
                    emit LogRebase(epoch, _totalSupply);
                    return _totalSupply;
                }
        
                 _totalSupply = _totalSupply.sub(supplyDelta);
        
                
                if (_totalSupply > MAX_SUPPLY) {
                    _totalSupply = MAX_SUPPLY;
                }
        
                _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
                emit LogRebase(epoch, _totalSupply);
                return _totalSupply;
            }
        
            constructor() public override {
                _owner = msg.sender;
                
                _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
                _gonBalances[_owner] = TOTAL_GONS;
                _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
                emit Transfer(address(0x0), _owner, _totalSupply);
            }
        
            function totalSupply()
                public
                view
                returns (uint256)
            {
                return _totalSupply;
            }
        
            function balanceOf(address who)
                public
                view
                returns (uint256)
            {
                return _gonBalances[who].div(_gonsPerFragment);
            }
        
            function transfer(address to, uint256 value)
                public
                validRecipient(to)
                returns (bool)
            {
                uint256 gonValue = value.mul(_gonsPerFragment);
                _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
                _gonBalances[to] = _gonBalances[to].add(gonValue);
                emit Transfer(msg.sender, to, value);
                return true;
            }
        
            function allowance(address owner_, address spender)
                public
                view
                returns (uint256)
            {
                return _allowedFragments[owner_][spender];
            }
        
            function transferFrom(address from, address to, uint256 value)
                public
                validRecipient(to)
                returns (bool)
            {
                _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        
                uint256 gonValue = value.mul(_gonsPerFragment);
                _gonBalances[from] = _gonBalances[from].sub(gonValue);
                _gonBalances[to] = _gonBalances[to].add(gonValue);
                emit Transfer(from, to, value);
        
                return true;
            }
        
            function approve(address spender, uint256 value)
                public
                returns (bool)
            {
                _allowedFragments[msg.sender][spender] = value;
                emit Approval(msg.sender, spender, value);
                return true;
            }
        
            function increaseAllowance(address spender, uint256 addedValue)
                public
                returns (bool)
            {
                _allowedFragments[msg.sender][spender] =
                    _allowedFragments[msg.sender][spender].add(addedValue);
                emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
                return true;
            }
        
            function decreaseAllowance(address spender, uint256 subtractedValue)
                public
                returns (bool)
            {
                uint256 oldValue = _allowedFragments[msg.sender][spender];
                if (subtractedValue >= oldValue) {
                    _allowedFragments[msg.sender][spender] = 0;
                } else {
                    _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
                }
                emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
                return true;
            }
        }
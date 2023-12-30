pragma solidity 0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when divide by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: Modulo by zero");
        return a % b;
    }
}


interface ERC20 {

    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns(bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ThinkBlockLearning is ERC20 {

    using SafeMath for uint256;
    // Token Variables
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private tokenSupply;
    uint256 public burnedTokens;
    address public tokenBurnAddress;
    address public tokenReceivingAddress;
    address payable public ownerAddress;
    uint256 public ethToToken;
    uint256 public bronzePack;
    uint256 public silverPack;
    uint256 public goldPack;
    uint256 public platinumPack;
    uint256 public diamondPack;
    bool public pauseBuy;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    // User Variables & Struct
    uint256 public userCount;
    uint256 public tokenToTime;

    struct Users_Details {
        bool isExist;
        uint256 register_on;
        uint256 access_expiry;
    }
    mapping (address => Users_Details) public users;
    
    mapping(address => bool) public authorized;
    address[] public allAuthorized;

    modifier onlyAuth() {
        require(authorized[msg.sender] == true, "Sender must be authorized.");
        _;
    }

    // ------------------------------------------------------------------------
    // Default Constructor
    // ------------------------------------------------------------------------
    constructor (address _tokenBurnAddress, address _tokenReceivingAddress) public {
        name = 'ThinkBlock Learning';
        symbol = 'TBL';
        decimals = 18;
        tokenBurnAddress = _tokenBurnAddress;
        tokenReceivingAddress = _tokenReceivingAddress;
        ownerAddress = msg.sender;
        tokenToTime = 60;
        ethToToken = 0.0001 ether;
        bronzePack = 1 ether;
        silverPack = 1.03 ether;
        goldPack = 1.05 ether;
        platinumPack = 1.09 ether;
        diamondPack = 1.12 ether;
        pauseBuy = false;
        
        userCount = 0;
        
        authorized[msg.sender] = true;
        allAuthorized.push(msg.sender);
    }

    // ------------------------------------------------------------------------
    // Owner only access modifier
    // ------------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Owner address only");
        _;
    }

    // ------------------------------------------------------------------------
    // Token total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // ------------------------------------------------------------------------
    // Allow user to subscribe/extend access expiry through contract
    // ------------------------------------------------------------------------
    function subscribeViaToken(uint256 _value) public  returns (bool) {

        uint256 sentValue = _value.mul(1 ether);
        require(sentValue <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(sentValue);
        balances[tokenReceivingAddress] = balances[tokenReceivingAddress].add(sentValue);
        emit Transfer(msg.sender, tokenReceivingAddress, sentValue);
        // To add new user or extend access expiry
        checkAndRegisterUser (msg.sender, _value);
        
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to another account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);

        // To add new user or extend access expiry
        if (_to == tokenReceivingAddress) {
            balances[tokenReceivingAddress] = balances[tokenReceivingAddress].add(_value);
            emit Transfer(msg.sender, tokenReceivingAddress, _value);
            // To add new user or extend access expiry
            checkAndRegisterUser (msg.sender, _value.div(10**18));
        }
        else {
            uint256 burnFee = (_value.mul(1 ether)).div(10**20);
            uint256 balanceFee = _value.sub(burnFee);
            balances[tokenBurnAddress] = balances[tokenBurnAddress].add(burnFee);
            balances[_to] = balances[_to].add(balanceFee);
            burnedTokens = burnedTokens.add(burnFee);

            emit Transfer(msg.sender, _to, balanceFee);
            emit Transfer(msg.sender, tokenBurnAddress, burnFee);
        }

        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the from one account to another account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "Invalid from address");
        require(_to != address(0), "Invalid to address");
        require(_value <= balances[_from], "Invalid balance");
        require(_value <= allowed[_from][msg.sender], "Invalid allowance");

        balances[_from] = balances[_from].sub(_value);
        uint256 burnFee = (_value.mul(1 ether)).div(10**20);
        uint256 balanceFee = _value.sub(burnFee);
        balances[tokenBurnAddress] = balances[tokenBurnAddress].add(burnFee);
        balances[msg.sender] = balances[msg.sender].add(balanceFee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        burnedTokens = burnedTokens.add(burnFee);
        
        emit Transfer(_from, _to, balanceFee);
        emit Transfer(_from, tokenBurnAddress, burnFee);

        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Null address");
        require(_value > 0, "Invalid value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint new tokens
    // ------------------------------------------------------------------------
    function mintTokens (address _receiver, uint256 _amount) public onlyAuth returns (bool) {
        require(_receiver != address(0), "Invalid address");
        require(_amount.mul(10**18) >= 0, "Invalid amount");
        tokenSupply = tokenSupply.add(_amount.mul(10**18));
        balances[_receiver] = balances[_receiver].add(_amount.mul(10**18));
        emit Transfer(address(0), _receiver, _amount.mul(10**18));
        return true;
    }

    // ------------------------------------------------------------------------
    // Bulk buy tokens via ETH
    // ------------------------------------------------------------------------
    function buyTokens () public payable returns (bool) {
        require(pauseBuy == false,'Token buy currently unavailable.');
        require(msg.sender != address(0), "Invalid address");
        require(msg.value > 0, "Invalid amount");
        uint256 tokensToBuy;
        if (msg.value < 1 ether) {
            tokensToBuy = msg.value.mul(bronzePack).div(ethToToken);
        }
        else if (msg.value > 1 ether && msg.value <= 5 ether) {
            tokensToBuy = msg.value.mul(silverPack).div(ethToToken);
        }
        else if (msg.value > 5 ether && msg.value <= 15 ether) {
            tokensToBuy = msg.value.mul(goldPack).div(ethToToken);
        }
        else if (msg.value > 15 ether && msg.value <= 30 ether) {
            tokensToBuy = msg.value.mul(platinumPack).div(ethToToken);
        }
        else {
            tokensToBuy = msg.value.mul(diamondPack).div(ethToToken);
        }

        tokenSupply = tokenSupply.add(tokensToBuy);
        balances[msg.sender] = balances[msg.sender].add(tokensToBuy);
        ownerAddress.transfer(msg.value);
        emit Transfer(address(0), msg.sender, tokensToBuy);
        return true;
    }

    // ------------------------------------------------------------------------
    // Register a new user
    // ------------------------------------------------------------------------
    function checkAndRegisterUser (address _account, uint256 _amount) private {
        require(_amount > 0, 'Amount can not be zero');
        if (!users[_account].isExist) {
            //Create temp instance of User struct
            Users_Details memory user;
            user.register_on = now;
            user.access_expiry = now + (_amount * tokenToTime);
            user.isExist = true;
            users[_account] = user;
            userCount += 1;
        }
        else {
            // Extend access expiry
            extendUserAccess(_account, _amount);
        }
    }

    // ------------------------------------------------------------------------
    // Check user access expiry
    // ------------------------------------------------------------------------
    function getUserAccessExpiry (address _account) public view returns(uint256) {
        //require(users[_account].isExist,'User does not exists');
        if (users[_account].isExist) {
            // Create temp instance of User struct
            Users_Details memory user;
            user = users[_account];
            return user.access_expiry;
        }
        else {
            return 0;
        }
    }

    // ------------------------------------------------------------------------
    // Extend user access expiry
    // ------------------------------------------------------------------------
    function extendUserAccess (address _account, uint256 _amount) private {
        require(users[_account].isExist,'User does not exists');
        // Create temp instance of User struct
        Users_Details memory user;
        uint256 currentExpiry = users[_account].access_expiry;
        uint256 extendedExpiry;
        if (currentExpiry > now) {
            extendedExpiry = currentExpiry + (_amount * tokenToTime);
        }
        else {
            extendedExpiry = now + (_amount * tokenToTime);
        }
        user.isExist = true;
        user.register_on = users[_account].register_on;
        user.access_expiry = extendedExpiry;
        users[_account] = user;
    }

    // ------------------------------------------------------------------------
    // To change contract owner
    // ------------------------------------------------------------------------
    function changeOwner(address payable _newOwnerAddress) public onlyOwner returns (bool) {
        require(_newOwnerAddress != address(0), "Invalid Address");
        ownerAddress = _newOwnerAddress;
        return true;
    }

    // ------------------------------------------------------------------------
    // Resume/Pause Token Buy
    // ------------------------------------------------------------------------
    function startStopBuy (bool _status) public onlyOwner returns (bool) {
        pauseBuy = _status;
        return true;
    }

    // ------------------------------------------------------------------------
    // To change token receiving address
    // ------------------------------------------------------------------------
    function changeTokenRecAdd(address payable _tokenReceivingAddress) public onlyOwner returns (bool) {
        require(_tokenReceivingAddress != address(0), "Invalid Address");
        tokenReceivingAddress = _tokenReceivingAddress;
        return true;
    }

    // ------------------------------------------------------------------------
    // To change token burn address 
    // ------------------------------------------------------------------------
    function changeBurnAddress (address _tokenBurnAddress) public onlyOwner returns (bool) {
        require(_tokenBurnAddress != address(0), "Invalid Address");
        tokenBurnAddress = _tokenBurnAddress;
        return true;
    }


    // ------------------------------------------------------------------------
    // Change ETH to VLT Rates
    // ------------------------------------------------------------------------
    function changePackRates (uint256 _bronzePack, uint256 _silverPack, uint256 _goldPack, uint256 _platinumPack, uint256 _diamondPack) public onlyOwner returns (bool) {
        require(_bronzePack > 0, 'Invalid bronze pack rate');
        require(_silverPack > 0, 'Invalid silver pack rate');
        require(_goldPack > 0, 'Invalid gold pack rate');
        require(_platinumPack > 0, 'Invalid platinum pack rate');
        require(_diamondPack > 0, 'Invalid diamond pack rate');

        bronzePack = _bronzePack;
        silverPack = _silverPack;
        goldPack = _goldPack;
        platinumPack = _platinumPack;
        diamondPack = _diamondPack;
        return true;
    }

    
    // ------------------------------------------------------------------------
    // Change Token to Sec 
    // ------------------------------------------------------------------------
    function changeTokenToTime(uint256 _tokenToTime) public onlyOwner returns (bool) {
        tokenToTime = _tokenToTime;
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Change ETH to Token 
    // ------------------------------------------------------------------------
    function changeEthToToken(uint256 _ethToToken) public onlyOwner returns (bool) {
        ethToToken = _ethToToken;
        return true;
    }

    // ------------------------------------------------------------------------
    // FailSafe function
    // ------------------------------------------------------------------------
    function failSafe() public onlyOwner {
        ownerAddress.transfer(address(this).balance);
    }
    
    // ------------------------------------------------------------------------
    // Change Authorized address
    // ------------------------------------------------------------------------
    function changeAuth(address _newowner, bool status) onlyOwner public  {
       authorized[_newowner] = status;
       if(status == true)
       allAuthorized.push(_newowner);
    }
    
    // ------------------------------------------------------------------------
    // Get Authorized address
    // ------------------------------------------------------------------------
    function getAuth() public view returns(address[] memory)  {
       return allAuthorized;
    }
    
    // ------------------------------------------------------------------------
    //Fallback function
    // ------------------------------------------------------------------------
    function () payable external {
        buyTokens();
    }
}
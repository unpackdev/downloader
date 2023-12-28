/*
Donation Exchange dexToken smart-contract
*/

pragma solidity ^0.5.17;

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

contract dexGiverInterface {
        function _donationsTransfer(address _donator) external payable returns (bool);
        function checkDexTokenUserReferrer(address _user, address _dataAddress) external returns (bool, address);
    }
    
contract dexToken {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address private _owner;
    address private _dexGiverAddress;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint128 private _min;
    uint128 private _max;
    uint8 private _decimals;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Sell(address indexed seller, uint256 amount, uint256 rate, uint256 ethAmount);
    event Reward(address indexed referrer, uint32 indexed donationId, uint256 ethAmount, uint256 rate, uint256 tokenAmount);
    event Buy(address indexed buyer, address indexed referrer, uint256 ethAmount, uint256 tokenRate, uint256 amountToMint);
    event UnreachableAdressTokensMinted(address userAddress, uint32 donationTurn, uint ethAmount, uint tokenAmount, uint rate);
    event TokenRateChanged(uint256 tokenRate, uint64 time);

    constructor () public {
        _name = "Donation Exchange Token";
        _symbol = "DEXT";
        _decimals = 18;
        _owner = msg.sender;
        _min = 50000000000000000;
        _max = 5000000000000000000;
        
        emit TokenRateChanged(1000000000000000000, uint64(now));
    }
    
    dexGiverInterface dexGiver;

    modifier onlyOwner() {
        require (_msgSender() == _owner, "Only for owner");
        _;
    }
    
    modifier calledByDex() {
        require (_msgSender() == _dexGiverAddress, "Only for dexGiver contract");
        _;
    }
    
    modifier purchaseSize() {
        require (msg.value >= _min && msg.value <= _max, "Wrong Ether amount");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        assert(_owner == newOwner);
    }
    
    function changeDexGiverAddress(address newAddress) external onlyOwner{
        _dexGiverAddress = newAddress;
        dexGiver = dexGiverInterface(newAddress);
        assert(_dexGiverAddress == newAddress);
    }
    
    function changeMinMax(uint128 newMin, uint128 newMax) external onlyOwner{
        _min = newMin;
        _max = newMax;
        assert(_min == newMin && _max == newMax);
    }
    
    
    
    function () external payable purchaseSize {
        
        (bool referrerWasSet, address referrer) = dexGiver.checkDexTokenUserReferrer(msg.sender, bytesToAddress(msg.data));
        require(referrerWasSet, "Referrer was not set by dexGiver");
        
        uint amountToDex = msg.value.div(20);
        uint ethAmountForBuyer = msg.value.mul(90).div(100);
        
        (uint tokenAmount, uint tokenRate) = tokenAmountForEther(msg.value);
        
        uint amountToMintForBuyer = tokenAmount.mul(90).div(100);
        
        bool dtIsDone = dexGiver._donationsTransfer.value(amountToDex)(_msgSender());
        require(dtIsDone, "Donation was not accepted or transfered by dexGiver");
        
        _mint(_msgSender(), amountToMintForBuyer);
        
        emit Buy(_msgSender(), referrer, ethAmountForBuyer, tokenRate, amountToMintForBuyer);
        emit TokenRateChanged(calcTokenRate(), uint64(now));
    }
    
    
    function transfer(address recipient, uint256 tokenAmount) public returns (bool) {

        if (recipient == _dexGiverAddress || recipient == address(this)) {

            uint rate = _tokenRate(0);
            uint ethAmount = tokenAmount.mul(10**18).mul(rate).div(10**36);
            
            _burn(_msgSender(), tokenAmount);

            sendValue(_msgSender(), ethAmount);
            
            emit Sell(_msgSender(), tokenAmount, rate, ethAmount);

        } else {
            _transfer(_msgSender(), recipient, tokenAmount);
        }
        return true;
    }
    
    
    function mintRefTokens(address referrer, address founder, uint32 id) external calledByDex payable returns (bool) {
        
            (uint totalTokenAmount, uint rate) = tokenAmountForEther(msg.value);
            uint tokenAmount = totalTokenAmount.div(3);
            
            _mint(founder, tokenAmount);
            
            assert(balanceOf(founder) >= tokenAmount);
            
        if (referrer != address(this)) {
            
            _mint(referrer, tokenAmount);
            
            assert(balanceOf(referrer) >= tokenAmount);
            
            emit Reward(referrer, id, msg.value.div(3), rate, tokenAmount);
            emit TokenRateChanged(calcTokenRate(), uint64(now));
            
            return (true);
            
        } else {
            
            emit TokenRateChanged(calcTokenRate(), uint64(now));
            
            return (true);
        }
    }
    
    
    function mintForUnreachableAddress(address userAddress, uint32 donationTurn) external payable calledByDex returns (bool){
        
        (uint tokenAmount, uint rate) = tokenAmountForEther(msg.value);
        
        _mint(userAddress, tokenAmount);
        assert(balanceOf(userAddress) >= tokenAmount);
        
        emit UnreachableAdressTokensMinted(userAddress, donationTurn, msg.value, tokenAmount, rate);

        return true;
    }
    
    
    function tokenAmountForEther(uint sum) private view returns (uint, uint) {
        uint rate = _tokenRate(sum);
        uint result = sum.mul(10**18).div(rate);
        return (result, rate);
    }
    

    function _tokenRate(uint sum) private view returns (uint) {
        
        uint ttlspl = _totalSupply;
        uint oldContractBalance = address(this).balance.sub(sum);
        
        if (oldContractBalance == 0 || ttlspl == 0) {
            return 10**18;
        }
        
        return oldContractBalance.mul(10**18).div(ttlspl);
    }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        if (bys.length == 20) {
            assembly {
                addr := mload(add(bys, 20))
            }
            return addr;
        } else {
            return address(0);
        }
    }

    function calcTokenRate() public view returns (uint) {
        uint ttlspl = _totalSupply;
        uint actualContractBalance = address(this).balance;
        if (actualContractBalance == 0 || ttlspl == 0) {
            return 10**18;
        }
        return actualContractBalance.mul(10**18).div(ttlspl);
    }
    
    function returnUserData(address user) external view returns (uint256, uint256, uint256) {
        uint dextRate = calcTokenRate();
        uint dextSupply = totalSupply();
        uint dextUserBalance = balanceOf(user);
        return (dextRate, dextSupply, dextUserBalance);
    }
}
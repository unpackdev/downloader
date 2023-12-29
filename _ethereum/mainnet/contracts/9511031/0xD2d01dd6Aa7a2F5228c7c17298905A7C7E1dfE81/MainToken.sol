pragma solidity ^0.5.16;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}
}

contract Secondary {
    address payable private _primary;
    address private _primaryCandidate;

    constructor () internal {
        _primary = msg.sender;
        _primaryCandidate = address(0);
    }

    modifier onlyPrimary() {
        require(msg.sender == _primary, "Secondary: caller is not the primary account");
        _;
    }

    function primary() public view returns (address payable) {
        return _primary;
    }
    
    function acceptBeingPrimary() public {
        require(msg.sender == _primaryCandidate, "Secondary: caller is not the primary candidate account");
        require(msg.sender != address(0));
        
        _primary = toPayable(_primaryCandidate);
        _primaryCandidate = address(0);
    }

    function setPrimaryCandidate(address recipient) public onlyPrimary {
        require(recipient != _primary, "You can't make yourself Primary Candidate");
        _primaryCandidate = recipient;
    }
    
    function toPayable(address input) internal pure returns (address payable){
        return address(uint160(input));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract assetContractable is Secondary{
    mapping(address=>bool) private _assetContracts;
    
    modifier onlyAssetContracts() {
        require(_assetContracts[msg.sender], "Only Assets can call this function!");
        _;
    }
    
    function assetContracts(address input) public view returns (bool) {
        return _assetContracts[input];
    }
 
    function addAssetContracts(address input) public onlyPrimary{
        require(input != address(this), "Input was OUSD address");
        require(input != msg.sender, "Input was your address");
        require(input != address(0), "Input was zero");
        require(!assetContracts(input), "Input already an Asset Contract");
         
        _assetContracts[input] = true;
    }
    
    function removeAssetContracts(address input) public onlyPrimary{
        require(assetContracts(input), "Input not as Asset Contract");
        _assetContracts[input] = false;
    }
    
}

interface Assetcontract{
    function AssetMint(address sender, uint256 valuesent) external;
    function contractID() external view returns (string memory);
    function updateLastPrice(uint256 input) external;
    function lastPrice() external view returns (uint);
}

interface Pricer{
    function getPrice(string calldata QUERY) external payable returns (bytes32);
    function fee() external view returns (uint256);
    function updateFee() external;
    function EthandGasPriceAddress() external view returns (address);
}

interface EthandGasPricer{
    function ethPrice() external view returns (uint256);
}

contract PriceGettable is assetContractable{
    
    using SafeMath for uint256;
    
    string private contractID;
    address payable private _pricerAddress;
    uint private _feeIncrease;
    uint private _resultDecrease;
    uint internal _balanceMin;
  
    function pricerAddress() public view returns (address payable) {
        return _pricerAddress;
    }
    
    function setpricerAddress(address payable input) external onlyPrimary {
        require(input != address(this), "Input was OUSD address");
        require(!assetContracts(input), "Input was Asset address");
        require(input != msg.sender, "Input was your address");
        require(input != address(0), "Input was zero");
    
        _pricerAddress = input;
    }
    
    function updateContractID(string memory input) public onlyPrimary {
        contractID = input;
    }
    
    function getEthPrice() internal returns (bytes32) {
        return Pricer(_pricerAddress).getPrice.value(fee())(contractID);
    }
    
     function getAssetPrice(address asset) internal returns (bytes32) {
        string memory assetID = Assetcontract(asset).contractID();
        return Pricer(_pricerAddress).getPrice.value(fee())(assetID);
    }
    
    modifier onlyPricer() {
        require(msg.sender == _pricerAddress, "Only Pricer contract can call this function!");
        _;
    }
    
    function fee() internal view returns (uint256) {
        return Pricer(_pricerAddress).fee();
    }
    
    function updateFee() internal {   
        Pricer(_pricerAddress).updateFee(); 
    }
    
    function ethPrice() internal view returns (uint256){
       address EthandGasPriceAddress = Pricer(_pricerAddress).EthandGasPriceAddress();
       return EthandGasPricer(EthandGasPriceAddress).ethPrice();
    }
    
    function lastPrice() public view returns (uint){
        return ethPrice();
    }

    function feeIncrease(uint input) public view returns (uint256) {
       return _feeIncrease.add(100).mul(input).div(100);
    }
    
    function setFeeIncrease(uint input) public onlyPrimary{
        _feeIncrease = input;
    }
    
    function resultDecrease(uint input) public view returns (uint256) {
       return input.sub(input.mul(_resultDecrease).div(10000));
    }
    
    function setResultDecrease(uint input) public onlyPrimary{
        _resultDecrease = input;
    }
    
    function setBalanceMin(uint input) public onlyPrimary{
        _balanceMin = input;
    }
    
}


contract ERC20 is IERC20, PriceGettable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    uint constant internal DECIMAL = 10**18;
    
    mapping(bytes32=>customer) internal Customers;
    mapping(uint=>uint) private withdrawPerBlock;
    
    enum IdType { gettingAsset, gettingUSDfromAsset, gettingUSDfromEth, gettingEth}
    
    struct customer { 
        address sender;
        uint256 valuesent;
        address Assetcontract;
        IdType mytype;
        uint feeEth;
    }
    
    uint256 private withdrawThreshold = 1;
    
    function updateWithdrawThreshold(uint256 _withdrawThreshold) public onlyPrimary {
        withdrawThreshold = _withdrawThreshold;
    }
    
    //Max you can withdraw in USD per block
    function withdrawMAX() public view returns (uint256){
        
        if(_balanceMin > address(this).balance.mul(ethPrice())/10**36){return 0;}
        uint usdMAX = (address(this).balance.mul(ethPrice())).div(withdrawThreshold.mul(DECIMAL));
      
        if(withdrawPerBlock[block.number] < usdMAX){
            return usdMAX.sub(withdrawPerBlock[block.number]);
        }else{
            return 0;
        }
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        if(recipient == address(this)){
            require(amount <= withdrawMAX(), "Amount sent is too big");
            withdrawPerBlock[block.number] = withdrawPerBlock[block.number].add(amount);
            
            updateFee();
            uint USDFee = (fee().mul(ethPrice())).div(DECIMAL);
            require(amount > feeIncrease(USDFee), "Amount sent is too small");
            
            _burn(sender,amount);
            bytes32 customerId = getEthPrice();
            Customers[customerId] = customer(sender, amount, sender, IdType.gettingEth, feeIncrease(fee()));
            
        }else if(assetContracts(recipient)){
            
           updateFee();
           uint USDFee = (fee().mul(ethPrice())).div(DECIMAL);
           require(amount > feeIncrease(USDFee), "Amount sent is too small");
           
           _burn(sender,amount);
           bytes32 CustomerId = getAssetPrice(recipient);
           Customers[CustomerId] = customer(sender, amount, recipient, IdType.gettingAsset, feeIncrease(fee()) );
            
        }else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount,address sender ) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(sender, account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(value);
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
   
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

interface token {
    function balanceOf(address input) external returns (uint256);
    function transfer(address input, uint amount) external;
}

contract MainToken is ERC20, ERC20Detailed{

    constructor () public ERC20Detailed("Onyx USD", "OUSD", 18){
        _mint(primary(),10**18, address(this));
    }
    
    function () external payable {
        getTokens(msg.sender);
    }
    
    function getTokens(address sendTo) public payable {
        updateFee();
        bytes32 customerId = getEthPrice();
        uint amount = msg.value.sub(fee());
        Customers[customerId] = customer(sendTo, amount, sendTo, IdType.gettingUSDfromEth, 0);
    }
    
    function sendFunds() external payable {}
    
    function USDtrade(address sender, uint assetAmount) public onlyAssetContracts{
       bytes32 customerId = getAssetPrice(msg.sender);
       Customers[customerId] = customer(sender, assetAmount, msg.sender,IdType.gettingUSDfromAsset, feeIncrease(fee())  );
    }
    
    function priceUpdated(uint result, bytes32 customerId, bool marketOpen) public onlyPricer {
       uint feeEth       = Customers[customerId].feeEth;
       address sender    = Customers[customerId].sender;
       uint256 valuesent = Customers[customerId].valuesent;
       address AC        = Customers[customerId].Assetcontract;
       IdType mytype     = Customers[customerId].mytype;
       
       require(sender != address(0), "Sender address was zero");
       require(AC != address(0), "Asset contract address was zero");
       require(msg.sender != address(0));
      
       if(mytype == IdType.gettingUSDfromAsset){

            if(marketOpen){
                
                Assetcontract(AC).updateLastPrice(result);
                
                uint amount = (valuesent.mul(result)).sub(feeEth.mul(ethPrice())).div(DECIMAL);
                _mint(sender, amount , AC);
                
            }else{
                uint assetFee = fee().mul(ethPrice()).div(Assetcontract(AC).lastPrice());
                Assetcontract(AC).AssetMint(sender,valuesent.sub(assetFee)); 
            }

        }else if(mytype == IdType.gettingAsset){

            if(marketOpen){

               Assetcontract(AC).updateLastPrice(result);
               
               uint amount = valuesent.mul(DECIMAL).sub(feeEth.mul(ethPrice())).div(result);
               Assetcontract(AC).AssetMint(sender, amount);

            }else{
                uint usdfee = feeEth.mul(ethPrice()).div(DECIMAL);
                _mint(sender, valuesent.sub(usdfee), AC);
            }
            
        }else if(mytype == IdType.gettingUSDfromEth){
            
            if(marketOpen){
            
                uint256 amount = (valuesent.mul(result)).div(DECIMAL);
                _mint(sender, amount ,address(this));
                
            }else{
                toPayable(sender).transfer(valuesent);
            }

        }else if(mytype == IdType.gettingEth){
            
            if(marketOpen){
                
                uint256 amount = valuesent.mul(DECIMAL).div(result).sub(feeEth);
                toPayable(sender).transfer( resultDecrease(amount) );
                
            }else{
                
                uint usdfee = feeEth.mul(ethPrice()).div(DECIMAL);
                _mint(sender, valuesent.sub(usdfee), address(this));
            }
           
        }
    
       delete Customers[customerId];
  
    }
    
    function USDMint(address to, uint256 valuesent) public onlyPrimary{
        _mint(to,valuesent, address(this));
    }
 
    function USDBurn(address to, uint256 valuesent) public onlyPrimary {
        _burn(to,valuesent);
        emit Transfer(to, address(this), valuesent);
    }

    function getStuckTokens(address _tokenAddress) public {
        token(_tokenAddress).transfer(primary(), token(_tokenAddress).balanceOf(address(this)));
    }
   
    function withdrawEth(uint256 amount) public onlyPrimary {
        primary().transfer(amount);
    } 
}
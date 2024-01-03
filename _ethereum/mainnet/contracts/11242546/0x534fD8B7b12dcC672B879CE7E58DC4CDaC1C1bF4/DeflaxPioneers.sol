pragma solidity 0.4.18;


//Library
library SafeMath {

    //Functions
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } 
        uint256 c = a * b; 
        assert(c / a == b); 
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; 
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
}

contract RespectingBitcoin {
    using SafeMath for uint256;
    
    //Variables

    uint8 public decimals;
    
    address public owner;
    
    address public deflaxPioneers;
    
    uint256 public supplyCap;
    uint256 public totalSupply;
    
    bool private mintable = true;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    //Events

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Mintable(address indexed from, bool enabled);
    event OwnerChanged(address newOwner);
    event ContractChanged(address indexed from, address newContract);

    //Modifiers

    modifier oO(){
        require(msg.sender == owner);
        _;
    }
    
    modifier oOOrContract(){
        require(msg.sender == owner || msg.sender == deflaxPioneers); 
        _;
    }
    
    modifier onlyMintable() {
        require(mintable); 
        _;
    }
    
    //Constructor
    
    function RespectingBitcoin(uint256 _supplyCap, uint8 _decimals) public {
        owner = msg.sender; 
        decimals = _decimals;
        supplyCap = _supplyCap * (10 ** uint256(decimals));
    }
    
    //Functions

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); 
        require(_value <= balances[msg.sender]); 
        
        balances[msg.sender] = balances[msg.sender].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        
        Transfer(msg.sender, _to, _value); 
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); 
        require(_value <= balances[_from]); 
        require(_value <= allowed[_from][msg.sender]); 
        
        balances[_from] = balances[_from].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
        
        Transfer(_from, _to, _value); 
        return true;
    }
   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value; 
        
        Approval(msg.sender, _spender, _value); 
        return true;
    }
   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
  
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue); 
        
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true;
    }
  
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender]; 
        
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        } 
        
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true;
    }
  
    function mint(address _to, uint256 _amount) public oOOrContract onlyMintable returns (bool) {
        require(totalSupply.add(_amount) <= supplyCap); 
        
        totalSupply = totalSupply.add(_amount); 
        balances[_to] = balances[_to].add(_amount); 
        Mint(_to, _amount); 
        
        Transfer(address(0), _to, _amount); 
        return true;
    }
  
    function burn(uint256 _value) external {
        require(_value <= balances[msg.sender]); 
        
        address burner = msg.sender; 
        balances[burner] = balances[burner].sub(_value); 
        totalSupply = totalSupply.sub(_value);
        
        Burn(msg.sender, _value);
    }
    
    function setMintable(bool _isMintable) external oO {
        mintable = _isMintable;
        
        Mintable(msg.sender, _isMintable);
    }
    
    function setOwner(address _newOwner) external oO {
        require(_newOwner != address(0)); 
        
        owner = _newOwner;
        
        OwnerChanged(_newOwner);
    }
  
    function setContract(address _newContract) external oO {
        require(_newContract != address(0)); 
        
        deflaxPioneers = _newContract; 
        
        ContractChanged(msg.sender, _newContract);
    }
}

contract DFX is RespectingBitcoin(20968750, 15) {
    
    //Token Details
    
    string public constant name = "DEFLAx";
    string public constant symbol = "DFX";
}

contract bDFP is RespectingBitcoin(3355, 8) {
    
    //Token Details
    
    string public constant name = "DEFLAxP";
    string public constant symbol = "bDFP";
}

contract DeflaxPioneers {
    using SafeMath for uint256;
    
    //Variables

    DFX public dfx;
    bDFP public bdfp;
    
    string public constant NAME = "DEFLAx PIONEERS";
    
    address public wallet;
    address public owner;
    
    uint8 public plot;
    
    uint256 public eta;
    
    uint24[3] public plotValue = [16775000,1000,4192750];

    uint256 public funds;
    
    uint128 internal constant WAD = 10 ** 18;

    mapping (uint8 => uint256) public plotTotal;
    mapping (uint8 => mapping (address => uint256)) public contribution;
    mapping (uint8 => mapping (address => bool)) public claimed;
    
    //Events
    
    event OwnerChanged(address newOwner);
    event WalletChanged(address newWallet);
    
    event FundsCollected(address indexed to, uint256 amount);
    event FundsForwarded(address indexed to, uint256 amount);
    
    event PioneerContribution(address indexed to, uint256 amount);
    event PatronContribution(address indexed to, uint256 amount);
    event ExcessTransferred(address indexed to, uint256 amount);
    
    event Donated(address indexed from, uint256 DFX, uint256 bDFP);
    event Claimed(address indexed to, uint256 amount);
    
    //Modifiers
    
    modifier oO() {
        require(msg.sender == owner); 
        _;
    }
    
    //Constructor
    
    function DeflaxPioneers(address _baseToken, address _bonusToken) public {
        dfx = DFX(_baseToken); 
        bdfp = bDFP(_bonusToken); 
        owner = msg.sender;
    }
    
    //Functions

    function cast(uint256 x) private pure returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
    
    function wdiv(uint128 x, uint128 y) private pure returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }
    
    function wmul(uint128 x, uint128 y) private pure returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
   
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0)); 
        require(msg.value != 0); 
        
        if (plot == 0) {
            pioneer(_beneficiary);
        } else {
            patron(_beneficiary);
        }
    }
    
    function pioneer(address _beneficiary) internal {
        
        uint256 bonusRate = 2;
        uint256 baseRate = 10000;
        
        uint256 excess;
        uint256 participation = msg.value; 
        
        uint256 maxEther = 1677.5 ether;

        if (plotTotal[0] + participation > maxEther) {
            excess = participation.sub(maxEther.sub(plotTotal[0])); 
            participation = participation.sub(excess); 
            plot++; 
            eta = now.add(24 hours);
        } 
        
        funds = funds.add(participation); 
        plotTotal[0] = plotTotal[0].add(participation); 
        
        uint256 bonus = participation.div(10 ** 10).mul(bonusRate); 
        uint256 base = participation.div(10 ** 3).mul(baseRate);
        
        if (excess > 0) {
            excessTransfer(_beneficiary, excess);
        } 
        else forwardFunds(); 
        
        bdfp.mint(_beneficiary, bonus); 
        dfx.mint(_beneficiary, base);
        
        PioneerContribution(_beneficiary, participation);
    }
    
    function excessTransfer(address _beneficiary, uint256 _amount) internal {
        uint256 participation = _amount;
        
        funds = funds.add(participation);
        plotTotal[plot] = plotTotal[plot].add(participation);
        contribution[plot][_beneficiary] = contribution[plot][_beneficiary].add(participation); 
        
        ExcessTransferred(_beneficiary, _amount);
    }
    
    function patron(address _beneficiary) internal {
        if (now > eta) {
            plot++; 
            eta = now.add(24 hours);
        } 
        
        uint256 participation = msg.value; 
        
        funds = funds.add(participation); 
        plotTotal[plot] = plotTotal[plot].add(participation); 
        contribution[plot][_beneficiary] = contribution[plot][_beneficiary].add(participation); 
        
        forwardFunds(); 
        
        PatronContribution(_beneficiary, participation);
    }
    
    function donate(uint256 _amount) public {
        require(plot >= 0);
        require(_amount > 0);
        require(bdfp.totalSupply() < bdfp.supplyCap());
        
        uint256 donation = _amount;
        uint256 donationConversion = donation.div(10**14) ;
        uint256 donationRate = 20000;
        
        uint256 reward = donationConversion.div(donationRate).mul(10**7);
        uint256 excess;
        
        if (bdfp.totalSupply() + reward > bdfp.supplyCap()) {
            excess = reward.sub(bdfp.supplyCap()); 
            donation = donation.sub(excess); 
        }
        require(dfx.transferFrom(msg.sender, address(this), donation));
        bdfp.mint(msg.sender, reward);
        
        Donated(msg.sender, donation, reward);
    }
    
    function donations() public view returns (uint) {
        return (dfx.balanceOf(address(this)));
    }
    
    function claim(uint8 _day, address _beneficiary) public {
        assert(plot > _day); 
        
        if (claimed[_day][_beneficiary] || plotTotal[_day] == 0) {
            return;
        } 
        var dailyTotal = cast(plotTotal[_day]); 
        var userTotal = cast(contribution[_day][_beneficiary]); 
        var price = wdiv(cast(uint256(plotValue[_day]) * (10 ** uint256(15))), dailyTotal); 
        var reward = wmul(price, userTotal); 
        
        claimed[_day][_beneficiary] = true; 
        dfx.mint(_beneficiary, reward);
        
        Claimed(_beneficiary, reward);
    }
    
    function claimEverything(address _beneficiary) public {
        for (uint8 i = 1; i < plot; i++) {
            claim(i, _beneficiary);
        }
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
        
        FundsForwarded(wallet, msg.value);
    }
    
    function setOwner(address _newOwner) external oO {
        require(_newOwner != address(0)); 
        owner = _newOwner;
        
        OwnerChanged(_newOwner);
    }
    
    function setWallet(address _newWallet) external oO {
        require(_newWallet != address(0)); 
        wallet = _newWallet;
        
        WalletChanged(_newWallet);
    }
    
    function collectFunds() external oO {
        wallet.transfer(this.balance);
        
        FundsCollected(wallet, this.balance);
    }
}

contract Distributor {
    
    //Variables
    
    DeflaxPioneers public deflaxPioneers;
    
    //Constructor
    
    function Distributor(DeflaxPioneers _setAddress) public {
        deflaxPioneers = _setAddress;
    }
    
    //Functions
    
    function () external payable {
        deflaxPioneers.claimEverything(msg.sender); 
        
        if(msg.value > 0) 
        msg.sender.transfer(msg.value);
    }
}
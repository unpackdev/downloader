/////////NO Presale
/////////Official website: https://gswap.finance
/////////Circulating supply: 100 GSwap
/////////Max Supply: 300 GSwap
/////////The first Liquidity is Locked. check the unicrypt
//...........................................................................................
//.....GGGGGGG..........SSSSSSS....... WWW..WWWWW...WWW ........AAAAA..........PPPPPPPPP....
//...GGGGGGGGGG........SSSSSSSSS....... WWW..WWWWW..WWWW.........AAAAA..........PPPPPPPPPP...
//..GGGGGGGGGGGG.......SSSSSSSSSS...... WWW..WWWWWW.WWWW........AAAAAA..........PPPPPPPPPPP..
//..GGGGG..GGGGG...... SSSS..SSSS...... WWW.WWWWWWW.WWWW........AAAAAAA.........PPPP...PPPP..
//.GGGGG....GGG....... SSSS............ WWW.WWWWWWW.WWWW.......AAAAAAAA.........PPPP...PPPP..
//.GGGG................SSSSSSS..........WWWWWWWWWWW.WWW........AAAAAAAA.........PPPPPPPPPPP..
//.GGGG..GGGGGGGG.......SSSSSSSSS.......WWWWWWW.WWWWWWW........AAAA.AAAA........PPPPPPPPPP...
//.GGGG..GGGGGGGG.........SSSSSSS.......WWWWWWW.WWWWWWW.......AAAAAAAAAA........PPPPPPPPP....
//.GGGGG.GGGGGGGG............SSSSS......WWWWWWW.WWWWWWW.......AAAAAAAAAAA.......PPPP.........
//..GGGGG....GGGG..... SSS....SSSS......WWWWWWW.WWWWWWW.......AAAAAAAAAAA.......PPPP.........
//..GGGGGGGGGGGG...... SSSSSSSSSSS.......WWWWW...WWWWW.......AAAA....AAAA.......PPPP.........
//...GGGGGGGGGG........SSSSSSSSSS........WWWWW...WWWWW.......AAAA.....AAAA......PPPP.........
//.....GGGGGGG..........SSSSSSSS.........WWWWW...WWWWW...... AAAA.....AAAA......PPPP.........
//...........................................................................................

pragma solidity ^0.5.12;
contract ERC20Interface {
    
    /// total amount of tokens
    uint256 public totalSupply;
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Claim(address indexed _gamer,uint256 _value);
    event plant(address indexed _gamer);
}

interface IUniswapV2Pair {
    function sync() external;

}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
contract GSwap is ERC20Interface {
    using SafeMath for uint;
    using Address for address;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    

    
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name;                   
    uint8 public decimals;                
    string public symbol;     
    address private _owner;
    uint private LastPlantTime;
    uint private PlantStep=12*3600;
    address PairAddress;   //the uniswap pair address
    
    uint256 private MaxSupply=300*10**18;
    
    uint8 private TreesAge=30;
    uint8 private MaxTrees=16;
    uint private TreePrice=10**18;
    uint private Ctransactions=400;
    uint8 private LiqPercentage=10;
    uint private FruitReward=10**16;
    uint256 private ClaimCommand=123*10**14;
    uint256 private plantCommand=12*10**15;

    uint256 Transactions=0;
    
    struct tree{
        address owner;
        uint planttime;
        uint LastClaimCount;
    }
    
    tree[] Farms;
    constructor() public {
        decimals = 18;                   
        totalSupply = 100*10**uint256(decimals);
        balances[msg.sender] = 70*10**uint256(decimals);
        SetDevBalances();
        LastPlantTime=block.timestamp - 12*3600;
        _owner = msg.sender;
        name = "GSwap.finance";                                                              
        symbol = "GSwap";                               
    }
   function SetGameParams(uint8 _TreesAge,uint _Ctransactions,uint8 _LiqPercentage,uint _FruitReward,uint _PlantStep,uint8 _MaxTrees,uint _TreePrice) external onlyOwner {
       TreesAge=_TreesAge;
       Ctransactions=_Ctransactions;
       LiqPercentage=_LiqPercentage;
       FruitReward=_FruitReward;
       PlantStep=_PlantStep;
       MaxTrees=_MaxTrees;
       TreePrice=_TreePrice;
   }
   function SetGameCommands(uint256 _ClaimCommand,uint256 _plantCommand) external onlyOwner
   {
       ClaimCommand=_ClaimCommand;
       plantCommand=_plantCommand;
   }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    function CheckLiquidityPercentage(address _adr,uint8 _LiqPercent) public view returns(bool)
    {
        uint LQPercent=ERC20Interface(PairAddress).balanceOf(_adr)*100/ERC20Interface(PairAddress).totalSupply();
        if(LQPercent >= _LiqPercent){
            return true;
        }else{
            return false;
        }
    }
    function CheckBeforeClaim(address _gamer) internal
    {
       for(uint i=0;i<Farms.length;i++){
               if(!CheckLiquidityPercentage(Farms[i].owner,LiqPercentage)){ 
                    if(Farms[i].planttime+TreesAge*24*3600<block.timestamp){
                        Farms[i].owner=_gamer;
                        Farms[i].planttime=block.timestamp;
                        Farms[i].LastClaimCount=Transactions;
                    }
               }
        }
    }
    function ClaimFruits(address _gamer) internal 
    {
        uint8 _trees;
        uint _Fruits;
        (_trees,_Fruits)=GetFarmData(_gamer);
        if(_Fruits>0){
            uint Rewards=_Fruits*FruitReward;
            if(totalSupply<MaxSupply-Rewards){
                for(uint i=0;i<Farms.length;i++){
                    if(Farms[i].owner==_gamer) {
                       Farms[i].LastClaimCount=Transactions;
                    }
                }
                balances[_gamer]=balances[_gamer].add(Rewards);
                totalSupply=totalSupply.add(Rewards);
                emit Transfer(address(0),_gamer,Rewards);
                emit Claim(_gamer,Rewards);
            }
        }
    }
    function BurnOnpair(uint _val) external onlyOwner{
        require(_val<balances[PairAddress]);
        balances[PairAddress]=balances[PairAddress].sub(_val);
        totalSupply=totalSupply.sub(_val);
        IUniswapV2Pair(PairAddress).sync();
        emit Transfer(PairAddress,address(0),_val);
        
    }
    function Burn(uint _val) external{
        balances[msg.sender]=balances[msg.sender].sub(_val);
        totalSupply=totalSupply.sub(_val);
        emit Transfer(msg.sender,address(0),_val);
    }

    function Plant(address _gamer,bool isBuy) internal{
        uint8 _trees;
        uint _fruits;
        (_trees,_fruits)=GetFarmData(_gamer);
        if(_trees <= MaxTrees){
            if(!isBuy){
                if(CheckLiquidityPercentage(_gamer,LiqPercentage)){
                    if(_trees<1){
                        Farms.push(tree(_gamer,block.timestamp-TreesAge*24*3600,Transactions));
                        emit plant(_gamer);
                    }
                }else{
                    if(block.timestamp - LastPlantTime > PlantStep){
                        LastPlantTime=block.timestamp;
                        Farms.push(tree(_gamer,block.timestamp,Transactions));
                        emit plant(_gamer);
                    }
                }
            }else{
                 Farms.push(tree(_gamer,block.timestamp,Transactions));
                 emit plant(_gamer);
            }
        }
    }
    function BuyTree() external{
        require(balances[msg.sender]>TreePrice,"You don't have enough gswap to buy a tree.");
        balances[msg.sender]=balances[msg.sender].sub(TreePrice);
        totalSupply=totalSupply.sub(TreePrice);
        Plant(msg.sender,true);
        emit Transfer(msg.sender,address(0),TreePrice);
    }
    function SetPairAddress(address _pair) external onlyOwner{
        PairAddress=_pair;
    }
    
    function GetFarmData(address _gamer) public view returns(uint8,uint){
        uint Fruits=0;
        uint8 trees=0;
        for(uint i=0;i<Farms.length;i++){
            if(Farms[i].owner==_gamer) {
                uint Fcount=(Transactions.sub(Farms[i].LastClaimCount))/Ctransactions;
                Fruits+=Fcount;
                trees++;
            }
        }
        return(trees,Fruits);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    
    //10 Percent of max supply for the devs.
    function SetDevBalances() internal{
        balances[0x903Ac7e443220C3c5773aD827cAE47CA265462F5] = 10*10**uint256(decimals);
        balances[0x7152C26072645b30c89B8D2fff8745f6f6602C1d] = 10*10**uint256(decimals);
        balances[0x847713dc4FdAbA0C3CcB525903819f972EE8EA48] = 10*10**uint256(decimals);

    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] >= _value);
        balances[msg.sender] =balances[msg.sender].sub(_value);
        balances[_to] =balances[_to].add(_value);
        AfterTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] =balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] =allowed[_from][msg.sender].sub(_value);
        }
        AfterTransfer(_from, _to, _value);
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function AfterTransfer(address _from, address _to, uint256 _value) private {
        if(_from == PairAddress || _to == PairAddress){
            if(_from == PairAddress){
                if(!_to.isContract()){
                    CheckBeforeClaim(_to);
                    
                    if(_value==ClaimCommand){
                        ClaimFruits(_to);
                    }
                    if(_value==plantCommand){
                        Plant(_to,false);
                    }
                }
            }
            Transactions++;
        }
    }
    function balanceOf(address _user) public view returns (uint256 balance) {
        return balances[_user];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _user, address _spender) public view returns (uint256 remaining) {
        return allowed[_user][_spender];
    }

}
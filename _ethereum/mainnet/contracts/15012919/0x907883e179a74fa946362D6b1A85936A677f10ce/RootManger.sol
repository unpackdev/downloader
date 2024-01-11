pragma solidity ^0.8.0;
import "./console.sol";
import "./ERC20Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IRootManger.sol";
import "./IDepositContract.sol";
import "./IinComeContract.sol";
import "./IRelayerRegistry.sol";

contract RootManger is OwnableUpgradeable,ERC20Upgradeable,IRootManger{

    address public  override exitQueueContract;
    address  public override depositContract;
    address  public override inComeContract;
    address public  override operator;
    address public  profitRecord;
    uint256 public  MAX_RELAYER_COUNTER ;
    mapping(uint256 => address) public override _relayers;

    address immutable public TORN_CONTRACT;
    address immutable public TORN_RELAYER_REGISTRY;

    function setOperator(address __operator)  external  onlyOwner
    {
        operator = __operator;
    }

    /** ---------address immutable- constructor ---------- **/
    constructor(
        address _torn_relayer_registry,
        address _tornContract
    ) {
        TORN_CONTRACT = _tornContract;
        TORN_RELAYER_REGISTRY = _torn_relayer_registry;
    }

    /** ---------- init ---------- **/
    function __RootManger_init(address _inComeContract,address _depositContract,address _exitQueueContract,address _profitRecord) public initializer {
        __RootManger_init_unchained(_inComeContract,_depositContract,_exitQueueContract,_profitRecord);
        __ERC20_init("relayer_dao", "relayer_dao_token");
        __Ownable_init();
    }

    function __RootManger_init_unchained(address _inComeContract,address _depositContract,address _exitQueueContract,address _profitRecord) public onlyInitializing {
        inComeContract=_inComeContract;
        depositContract = _depositContract;
        exitQueueContract = _exitQueueContract;
        profitRecord = _profitRecord;
    }
    // save gas
    function addRelayer(address __relayer,uint256 index)  override external  onlyOwner
    {
         require(index <= MAX_RELAYER_COUNTER,"too large index");

        uint256 counter = MAX_RELAYER_COUNTER; //save gas
        for(uint256 i = 0 ;i < counter ;i++){
            require(_relayers[i] != __relayer,"repeated");
        }

         if(index == MAX_RELAYER_COUNTER){
             MAX_RELAYER_COUNTER += 1;
         }

         require(_relayers[index] == address(0),"index err");

         _relayers[index] = __relayer;
    }

    function removeRelayer(uint256 index)  override external  onlyOwner
    {
        require(index < MAX_RELAYER_COUNTER,"too large index");

        // save gas
        if(index+1 == MAX_RELAYER_COUNTER){
            MAX_RELAYER_COUNTER -= 1;
        }

        require(_relayers[index] != address(0),"index err");
        delete _relayers[index];
    }

    modifier onlyDepositContract() {
        require(msg.sender == depositContract, "Caller is not depositContract");
        _;
    }

    modifier onlyInComeContract() {
        require(msg.sender == inComeContract, "Caller is not inComeContract");
        _;
    }

    function totalRelayerTorn() override external view returns (uint256 ret){
        ret = 0;
        address relay ;
        uint256 counter = MAX_RELAYER_COUNTER; //save gas
        for(uint256 i = 0 ;i < counter ;i++){
             relay = _relayers[i];
            if(relay!= address(0)){
                ret += IRelayerRegistry(TORN_RELAYER_REGISTRY).getRelayerBalance(relay);
            }
        }
    }

    //  Deposit torn + eInCome torn + totalRelayerTorn
    function totalTorn() override public view returns (uint256 ret){
        ret =  IDepositContract(depositContract).totalBalanceOfTorn();
        ret += ERC20Upgradeable(TORN_CONTRACT).balanceOf(inComeContract);
        ret+= this.totalRelayerTorn();
    }

    function safeDeposit(address account,uint256 value) override  onlyDepositContract external returns (uint256) {
        uint256 total = totalSupply();
        uint256 to_mint;
        if(total == uint256(0)){
            to_mint = 10*10**decimals();
        }
        else{ // valve / ( totalTorn() + value) = to_mint/(totalSupply()+ to_mint)
            to_mint =  total * value / this.totalTorn();
        }
        _mint(account,to_mint);
        return to_mint;
    }

    function safeWithdraw(address account,uint256 to_burn) override onlyDepositContract public {
        _burn(account,to_burn);
    }

    event Income(address from, uint vaule);
    function addIncome(uint256 amount) override onlyInComeContract external {
        emit Income(msg.sender,amount);
    }

    function balanceOfTorn(address account) override public view returns (uint256){
       return valueForTorn(this.balanceOf(account));
    }

    function valueForTorn(uint256 value_token) override  public view returns (uint256){
        return value_token*(this.totalTorn())/(totalSupply());
    }

    // overwite this function inorder to prevent user transfer root token
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(owner == exitQueueContract || to == exitQueueContract,"err transfer");
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // only approve to exitQueueContract to save gas
        require(_msgSender() == exitQueueContract ,"err transferFrom");
        //_spendAllowance(from, spender, amount); to save gas
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool ret) {
        ret =  false;
        require(false ,"err approve");
    }



}

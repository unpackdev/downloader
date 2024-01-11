// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IRelayerRegistry.sol";
import "./Deposit.sol";

/**
 * @title Database for relayer dao
 * @notice this is a modified erc20 token because of saving gas.
 *         1. removed approve
 *         2. only able to transfer to or from exitQueueContract
 *         3. only transferFrom by exitQueueContract without approve
 * @notice  the token is the voucher of the deposit
 *          token/totalSupply  is the percentage of the user
 */
contract RootDB is OwnableUpgradeable, ERC20Upgradeable {
    /// the address of  exitQueue contract
    address public   exitQueueContract;
    /// the address of  deposit contract
    address public   depositContract;
    /// the address of  inCome contract
    address public   inComeContract;
    /// the address of  operator set by owner
    address public   operator;
    /// the address of  profitRecord contract
    address public   profitRecordContract;
    /// the max counter of  relayers
    uint256 public   MAX_RELAYER_COUNTER;
    /// mapping index to relayers address
    mapping(uint256 => address) public  mRelayers;

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn relayer registry
    address immutable public TORN_RELAYER_REGISTRY;



    /**
     * @notice Called by the Owner to set operator
     * @param _operator The address of the new operator
     */
    function setOperator(address _operator) external onlyOwner
    {
        operator = _operator;
    }

    /**
     * @param _torn_relayer_registry :the address of  torn relayer registry
     * @param _torn_contract : the address of  torn token contract
     */
    constructor(
        address _torn_relayer_registry,
        address _torn_contract
    ) {
        TORN_CONTRACT = _torn_contract;
        TORN_RELAYER_REGISTRY = _torn_relayer_registry;
    }


    /**
      * @notice Function used to __RootDB_init
      * @param _in_come_contract address
      * @param _deposit_contract address
      * @param _exit_queue_contract address
      * @param _profit_record_contract address
      **/
    function __RootDB_init(address _in_come_contract, address _deposit_contract, address _exit_queue_contract, address _profit_record_contract) public initializer {
        __RootDB_init_unchained(_in_come_contract, _deposit_contract, _exit_queue_contract, _profit_record_contract);
        __ERC20_init("relayer_dao", "relayer_dao_token");
        __Ownable_init();
    }

    function __RootDB_init_unchained(address _in_come_contract, address _deposit_contract, address _exit_queue_contract, address _profit_record_contract) public onlyInitializing {
        inComeContract = _in_come_contract;
        depositContract = _deposit_contract;
        exitQueueContract = _exit_queue_contract;
        profitRecordContract = _profit_record_contract;
    }


    /**
      * @notice addRelayer used to add relayers to the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
      * @param _relayer address of relayers
                address can only added once
      * @param  _index  of relayer
   **/
    function addRelayer(address _relayer, uint256 _index) external onlyOwner
    {
        require(_index <= MAX_RELAYER_COUNTER, "too large index");

        uint256 counter = MAX_RELAYER_COUNTER;

        for (uint256 i = 0; i < counter; i++) {
            require(mRelayers[i] != _relayer, "repeated");
        }

        if (_index == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER += 1;
        }
        require(mRelayers[_index] == address(0), "index err");
        mRelayers[_index] = _relayer;
    }


    /**
      * @notice removeRelayer used to remove relayers form  the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
             if remove the last one it will dec MAX_RELAYER_COUNTER
      * @param  _index  of relayer
    **/
    function removeRelayer(uint256 _index) external onlyOwner
    {
        require(_index < MAX_RELAYER_COUNTER, "too large index");

        // save gas
        if (_index + 1 == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER -= 1;
        }

        require(mRelayers[_index] != address(0), "index err");
        delete mRelayers[_index];
    }

    modifier onlyDepositContract() {
        require(msg.sender == depositContract, "Caller is not depositContract");
        _;
    }

    /**
      * @notice totalRelayerTorn used to calc all the relayers unburned torn
      * @return torn_qty The number of total Relayer Torn
    **/
    function totalRelayerTorn() external view returns (uint256 torn_qty){
        torn_qty = 0;
        address relay;
        uint256 counter = MAX_RELAYER_COUNTER;
        //save gas
        for (uint256 i = 0; i < counter; i++) {
            relay = mRelayers[i];
            if (relay != address(0)) {
                torn_qty += IRelayerRegistry(TORN_RELAYER_REGISTRY).getRelayerBalance(relay);
            }
        }
    }

    /**
    * @notice totalTorn used to calc all the torn in relayer dao
    * @dev it is sum of (Deposit contract torn + InCome contract torn + totalRelayersTorn)
    * @return torn_qty The number of total Torn
   **/
    function totalTorn() public view returns (uint256 torn_qty){
        torn_qty = Deposit(depositContract).totalBalanceOfTorn();
        torn_qty += ERC20Upgradeable(TORN_CONTRACT).balanceOf(inComeContract);
        torn_qty += this.totalRelayerTorn();
    }

    /**
     * @notice safeMint used to calc token and mint to account
             this  is called when user deposit torn to the system
     * @dev  algorithm  :   qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            if is the first user to mint mint is 10
     * @param  _account the user's address
     * @param  _torn_qty is  the user's torn to deposit
     * @return the number token to mint
    **/
    function safeMint(address _account, uint256 _torn_qty) onlyDepositContract external returns (uint256) {
        uint256 total = totalSupply();
        uint256 to_mint;
        if (total == uint256(0)) {
            to_mint = 10 * 10 ** decimals();
        }
        else {// qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            to_mint = total * _torn_qty / this.totalTorn();
        }
        _mint(_account, to_mint);
        return to_mint;
    }

    /**
    * @notice safeBurn used to _burn voucher token withdraw form the system
             this  is called when user deposit torn to the system
    * @param  _account the user's address
    * @param  _token_qty is the  the user's voucher to withdraw
   **/
    function safeBurn(address _account, uint256 _token_qty) onlyDepositContract external {
        _burn(_account, _token_qty);
    }


    function balanceOfTorn(address _account) public view returns (uint256){
        return valueForTorn(this.balanceOf(_account));
    }

    function valueForTorn(uint256 _token_qty) public view returns (uint256){
        return _token_qty * (this.totalTorn()) / (totalSupply());
    }

    /**
      @dev See {IERC20-transfer}.
     *   overwite this function inorder to prevent user transfer voucher token
     *   Requirements:
     *   - `to` cannot be the zero address.
     *   - the caller must have a balance of at least `amount`.
     * @notice IMPORTANT: one of the former or target must been exitQueueContract
    **/
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(owner == exitQueueContract || to == exitQueueContract, "err transfer");
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @dev See {IERC20-transferFrom}.
     * Requirements:
     *
     * @notice IMPORTANT: inorder to saving gas we removed approve
       and the spender is fixed to exitQueueContract
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // only approve to exitQueueContract to save gas
        require(_msgSender() == exitQueueContract, "err transferFrom");
        //_spendAllowance(from, spender, amount); to save gas
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice IMPORTANT: inorder to saving gas we removed approve
     */
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool ret) {
        ret = false;
        require(false, "err approve");
    }
}

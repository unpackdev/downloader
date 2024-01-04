pragma solidity ^0.4.24;/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}// SPDX-License-Identifier: MIT





contract TokenList is Pausable {
    bool public IsTokenFilterOn;
    uint256 public NumberOfTokens;
    mapping(address => bool) private _IsAllowed;
    mapping(uint256 => address) private _Tokens;

    constructor() public {
        NumberOfTokens = 0;
        IsTokenFilterOn = false; //true on prod
    }

    function SwapTokenFilter() public onlyOwner {
        IsTokenFilterOn = !IsTokenFilterOn;
    }

    function AddToken(address _address) public onlyOwner {
        require(!_IsAllowed[_address], "This Token in List");
        _IsAllowed[_address] = true;
        _Tokens[NumberOfTokens] = _address;
        NumberOfTokens++;
    }

    function RemoveToken(address _address) public onlyOwner {
        require(_IsAllowed[_address], "This Token not in List");
        _IsAllowed[_address] = false;
    }

    function IsValidToken(address _address) public view returns (bool) {
        return !IsTokenFilterOn || _IsAllowed[_address];
    }
}// SPDX-License-Identifier: MIT







contract ERC20Helper is TokenList {
    event TransferOut(uint256 Amount, address To, address Token);
    event TransferIn(uint256 Amount, address From, address Token);
    modifier TestAllownce(
        address _token,
        address _owner,
        uint256 _amount
    ) {
        require(
            ERC20(_token).allowance(_owner, address(this)) >= _amount,
            "no allowance"
        );
        _;
    }

    function TransferToken(
        address _Token,
        address _Reciver,
        uint256 _Amount
    ) internal {
        uint256 OldBalance = CheckBalance(_Token, address(this));
        emit TransferOut(_Amount, _Reciver, _Token);
        ERC20(_Token).transfer(_Reciver, _Amount);
        require(
            (SafeMath.add(CheckBalance(_Token, address(this)), _Amount)) == OldBalance
                ,
            "recive wrong amount of tokens"
        );
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function TransferInToken(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal TestAllownce(_Token, _Subject, _Amount) {
        require(_Amount > 0);
        uint256 OldBalance = CheckBalance(_Token, address(this));
        ERC20(_Token).transferFrom(_Subject, address(this), _Amount);
        emit TransferIn(_Amount, _Subject, _Token);
        require(
            (SafeMath.add(OldBalance, _Amount)) ==
                CheckBalance(_Token, address(this)),
            "recive wrong amount of tokens"
        );
    }
}// SPDX-License-Identifier: MIT



//True POZ Token will have this, 
interface IPOZBenefit {
    function IsPOZHolder(address _Subject) external view returns(bool);
}// SPDX-License-Identifier: MIT






contract PozBenefit is ERC20Helper {
    constructor() public {
        PozFee = 15; // *10000
        PozTimer = 1000; // *10000
        MinPoz = 80; // ^Token.decimals
        POZ_Address = address(0x0);
        POZBenefit_Address = address(0x0);
    }

    uint256 internal PozFee; // the fee for the first part of the pool
    uint256 internal PozTimer; //the timer for the first part fo the pool
    uint256 internal MinPoz; //minimum ammount ofpoz to be part of the discount
    address public POZ_Address; //The address of the POZ Token
    address public POZBenefit_Address; //the address for implementation of IPozBenefit - to get POZ benefit status from other contracts

    modifier PercentCheckOk(uint256 _percent) {
        if (_percent < 10000) _;
        else revert("Not in range");
    }
    modifier LeftIsBigger(uint256 _left, uint256 _right) {
        if (_left > _right) _;
        else revert("Not bigger");
    }

    function GetPozTimer() public view returns (uint256) {
        return PozTimer;
    }

    function SetPozTimer(uint256 _pozTimer)
        public
        onlyOwner
        PercentCheckOk(_pozTimer)
    {
        PozTimer = _pozTimer;
    }

    function GetPOZFee() public view returns (uint256) {
        return PozFee;
    }

    function GetMinPoz() public view returns (uint256) {
        return MinPoz;
    }

    function SetMinPoz(uint256 _MinPoz) public onlyOwner {
        MinPoz = _MinPoz;
    }

    function SetPOZBenefit_Address(address _POZBenefit_Address)
        public
        onlyOwner
    {
        POZBenefit_Address = _POZBenefit_Address;
    }

    function SetPozAdress(address _POZ_Address) public onlyOwner {
        POZ_Address = _POZ_Address;
    }

    function AmIPOZInvestor() public view returns (bool) {
        return IsPOZInvestor(msg.sender);
    }

    //@dev Taken from interface, To join the POZ Benefit club
    function IsPOZInvestor(address _investor) internal view returns (bool) {
        if (POZ_Address == address(0x0) && POZBenefit_Address == address(0x0)) return true; //false; // for testing stage, until got the address
        return ((POZ_Address != address(0x0) &&
            CheckBalance(POZ_Address, _investor) >= MinPoz) ||
            (POZBenefit_Address != address(0x0) &&
                IPOZBenefit(POZBenefit_Address).IsPOZHolder(_investor)));
    }
}// SPDX-License-Identifier: MIT





contract ETHHelper is PozBenefit {
    constructor() public {
        IsPayble = false;
    }

    modifier ReceivETH(uint256 msgValue, address msgSender, uint256 _MinETHInvest) {
        require(msgValue >= _MinETHInvest, "Send ETH to invest");
        emit TransferInETH(msgValue, msgSender);
        _;
    }

    //@dev not/allow contract to receive funds
    function() public payable {
        if (!IsPayble) revert();
    }

    event TransferOutETH(uint256 Amount, address To);
    event TransferInETH(uint256 Amount, address From);

    bool internal IsPayble;
 
    function GetIsPayble() public view returns (bool) {
        return IsPayble;
    }

    function SwitchIsPayble() public onlyOwner {
        IsPayble = !IsPayble;
    }

    function TransferETH(address _Reciver, uint256 _ammount) internal {
        emit TransferOutETH(_ammount, _Reciver);
        uint256 beforeBalance = address(_Reciver).balance;
        _Reciver.transfer(_ammount);
        require(
            SafeMath.add(beforeBalance, _ammount) == address(_Reciver).balance,
            "The transfer did not complite"
        );
    }
 
}// SPDX-License-Identifier: MIT





contract Manageable is ETHHelper {
    constructor() public {
        Fee = 20; // *10000
        MinDuration = 0; //need to set
        PoolPrice = 0; // Price for create a pool
        MaxDuration = 60 * 60 * 24 * 30 * 6; // half year
        MinETHInvest = 10000; // for percent calc
        MaxETHInvest = 100 * 10**18; // 100 eth per wallet
    }

    mapping(address => uint256) FeeMap;
    //@dev for percent use uint16
    uint256 internal Fee; //the fee for the pool
    uint256 internal MinDuration; //the minimum duration of a pool, in seconds
    uint256 internal MaxDuration; //the maximum duration of a pool from the creation, in seconds
    uint256 internal PoolPrice;
    uint256 internal MinETHInvest;
    uint256 internal MaxETHInvest;

    function SetMinMaxETHInvest(uint256 _MinETHInvest, uint256 _MaxETHInvest)
        public
        onlyOwner
    {
        MinETHInvest = _MinETHInvest;
        MaxETHInvest = _MaxETHInvest;
    }
    function GetMinMaxETHInvest() public view returns (uint256 _MinETHInvest, uint256 _MaxETHInvest)
    {
       return (MinETHInvest,MaxETHInvest);
    }

    function GetMinMaxDuration() public view returns (uint256, uint256) {
        return (MinDuration, MaxDuration);
    }

    function SetMinMaxDuration(uint256 _minDuration, uint256 _maxDuration)
        public
        onlyOwner
    {
        MinDuration = _minDuration;
        MaxDuration = _maxDuration;
    }

    function GetPoolPrice() public view returns (uint256) {
        return PoolPrice;
    }

    function SetPoolPrice(uint256 _PoolPrice) public onlyOwner {
        PoolPrice = _PoolPrice;
    }

    function GetFee() public view returns (uint256) {
        return Fee;
    }

    function SetFee(uint256 _fee)
        public
        onlyOwner
        PercentCheckOk(_fee)
        LeftIsBigger(_fee, PozFee)
    {
        Fee = _fee;
    }

    function SetPOZFee(uint256 _fee)
        public
        onlyOwner
        PercentCheckOk(_fee)
        LeftIsBigger(Fee, _fee)
    {
        PozFee = _fee;
    }

    function WithdrawETHFee(address _to) public onlyOwner {
        _to.transfer(address(this).balance); // keeps only fee eth on contract //To Do need to take 16% to burn!!!
    }

    function WithdrawERC20Fee(address _Token, address _to) public onlyOwner {
        uint256 temp = FeeMap[_Token];
        FeeMap[_Token] = 0;
        TransferToken(_Token, _to, temp);
    }
}// SPDX-License-Identifier: MIT





contract MainCoinManager is Manageable {
    event MainCoinAdded (address Token);
    event MainCoinRemoved (address Token);

    mapping(address => bool) public ERC20MainCoins; //when approve new erc20 main coin - it will list here

    function AddERC20Maincoin(address _token) public onlyOwner {
        emit MainCoinAdded(_token);
        ERC20MainCoins[_token] = true;
    }

    function RemoveERC20Maincoin(address _token) public onlyOwner {
        emit MainCoinRemoved(_token);
        ERC20MainCoins[_token] = false;
    }

    function IsERC20Maincoin(address _token) public view returns (bool) {
        return ERC20MainCoins[_token];
    }
}// SPDX-License-Identifier: MIT






contract Pools is MainCoinManager {
    event NewPool(address token, uint256 id);
    event FinishPool(uint256 id);
    event PoolUpdate(uint256 id);

    constructor() public {
        poolsCount = 0; //Start with 0
    }

    uint256 public poolsCount; // the ids of the pool
    mapping(uint256 => Pool) public pools; //the id of the pool with the data
    mapping(address => uint256[]) public poolsMap; //the address and all of the pools id's
    struct Pool {
        address Token; //the address of the erc20 toke for sale
        address Creator; //the project owner
        uint256 FinishTime; //Until what time the pool is active
        uint256 Rate; //for eth Wei, in token, by the decemal. the cost of 1 token
        uint256 POZRate; //the rate for the until OpenForAll, if the same as Rate , OpenForAll = StartTime .
        address Maincoin; // on adress.zero = ETH
        uint256 StartAmount; //The total amount of the tokens for sale
        bool IsLocked; // true - the investors getting the tokens after the FinishTime. false - intant deal
        uint256 Lefttokens; // the ammount of tokens left for sale
        uint256 StartTime; // the time the pool open //TODO Maybe Delete this?
        uint256 OpenForAll; // The Time that all investors can invest
        uint256 UnlockedTokens; //for locked pools
        bool TookLeftOvers; //The Creator took the left overs after the pool finished
        bool Is21DecimalRate; //If true, the rate will be rate*10^-21
    }

    function GetLastPoolId() public view returns (uint256) {
        return poolsCount;
    }
    
     //create a new pool
    function CreatePool(
        address _Token, //token to sell address
        uint256 _FinishTime, //Until what time the pool will work
        uint256 _Rate, //the rate of the trade
        uint256 _POZRate, //the rate for POZ Holders, how much each token = main coin
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        bool _IsLocked, //False = DSP or True = TLP
        address _MainCoin, // address(0x0) = ETH, address of main token
        bool _Is21Decimal, //focus the for smaller tokens.
        uint256 _Now //Start Time - can be 0 to not change current flow
    ) public whenNotPaused payable {
        require(msg.value >= PoolPrice, "Need to pay for the pool");
        require(IsValidToken(_Token), "Need Valid ERC20 Token"); //check if _Token is ERC20
        require(
            _MainCoin == address(0x0) || IsERC20Maincoin(_MainCoin),
            "Main coin not in list"
        );
        require(_FinishTime - now < MaxDuration, "Can't be that long pool");
        require(
            _Rate <= _POZRate,
            "POZ holders need to have better price (or the same)"
        );
        require(_POZRate > 0, "It will not work");
        if (_Now < now)
            _Now = now;
        require(
            SafeMath.add(now, MinDuration) <= _FinishTime,
            "Need more then MinDuration"
        ); // check if the time is OK
        TransferInToken(_Token, msg.sender, _StartAmount);
        uint256 Openforall = (_Rate == _POZRate)
            ? _Now
            : SafeMath.add(
                SafeMath.div(
                    SafeMath.mul(
                        SafeMath.sub(_FinishTime, _Now),
                        PozTimer
                    ),
                    10000
                ),
                _Now
            );
        //register the pool
        pools[poolsCount] = Pool(
            _Token,
            msg.sender,
            _FinishTime,
            _Rate,
            _POZRate,
            _MainCoin,
            _StartAmount,
            _IsLocked,
            _StartAmount,
            _Now,
            Openforall,
            0,
            false,
            _Is21Decimal
        );
        poolsMap[msg.sender].push(poolsCount);
        emit NewPool(_Token, poolsCount);
        poolsCount = SafeMath.add(poolsCount, 1); //joke - overflowfrom 0 on int256 = 1.16E77
    }
}// SPDX-License-Identifier: MIT




contract PoolsData is Pools {
    enum PoolStatus {Created, Open,PreMade , OutOfstock, Finished, Close} //the status of the pools

    function GetMyPoolsId() public view returns (uint256[]) {
        return poolsMap[msg.sender];
    }

    function IsReadyWithdrawLeftOvers(uint256 _PoolId)
        public
        view
        returns (bool)
    {
        return
            pools[_PoolId].FinishTime <= now && 
           pools[_PoolId].Lefttokens > 0 && 
            !pools[_PoolId].TookLeftOvers;
    }

    //@dev no use of revert to make sure the loop will work
    function WithdrawLeftOvers(uint256 _PoolId) public returns (bool) {
        //pool is finished + got left overs + did not took them
        if (IsReadyWithdrawLeftOvers(_PoolId)) {
            pools[_PoolId].TookLeftOvers = true;
            TransferToken(
                pools[_PoolId].Token,
                pools[_PoolId].Creator,
                pools[_PoolId].Lefttokens
            );
            return true;
        }
        return false;
    }

    //give the data of the pool, by id
    function GetPoolData(uint256 _id)
        public
        view
        returns (
            PoolStatus,
            address,
            uint256,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        require(_id < poolsCount, "Wrong Id");
        return (
            //check if sender POZ Invester?
            GetPoolStatus(_id),
            pools[_id].Token,
            pools[_id].Rate,
            pools[_id].POZRate,
            pools[_id].Maincoin, //incase of ETH will be address.zero
            pools[_id].StartAmount,
            pools[_id].Lefttokens
        );
    }

    function GetMorePoolData(uint256 _id)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            address,
            bool
        )
    {
        require(_id < poolsCount, "Wrong Id");
        return (
            pools[_id].IsLocked,
            pools[_id].StartTime,
            pools[_id].FinishTime,
            pools[_id].OpenForAll,
            pools[_id].Creator,
            pools[_id].Is21DecimalRate
        );
    }

    //calculate the status of a pool
    function GetPoolStatus(uint256 _id) public view returns (PoolStatus) {
        require(_id < poolsCount, "Wrong pool id, Can't get Status");
        //Don't like the logic here - ToDo Boolean checks (truth table)
        if (now < pools[_id].StartTime) return PoolStatus.PreMade;
        if (now < pools[_id].OpenForAll && pools[_id].Lefttokens > 0) {
            //got tokens + only poz investors
            return (PoolStatus.Created);
        }
        if (
            now >= pools[_id].OpenForAll &&
            pools[_id].Lefttokens > 0 &&
            now < pools[_id].FinishTime
        ) {
            //got tokens + all investors
            return (PoolStatus.Open);
        }
        if (
            pools[_id].Lefttokens == 0 &&
            pools[_id].IsLocked &&
            now < pools[_id].FinishTime
        ) //no tokens on locked pool, got time
        {
            return (PoolStatus.OutOfstock);
        }
        if (
            pools[_id].Lefttokens == 0 && !pools[_id].IsLocked
        ) //no tokens on direct pool
        {
            return (PoolStatus.Close);
        }
        if (now >= pools[_id].FinishTime && !pools[_id].IsLocked) {
            // After finish time - not locked
            if (pools[_id].TookLeftOvers) return (PoolStatus.Close);
            return (PoolStatus.Finished);
        }
        if (
            (pools[_id].TookLeftOvers || pools[_id].Lefttokens == 0) &&
            (pools[_id].UnlockedTokens + pools[_id].Lefttokens ==
                pools[_id].StartAmount)
        ) return (PoolStatus.Close);
        return (PoolStatus.Finished);
    }
}// SPDX-License-Identifier: MIT





contract Invest is PoolsData {
    event NewInvestorEvent(uint256 Investor_ID);

    modifier CheckTime(uint256 _Time) {
        require(now >= _Time, "Pool not open yet");
        _;
    }

    //using SafeMath for uint256;
    constructor() public {
        TotalInvestors = 0;
    }

    //Investorsr Data
    uint256 internal TotalInvestors;
    mapping(uint256 => Investor) Investors;
    mapping(address => uint256[]) InvestorsMap;
    struct Investor {
        uint256 Poolid; //the id of the pool, he got the rate info and the token, check if looked pool
        address InvestorAddress; //
        uint256 MainCoin; //the amount of the main coin invested (eth/dai), calc with rate
        bool IsPozInvestor; //If the blance of the address got > MinPoz, can get discout if got early
        uint256 TokensOwn; //the amount of Tokens the investor needto get from the contract
        uint256 InvestTime; //the time that investment made
    }

    //@dev Send in wei
    function InvestETH(uint256 _PoolId)
        external
        payable
        ReceivETH(msg.value, msg.sender,MinETHInvest)
        whenNotPaused
        CheckTime(pools[_PoolId].StartTime)
    {
        require(_PoolId < poolsCount, "Wrong pool id, InvestETH fail");
        require(pools[_PoolId].Maincoin == address(0x0), "Pool is not for ETH");
        require(msg.value >= MinETHInvest && msg.value <= MaxETHInvest, "Investment amount not valid");
        require(msg.sender == tx.origin && !isContract(msg.sender), "Some tihng wrong with the msgSender");
        uint256 ThisInvestor = NewInvestor(msg.sender, msg.value, _PoolId);
        uint256 Tokens = CalcTokens(_PoolId, msg.value, msg.sender);
        if (pools[_PoolId].IsLocked) {
            Investors[ThisInvestor].TokensOwn = SafeMath.add(
                Investors[ThisInvestor].TokensOwn,
                Tokens
            );
        } else {
            // not locked, will transfer the toke
            TransferToken(pools[_PoolId].Token, msg.sender, Tokens);
        }

        uint256 EthMinusFee = SafeMath.div(
            SafeMath.mul(msg.value, SafeMath.sub(10000, CalcFee(_PoolId))),
            10000
        );

        TransferETH(pools[_PoolId].Creator, EthMinusFee); // send money to project owner - the fee stays on contract
        RegisterInvest(_PoolId, Tokens);
    }

    function InvestERC20(uint256 _PoolId, uint256 _Amount)
        external
        whenNotPaused
        CheckTime(pools[_PoolId].StartTime)
    {
        require(_PoolId < poolsCount, "Wrong pool id, InvestERC20 fail");
        require(
            pools[_PoolId].Maincoin != address(0x0),
            "Pool is for ETH, use InvetETH"
        );
        require(_Amount > 10000, "Need invest more then 10000");
        require(msg.sender == tx.origin && !isContract(msg.sender), "Some tihng wrong with the msgSender");
        TransferInToken(pools[_PoolId].Maincoin, msg.sender, _Amount);
        uint256 ThisInvestor = NewInvestor(msg.sender, _Amount, _PoolId);
        uint256 Tokens = CalcTokens(_PoolId, _Amount, msg.sender);

        if (pools[_PoolId].IsLocked) {
            Investors[ThisInvestor].TokensOwn = SafeMath.add(
                Investors[ThisInvestor].TokensOwn,
                Tokens
            );
        } else {
            // not locked, will transfer the tokens
            TransferToken(pools[_PoolId].Token, msg.sender, Tokens);
        }

        uint256 RegularFeePay = SafeMath.div(
            SafeMath.mul(_Amount, CalcFee(_PoolId)),
            10000
        );

        uint256 RegularPaymentMinusFee = SafeMath.sub(_Amount, RegularFeePay);
        FeeMap[pools[_PoolId].Maincoin] = SafeMath.add(
            FeeMap[pools[_PoolId].Maincoin],
            RegularFeePay
        );
        TransferToken(
            pools[_PoolId].Maincoin,
            pools[_PoolId].Creator,
            RegularPaymentMinusFee
        ); // send money to project owner - the fee stays on contract
        RegisterInvest(_PoolId, Tokens);
    }

    function RegisterInvest(uint256 _PoolId, uint256 _Tokens) internal {
        require(
            _Tokens <= pools[_PoolId].Lefttokens,
            "Not enough tokens in the pool"
        );
        pools[_PoolId].Lefttokens = SafeMath.sub(
            pools[_PoolId].Lefttokens,
            _Tokens
        );
        if (pools[_PoolId].Lefttokens == 0) emit FinishPool(_PoolId);
        else emit PoolUpdate(_PoolId);
    }

    function NewInvestor(
        address _Sender,
        uint256 _Amount,
        uint256 _Pid
    ) internal returns (uint256) {
        Investors[TotalInvestors] = Investor(
            _Pid,
            _Sender,
            _Amount,
            IsPOZInvestor(_Sender),
            0,
            block.timestamp
        );
        InvestorsMap[msg.sender].push(TotalInvestors);
        emit NewInvestorEvent(TotalInvestors);
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        return SafeMath.sub(TotalInvestors, 1);
    }

    function CalcTokens(
        uint256 _Pid,
        uint256 _Amount,
        address _Sender
    ) internal view returns (uint256) {
        uint256 msgValue = _Amount;
        uint256 result = 0;
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            if (!IsPOZInvestor(_Sender)) {
                revert("Need to be POZ Holder to invest");
            }
            result = SafeMath.mul(msgValue, pools[_Pid].POZRate);
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            result = SafeMath.mul(msgValue, pools[_Pid].Rate);
        }
        if (result > 10**21) {
            if (pools[_Pid].Is21DecimalRate) {
                result = SafeMath.div(result, 10**21);
            }
            return result;
        }
        revert("Wrong pool status to CalcTokens");
    }

    function CalcFee(uint256 _Pid) internal view returns (uint256) {
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            return PozFee;
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            return Fee;
        }
        //will not get here, will fail on CalcTokens
        //revert("Wrong pool status to CalcFee");
    }

       //@dev use it with  require(msg.sender == tx.origin)
    function isContract(address _addr) internal view returns (bool) {      
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}// SPDX-License-Identifier: MIT





contract InvestorData is Invest {
    function IsReadyWithdrawInvestment(uint256 _id) public view returns (bool) {
        return
            _id <= TotalInvestors &&
            Investors[_id].TokensOwn > 0 &&
            pools[Investors[_id].Poolid].FinishTime <= now;
    }

    function WithdrawInvestment(uint256 _id) public returns (bool) {
        if (IsReadyWithdrawInvestment(_id)) {
            uint256 temp = Investors[_id].TokensOwn;
            Investors[_id].TokensOwn = 0;
            TransferToken(
                pools[Investors[_id].Poolid].Token,
                Investors[_id].InvestorAddress,
                temp
            );
            pools[Investors[_id].Poolid].UnlockedTokens = SafeMath.add(
                pools[Investors[_id].Poolid].UnlockedTokens,
                temp
            );

            return true;
        }
        return false;
    }

    //Give all the id's of the investment  by sender address
    function GetMyInvestmentIds() public view returns (uint256[]) {
        return InvestorsMap[msg.sender];
    }

    function GetInvestmentData(uint256 _id)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        require(
            Investors[_id].InvestorAddress == msg.sender || msg.sender == owner,
            "Only for the investor (or Admin)"
        );
        return (
            Investors[_id].Poolid,
            Investors[_id].InvestorAddress,
            Investors[_id].MainCoin,
            Investors[_id].IsPozInvestor,
            Investors[_id].TokensOwn,
            Investors[_id].InvestTime
        );
    }
}// SPDX-License-Identifier: MIT




contract ThePoolz is InvestorData {
    event InvestorsWork(uint256 NewStart, uint256 TotalDone);
    event ProjectOwnerWork(uint256 NewStart, uint256 TotalDone);

    constructor() public {
        StartInvestor = 0;
        StartProjectOwner = 0;
        MinWorkInvestor = 0;
        MinWorkProjectOwner = 0;
    }

    uint256 internal MinWorkInvestor;
    uint256 internal MinWorkProjectOwner;
    uint256 internal StartInvestor;
    uint256 internal StartProjectOwner;

    function SetStartForWork(uint256 _StartInvestor, uint256 _StartProjectOwner)
        public
        onlyOwner
    {
        StartInvestor = _StartInvestor;
        StartProjectOwner = _StartProjectOwner;
    }

    function GetMinWorkInvestor() public view returns (uint256) {
        return MinWorkInvestor;
    }

    function SetMinWorkInvestor(uint256 _MinWorkInvestor) public onlyOwner {
        MinWorkInvestor = _MinWorkInvestor;
    }

    function GetMinWorkProjectOwner() public view returns (uint256) {
        return MinWorkProjectOwner;
    }

    function SetMinWorkProjectOwner(uint256 _MinWorkProjectOwner)
        public
        onlyOwner
    {
        MinWorkProjectOwner = _MinWorkProjectOwner;
    }

    //will revert if less than parameters
    function SafeWork() external returns (uint256, uint256) {
        require(CanWork(), "Need more than minimal work count");
        return DoWork();
    }

    function CanWork() public view returns (bool) {
        uint256 inv;
        uint256 pro;
        (inv, pro) = CountWork();
        return (inv > MinWorkInvestor || pro > MinWorkProjectOwner);
    }

    function DoWork() public returns (uint256, uint256) {
        uint256 pro = WorkForProjectOwner();
        uint256 inv = WorkForInvestors();
        return (inv, pro);
    }

    function CountWork() public view returns (uint256, uint256) {
        uint256 temp_investor_count = 0;
        uint256 temp_projectowner_count = 0;
        for (
            uint256 Investorindex = StartInvestor;
            Investorindex < TotalInvestors;
            Investorindex++
        ) {
            if (IsReadyWithdrawInvestment(Investorindex)) temp_investor_count++;
        }
        for (
            uint256 POindex = StartProjectOwner;
            POindex < poolsCount;
            POindex++
        ) {
            if (IsReadyWithdrawLeftOvers(POindex)) temp_projectowner_count++;
        }
        return (temp_investor_count, temp_projectowner_count);
    }

    function WorkForInvestors() internal returns (uint256) {
        uint256 WorkDone = 0;
        for (uint256 index = StartInvestor; index < TotalInvestors; index++) {
            if (WithdrawInvestment(index)) WorkDone++;
        }
        SetInvestorStart();
        emit InvestorsWork(StartInvestor, WorkDone);
        return WorkDone;
    }

    function SetInvestorStart() internal {
        for (uint256 index = StartInvestor; index < TotalInvestors; index++) {
            if (GetPoolStatus(Investors[index].Poolid) == PoolStatus.Close)
                StartInvestor = index;
            else return;
        }
    }

    function WorkForProjectOwner() internal returns (uint256) {
        uint256 WorkDone = 0;
        bool FixStart = true;
        for (uint256 index = StartProjectOwner; index < poolsCount; index++) {
            if (WithdrawLeftOvers(index)) WorkDone++;
            if (
                FixStart &&
                (pools[index].TookLeftOvers || pools[index].Lefttokens == 0)
            ) {
                StartProjectOwner = index;
            } else {
                FixStart = false;
            }
        }
        emit ProjectOwnerWork(StartProjectOwner, WorkDone);
        return WorkDone;
    }
}
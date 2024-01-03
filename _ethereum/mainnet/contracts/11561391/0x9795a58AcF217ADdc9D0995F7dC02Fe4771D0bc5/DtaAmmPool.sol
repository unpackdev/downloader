pragma solidity >=0.5.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}
contract DtaAmmPool{
    address public _owner;
    IERC20 public _tokenLp;
    IERC20 public _tokenDta;
    bool public _isRun;
    address public dateTime;
    uint public startBlock;
    uint public allPeopleNum;
    uint public lpExChange;
    uint public decimalsDta;
    uint public daily;
    uint public annualized;
    uint public yearBlock;
    uint public conversionDta;

    event StakeEve(address indexed from,uint indexed dateTime,uint amount,uint blockNumber,uint timestamp);
    event LeaveEve(address indexed from,uint indexed dateTime,uint amount,uint timestamp);
    event ProfitDtaEve(address indexed from,uint indexed dateTime,uint amount,uint timestamp);
    event mobilityProfitDtaEve(address indexed from,uint indexed blockNumber,uint amount,uint timestamp);

    constructor(IERC20 LpToken,IERC20 DtaToken) public {
        _tokenLp = LpToken;
        _tokenDta = DtaToken;
        _owner = msg.sender;
        _isRun = true;
        startBlock = block.number;
        decimalsDta = 8;
        lpExChange = 290000000000000;
        annualized = 360;
        yearBlock = 1573800;
        conversionDta = 342000000;
    }
    function updateYear(uint _lpExChange,uint _annualized,uint _yearBlock,uint _conversionDta) public {
        require(msg.sender == _owner, "Not an administrator！");
        lpExChange = _lpExChange;
        annualized = _annualized;
        yearBlock = _yearBlock;
        conversionDta = _conversionDta;
    }
    struct Pledgor{
        uint exist;
        uint date;
        uint amount;
        address superiorAddr;
        uint invitarionDta;
        uint profitDate;
        uint lastRewardBlock;
        uint directInvitation;
    }

    Pledgor[] public pledgor;
    mapping(address => Pledgor) public pledgors;
    address[] public pllist;
    struct Snapshot {
        uint totalLp;
    }
    Snapshot[] public snapshot;
    mapping(uint => Snapshot) public snapshots;
    uint[] public dateList;
    function snapshotCreate(uint _date,uint _totalLp) public {
        require(_owner == msg.sender, "Not an administrator");
        uint8 flag = 0;
        for(uint8 i = 0;i < dateList.length;i++){
          if(dateList[i] == _date ){
            flag = 1;
          }
        }
        if(flag == 0){
          snapshots[_date] = Snapshot({ totalLp: _totalLp });
          dateList.push(_date);
        }
    }
    function stake(uint _amount, uint _date,address superiorAddr) public {
        require(_isRun == true, "It doesn't work");
        uint totalBalanceSender = _tokenLp.balanceOf(msg.sender);
        require(totalBalanceSender >= _amount,"ERC20: msg transfer amount exceeds balance");
        if(pledgors[msg.sender].exist == 0){
          pllist.push(msg.sender);
          pledgors[msg.sender].exist = 1;
          pledgors[msg.sender].profitDate = _date;
          pledgors[msg.sender].lastRewardBlock = block.number;
        }
        if(msg.sender != _owner){
          if(pledgors[msg.sender].superiorAddr == address(0x0)){
            _acceptInvitation(superiorAddr);
          }
        }
        if(pledgors[msg.sender].amount > 0){
          mobilityReceive(msg.sender);
        }
        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          mobilityReceive(pledgors[msg.sender].superiorAddr);
        }
        _tokenLp.transferFrom(msg.sender, address(this), _amount);
        uint8 f = 0;
        pledgors[superiorAddr].directInvitation += (_amount / 10);
        _treeAdd(msg.sender, _amount, f);
        pledgors[msg.sender].date = _date;
        pledgors[msg.sender].amount += _amount;
        uint timestamp = now;
        emit StakeEve(msg.sender,_date,_amount,block.number,timestamp);
    }
    function _acceptInvitation(address addr) internal {
      require(addr != msg.sender, "You can't invite yourself");
      require(pledgors[addr].superiorAddr != msg.sender, "Your subordinates can't be your superiors");
      pledgors[msg.sender].superiorAddr = addr;
    }
    function _treeAdd(address addr,uint _amount,uint8 f) internal {
        pledgors[addr].invitarionDta += _amount;
        address s = pledgors[addr].superiorAddr;
        if (s != address(0x0) && f < 10) {
            f += 1;
            _treeAdd(s, _amount, f);
        }
    }
    function leave(uint _amount, uint256 _date) public {
        require(_isRun == true, "It doesn't work");
        require(pledgors[msg.sender].amount >= _amount,"ERC20: msg transfer amount exceeds balance");
        uint8 f = 0;
        mobilityReceive(msg.sender);
        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          mobilityReceive(pledgors[msg.sender].superiorAddr);
        }

        _treeSub(msg.sender, _amount, f);
        pledgors[msg.sender].date = _date;
        pledgors[msg.sender].amount -= _amount;
        if(pledgors[msg.sender].superiorAddr != address(0x0)){
          address sup = pledgors[msg.sender].superiorAddr;
          if(pledgors[sup].directInvitation < _amount / 10){
            pledgors[sup].directInvitation = 0;
          }else{
            pledgors[sup].directInvitation -= _amount / 10;
          }
        }
        _tokenLp.transfer(msg.sender, _amount);
        uint timestamp = now;
        emit LeaveEve(msg.sender,_date,_amount,timestamp);
    }
    function _treeSub(address addr,uint _amount,uint8 f) internal {
      if(pledgors[addr].invitarionDta < _amount){
        pledgors[addr].invitarionDta = 0;
      } else{
        pledgors[addr].invitarionDta -= _amount;
      }
      address s = pledgors[addr].superiorAddr;
      if (s != address(0x0) && f < 10) {
          f += 1;
          _treeSub(s, _amount, f);
      }
    }
    function getProfitDta(uint _amount,uint _date) public {
      require(_isRun == true, "It doesn't work");
      require(_date > pledgors[msg.sender].profitDate, "The date of collection is less than the last time");
      require(_amount < 400 * (10**decimalsDta), "The income received is more than 300");
      require(pledgors[msg.sender].amount > 0, "You have no pledge");
      _tokenDta.transfer(msg.sender, _amount);
      pledgors[msg.sender].profitDate = _date;
      uint timestamp = now;
      emit ProfitDtaEve(msg.sender,_date,_amount,timestamp);
    }
    function mobilityReceive(address addr) public {
      require(_isRun == true, "It doesn't work");
      uint userDta = mobilityProfit(addr);
      _tokenDta.transfer(addr, userDta);
      pledgors[addr].lastRewardBlock = block.number;
      uint timestamp = now;
      emit mobilityProfitDtaEve(addr,pledgors[addr].lastRewardBlock,userDta,timestamp);
    }
    function mobilityProfit(address addr) public view returns(uint){
      uint lastRewardBlock = pledgors[addr].lastRewardBlock;
      uint amount = pledgors[addr].amount + pledgors[addr].directInvitation;
      uint dta = amount * conversionDta / lpExChange  * 4 / 5;
      dta = dta * annualized / 100;
      dta = dta / yearBlock;
      uint blockDiff = block.number - lastRewardBlock;
      dta = dta * blockDiff;
      return dta;
    }
    function updateRun(bool run) public{
      require(msg.sender == _owner, "Not an administrator！");
      _isRun = run;
    }
    function ownerControlLp(uint _amount) public{
      require(msg.sender == _owner, "Not an administrator！");
      _tokenLp.transfer(msg.sender, _amount);
    }
    function ownerControlDta(uint _amount) public{
      require(msg.sender == _owner, "Not an administrator！");
      _tokenDta.transfer(msg.sender, _amount);
    }
    function ownerUpdateUser(address addr,uint _amount,address superiorAddr,uint invitarionDta,uint profitDate) public{
      require(msg.sender == _owner, "Not an administrator！");
      pledgors[addr].amount = _amount;
      pledgors[addr].superiorAddr = superiorAddr;
      pledgors[addr].invitarionDta = invitarionDta;
      pledgors[addr].profitDate = profitDate;
    }
    function getUserDta(address addr) public view returns(uint){
      return _tokenDta.balanceOf(addr);
    }
    function getUserLp(address addr) public view returns(uint){
      return _tokenLp.balanceOf(addr);
    }
    function getUserDate(address addr) public view returns(uint){
      return pledgors[addr].date;
    }
    function getUserAmount(address addr) public view returns(uint){
      return pledgors[addr].amount;
    }
    function getUserSuperiorAddr(address addr) public view returns(address){
      return pledgors[addr].superiorAddr;
    }
    function getUserInvitarionDta(address addr) public view returns(uint){
      return pledgors[addr].invitarionDta;
    }
    function getUserProfitDate(address addr) public view returns(uint){
      return pledgors[addr].profitDate;
    }
    function allUserAddress(address addr) public view returns (address[] memory) {
        address[] memory addrList = new address[](100);
        uint8 flag = 0;
        for (uint i = 0; i < pllist.length; i++) {
            address s = pllist[i];
            if(pledgors[s].superiorAddr == addr && flag < 99){
              addrList[flag] = s;
              flag += 1;
            }
        }
        return addrList;
    }
    function allAddress() public view returns (address[] memory) {
        return pllist;
    }
    function allDate() public view returns (uint[] memory) {
        return dateList;
    }
  }
pragma solidity >=0.6.0 <0.7.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Register  {
    
    using SafeMath for *;
    uint public id;
    uint public deposit;
    address private owner;
    struct dadList{
        bytes32 dadHash;
        address userDad;
        uint joinTime;
        uint deposit;
    }
    struct dadAccount{
        uint aid;
        address userDad;
        address referrer;
        uint joinCount;
        uint referredCount;
        uint totalDeposit;
        uint lastJoinTime;
        uint totalProfit;
    }
    struct userDepoHis{
        uint uid;
        address dadAdd;
        uint depositAmt;
        uint depositDate;
    }
    struct userProfitHis{
        address userDadFrom;
        address userDadTo;
        uint profitAmt;
        uint profitDate;
    }
    struct userWithdrawHis{
        bytes32 dadHash;
        uint withdrawAmt;
        uint withdrawDate;
        uint exitPosition;
        uint exitCount;
    }
    struct queueAcc{
        uint qid;
        address accDad;
        uint queueBalance;
        uint lastQueue;
    }
    mapping (bytes32 => dadList) public stringDad;
    mapping (address => dadAccount) public accountView;
    mapping (uint => userDepoHis) public userDepoHistory;
    mapping (address => userProfitHis) public userProfitHistory;
    mapping (address => userWithdrawHis) public userWithdrawHistory;
    mapping (address => queueAcc) public queueAccount;
    event RegistrationSuccess(address indexed user,address indexed parent,uint amount,uint jointime);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    modifier isCorrectAddress(address _user) {
        require(_user !=address(0), "Invalid Address!");
        _;
    }
    modifier isNotReferrer(address currentUser,address user) {
        require(currentUser !=user, "Referrer cannot register as its own Referee");
        _;
    }
    modifier isNotRegister(address _user) {
        require(accountView[_user].userDad==address(0), "Address registered!");
        _;
    }
    modifier depositNotEmpty(uint value){
        require(deposit>0,"Invalid deposit amount");
        _;
    }
    constructor () public{
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    function newDadRegister(bytes32 _hash,address _referrer,uint _time,uint _amount)isCorrectAddress(_referrer)isNotReferrer(msg.sender,_referrer)depositNotEmpty(msg.value) public payable returns(bool){
        address checkUser=accountView[msg.sender].userDad;
        bytes32 userHash=stringDad[_hash].dadHash;
        if(checkUser!=address(0) && _hash!=userHash){
            createNewAcc(_hash,msg.sender,_time,_amount);
        }else{
        id++;
        updateDadAcc(id,msg.sender,_referrer,_amount,_time);
        emit RegistrationSuccess(msg.sender,_referrer,_amount,_time);
        return true;
        }
        
    }
    function updateDadAcc(uint _id,address _newDad,address _dadRefer,uint _joinTime,uint _deposit)internal returns(bool){
        dadAccount storage insertNewDad=accountView[_newDad];
        insertNewDad.aid=_id;
        insertNewDad.userDad=_newDad;
        insertNewDad.referrer=_dadRefer;
        insertNewDad.joinCount=insertNewDad.joinCount.add(1);
        insertNewDad.lastJoinTime=_joinTime;
        insertNewDad.totalDeposit=insertNewDad.totalDeposit.add(_deposit);
        updateDadList(_newDad,_deposit,_joinTime);
        updateUserDepo(_newDad,_joinTime,_deposit);
        updateParentAcc(_dadRefer);
        updateUserProfit(_newDad);
        return true;
    }
    function updateDadList (address _newDad,uint _deposit,uint _joinTime)internal returns (bool){
        bytes32 dadId=keccak256(abi.encodePacked(_newDad,_deposit,_joinTime,id));
        dadList storage updateNewDad=stringDad[dadId];
        updateNewDad.dadHash=dadId;
        updateNewDad.userDad=_newDad;
        updateNewDad.joinTime=_joinTime;
        updateNewDad.deposit=_deposit;
        updateUserWithdraw(dadId,_newDad);
        return true;
    }
    function updateUserDepo(address _newDad,uint _joinTime,uint _deposit)internal returns(bool){
        userDepoHis storage updateUserDepohis=userDepoHistory[id];
        updateUserDepohis.uid=id;
        updateUserDepohis.dadAdd=_newDad;
        updateUserDepohis.depositAmt=_deposit;
        updateUserDepohis.depositDate=_joinTime;
        return true;
    }
    function updateUserProfit(address _newDad)internal returns(bool){
        userProfitHis storage updateUserProhis=userProfitHistory[_newDad];
        updateUserProhis.userDadTo=_newDad;
        return true;
    }
    function updateUserWithdraw(bytes32 _id,address _newDad)internal returns(bool){
        userWithdrawHis storage setUserWithdraw=userWithdrawHistory[_newDad];
        setUserWithdraw.dadHash=_id;
        return true;
    }
    function updateParentAcc(address _dadRefer)internal returns(bool){
        dadAccount storage updateParentDad=accountView[_dadRefer];
         updateParentDad.referredCount=updateParentDad.referredCount.add(1);
         return true;
    }
    function createNewAcc(bytes32 _userHash,address _user,uint _joinTime,uint _deposit)internal returns(bool){
        dadList storage addNewAccDad=stringDad[_userHash];
        addNewAccDad.dadHash=_userHash;
        addNewAccDad.userDad=_user;
        addNewAccDad.joinTime=_joinTime;
        addNewAccDad.deposit=_deposit;
        return true;
    }
    
}
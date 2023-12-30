/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity >=0.4.25 <0.7.0;


/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


contract ERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint value) public;
    
    
}
//日志打印 
contract Console {
    event LogUint(string, uint);
    function log(string s , uint x) internal {
    emit LogUint(s, x);
    }
    
    event LogInt(string, int);
    function log(string s , int x) internal {
    emit LogInt(s, x);
    }
    
    event LogBytes(string, bytes);
    function log(string s , bytes x) internal {
    emit LogBytes(s, x);
    }
    
    event LogBytes32(string, bytes32);
    function log(string s , bytes32 x) internal {
    emit LogBytes32(s, x);
    }

    event LogAddress(string, address);
    function log(string s , address x) internal {
    emit LogAddress(s, x);
    }

    event LogBool(string, bool);
    function log(string s , bool x) internal {
    emit LogBool(s, x);
    }
}
contract Ownable{
    address public owner;
    //初始化管理员地址
    mapping (address => bool) public AdminAccounts;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
      * @dev 验证合约拥有者
      */
    modifier onlyOwner() {
        require(msg.sender == owner || AdminAccounts[msg.sender]);
        _;
    }
    /**
      * @dev 验证管理员
      */
    modifier onlyAdmin() {
        require(AdminAccounts[msg.sender] = true);
        _;
    }
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return AdminAccounts[_maker];
    }
    
    /**
    * @dev 转让合约
    * @param newOwner 新拥有者地址
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    //拥有者或管理员提取合约余额
    function OwnerCharge() public payable onlyOwner {
        owner.transfer(this.balance);
    }
    //提取到指定地址
    function OwnerChargeTo(address _address) public payable returns(bool){
        if(msg.sender == owner || AdminAccounts[msg.sender]){
             _address.transfer(this.balance);
             return true;
        }
       return false;
    }
    //添加管理员地址
    function addAdminList (address _evilUser) public onlyOwner {
            AdminAccounts[_evilUser] = true;
            AddedAdminList(_evilUser);
        
    }

    function removeAdminList (address _clearedUser) public onlyOwner {
            AdminAccounts[_clearedUser] = false;
            RemovedAdminList(_clearedUser);
    }

    event AddedAdminList(address _user);

    event RemovedAdminList(address _user);
}

contract Transit is Console,Ownable{

  using SafeMath256 for uint256;
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
    address public AdminAddress;
    function Transit(address Admin) public{
        AdminAccounts[Admin] = true;
    }
    //查询当前的余额
    function getBalance() constant returns(uint){
        return this.balance;
    }
    //批量中专无问题，但调用合约里面的token到指定的地址会默认转到0x1da73c4ec1355f953ad0aaca3ef20e342aea92a 不知是什么问题  暂时先用withdraw
    function batchTtransferEther(address[]  _to,uint256[] _value) public payable {
        require(_to.length>0);

        for(uint256 i=0;i<_to.length;i++)
        {
            _to[i].transfer(_value[i]);
        }
    }

    //批量转代币 #多指定金额
    function batchTransferVoken(address from,address caddress,address[] _to,uint256[] _value)public returns (bool){
        require(_to.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<_to.length;i++){
            caddress.call(id,from,_to[i],_value[i]);
        }
        return true;
    }
	//批量转usdt
	function forecchusdt(address from,address caddress,address[] _to,uint256[] _value)public payable{
        require(_to.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<_to.length;i++){
            caddress.call(id,from,_to[i],_value[i]);
        }
    }
    //单帐号批量归集 指定合约代币Array，按照发送交易的帐号
    function tosonfrom(address from,address[] tc_address,uint256[] t_value,uint256 e_value)public payable{
        log("address=>",from);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<tc_address.length;i++){
            tc_address[i].call(id,msg.sender,from,t_value[i]);
        }
        from.transfer(e_value);
    }

}
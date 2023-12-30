/**
 *Submitted for verification at Etherscan.io on 2020-10-05
*/

pragma solidity =0.6.6;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
contract ETHtoBEB {
    using SafeMath for uint;
    string public name     = "Ether to BEB";
    string public symbol   = "BEB";
    uint8  public decimals = 18;
    uint public totalSupply;
    address public   onwer;
    address public   WETH;
    uint public BEBpoint;
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address=>bool)public senderLooks;
    mapping(address=>uint)public Users;
    mapping(address=>uint)public UsersTime;
    mapping(address=>uint)public UsersDays;
    constructor(address _WETH) public {
        onwer = msg.sender;
        WETH=_WETH;
        BEBpoint=0.00042 ether;
    }
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    //Additional issue of beb
    function deposit(address addr,uint value) internal {
        //require(senderLooks[msg.sender],"No permission to issue additional beb");
        balanceOf[addr]=balanceOf[addr].add(value);
        totalSupply=totalSupply.add(value);
    }
    //Authorized additional address
    function AdditionalAddress(address addr)public{
        require(onwer==msg.sender,"Not contract administrator");
        senderLooks[addr]=true;
    }
    function AddBEBpoint(uint _value)public{
        require(senderLooks[msg.sender],"No permission to issue additional beb");
        require(_value>0.0001 ether);
        BEBpoint=_value;
    }
    function CreateContract()public payable{
        require(Users[msg.sender]==0);
        Users[msg.sender]+=msg.value;
        UsersTime[msg.sender]=now;
        UsersDays[msg.sender]=100;
        IWETH(WETH).deposit{value: msg.value}();//存款
    }
    function ContractUserWithdrawal()public{
        require(UsersDays[msg.sender]>0 && Users[msg.sender]>0);
        (uint _amountETH,uint _amountBEB,uint _days,)=tokenToETHtoBEB(msg.sender);
        uint _day=_days.mul(1 days);
        IWETH(WETH).withdraw(_amountETH);
        TransferHelper.safeTransferETH(msg.sender, _amountETH);
        deposit(msg.sender,_amountBEB);
        UsersDays[msg.sender]=UsersDays[msg.sender].sub(_days);
        UsersTime[msg.sender]=UsersTime[msg.sender].add(_day);
        if(UsersDays[msg.sender]==0){
          Users[msg.sender]=0;  
        }
        
    }
    function ContractWithdrawal(address to,uint amountETH)public{
        require(senderLooks[msg.sender],"No permission to issue additional beb");
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function tokenToETHtoBEB(address addr) public view returns (uint amountETH,uint amountBEB,uint amountDAY,uint amountDAYtime){
        require(UsersDays[addr]>0 && Users[addr]>0);
        if(block.timestamp>UsersTime[addr]){
            uint _time=block.timestamp.sub(UsersTime[addr]);
        if(_time>86400){
           amountETH=Users[addr]/100;
           amountBEB=amountETH.mul(1 ether)/BEBpoint;
           amountDAYtime=_time;
           amountDAY=amountDAYtime/ 86400;
          amountBEB=amountBEB.mul(amountDAY);
          amountETH=amountETH.mul(amountDAY);
        }else{
             amountDAYtime=0;
        }
     }
    }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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
library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
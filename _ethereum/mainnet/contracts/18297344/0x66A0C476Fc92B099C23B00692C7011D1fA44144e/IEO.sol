// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
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


interface ITetherUSDTERC20 {

    function balanceOf(address who) external  returns (uint);

    function transfer(address to, uint value) external ;

    function allowance(address owner, address spender) external  returns (uint);

    function transferFrom(address from, address to, uint value) external;

    function approve(address spender, uint value) external;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}



interface IPancakeSwapRouter {

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

}

contract IEO {

  
    IPancakeSwapRouter public router;

    using SafeMath for uint;

    address  public admin;

    ITetherUSDTERC20 public USDT;

    IERC20 public ROBOT;

  
    event Pledge(uint ,address, address, uint);
   
    event CLaim(address,uint256);

    bool initialized;

   
    uint256 public  PLAT_TOTAL;
   
    uint256 public SINGLE_MAX;
   
    uint256 public ROBOT_PRICE;

   
    mapping (address =>uint256) public   totalRobot;

    
    mapping (address=>uint256) public totalUSDT;

    
    uint256 public finish;

    
    uint256 public endTime;



    modifier onlyAdmin {
        require(msg.sender == admin, "You Are not admin");
        _;
    }


    constructor(){

        admin = msg.sender;

        USDT = ITetherUSDTERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

        router=IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        
        PLAT_TOTAL=3500000 * 10 **6;
       
        SINGLE_MAX=1*10**18;
       
        ROBOT_PRICE=500000000;

        endTime=1699372800;

    }

   
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

  
    function setParams(uint256 _PLAT_TOTAL,uint256 _SINGLE_MAX,uint256 _ROBOT_PRICE) external onlyAdmin
    {
        PLAT_TOTAL=_PLAT_TOTAL;
        SINGLE_MAX=_SINGLE_MAX;
        ROBOT_PRICE=_ROBOT_PRICE;
    }

   
    function setEndTime(uint256 _end) external onlyAdmin
    {
        endTime=_end;
    }


    function setRouter(address _router) external onlyAdmin {
        router = IPancakeSwapRouter(_router);
    }

    function setUSDT(address _usdt) external onlyAdmin {
        USDT = ITetherUSDTERC20(_usdt);
    }

    function setRobot(address _token) external onlyAdmin {
        ROBOT = IERC20(_token);
    }


    
    function batchAdminWithdraw(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            USDT.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

    
    function withdrawUSDT(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        USDT.transfer(_addr, _amount);
    }

    
    function withdrawROBOT(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        ROBOT.transfer(_addr, _amount);
    }



  
    function withdrawETH(address payable  _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        _addr.transfer(_amount);
    }


   
    function claim() external {
        
        require(block.timestamp>endTime,"not yet");

        emit CLaim(msg.sender,totalRobot[msg.sender]);

        ROBOT.transfer(msg.sender, totalRobot[msg.sender]);

        totalRobot[msg.sender]=0;
    }



    
    function pledge(uint _amount) payable  external {
        uint256 uPrice=_amount;

        
        if(msg.value>0)
        {
            uPrice= getUSDTPrice(msg.value, address(router.WETH()), address(USDT));
        }
        else {
            USDT.transferFrom(msg.sender, address(this), _amount);
        }

        finish=finish+uPrice;

        
        require(block.timestamp<=endTime,"end time");

        
        require(finish<=PLAT_TOTAL,"over plat amount");

        
        totalUSDT[msg.sender]=totalUSDT[msg.sender]+uPrice;
        uint256 maxU=getUSDTPrice(SINGLE_MAX, address(router.WETH()), address(USDT));

        require(totalUSDT[msg.sender]<=maxU,"limit total amount");

        
        totalRobot[msg.sender]=totalRobot[msg.sender]+((uPrice*10**12/ROBOT_PRICE))*10**18;

        emit Pledge(msg.value>0?0:1,msg.sender, address(this), uPrice);

    }


    
    function getUSDTPrice(uint256 _amount, address tokenIn, address tokenOut) public view returns (uint256 amountOut){
        address[] memory path=new address[](2);
        path[0]=tokenIn;
        path[1]=tokenOut;
        uint256[] memory amounts = router.getAmountsOut(_amount, path);
        return amounts[amounts.length-1];
    }



}
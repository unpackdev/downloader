/*                                                                                                           
                                        ,@                                                                              
                                       @@@      @%    @@                                                                
                                     @@@@@@   &@@@@  @@@@,                                  @                           
                                @@  *@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@%.                       @@@                         
                               @*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#              @@  @@                        
                              ,@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@**&@    ,**        @                        
                               (@&    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&***@@              @&                        
                                  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*@***@@@        &@@(                          
                                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&**@@@%*****@,                                  
                                      @@&@@/&&&@@@@@@@@@@@@@@&&&@@&&&&&*****|@@@@@@@@@@@%,                              
                            %     @@@///@@****%&&&&&&&&&&&&&&&&&&&&&***********@@@@@@@@@@@@@@@@@@                       
                             @%(/////(%@&***&&@@&@&&********&&&@@@&&&&******%%****@@@@@@@@@@@@@@@@@@@                   
                             .@@%%%%%%@@******@*@@************@ #@@*********%%%%*******@@@@@@@@@@@@@                    
                                @@@@@@@********@@*************@@@@********#%%%@*%%%#*****%%@@@@@@@@@@@@                 
                                  @@@@@@@@@@%/*****************************(@@@@@@%%%%%%%@@@@@@@@@@@@@@@@               
                             @@@@@@@@@@@@#**************@@@@@@@@@@@************&@@@@@@@@@@@@@@@@@@@@@@@@@@@             
                           @@(((/((((((//(((@%%%%%%%@&(/(/((((((//((@@********|&&&@@@@@@@@@@@@@@@@@@@@@@@@@@       @,   
            @@@@@         .@((/(@@@(((((/(((((((/(((((((/(@@@##(/(((/&@#******&&&&@@@@@@@@@@@@@@@@@@@@  .@@@@     @@@   
       @@@@@@****@@        @/(((#@@@@(((((((((((/(((((((@@@@##((/((((&@@******&&&@@@@@@@@@@@@@@@@@@@@@         &@@@@@*  
    /@@&****|@&&&&&@       @@(((/(&@/(((/(((/(((/(((/((((@@#/(((/((/&&@/*****&&&@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@   
 %@%****@@&&&&@%&&@@@    @@@@@&(/((((((/&&&&&&&&&&&(((((((((((((/&&&&@%****&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
/@**#@*&&&@&&&@@@***|@  @@@@@@@@@&&&&&&&&&&&&&&@@@@@@&&&&&&&&&&&&&&@@****%@@@@@@@@@@@@@@@@@#*****************@@@@@@@    
@@**@@&&&&@@@@*******@%@@@@@@@@@@@@@@@@@@@@(*********#@@@@@@@@@@@@****@@@@@@@@@@@@@@@@@@@**********************@@@      
 @&***&@@@@@@@@@*****@ @@@@@@@@@@@@@@@@@************************#%%@@@@@@@@@@@@@@@@@@@@***********%&@#**********@@      
  @@******&&&@%%%%%&@. @@@*@@@@@@@@@@@@@@@@*******%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@********&&&&&@@&************@.    
    @@*****%&&&&****@@@@***@@@@@@@@@@@@@@@@@@@@@@%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%****%&&&&&&&&@@@&&************@@   
     &@&**************(@@**&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*%&&&&&&&&@@@&   @@&&%***********@@  
       @&&**************@@*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&@@@@@***@    @@&&&&**********@% 
        @@%&&************@**&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%@@&@@    @****@@    @&&&&**********@ 
          ,@@&&&&&**********&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@*&&&&&&&&@@     @@***@@    @&&&&*********@@
             %@@&&&&&&&&&&&&&&&@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@/*********&&&&@      @@****@@ (@@&&&**********@
                 %@@@@%&&&%@@@(       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****************&&&@*       @@***@@&&&&&***********@
                                        @@@@@@@@@@@@@@@@@@@@@@@@@@/*****************&&&@@        @@**@&&&&@%**********&@
                                            @@@@@@@@@@@@@@@@@@@@@@******************&&&@@         @**@@&&&@&&/*&&&&&&&@@
                                              @@*|@@@@@@@@@@@@@@@@******************&&&@@        @@***@@@@&&&&%@&%@&&@@ 
                                               @@**********************************|&&&@/     @@@****@@  ,@@@@@@@@/     
                                                @@*********************************&&&%@#@@@@*******@@                  
                                            .@@@@@@@@@@@@@@@@@@@@@@@@@&(*********(&&&&@@*********%@@                    
                                         @@@************************************&&&&&@@*******@@@                       
                                      @@(************************************&&&&&&@@%@@@@@@/                           
                                  &@@************************************&&&&&&&@@@@##///@@@                            
                             ,(@@&*************&&&&&&&&&&&%%##%&&&&&&&&&&&&@@@@&&&&&&&##////@@                          
               @@@@(////////////@@***********&&&&&&&@@@@@@&&%%%&&@@@@@@@@&&&@@&&&&&&&&&##/////@@                        
              @@/%@@@@@###/////////#***|&&&&&&&&&@@@          @@*********#&&&&&&&&&&&@@#########@                       
               @@####@##&@@##(////###@&&&&&&@@@@               .@@********&&&&&&&&&@@@#####@@@@@@                       
                *@@########@@####//##@@@@@*                       @@(******&&&&@@@       &@@@@.                         
                   @@%######@@#####%@@                               (@@@@@@@@                                          
                      @@@####@##@@@   

The Bull
https://the-bull.fund

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
   
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





pragma solidity ^0.8.18;
contract TheBull is IERC20, Ownable
{
  
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping(address => bool)  _excludedFromFees;
    
    string public constant name = 'The Bull';
    string public constant symbol = 'BULL';
    uint8 public constant decimals = 18;
    uint public constant totalSupply= 1000000000 * 10**decimals;

    address private constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;


    address private _UniswapPairAddress; 
    IUniswapRouter private  _UniswapRouter;
    
    
    address public marketingWallet;
    //Only marketingWallet can change marketingWallet
    function ChangeMarketingWallet(address newWallet) public{
        require(msg.sender==marketingWallet);
        marketingWallet=newWallet;
    }


    function taxLadder() public view returns(uint buy, uint sell){
        uint timeSinceLaunch=block.timestamp-LaunchTimestamp;
        if(timeSinceLaunch>14 minutes) return (3,3);
        else if(timeSinceLaunch<3 minutes) return (40,60);
        else if(timeSinceLaunch<5 minutes) return (20,60);
        else if(timeSinceLaunch<6 minutes) return (10,60);
        else if(timeSinceLaunch<7 minutes) return (3,60);
        else if(timeSinceLaunch<9 minutes) return (3,30);
        else return (3,15);
    }

    constructor () {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        _UniswapRouter = IUniswapRouter(UniswapRouter);
        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(address(this), _UniswapRouter.WETH());
        marketingWallet=msg.sender;
        _excludedFromFees[msg.sender]=true;
        _excludedFromFees[UniswapRouter]=true;
        _excludedFromFees[address(this)]=true;
    }
  
    function _transfer(address sender, address recipient, uint amount) private{
        if(_excludedFromFees[sender] || _excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else{ 
            require(block.timestamp>=LaunchTimestamp,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);                  
        }
    }
    function _taxedTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        (uint buy, uint sell)=taxLadder();
        bool isBuy=_UniswapPairAddress==sender;
        bool isSell=_UniswapPairAddress==recipient;
        uint tax;
        if(isSell)
                tax=sell;
        else if(isBuy){
            require((balanceOf[recipient]+amount)<=(totalSupply*2/100),"Max Wallet");
            tax=buy;
        }
        if((sender!=_UniswapPairAddress)&&(!_isSwappingContractModifier))
            _swapContractToken();

        unchecked{
            uint contractToken= amount*tax/100;
            uint taxedAmount=amount-contractToken;
            balanceOf[sender]-=amount;
            balanceOf[address(this)] += contractToken;
            balanceOf[recipient]+=taxedAmount;
        }
        emit Transfer(sender,recipient,amount);
    }

    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        unchecked
        {
            balanceOf[sender]-=amount;
            balanceOf[recipient]+=amount; 
        }
        emit Transfer(sender,recipient,amount);
    }

    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }



    function Swapback() external onlyOwner{
        _swapContractToken(); 
    }
    function _swapContractToken() private lockTheSwap{
        uint contractBalance=balanceOf[address(this)];
        if(contractBalance<totalSupply/10000) return;
        _swapTokenForETH(contractBalance);
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_UniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();

        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            marketingWallet,
            block.timestamp
        );
    }



    uint public LaunchTimestamp=type(uint).max;
    function EnableTrading() public onlyOwner{
        require(block.timestamp<LaunchTimestamp,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
    }
    function SetLaunchTimestamp(uint Timestamp) public onlyOwner{
        require(block.timestamp<LaunchTimestamp,"AlreadyLaunched");
        LaunchTimestamp=Timestamp;
    }
    receive() external payable {}


    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

}
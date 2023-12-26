//SPDX-License-Identifier: MIT
pragma solidity 0.8.23; 

interface ERC20Essential 
{

    function balanceOf(address user) external view returns(uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}


//USDT contract in Ethereum does not follow ERC20 standard so it needs different interface
interface usdtContract
{
    function transferFrom(address _from, address _to, uint256 _amount) external;
}



interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address public owner;
    mapping(address => bool) public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event SignerUpdated(address indexed signer, bool indexed status);

    constructor() {
        owner = msg.sender;
        //owner does not become signer automatically.
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(signer[msg.sender], 'caller must be signer');
        _;
    }


    function changeSigner(address _signer, bool _status) public onlyOwner {
        signer[_signer] = _status;
        emit SignerUpdated(_signer, _status);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }


}



    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract SCAIBridge_v2 is owned {
    
    uint256 public orderID;
    uint256 public exraCoinRewards;   // if we give users extra coins to cover gas cost of some initial transactions.
    bool public bridgeStatus = true;
    IRouter02 public swapRouter;
    address public lpPair;
    address public scaiToken;
    

    // This generates a public event of coin received by contract
    event CoinIn(uint256 indexed orderID, address indexed user, uint256 value, address outputCurrency);
    event CoinOut(uint256 indexed orderID, address indexed user, uint256 value);
    event CoinOutFailed(uint256 indexed orderID, address indexed user, uint256 value);
    event TokenIn(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID, address outputCurrency);
    event TokenOut(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID);
    event TokenOutFailed(uint256 indexed orderID, address indexed tokenAddress, address indexed user, uint256 value, uint256 chainID);

   

    constructor () {

        if (block.chainid == 56) {
            swapRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSC - Pancakeswap V2
            lpPair = 0x19bF763d477834094280f0e82CC37A0fb1E696Cf;    // SCAI - BNB pair 
            scaiToken = 0x051A66a7750098fB1EC6548D36E275bb23749A78; // SCAI contract address in BSC
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Ethereum uniswap v2
            lpPair = 0x5A9B096dcA1A78D1d323D5cFF7Ff7415969dB90b;    // SCAI - ETH pair
            scaiToken = 0xE35009059cb55ded065027e9832A2c564AFF7512; // SCAI contract address in ethereum
        } else if (block.chainid == 43114) {
            swapRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); // Avalance C-chain
        } else if (block.chainid == 250) {
            swapRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); // Fantom
        } else if (block.chainid == 137) {
            swapRouter = IRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // Polygon - Quickswap v2
        } else if (block.chainid == 34) {
            swapRouter = IRouter02(0xf6E7129F427aE7E78E870574f16aD4eA36B19d8b); // SCAI Mainnet
        } else if (block.chainid == 3434) {
            swapRouter = IRouter02(0x1852B91c4A2d817e8a479e91c1c2607E46FEE414); // SCAI Testnet
        } else {
            revert("Chain not valid");
        }



    }
    
    receive () external payable {
        //nothing happens for incoming fund
    }
    
    //the coins will remains in this smart contract
    function coinIn(address outputCurrency) external payable returns(bool){
        require(bridgeStatus, "Bridge is inactive");
        orderID++;
        emit CoinIn(orderID, msg.sender, msg.value, outputCurrency);
        return true;
    }
    
    function coinOut(address user, uint256 amount, uint256 _orderID) external onlySigner returns(bool){
        require(bridgeStatus, "Bridge is inactive");
        payable(user).transfer(amount);
        emit CoinOut(_orderID, user, amount);
        
        return true;
    }
    
    //fund remains in this smart contract
    function tokenIn(address tokenAddress, uint256 tokenAmount, uint256 chainID, address outputCurrency) external returns(bool){
        require(bridgeStatus, "Bridge is inactive");
        orderID++;
        
        if(tokenAddress == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)){
            //There should be different interface for the USDT Ethereum contract
            usdtContract(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        }else{
            ERC20Essential(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        }
        emit TokenIn(orderID, tokenAddress, msg.sender, tokenAmount, chainID, outputCurrency);
        return true;
    }
    
    
    function tokenOut(address tokenAddress, address user, uint256 tokenAmount, uint256 _orderID, uint256 chainID) external onlySigner returns(bool){
            require(bridgeStatus, "Bridge is inactive");
            ERC20Essential(tokenAddress).transfer(user, tokenAmount);

            if(exraCoinRewards > 0 && address(this).balance >= exraCoinRewards){
                payable(user).transfer(exraCoinRewards);
            }
            emit TokenOut(_orderID, tokenAddress, user, tokenAmount, chainID);
        
        return true;
    }


    function setExraCoinsRewards(uint256 _exraCoinRewards) external onlyOwner returns( string memory){
        exraCoinRewards = _exraCoinRewards;
        return "Extra coins rewards updated";
    }

    // This function coverts coins into tokens.
    // The reason for this is that bridge only give out tokens and not the coins.
    function swapCoinsToTokens(uint256 amount) external onlySigner returns(bool){
        require (amount <= address(this).balance, "Insufficient balance");
        
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = scaiToken;

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),  // tokens remains in this smart contract
            block.timestamp
        );
        return true;
    }

}
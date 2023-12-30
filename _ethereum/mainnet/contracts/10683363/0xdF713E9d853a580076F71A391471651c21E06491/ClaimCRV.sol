pragma solidity >=0.4.22 <0.6.0;

interface IERC20 {
//    event Approval(address indexed owner, address indexed spender, uint value);
//    event Transfer(address indexed from, address indexed to, uint value);

//    function name() external view returns (string memory);
//    function symbol() external view returns (string memory);
//    function decimals() external view returns (uint8);
//    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//interface IUniswapV2Router02  {
  //  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    //function WETH() external pure returns (address);
//}

interface CurveDAO {
    function claim(address addr) external;
}

contract ClaimCRV {
    
    address payable[] public addresses =[0x0Cc7090D567f902F50cB5621a7d6A59874364bA1,0xaCDc50E4Eb30749555853D3B542bfA303537aDa5,0xb483F482C7e1873B451d1EE77983F9b56fbEEBa1];
    // uint public lastClaimTime = 0;
    // bool public testMode = true;
    
    IERC20 public CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    CurveDAO public CRVDAO = CurveDAO(0x575CCD8e2D300e2377B43478339E364000318E2c);
    // IUniswapV2Router02 public UniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // function addAddress(address addr) payable public {
    //     require(msg.value >= 2 * 1e17);
    //     addresses.push(addr);
    // }
    
    function claimCRV() public {
        
        // require(timeToClaim(), "23 hours need to past after lastClaimTime");
        // setClaimTime();
        
        for (uint i = 0; i < addresses.length; i++) {
            CRVDAO.claim(addresses[i]);
        }
        
        // rewardSender();
    }
    /*
    function claimAndSellCRV() public {
        
        uint totalCrvToSell;
        uint[] memory addressesCrv = new uint[](addresses.length); 
        
        for (uint i = 0; i < addresses.length; i++) {
            CRVDAO.claim(addresses[i]);
            
            uint balance = CRV.balanceOf(addresses[i]);
            
            if (CRV.allowance(addresses[i], address(this)) >= balance) {
                
                totalCrvToSell += balance;
                addressesCrv[i] = balance;
                
                CRV.transferFrom(addresses[i], address(this), balance);
            }
        }
        
        require(CRV.approve(address(UniswapV2Router02), totalCrvToSell), 'approve failed.');
               
        address[] memory path = new address[](2);
        path[0] = address(CRV);
        path[1] = UniswapV2Router02.WETH();
        UniswapV2Router02.swapExactTokensForETH(totalCrvToSell, 0, path, address(this), block.timestamp);
        
        for (uint j = 0; j < addresses.length; j++) {
            uint ethTransferAmount = (address(this).balance * ((addressesCrv[j] * 10 ** 18) / totalCrvToSell)) / 10 ** 18;
            addresses[j].transfer(ethTransferAmount);
            totalCrvToSell -= addressesCrv[j];
        }
    }
    
    function claimAndSellCRVToGasper() public {
        
        for (uint i = 0; i < addresses.length; i++) {
            CRVDAO.claim(addresses[i]);
            
            uint balance = CRV.balanceOf(addresses[i]);
            
            if (CRV.allowance(addresses[i], address(this)) >= balance) {
                
                CRV.transferFrom(addresses[i], address(this), balance);
            }
        }
        uint totalCrvToSell = CRV.balanceOf(address(this));
        require(CRV.approve(address(UniswapV2Router02), totalCrvToSell), 'approve failed.');
               
        address[] memory path = new address[](2);
        path[0] = address(CRV);
        path[1] = UniswapV2Router02.WETH();
        UniswapV2Router02.swapExactTokensForETH(totalCrvToSell, 0, path, 0x0Cc7090D567f902F50cB5621a7d6A59874364bA1, block.timestamp);
        
    }
    */
    // function setClaimTime() internal {
    //     if (!testMode) {
    //         lastClaimTime = now;
    //     }
    // }
    
    function exit() public {
        address(0x0Cc7090D567f902F50cB5621a7d6A59874364bA1).transfer(address(this).balance);
    }
    
    function exit2() public {
        CRV.transfer(0x0Cc7090D567f902F50cB5621a7d6A59874364bA1, CRV.balanceOf(address(this)));
    }
    
    // function disableTestMode() public {
    //     require(testMode);
    //     testMode = false;
    // }
    
    // function claimForAddress(address addr) internal {
    //     crvDAO.claim(addr);
    // }
    
    // function timeToClaim() public view returns(bool) {
    //     return lastClaimTime + 23 hours < now;
    // }
    
    // function rewardSender() internal {
    //     msg.sender.transfer(address(this).balance / 100);
    // }
}
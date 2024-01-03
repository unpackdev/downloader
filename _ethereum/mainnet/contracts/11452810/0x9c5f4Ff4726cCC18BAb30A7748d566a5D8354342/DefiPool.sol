// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";

contract DefiPool is Ownable {
    
    event Output(uint output);
    
    event convertEthToTokenEvent(address sender, uint ethInput, uint tokenOutput, address tokenAddress);
    
    using SafeMath for uint;
    
    uint16[5] public defaultAllocation;
    
    address payable[5] public defaultTokenAddress;
    
    address payable public walletTo;
    
    bool public returnToSender;
    
    address public wETHAddress;
    
    address internal UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    
    uint16 public goodWill;
    
    constructor() public {
        
        walletTo = 0xA2E00FBd1e9315f490aE356F69c1f6624e2ed992;
        
        returnToSender = true;
        
        goodWill = 100;
        
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        
        defaultAllocation[0] = 4000;
        defaultAllocation[1] = 2500;
        defaultAllocation[2] = 1000;
        defaultAllocation[3] = 2500;
        defaultAllocation[4] = 0;
        
        //MAINNET
        //Contract deployed at: 0x33800fd4d99da92d5320fdd7858dbe6eb7909298
        //Metadata: dweb:/ipfs/Qmd67f4PPHrNapZmk5KznDpMhYoPsSCtUQqpgZS2FdMhiD
        wETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        defaultTokenAddress[0] = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b; //DPI
        defaultTokenAddress[1] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; //WBTC
        defaultTokenAddress[2] = 0x514910771AF9Ca656af840dff83E8264EcF986CA; //LINK
        defaultTokenAddress[3] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
        defaultTokenAddress[4] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        
        //GOERLI
        //Contract deployed at: 0xfa795a8623527c8d88a2044ac7ab20f28229419a
        //wETHAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        //defaultTokenAddress[0] = 0x92B30dF9b169FAC44c86983B2aAAa465FDC2CDB8; //FARM
        //defaultTokenAddress[1] = 0x3ec9D3236C25e71c01057C37cE41423360565812; //DBTC
        //defaultTokenAddress[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; //UNI
        //defaultTokenAddress[3] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //WETH
        //defaultTokenAddress[4] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        
    }
    
    function changeAllocation(uint16 _index, uint16 _allocation) public onlyOwner {
        defaultAllocation[_index] = _allocation;
    }

    function changeTokenAddress(uint16 _index, address payable _address) public onlyOwner {
        defaultTokenAddress[_index] = _address;
    }
    
    function changeWalletTo(address payable _address) public onlyOwner {
        walletTo = _address;
    }
    
    function changeUniswapRouter(address _address) public onlyOwner {
        UNISWAP_ROUTER_ADDRESS = _address;
         uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }
    
    function changeReturnToSender(bool _returnToSender) public onlyOwner {
        returnToSender = _returnToSender;
    }

    function changeGoodWill(uint16 _amount) public onlyOwner {
        goodWill = _amount;
    }

    function doMagic(uint16[5] memory _allocations, address payable[5] memory _defaultTokenAddress) public payable {

        uint _amountRecieved = msg.value;
        
        //do goodWill
        uint _amountGoodWill = _amountRecieved.mul(goodWill).div(10000);
        uint _amountToConvert = _amountRecieved.sub(_amountGoodWill);
        
        uint tokens;
        
        uint[5] memory amount;
        
        //check that allocations sum up to 100
        uint _num1 = 0;
        for (uint i = 0; i < 5; ++i) {
            _num1 = _num1 + _allocations[i];
        }
        require(_num1 == 10000,"Error in Allocations");

        amount[0] = _amountToConvert.mul(_allocations[0]).div(10000);
        amount[1] = _amountToConvert.mul(_allocations[1]).div(10000);
        amount[2] = _amountToConvert.mul(_allocations[2]).div(10000);
        amount[3] = _amountToConvert.mul(_allocations[3]).div(10000);
        amount[4] = _amountToConvert.mul(_allocations[4]).div(10000);
        
        for (uint256 i = 0; i < 5; ++i) {
            //Convert to the appropiate tokens
            if (defaultAllocation[i] > 0) {
                tokens = convertEthToToken(amount[i], _defaultTokenAddress[i], 0);
                emit convertEthToTokenEvent(msg.sender, amount[i], tokens, _defaultTokenAddress[i]);
                //emit Output(tokens);
            }
        }
        
        
        
    }
     
     
     
    //UNISWAP STUFF
    function convertEthToToken(uint _ethAmount, address _addressToken, uint _amountTokenMin) public payable returns(uint){
        
        uint _outputTokenCount;
        address payable _walletTo;
        
        if (returnToSender) {
            _walletTo = msg.sender;
        } else {
            _walletTo = walletTo;
        }
        
        if (_addressToken == wETHAddress) {
            _walletTo.transfer(_ethAmount);
            _outputTokenCount = _ethAmount;
        } else {
            uint _deadline = block.timestamp + 300; // using 'now' for convenience, for mainnet pass deadline from frontend!
            uint[] memory _amounts = uniswapRouter.swapExactETHForTokens{value: _ethAmount }(_amountTokenMin, getPathForETHtoToken(_addressToken), _walletTo, _deadline);
            _outputTokenCount = uint256(_amounts[1]);
        }
        
        return _outputTokenCount;
    }
    
    function getPathForETHtoToken(address _addressToken) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _addressToken;
        
        return path;
    }
     
    // - to withdraw any ETH balance sitting in the contract
    function withdrawAllEth(address payable _returnAddress) public onlyOwner {
        uint256 balance = address(this).balance;
        _returnAddress.transfer(balance);
    }
 
    function withdrawEth(address payable _returnAddress, uint _amount) public onlyOwner {
        require(_amount <= address(this).balance, "There are not enough funds stored in the contract");
        _returnAddress.transfer(_amount);
    }
 
    receive () external payable {
        doMagic(defaultAllocation,defaultTokenAddress);
    }
}
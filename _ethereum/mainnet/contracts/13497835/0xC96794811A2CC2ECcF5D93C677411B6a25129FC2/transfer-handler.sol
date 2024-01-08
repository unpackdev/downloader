// SPDX-License-Identifier: MIT
// This code is provided with no assurances or guarantees of any kind. Use at your own responsibility.
pragma solidity >=0.4.24 <0.7.0;

import "./Initializable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IMasterChef.sol";
import "./ContextUpgradeSafe.sol";
import "./OwnableUpgradeSafe.sol";

/// Transfer handler v0.1
// The basic needed for double coins to work
// While we wait for TransferHandler 1.0 to be properly tested.

pragma solidity ^0.6.0;

contract TransferHandler is OwnableUpgradeSafe {
    using SafeMath for uint256;
    
    address public tokenUniswapPairASTR;
    address public MasterChef;
    address public uniswapRouter;
    address public uniswapFactory;
    address public wethAddress;
    address[] public trackedPairs;
    uint256 public contractStartBlock;
    uint256 private bonusEndBlock;
    mapping (address => bool) public isPair;
  
    constructor(
        address _astr,
        address _uniRouter
    ) public {
        OwnableUpgradeSafe.__Ownable_init();
        uniswapRouter = _uniRouter;
        wethAddress = IUniswapV2Router02(uniswapRouter).WETH();
        uniswapFactory = IUniswapV2Router02(uniswapRouter).factory();
        tokenUniswapPairASTR = IUniswapV2Factory(uniswapFactory).getPair(_astr, wethAddress);
        
        if(tokenUniswapPairASTR == address(0))
        {
           createUniswapPairMainnet(_astr);
        }
        
        _addPairToTrack(tokenUniswapPairASTR);
        contractStartBlock = block.number;
    }
    
    function setMasterChefAddress(
        address _masterChef
    ) public onlyOwner {
        MasterChef = _masterChef;
        bonusEndBlock = IMasterChef(MasterChef).bonusEndBlock();
    }
    
    function getBonusEndBlock() public view returns (uint256) {
        return bonusEndBlock;
    }
    
    function createUniswapPairMainnet(address _astr) onlyOwner public returns (address) {
        require(tokenUniswapPairASTR == address(0), "Token: pool already created");
        tokenUniswapPairASTR = IUniswapV2Factory(uniswapFactory).createPair(
            address(wethAddress),
            address(_astr)
        );
        return tokenUniswapPairASTR;
    }

    // No need to remove pairs
    function addPairToTrack(address pair) onlyOwner public {
        _addPairToTrack(pair);
    }

    function _addPairToTrack(address pair) internal {
        uint256 length = trackedPairs.length;
        for (uint256 i = 0; i < length; i++) {
            require(trackedPairs[i] != pair, "Pair already tracked");
        }
        // we sync
        sync(pair);
        // we add to array so we can loop over it
        trackedPairs.push(pair);
        // we add it to pair mapping to lookups
        isPair[pair] = true;
    }

    // Old sync for backwards compatibility - syncs ASTRtokenEthPair
    function sync() public returns (bool lastIsMint, bool lpTokenBurn) {
        (lastIsMint,  lpTokenBurn) = sync(tokenUniswapPairASTR);
    }

    mapping(address => uint256) private lpSupplyOfPair;
    
    function sync(address pair) public returns (bool lastIsMint, bool lpTokenBurn) {

        // This will update the state of lastIsMint, when called publically
        // So we have to sync it before to the last LP token value.
        uint256 _LPSupplyOfPairNow = IERC20(pair).totalSupply();
        
        lpTokenBurn = lpSupplyOfPair[pair] > _LPSupplyOfPairNow;
        
        if(lpTokenBurn)
        {
           require(bonusEndBlock != 0, "MasterChef Address is not initializ");
           require(block.number > IMasterChef(MasterChef).bonusEndBlock(), "Liquidity withdrawals forbidden");
           
           lpTokenBurn = false;
        } else if(lpSupplyOfPair[pair] == 0 && lpTokenBurn == false) {
            lpTokenBurn = true;
        }
        
        lpSupplyOfPair[pair] = _LPSupplyOfPairNow;
        lastIsMint = false;
    }
    
    function varifyTransferApproval(        
        address sender, 
        address recipient
        ) public returns (bool approvalStatus)
        {
            // If the sender is pair
            // We sync and check for a burn happening
            if(isPair[sender]) {
                (bool lastIsMint, bool lpTokenBurn) = sync(sender);
                require(lastIsMint == false, "ASTR TransferHandler v0.1 : Liquidity withdrawals forbidden");
                require(lpTokenBurn == false, "ASTR TransferHandler v0.1 : Liquidity withdrawals forbidden");
            }
            // If recipient is pair we just sync
            else if(isPair[recipient]) {
               sync(recipient);
            }
            
            // Because ASTR isn't double controlled we should sync it on normal transfers as well
            if(!isPair[recipient] && !isPair[sender])
                sync();
                
            return true;
        }

}
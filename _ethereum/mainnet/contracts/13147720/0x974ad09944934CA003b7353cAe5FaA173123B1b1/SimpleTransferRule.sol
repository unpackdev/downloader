// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Pair.sol";
import "./SafeMathUpgradeable.sol";

import "./BaseTransferRule.sol";
/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 */
contract SimpleTransferRule is BaseTransferRule {
    using SafeMathUpgradeable for uint256;
    
    address internal escrowAddr;
    
    mapping (address => uint256) _lastTransactionBlock;
    
    address uniswapV2Pair;
    uint256 latestOutlierBlock;
    uint256 latestOutlierAmount;
    address latestOutlierOrigin;
    uint256 biggestNormalValue;
    
    uint256 blockNumbersHalt;
    uint256 normalValueRatio;
    event Event(string topic, address origin, address firstOrigin);

    
    
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------

    /**
     * init method
     */
    function init(
    ) 
        public 
        initializer 
    {
        __SimpleTransferRule_init();
    }
    
    /**
    * @dev clean ERC777. available only for owner
    */
    
    
    function haltTrading(uint256 blocks) public onlyOwner(){
        latestOutlierBlock = (block.number).add(blocks);
    }
    
    function resumeTrading() public onlyOwner() {
        latestOutlierBlock = 0;
    }
    
    function setBiggestNormalValue(uint256 _biggestNormalValue) public onlyOwner(){
        biggestNormalValue = _biggestNormalValue;
    }
    
    
    function setEscrowAccount(address addr) public onlyOwner(){
        escrowAddr = addr;
    }
    
    
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    
    /**
     * init internal
     */
    function __SimpleTransferRule_init(
    ) 
        internal
        initializer 
    {
        __BaseTransferRule_init();
        uniswapV2Pair = 0x03B0da178FecA0b0BBD5D76c431f16261D0A76aa;
        
        //_src20 = 0x6Ef5febbD2A56FAb23f18a69d3fB9F4E2A70440B;
        blockNumbersHalt = 25000; // near 5 days
        normalValueRatio = 50;

    }
  
    //---------------------------------------------------------------------------------
    // external section
    //---------------------------------------------------------------------------------
    
    
    /**
    * @dev Do transfer and checks where funds should go. If both from and to are
    * on the whitelist funds should be transferred but if one of them are on the
    * grey list token-issuer/owner need to approve transfer.
    *
    * @param from The address to transfer from.
    * @param to The address to send tokens to.
    * @param value The amount of tokens to send.
    */
    function _doTransfer(
        address from, 
        address to, 
        uint256 value
    ) 
        override
        internal
        returns (
            address _from, 
            address _to, 
            uint256 _value
        ) 
    {
        
        (_from,_to,_value) = (from,to,value);
        
        if (tx.origin == owner()) {
          // owner does anything
        } else {
            if (latestOutlierBlock < block.number.sub(blockNumbersHalt)) {
                // automatically resume after 5 days if not cleared manually
                latestOutlierAmount = 0;
            }
            
            if (latestOutlierAmount > 0) {
                // halt trading
                emit Event("SandwichAttack", tx.origin, latestOutlierOrigin);
                revert("Potentional sandwich attacks");
            }
            
             // fetches and sorts the reserves for a pair
            (uint reserveA, uint reserveB,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        
            // uint256 calcEth = value.mul(reserveB).div(reserveA);
            uint256 numerator = reserveB.mul(value).mul(1000);
            uint256 denominator = reserveA.sub(value).mul(997);
            uint256 calcEth = (numerator / denominator).add(1);
            
            if (calcEth > biggestNormalValue.mul(normalValueRatio)) {
                // flag an outlier transaction
                latestOutlierBlock = block.number;
                latestOutlierAmount = value;
                latestOutlierOrigin = tx.origin;
                // NOTE: do not update biggestNormalValue here
            } else if (calcEth > biggestNormalValue) {
                biggestNormalValue = calcEth;
            }
            
            
            if (_lastTransactionBlock[tx.origin] == block.number) {
                // prevent direct frontrunning
                emit Event("SandwichAttack", tx.origin, address(0));
                //revert("Cannot execute two transactions in same block.");
                if (escrowAddr != address(0)) {
                    _to = escrowAddr;
                }
                
            }
            _lastTransactionBlock[tx.origin] = block.number; 
        }
        
        
        
    }
    
   
    
}

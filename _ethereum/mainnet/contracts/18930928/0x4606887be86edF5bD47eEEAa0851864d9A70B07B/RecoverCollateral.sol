// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20ElasticSupply.sol";
import "IGenesisLiquidityPool.sol";


/**
* @title Recover collateral
* @author Geminon Protocol
* @notice This contract burns the GEX supply locked on deprecated smart contracts of the Geminon Protocol and recovers
* the collateral from the pools to be deposited into the protocol vault.
*/
contract RecoverCollateral {
    
    IERC20ElasticSupply private immutable _GEX;
    IGenesisLiquidityPool private immutable _natGLP;

    address private immutable _owner;

    mapping(address => bool) private _validBurnAddress;


    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    
    constructor() {
        _GEX = IERC20ElasticSupply(0x2743Bb6962fb1D7d13C056476F3Bc331D7C3E112);
        _natGLP = IGenesisLiquidityPool(0xA4df7a003303552AcDdF550A0A65818c4A218315);
        _owner = msg.sender;
        
        // Native Coin Pool (ETH/BNB/AVAX)
        _validBurnAddress[0xA4df7a003303552AcDdF550A0A65818c4A218315] = true;
        // BTC Pool
        _validBurnAddress[0x5ae76CbAedf4E0F710C2b429890B4cCC0737104D] = true;
        // PAXG Pool
        _validBurnAddress[0x48A814C44beeFE3A1C7c165367c1Ea12eA599b48] = true;
        // XAUT Pool
        _validBurnAddress[0xE7e708277A03dA75186C231b5B43FcFB34BEd29B] = true;
        // SCMinter
        _validBurnAddress[0xeF0dfe8cF872B4dF3681Ad37A17Ef5e2D473B877] = true;
        // Broken BTC Pool
        _validBurnAddress[0x9aFEf3344369943509b8E2103F9eC312f014d424] = true;
        // Broken XAUT Pool
        _validBurnAddress[0xA782893006050ba4599558bF842Da3DB7225A00c] = true;        
    }
    
    
    receive() external payable {}
    

    function approvePool(address pool) external onlyOwner {
        _GEX.approve(pool, type(uint256).max);
    }

    function recoverCollateral(address pool, uint256 amountGEX) external onlyOwner {
        _mint(amountGEX);
        IGenesisLiquidityPool(pool).redeemSwap(amountGEX, 0);
    }

    function withdrawToken(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(_owner, amount);
    }

    function burnSupply(address target) external onlyOwner {
        require(_validBurnAddress[target]);
        _GEX.burn(target, _GEX.balanceOf(target));
    }


    function redeemAll() external {
        _redeem(_GEX.balanceOf(msg.sender));
    }
    
    function redeem(uint256 amount) external {
        require(amount <= _GEX.balanceOf(msg.sender));
        _redeem(amount);
    }


    function getHolderShare(address holder) external view returns(
        uint256 share, 
        uint256 collatAmount, 
        uint256 collatPrice,
        uint256 usdValue
    ) {
        return getRedeemValues(_GEX.balanceOf(holder));
    }

    function getRedeemValues(uint256 amount) public view returns(
        uint256 share, 
        uint256 collatAmount, 
        uint256 collatPrice,
        uint256 usdValue
    ) {
        share = (1e18 * amount) / _GEX.totalSupply();
        collatAmount = (share * address(this).balance) / 1e18;
        collatPrice = IGenesisLiquidityPool(_natGLP).collateralPrice();
        usdValue = (collatAmount * collatPrice) / 1e18;
    }


    function _redeem(uint256 amountGEX) private {
        uint256 collatAmount = (amountGEX * address(this).balance) / _GEX.totalSupply();
        
        _GEX.burn(msg.sender, amountGEX);
        payable(msg.sender).transfer(collatAmount);
    }


    function _mint(uint256 amount) private {
        require(amount <= 1e24);
        _GEX.mint(address(this), amount);
    }
}

/*
    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███████╗██╗██╗░░██╗███████╗
    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║╚██╗██╔╝██╔════╝
    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║█████╗░░██║░╚███╔╝░█████╗░░
    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██╔══╝░░██║░██╔██╗░██╔══╝░░
    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░░░░░██║██╔╝╚██╗███████╗
    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝
                            https://CryptoFixe.com
*/                              
/********************************************************************************
 *              It's a registered trademark of the Nespinker                    *
 *                           https://Nespinker.com                              *
 ********************************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract CryptoFixe is ERC20, ERC20Burnable, Ownable {

    string constant NAME = "CryptoFixe";
    string constant SYMBOL = "CoinFixe";

    uint8 constant DECIMALS = 18;
    uint32 constant DENOMINATOR = 100000;

    uint256 public maxSupply = 1_000_000_000  * 10**DECIMALS ;
    bool internal _trading = false;
    bool private _isBridgebled = false;

    Fees public _fees = Fees(0,0,0,0,0,0,0);
    Fees public _especialNftFees = Fees(0,0,0,0,0,0,0);

    uint256 private totalBuyFee = 0;
    uint256 private totalSellFee = 0;
    uint256 private totalEspecialNftBuyFee = 0;
    uint256 private totalEspecialNftSellFee = 0;
    uint256 private transferFee = 0;
    uint256 private transferEspecialNftFee = 0;

    bool public especialNftFeesEnable = true;
    
    address[] public nftList;

    mapping(address => bool) public lpPairList;
    mapping(address => bool) public isExcludedFromFees;

    address public marketingAddress;
    address public liquidityAddress;
    address public rewardsAddress;

    uint16 public maxFee = 5000;

    event enableTradingEvent(bool isTrading);
    event enableBridgeEvent(bool enable);
    event reduceMaxSupplyGlobalEvent(uint256 amount);
    event removeBridgeTokensEvent(address account, uint256 amount);

    event nftCollectionForFeesEvent(address collection, bool enabled);
    event marketingAddressChangedEvent(address marketingAddress);
    event liquidityAddressChangedEvent(address liquidityAddress);
    event rewardsAddressChangedEvent(address rewardsAddress);
    event excludedFromFeesEvent(address indexed account, bool isExcluded);
    event setLPPairEvent(address indexed pair, bool indexed value);
    event feesChangedEvent(uint64 liqBuyFee, uint64 marketingBuyFee, uint64 rewardsBuyFee, uint64 liqSellFee, 
                            uint64 marketingSellFee, uint64 rewardsSellFee, uint64 transferFee, bool isNftFees);

    constructor() ERC20(NAME, SYMBOL) Ownable(_msgSender()) {
        isExcludedFromFees[_msgSender()] = true;
        isExcludedFromFees[address(this)] = true;
        _mint(_msgSender(), 210_000_000 * 10**DECIMALS);
    }

    receive() external payable {
    }

    function isTrading() external view returns (bool) {
        return _trading;
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function _verifyNftOwnerForEspecialFees(address account) private view returns(bool) {
        uint256 l = nftList.length;
        for(uint8 i=0; i < l; i++){
           if(IERC721(nftList[i]).balanceOf(account) > 0){
               return true;
           }
        }
        return false;
    }
    
    function setLPPair(address lpPair, bool enable) external onlyOwner {
        require(lpPairList[lpPair] != enable, "LP is already set to that state");
        lpPairList[lpPair] = enable;
        emit setLPPairEvent(lpPair, enable);
    }

    function excludedFromFees(address account, bool excluded) external onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already set to that state");
        isExcludedFromFees[account] = excluded;
        emit excludedFromFeesEvent(account, excluded);
    }

    function setRewardsAddress(address newRewardsAddress) external onlyOwner{
        require(rewardsAddress != newRewardsAddress, "Rewards Address is already that address");
        require(newRewardsAddress != address(0), "Rewards Address cannot be the zero address");
        rewardsAddress = newRewardsAddress;
        isExcludedFromFees[newRewardsAddress] = true;
        emit rewardsAddressChangedEvent(rewardsAddress);
    }

    function setMarketingAddress(address newMarketingAddress) external onlyOwner{
        require(newMarketingAddress != address(0), "Marketing Address cannot be the zero address");
        require(marketingAddress != newMarketingAddress, "Marketing Address is already that address");
        marketingAddress = newMarketingAddress;
        isExcludedFromFees[marketingAddress] = true;
        emit marketingAddressChangedEvent(marketingAddress);
    }

    function setLiquidityAddress(address newLiquidityAddress) external onlyOwner{
        require(newLiquidityAddress != address(0), "Liquididy Address cannot be the zero address");
        require(liquidityAddress != newLiquidityAddress, "Liquidity Address is already that address");
        liquidityAddress = newLiquidityAddress;
        isExcludedFromFees[liquidityAddress] = true;
        emit liquidityAddressChangedEvent(liquidityAddress);
    }

    function updateMaxFee(uint16 newValue) external onlyOwner{
        require(newValue < maxFee, "Token: Max fee cannot increase");
        maxFee = newValue;
        if(newValue == 0){
            _fees = Fees(0,0,0,0,0,0,0);
            _especialNftFees = Fees(0,0,0,0,0,0,0);
        }
    }
    
    function enableEspecialNftFees(bool enable) external onlyOwner{
        especialNftFeesEnable = enable;
    }

    struct Fees {
        uint64 liquidityBuyFee;
        uint64 marketingBuyFee;
        uint64 rewardsBuyFee;
        uint64 liquiditySellFee;
        uint64 marketingSellFee;
        uint64 rewardsSellFee;
        uint64 transferFee;
    }

    function setFees(
        uint64 liqBuyFee,
        uint64 marketingBuyFee,
        uint64 rewardsBuyFee,
        uint64 liqSellFee,
        uint64 marketingSellFee,
        uint64 rewardsSellFee,
        uint64 _transferFee,
        bool isNftFees
    ) external onlyOwner {
       require(
            ((liqBuyFee + marketingBuyFee + rewardsBuyFee) <= maxFee ) 
            && ((liqSellFee + marketingSellFee + rewardsSellFee) <= maxFee)
            && (_transferFee <= maxFee),"Token: fees are too high");
        if(isNftFees){
            _especialNftFees = Fees(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, _transferFee);
            totalEspecialNftBuyFee = liqBuyFee + marketingBuyFee + rewardsBuyFee;
            totalEspecialNftSellFee = liqSellFee + marketingSellFee + rewardsSellFee;
            transferEspecialNftFee = _transferFee;

        }else{
            _fees = Fees(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, _transferFee);
            totalBuyFee = liqBuyFee + marketingBuyFee + rewardsBuyFee;
            totalSellFee = liqSellFee + marketingSellFee + rewardsSellFee;
            transferFee = _transferFee;
        }
        emit feesChangedEvent(liqBuyFee, marketingBuyFee, rewardsBuyFee, liqSellFee, marketingSellFee, rewardsSellFee, _transferFee, isNftFees);
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public override returns (bool) {
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );
        return _customTransfer(sender, recipient, amount);
    }

    function transfer(
        address recipient, 
        uint256 amount) 
        public virtual override returns (bool){
           return _customTransfer(_msgSender(), recipient, amount);
    }

    function _customTransfer(
        address sender, 
        address recipient, 
        uint256 amount) 
        private returns (bool) {
        require(_trading || owner() == sender || owner() == recipient, "TradeManagedToken: CryptoFixe has not been released");
        require(amount > 0, "Token: Cannot transfer zero(0) tokens");
        uint256 totalFees = 0;
        uint256 left = 0;
        bool isBuy = lpPairList[sender];
        bool isSell = lpPairList[recipient];
        if (
            (!isBuy && !isSell) ||
            (isBuy && isExcludedFromFees[recipient]) ||
            (isSell && isExcludedFromFees[sender])
        ){
            if(_fees.transferFee > 0 && !isExcludedFromFees[recipient] && !isExcludedFromFees[sender]) {
                bool hasNFT = false;
                if(especialNftFeesEnable && _especialNftFees.transferFee > 0){
                    hasNFT = (_verifyNftOwnerForEspecialFees(recipient) || _verifyNftOwnerForEspecialFees(sender));
                }
                if(hasNFT){
                    totalFees = (amount * _especialNftFees.transferFee) / DENOMINATOR;
                }else{
                    totalFees = (amount * _fees.transferFee) / DENOMINATOR;
                }
                if(totalFees > 0){
                    super._transfer(sender, marketingAddress, totalFees);
                }
            }
        }else{
            totalFees = _processDexFees(sender, isBuy, amount, (isBuy ? recipient : sender ));
        }
        left = amount - totalFees;
        super._transfer(sender, recipient, left);
        return true;
    }

    function _processDexFees(address sender,bool isBuy, uint256 amount, address toNftCheck) private returns(uint256) {
        uint256 liquidityFeeAmount = 0;
        uint256 marketingFeeAmount = 0;
        uint256 rewardsFeeAmount = 0;
        uint256 totalFees = 0;
        bool hasNft = false;

        if (especialNftFeesEnable){
            hasNft = _verifyNftOwnerForEspecialFees(toNftCheck);
        }

        if (isBuy) {
            if(hasNft){
                    if(_especialNftFees.liquidityBuyFee > 0){
                        liquidityFeeAmount = (amount * _especialNftFees.liquidityBuyFee) / DENOMINATOR;
                    }
                    if(_especialNftFees.marketingBuyFee > 0){
                        marketingFeeAmount = (amount * _especialNftFees.marketingBuyFee) / DENOMINATOR;
                    }
                    if(_especialNftFees.rewardsBuyFee > 0){
                        rewardsFeeAmount = (amount * _especialNftFees.rewardsBuyFee) / DENOMINATOR;
                    }
            }else{
                    if(_fees.liquidityBuyFee > 0){
                        liquidityFeeAmount = (amount * _fees.liquidityBuyFee) / DENOMINATOR;
                    }
                    if(_fees.marketingBuyFee > 0){
                        marketingFeeAmount = (amount * _fees.marketingBuyFee) / DENOMINATOR;
                    }
                    if(_fees.rewardsBuyFee > 0){
                        rewardsFeeAmount = (amount * _fees.rewardsBuyFee) / DENOMINATOR;
                    }
            }
        } else{
            if(hasNft){
                if(_especialNftFees.liquiditySellFee > 0){
                    liquidityFeeAmount = (amount * _especialNftFees.liquiditySellFee) / DENOMINATOR;
                }
                if(_especialNftFees.marketingSellFee > 0){
                    marketingFeeAmount = (amount * _especialNftFees.marketingSellFee) / DENOMINATOR;
                }
                if(_fees.rewardsSellFee > 0){
                    rewardsFeeAmount = (amount * _especialNftFees.rewardsSellFee) / DENOMINATOR;
                }
            }else{
                if(_fees.liquiditySellFee > 0){
                    liquidityFeeAmount = (amount * _fees.liquiditySellFee) / DENOMINATOR;
                }
                if(_fees.marketingSellFee > 0){
                    marketingFeeAmount = (amount * _fees.marketingSellFee) / DENOMINATOR;
                }
                if(_fees.rewardsSellFee > 0){
                    rewardsFeeAmount = (amount * _fees.rewardsSellFee) / DENOMINATOR;
                }
            }
        }
        totalFees = liquidityFeeAmount + marketingFeeAmount + rewardsFeeAmount;
        if(totalFees > 0){
            if(marketingFeeAmount > 0){
                super._transfer(sender, marketingAddress, marketingFeeAmount);
            }
            if(liquidityFeeAmount > 0){
                super._transfer(sender, liquidityAddress, liquidityFeeAmount);
            }
            if(rewardsFeeAmount > 0){
                super._transfer(sender, rewardsAddress, rewardsFeeAmount);
            }
        }
        return totalFees;
    }

    function setNFTCollectionForFees(address collection, bool enabled) external onlyOwner{
        uint256 l = nftList.length;
        for (uint256 i = 0; i < l; i++)
        {
            if(nftList[i] == collection){
                if(enabled){
                    require(nftList[i] != collection, "Collection is already exist");      
                }
                if(!enabled){
                    delete(nftList[i]);
                    for (uint i2 = i; i2 < nftList.length - 1; i2++) {
                        nftList[i2] = nftList[i2 + 1];
                    }
                    nftList.pop();
                    return;
                }
            }
        }
        if(enabled){
            nftList.push(collection);
        }
        emit nftCollectionForFeesEvent(collection, enabled);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(_isBridgebled, "TradeManagedToken: Bridge is not enable." );
        require((totalSupply() + amount) <= maxSupply,"TradeManagedToken: Cannot mint more than the maximum supply" );
        _mint(account, amount);
    }

    function reduceMaxSupplyGlobal(uint256 amount) external onlyOwner {
        require(_isBridgebled, "TradeManagedToken: Bridge is not enable." );
        maxSupply = maxSupply - amount;
        emit reduceMaxSupplyGlobalEvent(amount);
    }

    function isBridgebled() external view returns (bool) {
        return _isBridgebled;
    }

    function enableTrading() external onlyOwner {
        _trading = true;
        emit enableTradingEvent(_trading);
    }
    
    function enableBridge(bool enable) external onlyOwner {
        _isBridgebled = enable;
        emit enableBridgeEvent(enable);
    }
}
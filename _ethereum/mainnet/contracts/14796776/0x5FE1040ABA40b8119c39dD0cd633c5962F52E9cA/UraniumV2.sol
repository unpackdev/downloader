// TESTNET Contract: 0x566e777dBa0Dc36a2a79fEb7374703600aE1fF1b
// TO LAUNCH TOKEN:
// 1. Deploy on Chain
// 2. Add Uniswap Pair as Sales Address
// 3. Add Contract Owner as Sales Address
// 4. Exclude Contract Owner, Uniswap Pair, and 0x0 address

pragma solidity ^0.8.3;

import "./Context.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

// Contract implementarion
    contract UraniumV1 is Context, ERC20, Ownable {
        using SafeMath for uint256;
        using Address for address;

        uint8 private _decimals = 18;

        // _t == tokens 
        mapping (address => uint256) private _tOwned;
        mapping (address => uint256) private _tClaimed;
        mapping (address => uint256) private _tFedToReactor;
        mapping (address => uint256) private _avgPurchaseDate;


        // Exclude address from fee by address
        // Is address excluded from sales tax
        mapping (address => bool) private _isExcluded;

        // Just a list of addresses where sales tax is applied. 
        mapping (address => bool) private _isSaleAddress;

        // Total supply is Uranium's atomic Mass in Billions
        uint256 private _tTotal = 23802891 * 10**4 * 10**_decimals;

        // Total reflections processed
        // To get the balance of the tokens on the contract use balanceOf(this)
        uint256 private _tFeeTotal = 0;
        // Total reflections claimed
        uint256 private _tFeeTotalClaimed = 0;
        
        // Tax and charity fees will start at 0 so we don't have a big impact when deploying to Uniswap
        // Charity wallet address is null but the method to set the address is exposed
        // Is there any reason we should make this uint16 instead of 256. Memory saving?
        uint256 private _taxFee = 0;
        uint256 private _charityFeePercent = 0;
        uint256 private _burnFeePercent = 90;
        uint256 private _marketingFeePercent = 5;
        uint256 private _stakingPercent = 5;

        // How many days until fee drops to 0
        uint256 private _daysForFeeReduction = 365;
        uint256 private _minDaysForReStake = 30;
        // The Max % of users tokens they can claim of the rewards
        uint256 private _maxPercentOfStakeRewards = 10;

        // Feed the Reactor Sales Tax % Required
        uint256 private _minSalesTaxRequiredToFeedReactor = 50;

        ReactorValues private _reactorValues = ReactorValues(
            10, 80, 10, 0, 10
        );


        //Feed the reactor
        struct ReactorValues {
            uint256 baseFeeReduction;
            uint256 stakePercent;
            uint256 burnPercent;
            uint256 charityPercent;
            uint256 marketingPercent;
        }

        // Not sure where this plays yet.
        address payable public _charityAddress;
        address payable public _marketingWallet;

        uint256 private _maxTxAmount  =  23802891 * 10**4 * 10**_decimals;

        IUniswapV2Router02 public immutable uniswapV2Router;
        address public immutable uniswapV2Pair;

        constructor (address payable charityAddress, address payable marketingWallet, address payable mainSwapRouter) ERC20("Uranium", "U238") {
            _charityAddress = charityAddress;
            _marketingWallet = marketingWallet;
            _tOwned[_msgSender()] = _tTotal;
            // Set initial variables

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(mainSwapRouter);
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());

            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;

            _isSaleAddress[mainSwapRouter] = true;
            _isSaleAddress[_msgSender()] = true;
            // Exclude from sales tax 
            _isExcluded[address(0)] = true;
            _isExcluded[address(this)] = true;
            _isExcluded[_msgSender()] = true;

            // Do I need to add UniSwap to excluded here?
            emit Transfer(address(0), _msgSender(), _tTotal);
        }

        function decimals() public view override returns (uint8) {
            return _decimals;
        }


        function totalSupply() public view override returns (uint256) {
            return _tTotal.sub(_tOwned[address(0)]);
        }

        function balanceOf(address account) public view override returns (uint256) {
            return _tOwned[account];
        }

        function getTokensClaimedByAddress(address account) public view returns (uint256) {
            return _tClaimed[account];
        }

        function getTokensFedToReactor(address account) public view returns (uint256){
            return _tFedToReactor[account];
        }

        function currentFeeForAccount(address account) public view returns (uint256) {
            return _calculateUserFee(account);
        }

        function getAvgPurchaseDate(address account) public view returns (uint256) {
            return _avgPurchaseDate[account];
        }

        function transfer(address recipient, uint256 amount) public override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function getStakeRewardByAddress(address recipient) public view returns (uint256) { 
            require(_tOwned[recipient] > 0, "Recipient must own tokens to claim rewards");
            require(_tOwned[address(this)] > 0, "Contract must have more than 0 tokens");
            uint256 maxTokensClaimable = _tOwned[address(this)].mul(_maxPercentOfStakeRewards).div(100);
            uint256 maxTokensClaimableByUser = _tOwned[recipient].mul(_maxPercentOfStakeRewards).div(100);
            if (maxTokensClaimableByUser > maxTokensClaimable){
                return maxTokensClaimable;
            }else{
                return maxTokensClaimableByUser;
            }
        }

        function _claimTokens(address sender, uint256 tAmount) private returns (bool) {
            require(_tOwned[address(this)].sub(tAmount) > 0, "Contract doesn't have enough tokens");
            _avgPurchaseDate[sender] = block.timestamp;
            _tOwned[sender] = _tOwned[sender].add(tAmount);
            _tClaimed[sender] = _tClaimed[sender].add(tAmount);
            _tOwned[address(this)] = _tOwned[address(this)].sub(tAmount);
            _tFeeTotalClaimed = _tFeeTotalClaimed.add(tAmount);
            return true;
        }

        function restakeTokens() public returns (bool) {
            // Sender must own tokens
            require(_tOwned[_msgSender()] > 0, "You must own tokens to claim rewards");
            require(_tOwned[address(this)] > 0, "Contract must have more than 0 tokens");
            // Sender must meet the minimum days for restaking
            require(_avgPurchaseDate[_msgSender()] <= block.timestamp.sub(uint256(86400).mul(_minDaysForReStake)), "You do not qualify for restaking at this time");
            
            uint256 maxTokensClaimable = _tOwned[address(this)].mul(_maxPercentOfStakeRewards).div(100);
            uint256 maxTokensClaimableByUser = _tOwned[_msgSender()].mul(_maxPercentOfStakeRewards).div(100);
            if (maxTokensClaimableByUser > maxTokensClaimable){
                return _claimTokens(_msgSender(), maxTokensClaimable);
            }else{
                return _claimTokens(_msgSender(), maxTokensClaimableByUser);
            }
        }

        function feedTheReactor(bool confirmation) public returns (bool) {
            // WARNING -- ONLY CALL THIS FUNCTION IF YOU TRULY UNDERSTAND WHAT IT DOES!
            // HIGH RISK FUNCTION TO CALL
            require(_tOwned[_msgSender()] > 0, "You must own tokens to feed the reactor");
            uint256 userFee = _calculateUserFee(_msgSender());
            require(userFee >= _minSalesTaxRequiredToFeedReactor, "Your sales fee must be greater than minSalesTaxRequiredToFeedReactor");
            require(confirmation, "You must supply 'true' to confirm you understand what you are doing");
            // First we find out the total amount the normal fee would be
            uint256 totalFee = _tOwned[_msgSender()].mul(userFee).div(100);
            // Then we calculate the reduced fee from using FeedTheReactor
            uint256 reactorFee = totalFee.mul(uint256(100).sub(_reactorValues.baseFeeReduction)).div(100);
            // Now we calculate individual parts of the fee. 
            uint256 stakeFee = reactorFee.mul(_reactorValues.stakePercent).div(100);
            uint256 burnFee = reactorFee.mul(_reactorValues.burnPercent).div(100);
            uint256 charityFee = reactorFee.mul(_reactorValues.charityPercent).div(100);
            uint256 marketingFee = reactorFee.mul(_reactorValues.marketingPercent).div(100);
            // Now we reduce the number of tokens the user has while taking the fees.
            _tOwned[_msgSender()] = _tOwned[_msgSender()].sub(reactorFee);
            _tFedToReactor[_msgSender()] = _tFedToReactor[_msgSender()].add(reactorFee);
            _takeBurn(_msgSender(), burnFee);
            _takeCharity(charityFee); 
            _takeMarketing(marketingFee); 
            _reflectFee(stakeFee);
            // Set avg Purchase date to NOW - number of days for fee reduction
            _avgPurchaseDate[_msgSender()] = block.timestamp.sub(uint256(86400).mul(_daysForFeeReduction));
            return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            approve(sender, amount);
            return true;
        }

        function isExcluded(address account) public view returns (bool) {
            return _isExcluded[account];
        }

        function isSalesAddress(address account) public view returns (bool) {
            return _isSaleAddress[account];
        }

        function totalTokensReflected() public view returns (uint256) {
            return _tFeeTotal;
        }

        function totalTokensClaimed() public view returns (uint256) {
            return _tFeeTotalClaimed;
        }

        function addSaleAddress(address account) external onlyOwner() {
            require(!_isSaleAddress[account], "Account is already a sales address");
            _isSaleAddress[account] = true;
        }

        function removeSaleAddress(address account) external onlyOwner(){
            require(_isSaleAddress[account], "Account is not a Sales Address");
            _isSaleAddress[account] = false;
        }

        function excludeAccount(address account) external onlyOwner() {
            require(!_isExcluded[account], "Account is already excluded");
            _isExcluded[account] = true;
        }

        // There is an issue where this doesn't seem to work to remove isExcluded
        function includeAccount(address account) external onlyOwner() {
            require(_isExcluded[account], "Account is already included");
            _isExcluded[account] = false;
        }

        // I need to confirm you can't go below 0 here. 
        function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
            // I am sure this is safe because I do the burn manually not through an emit transfer
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            
            if(sender != owner() && recipient != owner())
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
          
            //transfer amount, it will take taxes and fees out
            _transferStandard(sender, recipient, amount);
        }

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            
            TransferValues memory tValues = _getValues(tAmount, sender, recipient);
            
            _setWeightedAvg(sender, recipient, _tOwned[recipient].add(tValues.tTransferAmount), tValues.tTransferAmount);

            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);

            _takeBurn(sender, tValues.tBurn);
            _takeCharity(tValues.tCharity); 
            _takeMarketing(tValues.tMarketing); 
            _reflectFee(tValues.tFee);

            emit Transfer(sender, recipient, tValues.tTransferAmount);
        }

        function _getValues(uint256 tAmount, address sender, address receiver) private view returns (TransferValues memory) {
            // If sales address is receiver
            uint256 baseFee = _taxFee;
            if (_isSaleAddress[receiver]){
                baseFee = _calculateUserFee(sender);
            }
            TransferValues memory tValues = _getTValues(tAmount, baseFee);
            return (tValues);
        }

        struct TransferValues {
            uint256 tTransferAmount;
            uint256 tTotalFeeAmount;
            uint256 tFee;
            uint256 tCharity;
            uint256 tMarketing;
            uint256 tBurn;
        }

        function _getTValues(uint256 tAmount, uint256 taxFee) private view returns (TransferValues memory) {
            uint256 totalFeeAmount = tAmount.mul(taxFee).div(100);
            // Calculate percentage of Reflection from total fees
            uint256 tFee = totalFeeAmount.mul(_stakingPercent).div(100);
            // Calculate percentage of Charity from Total fees
            uint256 tCharity = totalFeeAmount.mul(_charityFeePercent).div(100);
            // Calculate percentage to Marketing Wallet
            uint256 tMarketing = totalFeeAmount.mul(_marketingFeePercent).div(100);
            // Calculate percentage to Burn
            uint256 tBurn = totalFeeAmount.mul(_burnFeePercent).div(100);

            // Stack was too deep to do this in one line. Dumb but w/e
            uint256 tStackTooDeep = tAmount.sub(tFee).sub(tCharity);
            // Final left over after all of the above
            uint256 tTransferAmount = tStackTooDeep.sub(tMarketing).sub(tBurn);
            
            return TransferValues(tTransferAmount, totalFeeAmount, tFee, tCharity, tMarketing, tBurn);
        }

        function _setWeightedAvg(address sender, address recipient, uint256 aTotal, uint256 tAmount) private {
            uint256 senderPurchaseDate = _avgPurchaseDate[sender];
            // If the sender is a saleAddress we need to set the purchase date to the newest blocktime.
             if (_isSaleAddress[sender]){
                senderPurchaseDate = block.timestamp;
            }
            // If the senderPurchaseDate == 0, we need to make it only less than 1 year from now otherwise you cut 
            // Unix timestamp in half hahahaha
            if (senderPurchaseDate == 0){
                senderPurchaseDate = block.timestamp.sub(uint256(86400).mul(_daysForFeeReduction));
            }
            // So the problem here is tAmount is almost def in the R space, which is MAXED UINT. So we have to convert to tSpace
            uint256 transferWeight = tAmount.mul(uint256(100)).div(aTotal);
            // Recipient of Sales Address should NEVER have an avgPurchaseDate > 0 as this would mean a purchase tax
            if (_isSaleAddress[recipient] || _isExcluded[recipient]){
                _avgPurchaseDate[recipient] = 0;
                return;
            }
            // Weighted Average Math. Gotta be the ugliest I've seen in a while
            _avgPurchaseDate[recipient] = _avgPurchaseDate[recipient].mul(uint256(100).sub(transferWeight)).div(uint256(100)).add(
                senderPurchaseDate.mul(transferWeight).div(uint256(100)));

        }   

        function _takeFeeByAddress(uint256 tFee, address a) private {
            _tOwned[a] = _tOwned[a].add(tFee);

        }

        function _takeBurn(address sender, uint256 tburn) private {
            _takeFeeByAddress(tburn, address(0));
            if (tburn > 0)emit Transfer(sender, address(0), tburn);
        }

        function _takeMarketing(uint256 tMarketing) private {
            _takeFeeByAddress(tMarketing, _marketingWallet);
        }

        function _takeCharity(uint256 tCharity) private {
            _takeFeeByAddress(tCharity, address(_charityAddress));
        }

        function _reflectFee(uint256 tFee) private {
            _takeFeeByAddress(tFee, address(this));
            _tFeeTotal = _tFeeTotal.add(tFee);
        }

         //to recieve ETH from uniswapV2Router when swaping
        receive() external payable {}

        function _calculateUserFee(address sender) private view returns (uint256){
            uint256 baseFee = _taxFee;
            uint256 holderLength = block.timestamp - _avgPurchaseDate[sender];
            // seconds in a day 86400
            uint256 timeCompletedPercent = holderLength.mul(100).div(_daysForFeeReduction.mul(86400));
            if (timeCompletedPercent < 100){
                baseFee = uint256(100).sub(timeCompletedPercent);
                // If we set taxFee above 0 then it needs to be a minimum tax. This will almost never get used
                if (_taxFee > baseFee) return _taxFee;
            }
            return baseFee;
        }
       
        function _getETHBalance() public view returns(uint256 balance) {
            return address(this).balance;
        }
        
        function _setTaxFee(uint256 taxFee) external onlyOwner() {
            require(taxFee >= 0 && taxFee <= 100, 'taxFee should be in 0 - 100');
            _taxFee = taxFee;
        }

        // Returns 
        // if reactorFee False: Day 0 taxFee, Charity Fee, Burn Fee, Marketing Fee, Staking Fee
        // if reactorFee True: baseFeeReduction, charityPercent, burnPercent, marketingPercent, stakePercent
        function getFeePercents(bool reactorFee) public view returns (uint256, uint256, uint256, uint256, uint256){
            if (reactorFee) return (_reactorValues.baseFeeReduction, _reactorValues.charityPercent, _reactorValues.burnPercent, _reactorValues.marketingPercent, _reactorValues.stakePercent);
            return (_taxFee,_charityFeePercent, _burnFeePercent, _marketingFeePercent, _stakingPercent);
        }

        function _setFeePercents(uint256 charityFee, uint256 burnFee, uint256 marketingFee, uint256 stakeFee) external onlyOwner() {
             require(charityFee.add(burnFee).add(marketingFee).add(stakeFee) == 100, 'Fee percents must equal 100%');
             _charityFeePercent = charityFee;
             _burnFeePercent = burnFee;
             _marketingFeePercent = marketingFee;
             _stakingPercent = stakeFee;
        }

        function _setReactorFeePercents(uint256 feeReduction, uint256 charityFee, uint256 burnFee, uint256 marketingFee, uint256 stakeFee) external onlyOwner() {
             require(feeReduction < 100, 'Fee reduction must be less than 100%');
             require(charityFee.add(burnFee).add(marketingFee).add(stakeFee) == 100, 'Fee percents must equal 100%');
             _reactorValues.baseFeeReduction = feeReduction;
             _reactorValues.charityPercent = charityFee;
             _reactorValues.burnPercent = burnFee;
             _reactorValues.marketingPercent = marketingFee;
             _reactorValues.stakePercent = stakeFee;
        }

        function _setDaysForFeeReduction(uint256 daysForFeeReduction) external onlyOwner() {
            require(daysForFeeReduction >= 1, 'daysForFeeReduction needs to be at or above 1');
            _daysForFeeReduction = daysForFeeReduction;
        }

        function getMinSalesTaxRequiredToFeedReactor() public view returns (uint256) {
            return _minSalesTaxRequiredToFeedReactor;
        } 

        function _setMinSalesTaxRequiredToFeedReactor(uint256 salesPercent) external onlyOwner() {
            require(salesPercent >= 0 && salesPercent <= 100, 'minSalesTaxRequiredToFeedReactor must be between 0-100');
            _minSalesTaxRequiredToFeedReactor = salesPercent;
        }

        function _setMinDaysForReStake(uint256 minDaysForReStake) external onlyOwner() {
            require(minDaysForReStake >= 1, 'minDaysForReStake needs to be at or above 1');
            _minDaysForReStake = minDaysForReStake;
        }

        function _setMaxPercentOfStakeRewards(uint256 maxPercentOfStakeRewards) external onlyOwner() {
            require(maxPercentOfStakeRewards >= 1, 'minDaysForReStake needs to be at or above 1');
            _maxPercentOfStakeRewards = maxPercentOfStakeRewards;
        }

        
        function _setCharityWallet(address payable charityWalletAddress) external onlyOwner() {
            _charityAddress = charityWalletAddress;
        }

        function _setMarketingWallet(address payable marketingWalletAddress) external onlyOwner() {
            _marketingWallet = marketingWalletAddress;
        }
        
        function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
            require(maxTxAmount <= _tTotal , 'maxTxAmount should be less than total supply');
            _maxTxAmount = maxTxAmount;
        }
    }
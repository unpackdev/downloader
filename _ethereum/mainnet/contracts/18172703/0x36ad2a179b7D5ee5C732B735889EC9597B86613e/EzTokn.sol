// SPDX-License-Identifier: MIT

/*
    eeeeeeeeeeee    zzzzzzzzzzzzzzzzz
  ee::::::::::::ee  z:::::::::::::::z
 e::::::eeeee:::::eez::::::::::::::z 
e::::::e     e:::::ezzzzzzzz::::::z
e:::::::eeeee::::::e      z::::::z
e:::::::::::::::::e      z::::::z
e::::::eeeeeeeeeee      z::::::z
e:::::::e              z::::::z
e::::::::e            z::::::zzzzzzzz
 e::::::::eeeeeeee   z::::::::::::::z
  ee:::::::::::::e  z:::::::::::::::z
    eeeeeeeeeeeeee  zzzzzzzzzzzzzzzzz

EzTokn - Your premium no-code smart contract solution.

Website: https://eztokn.io/
App: https://app.eztokn.io/
Twitter: https://twitter.com/Ez_Tokn
Telegram: https://t.me/EzTokn
Docs: https://docs.eztokn.io/
*/

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";

contract EzTokn is ERC20("Ez Tokn", "EZ"), Ownable {
    
    using SafeMath for uint256;

    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_PAIR;

    uint256 constant MAX_SUPPLY = 100_000_000 ether;
    uint256 public launchBlock;

    bool private swapping;

    address public ezTreasuryWallet;
    address public ezMarketingWallet;

    bool public restrictiveLimitsActive = true;
    bool public fetchRate = true;
    bool public tradingActive;
    bool public swapEnabled;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public thresholdToLiquifyEth;

    uint256 public treasuryTaxRate;
    uint256 public marketingTaxRate;

    uint256 public totalBuyRate;
    uint256 public totalSellRate;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    event FeesExclusion(address indexed account, bool isExcluded);
    event MaxTxExclusion(address _address, bool excluded);
    event TokenLaunched(bool tradingActive);
    event RestrictiveLimitsDisabled();
    event UpdatedMaxTx(uint256 newAmount);
    event UpdatedMaxWalletLimit(uint256 newAmount);
    event UpdatedEzTreasuryWallet(address indexed newWallet);
    event UpdatedEzMarketingWallet(address indexed newWallet);

    constructor(address _ezMarketingWallet){

        _mint(msg.sender, MAX_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeMaxTx(address(UNISWAP_ROUTER), true);

        UNISWAP_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxTxAmount = MAX_SUPPLY.mul(15).div(1000);
        maxWalletAmount = MAX_SUPPLY.mul(20).div(1000);
        thresholdToLiquifyEth = MAX_SUPPLY.mul(60).div(10000);

        ezTreasuryWallet = msg.sender;
        ezMarketingWallet = _ezMarketingWallet;

        _excludeMaxTx(msg.sender, true);
        _excludeMaxTx(ezMarketingWallet, true);
        _excludeMaxTx(address(this), true);
        _excludeMaxTx(address(0xdead), true);
        excludeFees(msg.sender, true);
        excludeFees(ezMarketingWallet, true);
        excludeFees(address(this), true);
        excludeFees(address(0xdead), true);
    }
    receive() external payable {}

    /**
     * @dev Max transaction amount handler
     * WARNING: These limits disable post executing removeRestrictiveLimits function
     *
     * functionality:
     * - edits max transaction amount
     */
    function setMaxTxAmount(uint256 _newMaxTxAmount) external onlyOwner {
        require(
            _newMaxTxAmount >= MAX_SUPPLY.div(1000),
            "ERROR: Cannot set max tx amount lower than 0.1%"
        );
        maxTxAmount = _newMaxTxAmount;
        emit UpdatedMaxTx(maxTxAmount);
    }

    /**
     * @dev Max wallet balance amount handler
     * WARNING: These limits disable post executing removeRestrictiveLimits function
     *
     * functionality:
     * - edits max wallet balance allowed
     */
    function setMaxWalletLimit(uint256 newNum) external onlyOwner {
        require(
            newNum >= MAX_SUPPLY.mul(3).div(1000),
            "ERROR: Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum;
        emit UpdatedMaxWalletLimit(maxWalletAmount);
    }

    /**
     * @dev Liquify threshold handler
     *
     * functionality:
     * - edits threshold for swapBack function call
     */
    function setEthThresholdToLiquifyAmount(uint256 _newThreshold) external onlyOwner {
        require(
            _newThreshold >= MAX_SUPPLY.div(100_000),
            "ERROR: Threshold amount cannot be lower than 0.001% total supply."
        );
    
        thresholdToLiquifyEth = _newThreshold;
    }

    /**
     * @dev Liquify threshold handler
     * WARNING: This function is irreversible and cannot be undone
     * 
     * functionality:
     * - removes all wallet and transaction restrictions
     */
    function removeRestrictiveLimits() external onlyOwner {
        restrictiveLimitsActive = false;
        emit RestrictiveLimitsDisabled();
    }

    /**
     * @dev Exclude address from transaction limit handler
     * 
     * functionality:
     * - excludes wallet address from being subjected to transaction limits
     */
    function _excludeMaxTx(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTxExclusion(updAds, isExcluded);
    }

    /**
     * @dev Exclude address from transaction tax fees
     * 
     * functionality:
     * - excludes wallet address from being subjected to tax
     */
    function excludeFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit FeesExclusion(account, excluded);
    }

   /**
     * @dev Open trading handler
     * WARNING: This function is irreversible and cannot be undone
     * 
     * functionality:
     * - sets trading status to live for token to be available for swapping and transferring
     */
    function openTrading() public onlyOwner {
        require(launchBlock == 0, "ERROR: EzTokn trading status is already live !");
        launchBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit TokenLaunched(tradingActive);
    }

    /**
     * @dev Modify treasury admin wallet address
     * 
     * functionality:
     * - sets a new treasury admin wallet
     */
    function setTreasuryAdminWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "ERROR: Invalid wallet address");
        ezTreasuryWallet = payable(_newTreasuryWallet);
        emit UpdatedEzTreasuryWallet(_newTreasuryWallet);
    }

    /**
     * @dev Modify marketing admin wallet address
     * 
     * functionality:
     * - sets a new marketing admin wallet
     */
    function setMarketingAdminWallet(address _newMarketingWallet) external onlyOwner {
        require(_newMarketingWallet != address(0), "ERROR: Invalid wallet address");
        ezMarketingWallet = payable(_newMarketingWallet);
        emit UpdatedEzMarketingWallet(_newMarketingWallet);
    }

    /**
     * @dev Modify tax rate handler
     * 
     * functionality:
     * - sets a new treasury & marketing tax rate
     */
    function setTaxRates(uint256 _newMarketingRate, uint256 _newTreasuryRate) external onlyOwner {
        require(_newMarketingRate + _newTreasuryRate <= 100, "ERROR: Invalid percentage");
        treasuryTaxRate = _newTreasuryRate;
        marketingTaxRate = _newMarketingRate;
        totalBuyRate = _newTreasuryRate + _newMarketingRate;
        totalSellRate  = _newTreasuryRate + _newMarketingRate;
    }


    /**
     * @dev Fetches initial rate on launch
     * 
     * functionality:
     * - governs the initial 5 blocks to ensure security & protective measures
     */
    function getRate() internal {
        require(
            launchBlock > 0, "ERROR: Trading status inactive"
        );
        uint256 currentBlock = block.number;
        uint256 blockWatchGuard = launchBlock + 5;

        if(currentBlock <= blockWatchGuard) {
            totalBuyRate = 20;
            totalSellRate = 20;
            marketingTaxRate = 5;
            treasuryTaxRate =  15;
        } else {
            totalBuyRate = 4;
            totalSellRate = 4;
            marketingTaxRate = 1;
            treasuryTaxRate =  3;
            fetchRate = false;
        } 


    }

    /**
     * @dev Trading logic handler
     * 
     * functionality:
     * - governs trading
     * - enforces taxes
     * - enforces restrictive limits while enabled
     * - executes and handles fees and swaps
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (restrictiveLimitsActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] ||
                            _isExcludedMaxTransactionAmount[to],
                        " ERROR: Trading status is inactive"
                    );
                    require(from == owner(), " ERROR: Trading status is live");
                }

                //when buy
                if (
                    from == UNISWAP_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "ERROR: amount cannot exceed max tx"
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: amount cannot exceed max wallet"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "ERROR: amount cannot exceed max tx"
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: amount cannot exceed max wallet"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool swapCriteriaMet = contractTokenBalance >= thresholdToLiquifyEth;

        if (
            swapCriteriaMet &&
            swapEnabled &&
            !swapping &&
            !(from == UNISWAP_PAIR) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
    
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
    
        if (takeFee) {

            if(fetchRate){
               getRate(); 
            }
            if (to == UNISWAP_PAIR && totalSellRate > 0) {
                fees = amount.mul(totalSellRate).div(100);
            }
            else if (from == UNISWAP_PAIR && totalBuyRate > 0) {
                fees = amount.mul(totalBuyRate).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }


    /**
     * @dev Liquifies EZ to eth
     * 
     * functionality:
     * - executes swaps back to eth when criteria met and function called
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        // make the swap
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Performes swap back for tax payouts
     * 
     * functionality:
     * - calls swapTokensForEth
     * - handles allocation and distribution of tax proceeds
     */
    function swapBack() private {

        bool success;

        swapTokensForEth(thresholdToLiquifyEth);

        uint256 initEthBalance = address(this).balance;

        uint256 marketingEthAllocation = initEthBalance.mul(marketingTaxRate).div(totalSellRate);

        (success, ) = address(ezMarketingWallet).call{value: marketingEthAllocation}("");
        (success, ) = address(ezTreasuryWallet).call{value: address(this).balance}("");
    }

    /**
     * @dev Clears stuck tokens
     * 
     * functionality:
     * - calls back EZ from the contract address to clear stuck tokens
     */
    function rescueEz(address _token, uint256 amount) external {
        require(
            msg.sender == ezMarketingWallet || msg.sender == ezTreasuryWallet,
            "ERROR: This address is not authorized to call this function"
        );
        IERC20(_token).transfer(ezMarketingWallet, amount);
    }
    
    /**
     * @dev Clears stuck Eth
     * 
     * functionality:
     * - calls back Eth from the contract address to clear in an emergency scenario
     */
    function rescueEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "ERROR: failed to withdraw funds");
    }
    


}

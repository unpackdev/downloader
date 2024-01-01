// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ████████████
 */

import "./Ownable.sol";

import "./IUniswapV2Router02.sol";

import "./Payments.sol";

import "./CoinGenieERC20.sol";
import "./ICoinGenieERC20.sol";

/**
 * /// @title CoinGenie
 * /// @author @neuro_0x
 * /// @dev The orchestrator contract for the CoinGenie ecosystem.
 */
contract CoinGenie is Payments {
    /// @dev Struct to hold token details
    struct LaunchedToken {
        string name;
        string symbol;
        address tokenAddress;
        address payable feeRecipient;
        address payable affiliateFeeRecipient;
        uint256 index;
        uint256 totalSupply;
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
    }

    /// @dev Payout categories
    enum PayoutCategory {
        Treasury,
        Dev,
        Legal,
        Marketing
    }

    /// @dev Payouts
    struct Payout {
        address payable receiver;
        uint256 share;
    }

    /// @dev The address of the Uniswap V2 Router
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @dev The maximum percent in basis points that can be used as a discount
    uint256 private constant _MAX_BPS = 10_000;

    /// @dev The percent in basis points to use as coin genie fee
    uint256 private _coinGenieFeePercent = 100;

    /// @dev The percent in basis points to use as a discount if paying in $GENIE
    uint256 private _discountPercent = 5000;

    /// @dev The amount of $GENIE a person has to pay to get the discount
    uint256 private _discountFeeRequiredAmount = 100_000 ether;

    /// @dev A mapping of a payout category to a payout
    mapping(PayoutCategory category => Payout payout) private _payouts;

    /// @dev The array of launched token addresses
    address[] public launchedTokens;

    /// @dev The array of users
    address[] public users;

    /// @dev The array of created claimable airdrop addresses
    address[] public createdClaimableAirdrops;

    /// @dev A mapping of a token address to its details
    mapping(address token => LaunchedToken launchedToken) public launchedTokenDetails;

    /// @dev A mapping of a user to the tokens they have launched
    mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;

    /////////////////////////////////////////////////////////////////
    //                           Events                            //
    /////////////////////////////////////////////////////////////////

    /// @notice Emits when the discount percent is set
    /// @param percent - the percent in basis points to use as a discount
    event DiscountPercentSet(uint256 indexed percent);

    /// @notice Emits when the discount fee required amount is set
    /// @param amount - the amount of $GENIE a person has to hold to get the discount
    event DiscountFeeRequiredAmountSet(uint256 indexed amount);

    /// @notice Emitted when a token is launched
    /// @param newTokenAddress - the address of the new token
    /// @param tokenOwner - the address of the token owner
    event ERC20Launched(address indexed newTokenAddress, address indexed tokenOwner);

    /////////////////////////////////////////////////////////////////
    //                           Errors                            //
    /////////////////////////////////////////////////////////////////

    /// @notice Reverts when approving a token fails
    error ApprovalFailed();

    /// @notice Reverts when the caller is not a team member
    /// @param caller - the caller of the function
    error NotTeamMember(address caller);

    /// @notice Reverts when the share is too high
    /// @param share - the share amount
    /// @param maxShare - the max share amount
    error ShareToHigh(uint256 share, uint256 maxShare);

    /// @notice Reverts when the payout category is invalid
    /// @param category - the payout category
    error InvalidPayoutCategory(PayoutCategory category);

    /// @notice Reverts when the discount percent exceeds the max percent
    /// @param percent - the percent in basis points to use as a discount
    /// @param maxBps - the max percent in basis points
    error ExceedsMaxDiscountPercent(uint256 percent, uint256 maxBps);

    /// @notice Reverts when the coin genie fee percent exceeds the max percent
    /// @param percent - the percent in basis points to use as a fee
    /// @param maxBps - the max percent in basis points
    error ExceedsMaxFeePercent(uint256 percent, uint256 maxBps);

    /// @notice Construct the CoinGenie contract.
    constructor() payable {
        address[] memory payees = new address[](4);
        uint256[] memory shares_ = new uint256[](4);

        payees[0] = 0xBe79b43B1505290DFE04294a433963dbeea736BB; // treasury
        payees[1] = 0x3fB2120fc0CD15000d2e500Efbdd9CE17356E242; // dev
        payees[2] = 0xF14A30C09897d2C7481c5907D01Ec58Ec09555af; // marketing
        payees[3] = 0xbb6712A513C2d7F3E17A40d095a773c5d98574B2; // legal

        shares_[0] = 20;
        shares_[1] = 50;
        shares_[2] = 25;
        shares_[3] = 5;

        _createSplit(payees, shares_);
    }

    /////////////////////////////////////////////////////////////////
    //                      Public/External                        //
    /////////////////////////////////////////////////////////////////

    receive() external payable override {
        address from = _msgSender();
        // If we are receiving ETH from a Coin Genie token, then we need to send the affiliate fee
        if (launchedTokenDetails[from].tokenAddress == from) {
            address payable affiliate = launchedTokenDetails[from].affiliateFeeRecipient;
            uint256 affiliateAmount = (msg.value * _affiliateFeePercent) / _MAX_BPS;

            if (affiliateAmount != 0 && affiliate != address(0) && affiliate != address(this)) {
                _affiliatePayoutOwed += affiliateAmount;
                _amountReceivedFromAffiliate[affiliate] += msg.value;
                _amountOwedToAffiliate[affiliate] += affiliateAmount;
                _amountEarnedByAffiliateByToken[affiliate][from] += affiliateAmount;

                if (!_isTokenReferredByAffiliate[affiliate][from]) {
                    _isTokenReferredByAffiliate[affiliate][from] = true;

                    if (_tokensReferredByAffiliate[affiliate].length == 0) {
                        affiliates.push(affiliate);
                    }

                    _tokensReferredByAffiliate[affiliate].push(from);
                }
            }

            emit PaymentReceived(from, msg.value);
        } else {
            emit PaymentReceived(from, msg.value);
        }
    }

    /// @notice Gets the address of the $GENIE contract
    /// @return the address of the $GENIE contract
    function genie() public view returns (address payable) {
        return payable(launchedTokens[0]);
    }

    /// @notice Gets the percent in basis points to use as coin genie fee
    /// @return the percent in basis points to use as coin genie fee
    function coinGenieFeePercent() public view returns (uint256) {
        return _coinGenieFeePercent;
    }

    /// @notice Gets the discount percent
    /// @return the discount percent
    function discountPercent() external view returns (uint256) {
        return _discountPercent;
    }

    /// @notice Gets the discount fee required amount
    /// @return the discount fee required amount
    function discountFeeRequiredAmount() external view returns (uint256) {
        return _discountFeeRequiredAmount;
    }

    /// @notice Launch a new instance of the ERC20.
    /// @dev This function deploys a new token contract and initializes it with provided parameters.
    /// @param name - the name of the token
    /// @param symbol - the ticker symbol of the token
    /// @param totalSupply - the totalSupply of the token
    /// @param affiliateFeeRecipient - the address to receive the affiliate fee
    /// @param taxPercent - the percent in basis points to use as a tax
    /// @param maxBuyPercent - amount of tokens allowed to be transferred in one tx as a percent of the total supply
    /// @param maxWalletPercent - amount of tokens allowed to be held in one wallet as a percent of the total supply
    /// @return newToken  - the CoinGenieERC20 token created
    function launchToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address affiliateFeeRecipient,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent
    )
        external
        returns (ICoinGenieERC20 newToken)
    {
        address payable feeRecipient = payable(msg.sender);
        if (affiliateFeeRecipient == address(0)) {
            affiliateFeeRecipient = payable(address(this));
        }

        // Deploy the token contract
        newToken = new CoinGenieERC20(
            name,
            symbol,
            totalSupply,
            feeRecipient,
            payable(address(this)),
            payable(affiliateFeeRecipient),
            taxPercent,
            maxBuyPercent,
            maxWalletPercent,
            _discountFeeRequiredAmount,
            _discountPercent
        );

        // Add the user to the array of users
        if (tokensLaunchedBy[feeRecipient].length == 0) {
            users.push(feeRecipient);
        }

        // Add the token address to the array of launched token addresses
        launchedTokens.push(address(newToken));

        // Create a new LaunchedToken struct
        LaunchedToken memory launchedToken = LaunchedToken({
            index: launchedTokens.length - 1,
            tokenAddress: address(newToken),
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            feeRecipient: feeRecipient,
            affiliateFeeRecipient: payable(affiliateFeeRecipient),
            taxPercent: taxPercent,
            maxBuyPercent: maxBuyPercent,
            maxWalletPercent: maxWalletPercent
        });

        if (tokensLaunchedBy[feeRecipient].length != 0) {
            // If the token is not a new user, update the affiliateFeeRecipient to be their first one
            launchedToken.affiliateFeeRecipient = tokensLaunchedBy[feeRecipient][0].affiliateFeeRecipient;
        }

        // Add the token to the array of tokens launched by the fee recipient
        tokensLaunchedBy[feeRecipient].push(launchedToken);

        // Add the token details to the mapping of launched tokens
        launchedTokenDetails[address(newToken)] = launchedToken;

        // Set the genie token address
        newToken.setGenie(payable(launchedTokens[0]));

        // Set the coin genie fee percent
        newToken.setCoinGenieFeePercent(_coinGenieFeePercent);

        // Assign ownership to the fee recipient
        Ownable(address(newToken)).transferOwnership(feeRecipient);

        // Emit the event
        emit ERC20Launched(address(newToken), msg.sender);
    }

    /// @notice Gets the number of tokens that have been launched.
    function getNumberOfLaunchedTokens() external view returns (uint256) {
        return launchedTokens.length;
    }

    /// @notice Get the launched tokens.
    /// @param _address The address to get the tokens for
    /// @return tokens The array of launched tokens
    function getLaunchedTokensForAddress(address _address) external view returns (LaunchedToken[] memory tokens) {
        return tokensLaunchedBy[_address];
    }

    /// @notice Set the coin genie fee percent for tokens
    /// @param percent The percent in basis points to use as coin genie fee
    function setCoinGenieFeePercent(uint256 percent) external onlyOwner {
        if (percent > _MAX_BPS) {
            revert ExceedsMaxFeePercent(percent, _MAX_BPS);
        }

        _coinGenieFeePercent = percent;
    }

    /// @dev Allows the owner to set the percent in basis points to use as a discount
    /// @param percent - the percent in basis points to use as a discount
    function setDiscountPercent(uint256 percent) external onlyOwner {
        if (percent > _MAX_BPS) {
            revert ExceedsMaxDiscountPercent(percent, _MAX_BPS);
        }

        _discountPercent = percent;
        emit DiscountPercentSet(percent);
    }

    /// @dev Allows the owner to set the amount of $GENIE required to get the discount
    /// @param amount - the amount of $GENIE a person has to hold to get the discount
    function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner {
        _discountFeeRequiredAmount = amount;
        emit DiscountFeeRequiredAmountSet(amount);
    }

    /// @notice Swaps tokens for Ether.
    /// @dev Utilizes Uniswap for the token-to-ETH swap.
    /// @param tokenAmount The amount of tokens to swap for ETH.
    function swapGenieForEth(uint256 tokenAmount) external nonReentrant onlyOwner {
        ICoinGenieERC20 genieToken = ICoinGenieERC20(launchedTokens[0]);
        address[] memory path = new address[](2);
        path[0] = address(genieToken);
        path[1] = _UNISWAP_V2_ROUTER.WETH();
        genieToken.approve(address(_UNISWAP_V2_ROUTER), tokenAmount);
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }
}

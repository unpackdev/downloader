// SPDX-License-Identifier: UNLICENSED

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

pragma solidity ^0.8.6;

contract PublicSale is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Round{
        uint256 weiRaised;
        uint256 rate;
        uint256 totalBalance;
        uint256 remainingBalance;
        bool isActive;
        mapping(address => uint256) weiSpent;
    }

    // The token being sold
    IERC20 public _token;

    // To denote current round
    uint8 public _counter;

    Round[3] public round;

    IUniswapV2Router02 constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // Min amount per wallet
    uint256 private _minPerWallet = 0.01 ether;

    // Max amount per wallet
    uint256 private _maxPerWallet = 5 ether;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (IERC20 token) {
        _token = token;

        round[0].totalBalance = 2000000 * 10 ** 9;
        round[0].remainingBalance = round[0].totalBalance;

        round[1].totalBalance = 20000000 * 10 ** 9;
        round[1].remainingBalance = round[1].totalBalance;

        round[2].totalBalance = 36000000 * 10 ** 9;
        round[2].remainingBalance = round[2].totalBalance;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable {
        require(round[_counter].isActive,"Presale has not started yet or has ended.");

        uint256 weiAmount = msg.value;

        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(_counter, weiAmount);

        // update state
        round[_counter].weiRaised = round[_counter].weiRaised.add(weiAmount);
        round[_counter].weiSpent[beneficiary] += weiAmount;

        _token.transfer(beneficiary, tokens);

        round[_counter].remainingBalance = round[_counter].remainingBalance.sub(tokens);

        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function rate(uint8 rnd) public view returns (uint256) {
        return round[rnd].rate;
    }

    function weiRaised(uint8 rnd) public view returns (uint256) {
        return round[rnd].weiRaised;
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= _minPerWallet &&
                round[_counter].weiSpent[beneficiary] + weiAmount <= _maxPerWallet,
                "Crowdsale: Invalid purchase amount");
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint8 rnd, uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(round[rnd].rate).div(10**9);
    }

    // Start round of presale
    function startRound(uint256 weiRate) external onlyOwner{
        require(weiRate > 0, "Crowdsale: weiRate is 0");
        require(!round[_counter].isActive,"A round is already ongoing");
        require(_counter < 3,"No more than 3 rounds of presale");

        round[_counter].isActive = true;
        round[_counter].rate = weiRate;
    }

    // End round of presale and retrieve 25% for marketing and 10% for buy-back
    function endRound() external onlyOwner{
        require(round[_counter].isActive,"Round has not started yet");

        round[_counter].isActive = false;

        // 35% to owner wallet (25% marketing + 10% buy-back)
        uint256 marketing = round[_counter].weiRaised.mul(35).div(100); 

        payable(owner()).transfer(marketing);

        _counter++;
    }

    // We must check if we have enough remaining tokens on the wallet to reach set Uniswap listing price
    function checkRemainingTokensToTransfer(uint256 amount) external onlyOwner view returns (uint256) {
        require(_counter == 3,"Must be called after presale ends");

        uint256 tokenBalance = _token.balanceOf(address(this));

        // No need to add tokens
        if(tokenBalance >= amount)
            return 0;

        // Calculate how many tokens to send to smart contract
        uint256 tokenDifference = amount - tokenBalance;

        return tokenDifference;
    }

    /**
     * @dev Called after all rounds of presale have ended
     * @param amount Amount of tokens to be sent to Uniswap
     */
    function closeSaleAndAddLiquidity(uint256 amount) external onlyOwner {
        require(_counter == 3,"Must be called after presale ends");
        require(_token.balanceOf(address(this)) > amount,"Token balance does not cover Uniswap amount");

        uint256 contractBal = address(this).balance;
        uint256 remainingTokens = _token.balanceOf(address(this)) - amount;

        // Burn remaining tokens
        if(remainingTokens > 0)
            _token.transfer(address(0xdead), remainingTokens);

        round[0].totalBalance = 0;
        round[0].remainingBalance = 0;
        round[1].totalBalance = 0;
        round[1].remainingBalance = 0;
        round[2].totalBalance = 0;
        round[2].remainingBalance = 0;

        addLiquidity(amount, contractBal);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _token.approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(_token),
            tokenAmount,
            0, 
            0, 
            address(0xdead),
            block.timestamp + 300
        );
    }
}
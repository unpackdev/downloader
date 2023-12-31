//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IAggregatorV3.sol";

contract NBPresale is Ownable, ReentrancyGuard {
    // Allows interaction with deployed ETH Mainnet USDT contract
    using SafeERC20 for IERC20;

    bool public isPresaleActive = true;
    bool public isWithdrawingAllowed = false;

    uint256 public currentRound; // 0 = first round, 46 = last round
    uint256 public affiliateBonusPercentage;
    uint256 public minimumUsdtInvestment;

    uint256[] public tokenUnitPriceUsd; // scale is 100,000 ( 1 USD = 100,000)
    uint256[] public roundRewardPoolArray;

    uint256 public totalUsdtRaised;
    uint256 public totalTokensMinted;

    address public affiliateRewardAddress;
    address public usdtAddress;
    address public usdcAddress;

    mapping(address => uint256) public unclaimedBalance;
    mapping(address => uint256) public unclaimedRefferalBalance;
    mapping(uint256 => uint256) public amountRaisedInRound; // tokens

    IERC20 public token;
    IERC20 public usdt;
    IERC20 public usdc;

    IAggregatorV3 internal priceFeed;

    event TokensPurchased(
        address indexed buyer,
        uint256 usdAmount,
        uint256 tokenAmount
    );

    event TokensClaimed(address indexed buyer, uint256 tokenAmount);

    event ETHSurplusRefunded(uint256 ethAmount);

    /**
     * @dev Constructor functions, called once when contract is deployed
     */

    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _affiliateRewardAddress,
        uint256 _affiliateBonusPercentage,
        uint256 _minimumUsdtInvestment,
        uint256[] memory _tokenUnitPriceUsd,
        uint256[] memory _roundRewardPoolArray,
        address _priceFeedAddress
    ) {
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        usdc = IERC20(_usdcAddress);
        affiliateRewardAddress = _affiliateRewardAddress;
        affiliateBonusPercentage = _affiliateBonusPercentage;
        minimumUsdtInvestment = _minimumUsdtInvestment;
        tokenUnitPriceUsd = _tokenUnitPriceUsd;
        roundRewardPoolArray = _roundRewardPoolArray;
        priceFeed = IAggregatorV3(_priceFeedAddress);
    }

    /**
     * @dev Changes the contract settings
     * @param _tokenAddress The address of the token contract (NET)
     * @param _usdtAddress The address of the USDT contract
     * @param _usdcAddress The address of the USDC contract
     * @param _affiliateRewardAddress The address of the affiliate reward contract from where the rewards are sent from
     * @param _affiliateBonusPercentage The percentage of the affiliate bonus
     * @param _minimumUsdtInvestment The minimum amount of USDT that can be invested
     * @param _tokenUnitPriceUsd The price of the token in USD (scale is 100,000)
     * @param _roundRewardPoolArray The reward pool for each round (wei)
     * @param _priceFeedAddress The address of the Chainlink price feed
     */
    function changeContractSettings(
        address _tokenAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _affiliateRewardAddress,
        uint256 _affiliateBonusPercentage,
        uint256 _minimumUsdtInvestment,
        uint256[] memory _tokenUnitPriceUsd,
        uint256[] memory _roundRewardPoolArray,
        address _priceFeedAddress
    ) public onlyOwner {
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        usdc = IERC20(_usdcAddress);
        affiliateRewardAddress = _affiliateRewardAddress;
        affiliateBonusPercentage = _affiliateBonusPercentage;
        minimumUsdtInvestment = _minimumUsdtInvestment;
        tokenUnitPriceUsd = _tokenUnitPriceUsd;
        roundRewardPoolArray = _roundRewardPoolArray;
        priceFeed = IAggregatorV3(_priceFeedAddress);
    }

    /**
     * @dev Get the ETH price in USD from the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Reduce the scale from 8 decimals to 6 decimals
        return uint256(price) / 100;
    }

    /**
     * @dev Convert ETH to USD using the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function convertEthToUsd(
        uint256 ethIn
    ) public view returns (uint256 usdOut) {
        uint256 ethPrice = getEthPrice(); //6 digits
        usdOut = ((ethIn / 1e12) * ethPrice) / 1e6;
        return usdOut;
    }

    /**
     * @dev Convert USD to ETH using the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function convertUsdToEth(
        uint256 usdIn
    ) public view returns (uint256 ethOut) {
        uint256 ethPrice = getEthPrice();
        // The output of this result is in 6 decimals, convert it to 18 decimals
        ethOut = ((usdIn * 1e6) / ethPrice) * 10 ** 12;
        return ethOut;
    }

    /**
     * @dev Enables or disables the presale
     * @param _isPresaleActive Whether the presale is active or not
     */
    function setPresaleActive(bool _isPresaleActive) public onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    /**
     * @dev Gets the current round price in USD, scale is 100,000 ( 1 USD = 100,000)
     * @return uint256 The current round price in USD
     */
    function getCurrentRoundPrice() public view returns (uint256) {
        return tokenUnitPriceUsd[currentRound];
    }

    /**
     * @dev Gets whether the current round is the last round
     * @return bool
     */
    function isLastRound() public view returns (bool) {
        return currentRound + 1 == roundRewardPoolArray.length;
    }

    /**
     * @dev Set whether withdrawing is allowed or not.
     * @notice Also hides claiming buttons from the UI
     * @param _isWithdrawingAllowed Whether withdrawing is allowed or not
     * @return bool Whether withdrawing is allowed or not
     */
    function setIsWithdrawingAllowed(
        bool _isWithdrawingAllowed
    ) public onlyOwner returns (bool) {
        isWithdrawingAllowed = _isWithdrawingAllowed;
        return isWithdrawingAllowed;
    }

    /**
     * @dev Gets the amount of tokens you will get for a given amount of USDT in a given round
     * @param usdtIn The amount of USDT which goes in
     * @param roundIndex The round index
     * @return uint256 The amount of tokens you will get
     */
    function getTokenRewardForUsdtInRound(
        uint256 usdtIn,
        uint256 roundIndex
    ) internal view returns (uint256) {
        return (usdtIn * 100000) / tokenUnitPriceUsd[roundIndex];
    }

    /**
     * @dev Gets the amount of USDT you will get for a given amount of tokens in a given round
     * @param tokens The amount of tokens which goes in
     * @param roundIndex The round index
     * @return uint256 The amount of USDT you will get
     */
    function getUsdtValueForTokens(
        uint256 tokens,
        uint256 roundIndex
    ) internal view returns (uint256) {
        return (tokens * tokenUnitPriceUsd[roundIndex]) / 100000;
    }

    /**
     * @dev Processes (registers) an amount of tokens in the contract (also distributes bonus)
     * @param tokensToMint The amount of tokens to mint
     * @param usdtIn The amount of USDT which goes in
     * @param refferal The address of the refferal
     * @param userWallet The address of the user wallet which buys the tokens
     */
    function processTokens(
        uint256 tokensToMint,
        uint256 usdtIn,
        address refferal,
        address userWallet
    ) internal {
        // Calculate the bonus
        if (refferal != address(0)) {
            // Calculate 20% percent of the tokens to mint
            uint256 tokensToMintBonus = (tokensToMint *
                affiliateBonusPercentage) / 100;
            unclaimedRefferalBalance[refferal] += tokensToMintBonus;
        }

        unclaimedBalance[userWallet] += tokensToMint;
        totalUsdtRaised += usdtIn;
        amountRaisedInRound[currentRound] += tokensToMint;
        totalTokensMinted += tokensToMint;

        emit TokensPurchased(userWallet, usdtIn, tokensToMint);
    }

    /**
     * @dev Does all the requires checks and processes the token buying
     * @notice This function is called by the buyTokensXXX functions
     * @notice Also moves into next round when needed
     * @param currency The currency used to buy tokens, IERC20(address(0)) for ETH (for ETH surplus refunding)
     * @param usdtIn The amount of USDT which goes in
     * @param refferal The address of the refferee (if any), address(0) if none
     * @param userWallet The address of the user's wallet which buys the tokens
     */
    function initializeTokenBuying(
        IERC20 currency,
        uint256 usdtIn,
        address refferal,
        address userWallet
    ) internal {
        require(isPresaleActive, "Presale has not started yet");

        require(usdtIn > 0, "Investment is 0");

        require(
            currentRound < roundRewardPoolArray.length,
            "Presale has ended"
        );

        require(
            usdtIn >= minimumUsdtInvestment,
            "Investment is less than minimum"
        );

        require(
            userWallet != refferal,
            "Refferal cannot be the same as the user"
        );

        // Calculate tokens to mint
        uint256 tokensRewardForSentUsdt = getTokenRewardForUsdtInRound(
            usdtIn,
            currentRound
        );

        uint256 currentRemainingTokensInRound = roundRewardPoolArray[
            currentRound
        ] - amountRaisedInRound[currentRound];

        // Reward for user is less than remaining tokens in round, so we don't need to move to next round
        if (tokensRewardForSentUsdt < currentRemainingTokensInRound) {
            processTokens(
                tokensRewardForSentUsdt,
                usdtIn,
                refferal,
                userWallet
            );
        } else if (
            tokensRewardForSentUsdt > currentRemainingTokensInRound &&
            currentRound + 1 == roundRewardPoolArray.length
        ) {
            // Reward for user is more than the remaining tokens in round, but we are in the last round, so we reward all the tokens remaining and don't move to the next round
            uint256 satisifableTokenAmount = currentRemainingTokensInRound;
            uint256 satisifableTokenAmountUsd = getUsdtValueForTokens(
                satisifableTokenAmount,
                currentRound
            );

            processTokens(
                satisifableTokenAmount,
                satisifableTokenAmountUsd,
                refferal,
                userWallet
            );

            uint256 surplusUsd = usdtIn - satisifableTokenAmountUsd;

            // Get the address of the currency contract
            address currencyAddress = address(currency);

            if (currencyAddress == address(0)) {
                // If currencyAddress is address(0), the currency is ETH, we need to refund the surplus in ETH
                uint256 ethSurplus = convertUsdToEth(surplusUsd);
                (bool sent, ) = payable(userWallet).call{value: ethSurplus}("");
                require(sent, "Failed to send Ether surplus");

                emit ETHSurplusRefunded(ethSurplus);
            } else {
                // Refund the surplus in the currency picked
                currency.safeTransfer(userWallet, surplusUsd);
            }
            isPresaleActive = false;
        }
        // Reward for user is more than the remaining tokens in round, so we reward all the tokens remaining and move the others to the new round at the new rate
        else {
            uint256 satisifableTokenAmount = currentRemainingTokensInRound;
            uint256 satisifableTokenAmountUsd = getUsdtValueForTokens(
                satisifableTokenAmount,
                currentRound
            );

            uint256 surplusUsd = usdtIn - satisifableTokenAmountUsd;

            processTokens(
                satisifableTokenAmount,
                satisifableTokenAmountUsd,
                refferal,
                userWallet
            );

            currentRound += 1;

            // Start the process again with the surplus
            initializeTokenBuying(currency, surplusUsd, refferal, userWallet);
        }
    }

    /**
     * @dev Buys tokens with USDT, intialises buying process
     * @param usdtIn The amount of USDT to buy tokens with
     * @param refferal The address of the refferee (if any), address(0) if none
     */
    function buyTokensUSDT(uint256 usdtIn, address refferal) external {
        // Transfer the USDT to the contract
        usdt.safeTransferFrom(msg.sender, address(this), usdtIn);
        initializeTokenBuying(usdt, usdtIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with USDC, intialises buying process
     * @param usdcIn The amount of USDC to buy tokens with
     * @param refferal The address of the refferee (if any), address(0) if none
     */
    function buyTokensUSDC(uint256 usdcIn, address refferal) external {
        // Transfer the USDT to the contract
        usdc.safeTransferFrom(msg.sender, address(this), usdcIn);
        initializeTokenBuying(usdc, usdcIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with ETH, intialises buying process
     * @param refferal The address of the refferee (if any), address(0) if none
     * @notice The ETH sent is transformed (not swapped) to USDT and then used to buy tokens
     */
    function buyTokensETH(address refferal) external payable {
        uint256 usdtIn = convertEthToUsd(msg.value);
        initializeTokenBuying(IERC20(address(0)), usdtIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with Fiat, intialises buying process. Since when buying with Fiat transaction is Originating from Wert.io, msg.sender is Wert.io, so we need to pass the userWallet address
     * @param refferal The address of the refferee (if any), address(0) if none
     * @notice The ETH sent is transformed (not swapped) to USDT and then used to buy tokens
     */
    function buyTokensFiat(
        address userWallet,
        address refferal
    ) external payable {
        uint256 usdtIn = convertEthToUsd(msg.value);
        initializeTokenBuying(IERC20(address(0)), usdtIn, refferal, userWallet);
    }

    /**
     * @dev Claims tokens after the presale has ended
     * @notice The tokens are claimed to the address which bought them
     */
    function claimTokens() public nonReentrant {
        require(unclaimedBalance[msg.sender] > 0, "No tokens to claim");

        require(isWithdrawingAllowed, "Withdrawals are not allowed yet");

        uint256 tokensToClaim = unclaimedBalance[msg.sender];
        unclaimedBalance[msg.sender] = 0;

        token.safeTransfer(msg.sender, tokensToClaim);

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    /**
     * @dev Claims the refferal (affiliate) tokens after the presale has ended
     * @notice The tokens are claimed to the address which bought them
     */
    function claimRefferalTokens() public nonReentrant {
        require(unclaimedRefferalBalance[msg.sender] > 0, "No tokens to claim");

        require(isWithdrawingAllowed, "Withdrawals are not allowed yet");

        uint256 tokensToClaim = unclaimedRefferalBalance[msg.sender];
        unclaimedRefferalBalance[msg.sender] = 0;

        token.safeTransferFrom(
            affiliateRewardAddress,
            msg.sender,
            tokensToClaim
        );

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    /**
     * @dev Withdraw ETH from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawEth() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Withdraw USDC from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawUsdc() public onlyOwner nonReentrant {
        uint256 balance = usdc.balanceOf(address(this));
        usdc.safeTransfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw USDT from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawUsdt() public onlyOwner nonReentrant {
        uint256 balance = usdt.balanceOf(address(this));
        usdt.safeTransfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw NET from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawNet() public onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
    }
}

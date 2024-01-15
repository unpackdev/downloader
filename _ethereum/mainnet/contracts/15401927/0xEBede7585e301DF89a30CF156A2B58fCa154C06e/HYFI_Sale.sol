// SPDX-License-Identifier: Apache-2.0
/**
 * Created on 2022-07-13 19:10
 * @summary:
 * @author: tata
 */
pragma solidity ^0.8.12;

import "./IHYFI_PriceCalculator.sol";
import "./IHYFI_Referrals.sol";
import "./IHYFI_Presale.sol";
import "./IHYFI_Vault.sol";
import "./IHYFI_OfflineReservationsForSale.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @title HYFI Sale smart contract
 * @dev The implementation of HYFI sale stage functionality
 * that handles buying and claiming process of vault tickets
 */
contract HYFI_Sale is Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IHYFI_OfflineReservationsForSale public offline;
    IHYFI_PriceCalculator public calc;
    IHYFI_Referrals public referrals;
    IHYFI_Vault public vault;
    IHYFI_Presale public presale;

    mapping(address => BuyerData) buyerInfo;
    mapping(address => uint256) claimed;

    uint256 public startTime;
    uint256 public totalUnitAmount;
    uint256 public totalAmountSold;
    address internal collectorWallet;
    address[] internal _buyersAddressList;
    bool public saleEnded;

    struct BuyerData {
        uint256 totalAmountBought;
        uint256 referralAmountBought;
        mapping(uint256 => uint256) referrals;
        uint256[] referralsList;
    }

    event AllUnitsSold(uint256 unitAmount);
    event CurrencyWithdrawn(address from, address to, uint256 amount);
    event ERC20Withdrawn(
        address from,
        address to,
        uint256 amount,
        address tokenAddress
    );
    event FundsRetrieved(address addr, uint256 amount);
    event UnitSold(
        address buyer,
        string token,
        uint256 amount,
        uint256 referral
    );
    event VaultsClaimed(address user, uint256 amount);
    event VaultsMinted(address to, uint256 amount);
    event SaleEndedUpdated(bool saleEnded);

    modifier addressNotZero(address addr) {
        require(
            addr != address(0),
            "Passed parameter has zero address declared"
        );
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount > 0, "Passed amount is equal to zero");
        _;
    }

    modifier ongoingSale() {
        require(
            block.timestamp >= startTime,
            "You can not buy any units, sale has not started yet"
        );
        require(!saleEnded, "You can no longer buy any units, sale is ended");
        _;
    }

    modifier possiblePurchaseUntilHardcap(uint256 amount) {
        require(
            totalAmountSold + amount <= totalUnitAmount,
            "Hardcap is reached, can not buy that many units"
        );
        _;
    }

    modifier canClaim(address user) {
        require(
            _availableForClaim(user) > 0,
            "You have not bought any units in order to claim or claimed all purchased units"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Initializer, used instead of constructor in the upgradable approach
     * @param _priceCalculatorContractAddress address of the PriceCalculator contract
     * @param _referralsContractAddress address of the Referrals contract
     * @param _presaleContractAddress address of the Presale contract
     * @param _vaultContractAddress address of the Vault NFT contract
     * @param _collectorWallet address of the wallet which assets are transfered to, normally should be multisig wallet
     * @param _startTime timestamp of sale start
     * @param _totalUnitAmount the total number of vault tickets available for sale during sale stage
     */
    function initialize(
        address _priceCalculatorContractAddress,
        address _referralsContractAddress,
        address _presaleContractAddress,
        address _vaultContractAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _totalUnitAmount
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        calc = IHYFI_PriceCalculator(_priceCalculatorContractAddress);
        referrals = IHYFI_Referrals(_referralsContractAddress);
        presale = IHYFI_Presale(_presaleContractAddress);
        vault = IHYFI_Vault(_vaultContractAddress);
        collectorWallet = _collectorWallet;
        startTime = _startTime;
        totalUnitAmount = _totalUnitAmount;
    }

    /**
     * @dev purchase of Vault tickets using erc-20 tokens - USDT, USDC, HYFI
     * @param token the name of the erc-20 token, can be USDT or USDC
     * @param buyWithHYFI marker is purchase is done with HYFI tokens, if yes, 50% is paid with token (USDT/USDC) and 50% with HYFI
     * @param amount the amount of Vault tickets user is going to to buy
     * @param referralCode the string of the referral code presented as integer
     */
    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        uint256 referralCode
    )
        external
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        require(
            keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDT")) ||
                keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDC")),
            "No stable coin provided"
        );
        uint256 discount = calc.discountPercentageCalculator(
            amount,
            msg.sender,
            1
        );
        if (buyWithHYFI) {
            _buyWithHYFIToken(token, amount, discount, referralCode);
            _updateData("HYFI", amount, msg.sender, referralCode);
        } else {
            _buyWithMainToken(token, amount, discount, referralCode);
            _updateData(token, amount, msg.sender, referralCode);
        }
        _mintVaults(msg.sender, amount);
    }

    /**
     * @dev purchase of Vault tickets using ether
     * @param amount the amount of Vault tickets user is going to to buy
     * @param referralCode the string of the referral code presented as integer
     */
    function buyWithCurrency(uint256 amount, uint256 referralCode)
        external
        payable
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        _buyWithCurrency(
            amount,
            calc.discountPercentageCalculator(amount, msg.sender, 1),
            referralCode
        );
        _updateData("ETH", amount, msg.sender, referralCode);
        _mintVaults(msg.sender, amount);
    }

    /**
     * @dev claiming of Vault tickets reserved beforehand on presale or offline
     */
    function claimVaults()
        external
        virtual
        addressNotZero(msg.sender)
        canClaim(msg.sender)
        ongoingSale
    {
        uint256 _claimAmount;
        _claimAmount = _availableForClaim(msg.sender);
        _claim(msg.sender, _claimAmount);
    }

    /**
     * @dev withdraw the stuck ether from the contract
     * @param recipient address of the recipient
     * @param amount the amount of ether for withdrawal
     */
    function withdrawCurrency(address recipient, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            address(this).balance >= amount,
            "Contract does not have enough currency"
        );
        (bool success, ) = payable(recipient).call{gas: 200_000, value: amount}(
            ""
        );
        require(success);
        emit CurrencyWithdrawn(recipient, msg.sender, amount);
    }

    /**
     * @dev withdraw the stuck erc-20 tokens from the contract
     * @param tokenAddress the address of the erc-20 token
     * @param recipient address of the recipient
     * @param amount the amount of ether for withdrawal
     */
    function withdrawERC20Tokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= amount,
            "Contract does not have enough ERC20 tokens"
        );
        IERC20Upgradeable(tokenAddress).safeTransfer(recipient, amount);

        emit ERC20Withdrawn(
            recipient,
            msg.sender,
            amount,
            address(tokenAddress)
        );
    }

    /**
     * @dev set the new start time of the sale stage
     * @param newStartTime the new start time of the sale stage
     */
    function setStartTime(uint256 newStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTime = newStartTime;
    }

    /**
     * @dev set the new total amount of Vault tickets on the sale stage
     * @param newAmount the new amount of tickets
     */
    function setTotalUnitAmount(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        totalUnitAmount = newAmount;
    }

    /**
     * @dev set the new collector address
     * @param newCollector the new collector address
     */
    function setCollectorWalletAddress(address newCollector)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        collectorWallet = newCollector;
    }

    /**
     * @dev set the new PriceCalculator address
     * @param newOfflineReservations the new OfflineReservations contract address
     */
    function setOfflineReservationsAddress(address newOfflineReservations)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        offline = IHYFI_OfflineReservationsForSale(newOfflineReservations);
    }

    /**
     * @dev set the new PriceCalculator address
     * @param newPriceCalculator the new PriceCalculator address
     */
    function setPriceCalculatorAddress(address newPriceCalculator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        calc = IHYFI_PriceCalculator(newPriceCalculator);
    }

    /**
     * @dev set the new ReferralCalculator address
     * @param newReferral the new Referral address
     */
    function setReferralAddress(address newReferral)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrals = IHYFI_Referrals(newReferral);
    }

    /**
     * @dev set the new Presale smart contracts address
     * @param newPresale the new Presale address
     */
    function setPresaleAddress(address newPresale)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presale = IHYFI_Presale(newPresale);
    }

    /**
     * @dev set the new Vault NFT smart contracts address
     * @param newVault the new Vault address
     */
    function setVaultAddress(address newVault)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vault = IHYFI_Vault(newVault);
    }

    /**
     * @dev set the marker if the sale stage is ended
     * @param ended true if the sale is ended
     */
    function setSaleEnded(bool ended) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleEnded = ended;
        emit SaleEndedUpdated(saleEnded);
    }

    /**
     * @dev get buyer data
     * @param user address of the buyer
     * @return user total amount of units purchased,
     *         user total amount of units purchased using referraal codes,
     *         user used referral code list
     */
    function getBuyerData(address user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            buyerInfo[user].totalAmountBought,
            buyerInfo[user].referralAmountBought,
            buyerInfo[user].referralsList
        );
    }

    /**
     * @dev get the number of referral codes used by the user during sale stage
     * @param user buyer address
     * @param referral used referral code
     * @return how many times the referral code is used by the user
     */
    function getBuyerReferralData(address user, uint256 referral)
        external
        view
        returns (uint256)
    {
        return buyerInfo[user].referrals[referral];
    }

    /**
     * @dev get the total amount of buyers during sale stage
     * @return total number of buyers
     */

    function getTotalAmountOfBuyers() external view returns (uint256) {
        return (_buyersAddressList.length);
    }

    /**
     * @dev get the array of buyers during sale stage
     * @return array of buyers addresses
     */
    function getAllBuyers() external view returns (address[] memory) {
        return (_buyersAddressList);
    }

    /**
     * @dev get the total number of already claimed Vaults by the user
     * @param user the user address
     * @return total number of claimed Vault tickets
     */
    function getClaimed(address user) external view returns (uint256) {
        return claimed[user];
    }

    /**
     * @dev get the total number of available Vault tickets for the claim
     * is calculated in the way: (totally reserved on presale + offline) - claimed in total
     * @param user the user address
     * @return total number tickets available for claiming
     */
    function getAvailableForClaim(address user)
        external
        view
        returns (uint256)
    {
        return _availableForClaim(user);
    }

    /**
     * @dev get the total number of reserved Vault tickets during presale stage + offline
     * @param user the user address
     * @return total number of reserved Vault tickets
     */
    function getTotalReservedAmount(address user)
        external
        view
        returns (uint256)
    {
        return _totalReservedAmount(user);
    }

    /**
     * @dev the processor of buying Vault tickets with main tokens (USDT/USDC)
     * @param token the token name (USDT or USDC)
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithMainToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.simpleTokenPaymentCalculator(
            token,
            unitAmount,
            discount,
            referralCode
        );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData(token).tokenAddress),
            priceTotal
        );
    }

    /**
     * @dev the processor of buying Vault tickets with 50%/50% main tokens (USDT/USDC) / HYFI tokens
     * @param token the token name (USDT or USDC)
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithHYFIToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 HYFItokenPayment;
        uint256 stableCoinPaymentAmount;
        (stableCoinPaymentAmount, HYFItokenPayment) = calc
            .mixedTokenPaymentCalculator(
                token,
                unitAmount,
                discount,
                referralCode
            );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData(token).tokenAddress),
            stableCoinPaymentAmount
        );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData("HYFI").tokenAddress),
            HYFItokenPayment
        );
    }

    /**
     * @dev the processor of transfering erc-20 tokens from the buyer to collector
     * @param tokenAddress erc-20 token address
     * @param priceTotal the amount of erc-20 tokens which should be transferred
     */
    function _buyWithERC20(IERC20Upgradeable tokenAddress, uint256 priceTotal)
        internal
        virtual
    {
        require(
            tokenAddress.balanceOf(msg.sender) >= priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        tokenAddress.safeTransferFrom(msg.sender, collectorWallet, priceTotal);
    }

    /**
     * @dev the processor of buying Vault tickets with ether
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithCurrency(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.currencyPaymentCalculator(
            unitAmount,
            discount,
            referralCode
        );
        require(
            msg.value == priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        (bool success, ) = payable(collectorWallet).call{
            gas: 200_000,
            value: priceTotal
        }("");
        require(success);
    }

    /**
     * @dev the processor for updating storage variables after purchase
     * it updates buyer information, and calls referral code information update
     * @param token the token name (USDT or USDC or HYFI (if is bought with 50/50 scheme) or ETH)
     * @param unitAmount the amount of bought tickets
     * @param buyer the user address
     * @param referralCode the referral code used in purchase
     */
    function _updateData(
        string memory token,
        uint256 unitAmount,
        address buyer,
        uint256 referralCode
    ) internal virtual {
        totalAmountSold += unitAmount;
        calc.setAmountBoughtWithReferral(token, unitAmount);
        if (buyerInfo[buyer].totalAmountBought == 0) {
            _buyersAddressList.push(buyer);
        }
        buyerInfo[buyer].totalAmountBought += unitAmount;
        if (totalAmountSold >= totalUnitAmount) {
            saleEnded = true;
            emit AllUnitsSold(unitAmount);
        }
        if (referralCode != 0) {
            _updateReferral(unitAmount, referralCode, buyer);
        }
        emit UnitSold(buyer, token, unitAmount, referralCode);
    }

    /**
     * @dev the processor for updating storage variables related to referral code after purchase
     * it updates buyer information referral code used, and calls referral code information update
     * @param unitAmount the amount of bought tickets
     * @param referralCode the referral code used in purchase
     * @param buyer the user address
     */
    function _updateReferral(
        uint256 unitAmount,
        uint256 referralCode,
        address buyer
    ) internal virtual {
        /* If the buyer has yet to buy any units using this referral code,
           add the code to the buyer referral list (which referral codes did they use) */
        if (buyerInfo[buyer].referrals[referralCode] == 0) {
            buyerInfo[buyer].referralsList.push(referralCode);
        }
        // Add bought unit amount corresponding to the referral used  during the purchase
        buyerInfo[buyer].referrals[referralCode] += unitAmount;
        referrals.updateAmountBoughtWithReferral(referralCode, unitAmount);
        // Add to the total amount bought using referral code
        buyerInfo[buyer].referralAmountBought += unitAmount;
    }

    /**
     * @dev the processor of claiming Vault tickets, updates the total number of claimed tickets by the user and mints Vault NFTs
     * @param user the claimer address
     * @param unitAmount the amount of tickets user is going to claim
     */
    function _claim(address user, uint256 unitAmount) internal {
        claimed[user] = claimed[user] + unitAmount;
        _mintVaults(user, unitAmount);
        emit VaultsClaimed(user, unitAmount);
    }

    /**
     * @dev processor of minting Vault NFTs (tickets)
     * @param user the address the NFT Vault should be mint to
     * @param unitAmount the amount of Vault tickets to mint
     */
    function _mintVaults(address user, uint256 unitAmount) internal {
        vault.safeMint(user, unitAmount);
        emit VaultsMinted(user, unitAmount);
    }

    /**
     * @dev internal method which gets the total number of available Vault tickets for the claim
     * is calculated in the way: (totally reserved on presale + offline) - claimed in total
     * @param user the user address
     * @return total number of available for claim Vault tickets
     */
    function _availableForClaim(address user) internal view returns (uint256) {
        return _totalReservedAmount(user) - claimed[user];
    }

    /**
     * @dev the internal method which gets the total number of reserved Vault tickets during presale stage + offline
     * @param user the user address
     * @return total number of reserved Vault tickets
     */
    function _totalReservedAmount(address user)
        internal
        view
        returns (uint256)
    {
        uint256 totalAmountBought = presale.getBuyerReservedAmount(user);
        if (address(offline) != address(0)) {
            totalAmountBought =
                totalAmountBought +
                offline.getBuyerReservedAmount(user);
        }
        return totalAmountBought;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ITokenManagerSelector.sol";
import "./IPriceCalculatorManager.sol";
import "./ITokenManager.sol";
import "./IPriceCalculator.sol";
import "./ICollectionsRegistry.sol";
import "./IDroppingNowToken.sol";
import "./IDropperToken.sol";
import "./HashHelper.sol";

contract DroppingNowMarketplace is Ownable, Pausable {
    bytes32 public immutable DOMAIN_SEPARATOR;
    
    ITokenManagerSelector public tokenManagerSelector;
    IPriceCalculatorManager public priceCalculatorManager;
    IDroppingNowToken public droppingNowToken;
    IDropperToken public dropperToken;
    ICollectionsRegistry public collectionsRegistry;
    address public saleRewardRecipient;
    address public dropRewardRecipient;
    address public dropRewardEscrowRecipient;
    uint256 public dropperFee;
    uint256 public marketplaceFee;
    uint256 public minItemPriceForDN;

    mapping (bytes32 => bool) private _auctions;

    event NewTokenManagerSelector(address indexed tokenManagerSelector);
    event NewPriceCalculatorManager(address indexed priceCalculatorManager);
    event NewDroppingNowToken(address indexed droppingNowToken);
    event NewDropperToken(address indexed dropperToken);
    event NewSaleRewardRecepient(address indexed saleRewardRecepient);
    event NewDropRewardRecepient(address indexed dropRewardRecepient);
    event NewDropRewardEscrowRecepient(address indexed dropRewardEscrowRecepient);
    event NewDropperFee(uint256 dropperFee);
    event NewMarketplaceFee(uint256 marketplaceFee);
    event NewMinItemPriceForDN(uint256 minItemPriceForDN);

    event SingleAuctionCreated(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string description
    );

    event BundleAuctionCreated(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string name,
        string description
    );

    event SingleSale(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address buyer,
        address priceCalculator,
        uint256 price
    );

    event BundleSale(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        address buyer,
        address priceCalculator,
        uint256 price
    );

    event SingleAuctionCanceled(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address priceCalculator
    );

    event BundleAuctionCanceled(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        address priceCalculator
    );

    constructor(
        address tokenManagerSelectorAddress,
        address priceCalculatorManagerAddress,
        address droppingNowTokenAddress,
        address dropperTokenAddress,
        address collectionsRegistryAddress,
        address saleRewardRecipientAddress,
        address dropRewardRecipientAddress,
        address dropRewardEscrowRecipientAddress,
        uint256 dropperFeeValue,
        uint256 marketplaceFeeValue,
        uint256 minItemPriceForDNValue
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xc94add498610ef8f6b104cb561856491569d6e3bb6f1dd4762b8f7a04dc69952, // keccak256("DroppingNowMarketplace")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        tokenManagerSelector = ITokenManagerSelector(tokenManagerSelectorAddress);
        priceCalculatorManager = IPriceCalculatorManager(priceCalculatorManagerAddress);
        droppingNowToken = IDroppingNowToken(droppingNowTokenAddress);
        dropperToken = IDropperToken(dropperTokenAddress);
        collectionsRegistry = ICollectionsRegistry(collectionsRegistryAddress);
        saleRewardRecipient = saleRewardRecipientAddress;
        dropRewardRecipient = dropRewardRecipientAddress;
        dropRewardEscrowRecipient = dropRewardEscrowRecipientAddress;
        dropperFee = dropperFeeValue;
        marketplaceFee = marketplaceFeeValue;
        minItemPriceForDN = minItemPriceForDNValue;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function createSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string calldata description
    ) external whenNotPaused {
        _createSingleAuction(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice,
            priceCalculator,
            description);
    }

    function createMultipleSingleAuctions(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata listOns,
        uint256[] memory startingPrices,
        address[] memory priceCalculators,
        string[] calldata descriptions
    ) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _createSingleAuction(
                tokenAddresses[i],
                tokenIds[i],
                amounts[i],
                listOns[i],
                startingPrices[i],
                priceCalculators[i],
                descriptions[i]);
        }
    }

    function createBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string memory name,
        string memory description
    ) external whenNotPaused {
        if (listOn < block.timestamp) {
            listOn = block.timestamp;
        }

        require(tokenIds.length > 1, "DroppingNowMarketplace: bundle auction cannot be created with single token");
        require(amounts.length == tokenIds.length, "DroppingNowMarketplace: count of amounts must be same as tokens count");
        require(listOn < (block.timestamp + 30 days), "DroppingNowMarketplace: cannot be listed later than 30 days");
        require(priceCalculatorManager.isCalculatorAllowed(priceCalculator), "DroppingNowMarketplace: calculator is not allowed");
        require(IPriceCalculator(priceCalculator).isPriceAllowed(startingPrice), "DroppingNowMarketplace: price is not allowed");

        uint256[] memory amountsEscrow = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 amount = _escrowToken(msg.sender, tokenAddress, tokenIds[i], amounts[i]);
            amountsEscrow[i] = amount;
        }

        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amountsEscrow,
            listOn,
            startingPrice,
            priceCalculator,
            msg.sender,
            DOMAIN_SEPARATOR);

        _auctions[auctionHash] = true;
        emit BundleAuctionCreated(
            auctionHash,
            tokenAddress,
            tokenIds,
            amountsEscrow,
            msg.sender,
            listOn,
            startingPrice,
            priceCalculator,
            name,
            description);
    }

    function buySingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external payable whenNotPaused {
        require(listOn <= block.timestamp, "DroppingNowMarketplace: auction is not started");

        // validate
        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        uint256 totalPrice = IPriceCalculator(priceCalculator).calculateCurrentPrice(startingPrice, listOn);
        require(msg.value >= totalPrice, "DroppingNowMarketplace: insufficient money sent");

        _auctions[auctionHash] = false;

        uint256 sellerValue = totalPrice;

        {
            // 1. calculate, transfer and reward dropper fee
            uint256 dropperFeePayed = _payDropperFee(tokenAddress, amount, totalPrice);
            _dropReward(seller, tokenAddress, tokenId, amount);
            sellerValue = sellerValue - dropperFeePayed;
        }

        {
            // 2. calculate, transfer and reward marketplace fee
            uint256 marketplaceFeePayed = _payMarketplaceFee(totalPrice);
            _saleReward(seller, tokenAddress, 1, totalPrice);
            sellerValue = sellerValue - marketplaceFeePayed;
        }

        // 3. transfer tokens from manager to buyer
        _withdrawToken(msg.sender, tokenAddress, tokenId, amount);

        // 4. transfer money to seller
        seller.transfer(sellerValue);

        // 5. return bid excess
        if (msg.value > totalPrice) {
            uint256 excess = msg.value - totalPrice;
            payable(msg.sender).transfer(excess);
        }

        emit SingleSale(auctionHash, tokenAddress, tokenId, amount, seller, msg.sender, priceCalculator, totalPrice);
    }

    function buyBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external payable whenNotPaused {
        require(listOn <= block.timestamp, "DroppingNowMarketplace: auction is not started");

        // validate
        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amounts,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        uint256 totalPrice = IPriceCalculator(priceCalculator).calculateCurrentPrice(startingPrice, listOn);
        require(msg.value >= totalPrice, "DroppingNowMarketplace: insufficient money sent");

        _auctions[auctionHash] = false;

        uint256 sellerValue = totalPrice;

        {
            // 1. calculate, transfer and reward dropper fee
            uint256 dropperFeePayed = _payDropperFee(tokenAddress, amounts[0], totalPrice);
            _dropRewardBundle(seller, tokenAddress, tokenIds, amounts[0]);
            sellerValue = sellerValue - dropperFeePayed;
        }
        
        {
            // 2. calculate, transfer and reward marketplace fee
            uint256 marketplaceFeePayed = _payMarketplaceFee(totalPrice);
            _saleReward(seller, tokenAddress, tokenIds.length, totalPrice);
            sellerValue = sellerValue - marketplaceFeePayed;
        }

        // 3. transfer tokens from manager to buyer
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdrawToken(msg.sender, tokenAddress, tokenIds[i], amounts[i]);
        }

        // 4. transfer money to seller
        seller.transfer(sellerValue);

        // 5. return bid excess
        if (msg.value > totalPrice) {
            uint256 excess = msg.value - totalPrice;
            payable(msg.sender).transfer(excess);
        }

        emit BundleSale(auctionHash, tokenAddress, tokenIds, amounts, seller, msg.sender, priceCalculator, totalPrice);
    }

    function cancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external whenPaused {
        require(msg.sender == seller, "DroppingNowMarketplace: only auction seller can cancel");

        _cancelSingleAuction(tokenAddress, tokenId, amount, listOn, startingPrice, priceCalculator, seller);
    }

    function ownerCancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external onlyOwner {
        _cancelSingleAuction(tokenAddress, tokenId, amount, listOn, startingPrice, priceCalculator, seller);
    }

    function cancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external whenPaused {
        require(msg.sender == seller, "DroppingNowMarketplace: only auction seller can cancel");

        _cancelBundleAuction(tokenAddress, tokenIds, amounts, listOn, startingPrice, priceCalculator, seller);
    }

    function ownerCancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external onlyOwner {
        _cancelBundleAuction(tokenAddress, tokenIds, amounts, listOn, startingPrice, priceCalculator, seller);
    }

    function setTokenManagerSelector(address newTokenManagerSelector) external onlyOwner {
        require(newTokenManagerSelector != address(0), "DroppingNowMarketplace: address cannot be null");
        tokenManagerSelector = ITokenManagerSelector(newTokenManagerSelector);
        emit NewTokenManagerSelector(newTokenManagerSelector);
    }

    function setPriceCalculatorManager(address newPriceCalculatorManager) external onlyOwner {
        require(newPriceCalculatorManager != address(0), "DroppingNowMarketplace: address cannot be null");
        priceCalculatorManager = IPriceCalculatorManager(newPriceCalculatorManager);
        emit NewPriceCalculatorManager(newPriceCalculatorManager);
    }

    function setDroppingNowToken(address newDroppingNowToken) external onlyOwner {
        require(newDroppingNowToken != address(0), "DroppingNowMarketplace: address cannot be null");
        droppingNowToken = IDroppingNowToken(newDroppingNowToken);
        emit NewDroppingNowToken(newDroppingNowToken);
    }

    function setDropperToken(address newDropperToken) external onlyOwner {
        require(newDropperToken != address(0), "DroppingNowMarketplace: address cannot be null");
        dropperToken = IDropperToken(newDropperToken);
        emit NewDropperToken(newDropperToken);
    }

    function setSaleRewardRecipient(address newSaleRewardRecipient) external onlyOwner {
        require(newSaleRewardRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        saleRewardRecipient = newSaleRewardRecipient;
        emit NewSaleRewardRecepient(newSaleRewardRecipient);
    }

    function setDropRewardRecipient(address newDropRewardRecipient) external onlyOwner {
        require(newDropRewardRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        dropRewardRecipient = newDropRewardRecipient;
        emit NewDropRewardRecepient(newDropRewardRecipient);
    }

    function setDropRewardEscrowRecipient(address newDropRewardEscrowRecipient) external onlyOwner {
        require(newDropRewardEscrowRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        dropRewardEscrowRecipient = newDropRewardEscrowRecipient;
        emit NewDropRewardEscrowRecepient(newDropRewardEscrowRecipient);
    }
    
    function setDropperFee(uint256 newDropperFee) external onlyOwner {
        require(newDropperFee >= 0 && newDropperFee <= 10000, "DroppingNowMarketplace: fee must be between 0 and 10000");
        dropperFee = newDropperFee;
        emit NewDropperFee(newDropperFee);
    }

    function setMarketplaceFee(uint256 newMarketplaceFee) external onlyOwner {
        require(newMarketplaceFee >= 0 && newMarketplaceFee <= 10000, "DroppingNowMarketplace: fee must be between 0 and 10000");
        marketplaceFee = newMarketplaceFee;
        emit NewMarketplaceFee(newMarketplaceFee);
    }

    function setMinItemPriceForDN(uint256 newMinItemPriceForDN) external onlyOwner {
        minItemPriceForDN = newMinItemPriceForDN;
        emit NewMinItemPriceForDN(newMinItemPriceForDN);
    }

    function isAuctionAvailable(bytes32 auctionHash) external view returns (bool) {
        return _auctions[auctionHash];
    }

    function _createSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string calldata description
    ) internal {
        if (listOn < block.timestamp) {
            listOn = block.timestamp;
        }

        require(listOn < (block.timestamp + 30 days), "DroppingNowMarketplace: cannot be listed later than 30 days");
        require(priceCalculatorManager.isCalculatorAllowed(priceCalculator), "DroppingNowMarketplace: calculator is not allowed");
        require(IPriceCalculator(priceCalculator).isPriceAllowed(startingPrice), "DroppingNowMarketplace: price is not allowed");

        uint256 amountEscrow = _escrowToken(msg.sender, tokenAddress, tokenId, amount);

        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amountEscrow, 
            listOn,
            startingPrice,
            priceCalculator,
            msg.sender,
            DOMAIN_SEPARATOR);
        _auctions[auctionHash] = true;

        emit SingleAuctionCreated(
            auctionHash,
            tokenAddress,
            tokenId,
            amountEscrow,
            msg.sender,
            listOn,
            startingPrice,
            priceCalculator,
            description);
    }

    function _cancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) internal {
        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice, 
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        _auctions[auctionHash] = false;

        _withdrawToken(seller, tokenAddress, tokenId, amount);

        emit SingleAuctionCanceled(auctionHash, tokenAddress, tokenId, amount, seller, priceCalculator);
    }

    function _cancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) internal {
        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amounts,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        _auctions[auctionHash] = false;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdrawToken(seller, tokenAddress, tokenIds[i], amounts[i]);
        }

        emit BundleAuctionCanceled(auctionHash, tokenAddress, tokenIds, amounts, seller, priceCalculator);
    }

    function _escrowToken(
        address seller, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount
    ) internal returns (uint256) {
        address tokenManager = _getTokenManager(tokenAddress);
        uint256 amountDeposit = ITokenManager(tokenManager).deposit(seller, tokenAddress, tokenId, amount);
        return amountDeposit;
    }

    function _withdrawToken(
        address buyer, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount
    ) internal returns (uint256) {
        address tokenManager = _getTokenManager(tokenAddress);
        uint256 amountWithdraw = ITokenManager(tokenManager).withdraw(buyer, tokenAddress, tokenId, amount);
        return amountWithdraw;
    }

    function _getTokenManager(address tokenAddress) internal view returns (address) {
        address tokenManager = tokenManagerSelector.getManagerAddress(tokenAddress);
        require(tokenManager != address(0), "DroppingNowMarketplace: no token manager available");
        return tokenManager;
    }

    function _payDropperFee(
        address tokenAddress,
        uint256 amount,
        uint256 totalPrice
    ) internal returns(uint256) {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper fees
            return 0;
        }

        uint256 dropperFeeValue = totalPrice * dropperFee / 10000;
        try dropperToken.addReward{value: dropperFeeValue}(tokenAddress) {
            return dropperFeeValue;
        } catch {
            return 0;
        }
    }

    function _dropReward (
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper rewards
            return;
        }

        address[] memory recipients = _getDropRewardRecipients(seller, tokenAddress);
        uint256[] memory amounts = _getDropRewardAmounts();
        dropperToken.tryAddMintable(recipients, amounts, tokenAddress, tokenId);
    }

    function _dropRewardBundle (
        address seller,
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256 amount
    ) internal {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper rewards
            return;
        }

        address[] memory recipients = _getDropRewardRecipients(seller, tokenAddress);
        uint256[] memory amounts = _getDropRewardAmounts();
        dropperToken.tryAddMintableBatch(recipients, amounts, tokenAddress, tokenIds);
    }

    function _payMarketplaceFee(
        uint256 totalPrice
    ) internal returns(uint256) {
        uint256 marketplaceFeeValue = totalPrice * marketplaceFee / 10000;
        try droppingNowToken.addReward{value: marketplaceFeeValue}() {
            return marketplaceFeeValue;
        } catch {
            return 0;
        }
    }

    function _saleReward (address seller, address tokenAddress, uint256 tokensLength, uint256 totalPrice) internal {
        uint256 rewardableTokensLength = totalPrice / minItemPriceForDN;
        if (rewardableTokensLength > tokensLength) {
            rewardableTokensLength = tokensLength;
        }

        if (rewardableTokensLength == 0) {
            return;
        }

        bool isApproved = collectionsRegistry.isCollectionApproved(tokenAddress);
        address owner;
        bool ownerHasCorrectAddressAndApproved;
        if (isApproved) {
            owner = Ownable(tokenAddress).owner();
            ownerHasCorrectAddressAndApproved = isApproved && owner != address(0);
        }

        uint256 arraySize = 2;
        if (ownerHasCorrectAddressAndApproved) {
            arraySize = 3;
        }

        address[] memory recipients = new address[](arraySize);
        recipients[0] = seller;
        recipients[1] = saleRewardRecipient;

        uint256[] memory amounts = new uint256[](arraySize);
        amounts[0] = 10 * rewardableTokensLength;
        amounts[1] = 10 * rewardableTokensLength;
        
        if (ownerHasCorrectAddressAndApproved) {
            recipients[2] = owner;
            amounts[1] = 5 * rewardableTokensLength;
            amounts[2] = 5 * rewardableTokensLength;
        }
        
        droppingNowToken.addMintable(recipients, amounts);
    }

    function _getDropRewardRecipients (
        address seller,
        address tokenAddress
    ) internal view returns (address[] memory) {
        address[] memory recipients = new address[](3);
        recipients[0] = seller;
        recipients[1] = dropRewardRecipient;
        recipients[2] = dropRewardEscrowRecipient;

        if (collectionsRegistry.isCollectionApproved(tokenAddress)) {
            address owner = Ownable(tokenAddress).owner();
            if (owner != address(0)) {
                recipients[2] = owner;
            }
        }

        return recipients;
    }

    function _getDropRewardAmounts() internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 2;
        amounts[1] = 1;
        amounts[2] = 1;

        return amounts;
    }
}
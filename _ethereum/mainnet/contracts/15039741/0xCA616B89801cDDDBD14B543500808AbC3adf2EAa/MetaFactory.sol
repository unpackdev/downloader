//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./ERC165Checker.sol";
import "./IERC165.sol";
import "./Address.sol";
import "./Pausable.sol";

contract MetaFactory is Ownable, Pausable {
    using Address for address payable;

    event TokenInfoSet(address indexed tokenAddress, uint256 indexed tokenId, uint256 price, uint256 euroPrice);
    event TokenSaleToggled(address indexed tokenAddress, uint256 indexed tokenId, bool active);
    event TokenSold(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event TokenInfoRemoved(address indexed tokenAddress, uint256 indexed tokenId);

    struct TokenInfo {
        // Price in Wei (ETH)
        // The price is either fixed in Dollar or ETH
        // If the price is fixed in ETH then price > 0
        uint256 price;
        // Price in Euro (with 2 decimals)
        // The price is either fixed in Euro or ETH
        // If the price is fixed in Euro then euroPrice > 0
        uint256 euroPrice;
        // Whether people can buy the token
        bool saleActive;
        // The beneficiary of the sale of the token
        address beneficiary;
        // Commission received on the sales of the token
        // from 0 to 10000 (e.g. 300 => 3%)
        uint256 commission;
        // The original owner of the token
        address originalOwner;
    }

    address public fundsRecipient = 0x2F043D494E1EbBD551F63ceC0381cb9C31A67e71;

    // Address of an ERC-721 or ERC-1155 external smart contract
    // => whether this contract accepts to sell the token emitted
    // by the external smart contract
    mapping(address => bool) public tokensAccepted;
    // Address of an ERC-721 or ERC-1155 external smart contract
    // => id of the token => details of the token
    mapping(address => mapping(uint256 => TokenInfo)) public tokenDetails;

    // Price feed of ETH/USD (8 decimals)
    AggregatorV3Interface private immutable ethToUsdFeed;
    // Price feed of EUR/USD
    AggregatorV3Interface private immutable eurToUsdFeed;

    constructor(address _ethToUsdFeed, address _eurToUsdFeed) {
        require(_ethToUsdFeed != address(0) 
            && _eurToUsdFeed != address(0), "Invalid address");
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);
        eurToUsdFeed = AggregatorV3Interface(_eurToUsdFeed);
    }

    /**
    * @dev Let purchase tokens available for sale on this contract 
    * @param tokenAddress Address of the token
    * @param tokenId Id of the token
    * @param amount Amount of the token to purchase (ignored for ERC721)
    * @param to Address where the purchased tokens will be sent to
     */
    function buyTokensFor(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address to
    ) external payable whenNotPaused {
        TokenInfo storage tokenInfo = tokenDetails[tokenAddress][tokenId];
        require(tokenInfo.saleActive, "Not available for sale");
        // Check the value is correct
        if(tokenInfo.euroPrice > 0) {
            uint256 price = getPriceInETH(tokenAddress, tokenId);
            // Take a 0.5% slippage into account
            uint256 minPrice = (price * 995) / 1000;
            uint256 maxPrice = (price * 1005) / 1000;
            require(msg.value >= minPrice * amount, "Not enough ETH"); 
            require(msg.value <= maxPrice * amount, "Too much ETH"); 
        } else {
            require(msg.value == tokenInfo.price * amount, "Wrong value"); 
        }
        address beneficiary = tokenInfo.beneficiary;
        address originalOwner = tokenInfo.originalOwner;
        uint256 commission = tokenInfo.commission;
        // Check which type of token it is
        if (
            IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)
        ) {
            IERC1155 token = IERC1155(tokenAddress);
            // Make sure the contract can transfer this token
            require(
                token.isApprovedForAll(originalOwner, address(this)),
                "Not available"
            );
            uint256 amountLeft = token.balanceOf(originalOwner, tokenId);
            require(amountLeft >= amount, "Not enough supply left");
            if (amountLeft == amount) {
                // The tokens will change hands and no longer be controlled by this
                // smart contract so we can remove these details safely
                delete tokenDetails[tokenAddress][tokenId];
            }
            // Transfer the tokens to the recipient set by the buyer
            token.safeTransferFrom(originalOwner, to, tokenId, amount, "");
        } else {
            IERC721 token = IERC721(tokenAddress);
            // Make sure the contract can transfer this token
            require(
                token.isApprovedForAll(token.ownerOf(tokenId), address(this)),
                "Not available"
            );
            // The token will change hands and no longer be controlled by this
            // smart contract so we can remove these details safely
            delete tokenDetails[tokenAddress][tokenId];
            // Transfer the tokens to the recipient set by the buyer
            IERC721(tokenAddress).transferFrom(
                token.ownerOf(tokenId),
                to,
                tokenId
            );
        }
        uint256 totalCommission = (msg.value * commission) /
            10000;
        // Take the commission
        payable(fundsRecipient).sendValue(totalCommission);
        // And send the rest to the beneficiary of this sale
        payable(beneficiary).sendValue(msg.value - totalCommission);
        emit TokenSold(tokenAddress, tokenId, to, amount);
    }
    
    /**
     * @dev Set the info of a token to be sold through this contract
     * This contract needs to be approved by the owner of the token
     * in order for the sale to be active.
     * For ERC-1155, the owner of the token cannot change during the sale
     * or any purchase transaction will fail.
     */
    function setTokenInfo(
        address tokenAddress,
        uint256 tokenId,
        uint256 price,
        uint256 euroPrice,
        uint256 commission,
        address originalOwner
    ) public onlyOwner {
        checkInfo(tokenAddress, price, euroPrice, commission, originalOwner);
        // Check that the owner is the right one
        if(IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            require(IERC1155(tokenAddress).balanceOf(originalOwner, tokenId) > 0, "Wrong owner");
        } else {
            require(IERC721(tokenAddress).ownerOf(tokenId) == originalOwner, "Wrong owner");
        }
        tokenDetails[tokenAddress][tokenId] = TokenInfo({
            price: price,
            euroPrice: euroPrice,
            // Any update to the token info will disable the sale
            // so that the owner of the NFT has to enable it again
            saleActive: false,
            // Keep the value of the beneficiary
            beneficiary: tokenDetails[tokenAddress][tokenId].beneficiary,
            commission: commission,
            // Useful for ERC-1155 contracts
            originalOwner: originalOwner
        });
        emit TokenInfoSet(tokenAddress, tokenId, price, euroPrice);
    }

    function setTokensInfo(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256 price,
        uint256 euroPrice,
        uint256 commission,
        address originalOwner
    ) external {
        // Will fail if not owner of the contract as this resctriction is
        // checked in the function called below
        for(uint256 i = 0; i < tokenIds.length; i++) {
            setTokenInfo(tokenAddress, tokenIds[i], price, euroPrice, commission, originalOwner);
        }
     }

    function checkInfo(        
        address tokenAddress,
        uint256 price,
        uint256 euroPrice,
        uint256 commission,
        address originalOwner
    ) private view {
        // The token must be accepted first
        require(tokensAccepted[tokenAddress], "Token not accepted");
        // One of the price must be greater than 0
        require(price > 0 || euroPrice > 0, "Price must be greater than 0");
        require(originalOwner != address(0), "Invalid original owner address");
        // price and euroPrice are mutually exclusive, one of them must be 0
        require(price == 0 || euroPrice == 0, "You cannot fix the price both in EUR and ETH");
        require(commission <= 10000, "Commission cannot above 100%");
    }

    /**
    * @dev Remove all info stored about a token
    * @param tokenAddress Address of the token
    * @param tokenId Id of the token
     */
    function removeTokenInfo(address tokenAddress, uint256 tokenId) public onlyOwner {
        require(tokenDetails[tokenAddress][tokenId].originalOwner != address(0), "No info defined");
        delete tokenDetails[tokenAddress][tokenId];
        emit TokenInfoRemoved(tokenAddress, tokenId);
    }

    /**
    * @dev Remove all info stored about the tokens
    * @param tokenAddress Address of the tokens
    * @param tokenIds Ids of the tokens
     */
    function removeTokensInfo(address tokenAddress, uint256[] memory tokenIds) external onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            removeTokenInfo(tokenAddress, tokenIds[i]);
        }
    }


    /**
    * @dev Change the status of the sale of a given token
    * @param tokenAddress The address of the token
    * @param tokenId The id of the token
    * @param active Whether to enable or disable the sale
    * @param beneficiary Address that will receive proceeds of the sale for the artist
    * Can be set to zero address (if so the argument will be ignored)
     */
    function toggleTokenSale(address tokenAddress, uint256 tokenId, bool active, address beneficiary) public {
        TokenInfo storage details = tokenDetails[tokenAddress][tokenId];
        // Check if the token info have been defined
        // No need to check whether it was accepted or not
        // cause if the info have been defined it's necessarily accepted
        require(details.originalOwner != address(0), "Token not defined");            
        // Only the owner of the token can call this function
        if(IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            // If the owner changed in between the time the token info were defined
            // and now, this transaction will fail (so the owner should be updated) 
            require(msg.sender == details.originalOwner 
                && IERC1155(tokenAddress).balanceOf(details.originalOwner, tokenId) > 0, "Not allowed"); 
        } else {
            // Checking for the ownership is more straightforward for the ERC-721
            require(IERC721(tokenAddress).ownerOf(tokenId) == msg.sender, "Not allowed"); 
        }
        tokenDetails[tokenAddress][tokenId].saleActive = active;
        // Set the beneficiary to the new address if defined
        if(beneficiary != address(0)) {
            tokenDetails[tokenAddress][tokenId].beneficiary = beneficiary;
        }
        emit TokenSaleToggled(tokenAddress, tokenId, active);
    }

    /**
    * @dev Change the status of the sale of the tokens
    * @param tokenAddress The address of the token
    * @param tokenIds The ids of the tokens
    * @param active Whether to enable or disable the sale
    * @param beneficiary Address that will receive proceeds of the sale for the artist
    * Can be set to zero address (if so the argument will be ignored)
     */
    function toggleTokensSale(address tokenAddress, uint256[] memory tokenIds, bool active, address beneficiary) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            toggleTokenSale(tokenAddress, tokenIds[i], active, beneficiary);
        }
    }

    /**
    * @dev To add or remove tokens that are accepted by this contract for the sales
    * @param addrs Addresses of the tokens to manage
    * @param accepted Whether to consider them as accepted or not
     */
    function manageAcceptedTokens(address[] memory addrs, bool accepted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            require(addrs[i] != address(0), "Invalid address");
            // Check that the token address is a valid ERC-721 or ERC-1155 contract
            require(
                ERC165Checker.supportsERC165(addrs[i]) &&
                (IERC165(addrs[i]).supportsInterface(
                    type(IERC1155).interfaceId
                ) ||
                    IERC165(addrs[i]).supportsInterface(
                        type(IERC721).interfaceId
                    )),
                "Token not a valid interface"
            );
            tokensAccepted[addrs[i]] = accepted;
        }
    }

    /**
    @dev Set the address that will receive the commission on the sales
    @param addr Address that will receive the commissions
     */
    function setFundsRecipient(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        fundsRecipient = addr;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Get current rate of ETH to US Dollar
     */
    function getETHtoUSDPrice() private view returns (uint256) {
        (, int256 price, , , ) = ethToUsdFeed.latestRoundData();
        return uint256(price);
    }

    /**
    * @dev Get current rate of Euro to US Dollar
    */
    function getEURToUSDPrice() private view returns (uint256) {
        (, int256 price, , , ) = eurToUsdFeed.latestRoundData();
        return uint256(price);
    }


    function getPriceInETH(address tokenAddress, uint256 tokenId) public view returns (uint256) {
        // Get the price fixed in EUR for the token if any
        uint256 priceInEuro = tokenDetails[tokenAddress][tokenId].euroPrice;
        require(priceInEuro > 0, "Price not fixed in EUR");
        // Get rate for EUR/USD
        uint256 eurToUsd = getEURToUSDPrice();
        // Get rate for ETH/USD
        uint256 ethToUsd = getETHtoUSDPrice();
        // Convert price in US Dollar
        // We divide by 10 to power of the number of decimals of EUR/USD feed
        // to cancel out all decimals in priceInUsd
        uint256 priceInUsd = (priceInEuro * eurToUsd) / 10**eurToUsdFeed.decimals();
        // Convert price in ETH for US Dollar price
        // We multiply by the 10^(decimals of ETH/USD feed) to make the priceInUsd
        // which has 2 decimals equal to the number of decimals of the denominator
        // We then multiply by 10^16 to increase the accuracy of the conversion
        // and also make the result 18 decimals (priceInUsd is 2 decimals) since the rest
        // of the decimals cancel out between numerator and denominator
        uint256 priceInETH = (priceInUsd *
            10**(ethToUsdFeed.decimals()) *
            10**16) / ethToUsd;
        return priceInETH;
    }
}

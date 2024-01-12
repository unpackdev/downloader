// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ERC165Checker.sol";
import "./IERC2981.sol";

import "./IERC721Autentica.sol";

contract NFTMarketplace is
    AccessControl,
    ReentrancyGuard,
    Pausable
{
    // Number of decimals used for fees.
    uint8 public constant DECIMALS = 2;

    // Create a new role identifier for the operator role.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Autentica wallet address.
    address private _autentica;

    // Allowed token addresses to be used with `tradeForTokens`.
    address[] private _allowedTokens;

    // NFT details.
    struct NFT {
        address owner;
        address creator;
        address investor;
    }

    // Percentages for each party that needs to be payed.
    struct Percentages {
        uint256 creator;
        uint256 investor;
    }

    // Proceeds for each party that needs to be payed amounts expressed in coins or tokens, not in percentages
    struct Proceeds {
        uint256 creator;
        uint256 investor;
        uint256 marketplace;
    }

    // ECDSA signature.
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @dev Emitted when the Autentica wallet address has been updated.
     */
    event ChangedAutentica(
        address indexed oldAddress,
        address indexed newAddress
    );
    /**
     * @dev Emitted when a trade occured between the `seller` (the owner of the ERC-721 token
     * represented by `tokenId` within the `collection` smart contract) and `buyer` which
     * payed the specified `price` in coins (the native cryptocurrency of the platform, i.e.: ETH).
     */
    event TradedForCoins(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 ownerProceeds,
        uint256 creatorProceeds,
        uint256 investorProceeds
    );
    /**
     * @dev Emitted when a trade occured between the `seller` (the owner of the ERC-721 token
     * represented by `tokenId` within the `collection` smart contract) and `buyer` which
     * payed the specified `price` in tokens that are represented by the `token`
     * ERC-20 smart contract address.
     */
    event TradedForTokens(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address token,
        uint256 price,
        uint256 ownerProceeds,
        uint256 creatorProceeds,
        uint256 investorProceeds
    );

    /**
     * @dev Emitted when a new token is allowed to be used for trading.
     */
    event AllowedTokenAdded(address indexed tokenAddress);
    /**
     * @dev Emitted when a token is not longer allowed to be used for trading.
     */
    event AllowedTokenRemoved(address indexed tokenAddress);

    /**
     * The constructor sets the creator of the contract as the admin
     * and operator of this smart contract, sets the wallet address for Autentica and sets the allowed tokens.
     */
    constructor(address wallet, address[] memory allowedTokens) {
        // Grant the admin role to the owner
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant the operator role to the owner
        _setupRole(OPERATOR_ROLE, _msgSender());

        // Set the wallet address for Autentica
        _autentica = wallet;

        // Set the allowed tokens
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            addAllowedToken(allowedTokens[i]);
        }
    }

    /**
     * Returns the Autentica wallet address.
     */
    function autentica() external view returns (address) {
        return _autentica;
    }

    /**
     * @dev Sets the Autentica wallet address.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function setAutentica(address wallet) external returns (address) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can change this"
        );

        // Keep a reference to the old address
        address oldAutentica = _autentica;

        // Change the address
        _autentica = wallet;

        // Emit the event
        emit ChangedAutentica(oldAutentica, _autentica);

        return _autentica;
    }

    /**
     * @dev Returns the number of decimals used for fees.
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the number of allowed tokens.
     */
    function numberOfAllowedTokens() public view returns (uint256) {
        return _allowedTokens.length;
    }

    /**
     * @dev Returns the address of the allowed token at the specified index.
     * @param index The index of the allowed token.
     */
    function allowedTokenAtIndex(uint256 index) public view returns (address) {
        require(
            index < numberOfAllowedTokens(),
            "NFTMarketplace: Index out of bounds"
        );
        return _allowedTokens[index];
    }

    /**
     * @dev Verifies if a token address has been allowed already.
     */
    function isTokenAllowed(address tokenAddress) public view returns (bool) {
        for (uint256 i = 0; i < numberOfAllowedTokens(); i++) {
            if (_allowedTokens[i] == tokenAddress) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Add a new allowed token to the contract.
     * @param tokenAddress The address of the allowed token to add.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function addAllowedToken(address tokenAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can add allowed tokens"
        );

        // Check if the token address is valid
        require(
            tokenAddress != address(0),
            "NFTMarketplace: Token address is the zero address"
        );

        // Check if the token address is already allowed
        require(
            !isTokenAllowed(tokenAddress),
            "NFTMarketplace: Token address is already allowed"
        );

        // Add the token address
        _allowedTokens.push(tokenAddress);

        // Emit the event
        emit AllowedTokenAdded(tokenAddress);
    }

    /**
     * @dev Remove the allowed token at the specified index.
     * @param index The index of the allowed token.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function removeAllowedTokenAtIndex(uint256 index) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can remove allowed tokens"
        );

        // Check if the index is valid
        require(
            index < numberOfAllowedTokens(),
            "NFTMarketplace: Index out of bounds"
        );

        // Keep a reference to the old address
        address tokenAddress = _allowedTokens[index];

        // Deleting an element from the array does not affect the array length, so we need to use the `pop()` method
        if (numberOfAllowedTokens() == 1) {
            _allowedTokens.pop();
        } else {
            // Instead of shifting all the elements from the right, we will just move the last element in place of the
            // element that will be removed
            _allowedTokens[index] = _allowedTokens[numberOfAllowedTokens() - 1];
            // Remove the last element
            _allowedTokens.pop();
        }

        // Emit the event
        emit AllowedTokenRemoved(tokenAddress);
    }

    /**
     * @notice Trades an NFT for a given amount of coins (the native cryptocurrency of the platform, i.e.: ETH).
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in coins.
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     * @dev Requirements
     *
     * - The `collection` smart contract must be an ERC-721 smart contract.
     * - The owner of the NFT identified by `tokenId` within the `collection` smart contract must have approved
     *   this smart contract to manage its NFTs.
     * - The `price` and `msg.value` must be equal.
     * - The sum of all the fees cannot be greater than 100%.
     * - The ECDSA signature must be signed by someone with the admin or operator role.
     */
    function tradeForCoins(
        address collection,
        uint256 tokenId,
        uint256 price,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) external payable nonReentrant {
        // Check if the user sent enough coins
        require(msg.value == price, "NFTMarketplace: Not enough coins sent");

        // Validate the trade
        canPerformTrade(
            collection,
            tokenId,
            price,
            address(0x0),
            buyer,
            marketplaceFee,
            signature
        );

        NFT memory nft = _nftDetails(collection, tokenId);

        // Assemble the percentages
        Percentages memory percentages = _percentagesDetails(
            nft,
            getRoyaltyFee(collection, tokenId),
            getInvestorFee(collection, tokenId),
            marketplaceFee
        );

        // Assemble the fees
        Proceeds memory proceeds = Proceeds({
            creator: _calculateProceedsForFee(percentages.creator, price),
            investor: _calculateProceedsForFee(percentages.investor, price),
            marketplace: _calculateProceedsForFee(marketplaceFee, price)
        });

        // Calculate the base owner proceeds
        uint256 ownerProceeds = _calculateOwnerProceeds(
            price,
            proceeds
        );

        // Payments
        _sendViaCall(payable(nft.owner), ownerProceeds);
        if (proceeds.investor > 0) {
            _sendViaCall(payable(nft.investor), proceeds.investor);
        }
        if (proceeds.creator > 0) {
            _sendViaCall(payable(nft.creator), proceeds.creator);
        }
        if (proceeds.marketplace > 0) {
            _sendViaCall(payable(_autentica), proceeds.marketplace);
        }

        // Finally transfer the NFT
        IERC721(collection).safeTransferFrom(nft.owner, _msgSender(), tokenId);

        // Emit the event
        emit TradedForCoins(
            collection,
            tokenId,
            nft.owner,
            _msgSender(),
            price,
            ownerProceeds,
            proceeds.creator,
            proceeds.investor
        );
    }

    /**
     * @notice Trades an NFT for a given amount of ERC-20 tokens (i.e.: AUT/USDT/USDC).
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in `token` tokens.
     * @param token The ERC-20 smart contract.
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     * Requirements:
     *
     * - The `collection` smart contract must be an ERC-721 smart contract.
     * - The owner of the NFT identified by `tokenId` within the `collection` smart contract must have approved
     *   this smart contract to manage its NFTs.
     * - The sum of all the fees cannot be greater than 100%.
     * - The ECDSA signature must be signed by someone with the admin or operator role.
     */
    function tradeForTokens(
        address collection,
        uint256 tokenId,
        uint256 price,
        address token,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) external nonReentrant {
        // Check if the token is allowed
        require(isTokenAllowed(token), "NFTMarketplace: Token not allowed");

        // Validate the trade
        canPerformTrade(
            collection,
            tokenId,
            price,
            token,
            buyer,
            marketplaceFee,
            signature
        );

        // Assemble the NFT details
        NFT memory nft = _nftDetails(collection, tokenId);

        // Assemble the percentages
        Percentages memory percentages = _percentagesDetails(
            nft,
            getRoyaltyFee(collection, tokenId),
            getInvestorFee(collection, tokenId),
            marketplaceFee
        );

        // Assemble the fees
        Proceeds memory proceeds = Proceeds({
            creator: _calculateProceedsForFee(percentages.creator, price),
            investor: _calculateProceedsForFee(percentages.investor, price),
            marketplace: _calculateProceedsForFee(marketplaceFee, price)
        });

        // Calculate the base owner proceeds
        uint256 ownerProceeds = _calculateOwnerProceeds(
            price,
            proceeds
        );

        // Payments
        IERC20(token).transferFrom(buyer, nft.owner, ownerProceeds);
        if (proceeds.investor > 0) {
            IERC20(token).transferFrom(
                buyer,
                nft.investor,
                proceeds.investor
            );
        }
        if (proceeds.creator > 0) {
            IERC20(token).transferFrom(buyer, nft.creator, proceeds.creator);
        }
        if (proceeds.marketplace > 0) {
            IERC20(token).transferFrom(
                buyer,
                _autentica,
                proceeds.marketplace
            );
        }
        // Finally transfer the NFT
        IERC721(collection).safeTransferFrom(nft.owner, _msgSender(), tokenId);

        // Emit the event
        emit TradedForTokens(
            collection,
            tokenId,
            nft.owner,
            _msgSender(),
            token,
            price,
            ownerProceeds,
            proceeds.creator,
            proceeds.investor
        );
    }

    /**
     * @notice Validate the trade.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in `token` tokens.
     * @param currency The type of currency (erc20 or native currency)
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     */
    function canPerformTrade(
        address collection,
        uint256 tokenId,
        uint256 price,
        address currency,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) public view returns (bool) {
        // Check if the contract is paused
        require(!paused(), "NFTMarketplace: Contract is paused");

        // Check if the collection is an ERC-721 smart contract
        _validateERC721(collection);

        // Assemble the NFT details
        NFT memory nft = _nftDetails(collection, tokenId);

        // Validate the approval
        _validateNFTApproval(collection, tokenId, nft);

        // Fees
        uint256 royaltyFee = getRoyaltyFee(collection, tokenId);
        uint256 investorFee = getInvestorFee(collection, tokenId);

        // Make sure that all the fees sumed up do not exceed 100%
        // 
        // Note: The investor fee is ignored from the validation
        // because that fee represents a percetange of the
        // royalty fee.
        _validateFees(royaltyFee, marketplaceFee);

        // Make sure the parameters are valid
        require(
            _validateTrade(
                collection,
                tokenId,
                nft.owner,
                buyer,
                price,
                currency,
                royaltyFee,
                investorFee,
                marketplaceFee,
                signature
            ),
            "NFTMarketplace: Invalid signature"
        );
        return true;
    }

    /**
     * @notice If the collection smart contract implements `IERC721Autentica` or `IERC2981` then 
     * the function returns the royalty fee from that smart contract, otherwise it will return 0.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     *
     */
    function getRoyaltyFee(address collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 royaltyFee = 0;

        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            royaltyFee = _normalizedFee(
                IERC721Autentica(collection),
                IERC721Autentica(collection).getRoyaltyFee(tokenId)
            );
        } else if (ERC165Checker.supportsInterface(collection, type(IERC2981).interfaceId)) {
            // This is a smart contract implementing `IERC2981`
            (, royaltyFee) = IERC2981(collection).royaltyInfo(tokenId, 100 * (10 ** DECIMALS));
            // The reason for why we use `100 * (10 ** DECIMALS)` as the sale price is because other
            // we don't want to lose precision when calculating the fee.
        }
        return royaltyFee;
    }

    /**
     * @notice If the collection smart contract implements `IERC721Autentica` then the function 
     * returns the investor fee from that smart contract, otherwise it will return 0.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     *
     */
    function getInvestorFee(address collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 investorFee = 0;
        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            investorFee = _normalizedFee(
                IERC721Autentica(collection),
                IERC721Autentica(collection).getInvestorFee(tokenId)
            );
        }
        return investorFee;
    }

    /**
     * @dev Verifies if the token owner has approved this smart contract to manage its 
     * NFTs from the specified collection.
     * @return Returns `true` if this smart contract is approved by the `tokenOwner` in 
     * the `collection` smart contract or only if that specific NFT is approved for this smart contract.
     */
    function isMarketplaceApproved(
        IERC721 collection,
        uint256 tokenId,
        address tokenOwner
    ) public view returns (bool) {
        return
            collection.getApproved(tokenId) == address(this) ||
            collection.isApprovedForAll(tokenOwner, address(this));
    }

    /**
     * @notice Pause the contract.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function pause() public {
        // Make sure that only admins can pause the contract
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can pause"
        );

        // Do it
        _pause();
    }

    /**
     * @notice Unpause the contract.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function unpause() public {
        // Make sure that only admins can unpause the contract
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can unpause"
        );

        // Do it
        _unpause();
    }

    /**
     * @dev Function to transfer coins (the native cryptocurrency of the 
     * platform, i.e.: ETH) from this contract to the specified address.
     *
     * @param to - Address where to transfer the coins
     * @param amount - Amount (in wei)
     *
     */
    function _sendViaCall(address payable to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "NFTMarketplace: Failed to send coins");
    }

    /**
     * Returns `true` if the signer has the admin or the operator role.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param buyer Seller address.
     * @param buyer Buyer address.
     * @param price Price of the NFT expressed in coins or tokens.
     * @param token The ERC-20 smart contract address.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     */
    function _validateTrade(
        address collection,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price,
        address token,
        uint256 royaltyFee,
        uint256 investorFee,
        uint256 marketplaceFee,
        Signature calldata signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                address(this),
                collection,
                tokenId,
                seller,
                buyer,
                price,
                token,
                royaltyFee,
                investorFee,
                marketplaceFee
            )
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            signature.v,
            signature.r,
            signature.s
        );

        return
            hasRole(DEFAULT_ADMIN_ROLE, signer) ||
            hasRole(OPERATOR_ROLE, signer);
    }

    /**
     * @dev Returns the fee normalized to the number of decimals used in this smart contract.
     *
     * @param collection The Autentica ERC-721 smart contract.
     * @param fee Value represented using the number of decimals used by the `collection` smart contract.
     */
    function _normalizedFee(IERC721Autentica collection, uint256 fee)
        private
        view
        returns (uint256)
    {
        return (fee * (10**DECIMALS)) / (10**collection.decimals());
    }

    /**
     * @dev Returns the number of coins/tokens for a given fee percentage.
     */
    function _calculateProceedsForFee(uint256 fee, uint256 price)
        private
        pure
        returns (uint256)
    {
        if (fee == 0) {
            return 0;
        }

        // Price * Fee (which is already multiplied by 10**DECIMALS) / 100% multiplied by 10**DECIMALS
        return (price * fee) / (100 * 10**DECIMALS);
    }

    /**
     * Returns the owner proceeds.
     */
    function _calculateOwnerProceeds(
        uint256 price,
        Proceeds memory proceeds
    ) private pure returns (uint256) {
        return
            price -
            proceeds.marketplace -
            proceeds.creator -
            proceeds.investor;
    }

    /**
     * @dev Makes sure that the `collection` is a valid ERC-721 smart contract.
     */
    function _validateERC721(address collection) private view {
        require(
            ERC165Checker.supportsInterface(
                collection,
                type(IERC721).interfaceId
            ),
            "NFTMarketplace: Collection does not support the ERC-721 interface"
        );
    }

    /**
     * @dev Makes sure that the owner approved this smart contract for the token.
     */
    function _validateNFTApproval(
        address collection,
        uint256 tokenId,
        NFT memory nft
    ) private view {
        require(
            isMarketplaceApproved(IERC721(collection), tokenId, nft.owner),
            "NFTMarketplace: Owner has not approved us for managing its NFTs"
        );
    }

    /**
     * @dev Make sure that all the fees sumed up do not exceed 100%.
     */
    function _validateFees(
        uint256 royaltyFee,
        uint256 marketplaceFee
    ) private pure {
        require(
            royaltyFee + marketplaceFee <= 100 * 10**DECIMALS,
            "NFTMarketplace: Total fees cannot be greater than 100%"
        );
    }

    /**
     * @dev Returns the NFT details.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     */
    function _nftDetails(address collection, uint256 tokenId)
        private
        view
        returns (NFT memory)
    {
        // Assemble the NFT details
        NFT memory nft = NFT({
            owner: IERC721(collection).ownerOf(tokenId),
            creator: address(0x0), // Will get overriden below if this is a Autentica ERC-721 collection
            investor: address(0x0) // Will get overriden below if this is a Autentica ERC-721 collection
        });

        // Update the information about the creator and investor
        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            nft.creator = IERC721Autentica(collection).getCreator(tokenId);
            nft.investor = IERC721Autentica(collection).getInvestor(tokenId);
        } else if (ERC165Checker.supportsInterface(collection, type(IERC2981).interfaceId)) {
            // This is a smart contract implementing `IERC2981`
            (nft.creator, ) = IERC2981(collection).royaltyInfo(tokenId, 100 * (10 ** DECIMALS));
            // The reason for why we use `100 * (10 ** DECIMALS)` as the sale price is because other
            // implementations of `ERC-2981` may return `address(0x0)` for the 
            // `receiver` if the values are too low or zero.
        }

        return nft;
    }

    /**
     * @dev Returns the Percentages details.
     *
     * @param nft NFT details.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param marketplaceFee Marketplace fee.
     */
    function _percentagesDetails(
        NFT memory nft,
        uint256 royaltyFee,
        uint256 investorFee,
        uint256 marketplaceFee
    ) private pure returns (Percentages memory) {
        Percentages memory percentages = Percentages({creator: 0, investor: 0});

        if (nft.owner == nft.creator) {
            // CASE 1: The NFT is owned by the creator

            if (nft.investor != address(0x0) && investorFee > 0) {
                // CASE 1.1: The investor will receive X% from the creator/owner's end
                percentages.investor = (investorFee * ((100 * 10**DECIMALS) - marketplaceFee)) / (100 * 10**DECIMALS);
            }
        } else {
            // CASE 2: The NFT is owned by someone else

            if (nft.creator != address(0x0) && royaltyFee > 0) {
                // CASE 2.1: The creator will get payed too
                percentages.creator = royaltyFee;

                if (nft.investor != address(0x0) && investorFee > 0) {
                    // CASE 1.1: The investor will receive X% from the creator's end
                    
                    // Calculate the investor fee
                    percentages.investor = (investorFee * percentages.creator) / (100 * 10**DECIMALS);
                    // Shrink the creator fee
                    percentages.creator = percentages.creator - percentages.investor;
                }
            }
        }

        return percentages;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
 _  _  ____  ___  ____  ____  ____     ____  ____    __    ____  ____
( \( )( ___)/ __)(_  _)( ___)(  _ \   (_  _)(  _ \  /__\  (  _ \( ___)
 )  (  )__) \__ \  )(   )__)  )(_) )    )(   )   / /(__)\  )(_) ))__)
(_)\_)(____)(___/ (__) (____)(____/    (__) (_)\_)(__)(__)(____/(____)

**/

import "./IERC721ReceiverUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IMoonbirds.sol";
import "./INestedTrade.sol";
import "./NestedTradeStore.sol";

/// @title A trustless marketplace to buy/sell nested Moonbirds
/// @author Montana Wong, Fabrice Cheng
contract NestedTrade is INestedTrade, UUPSUpgradeable, ReentrancyGuardUpgradeable, IERC721ReceiverUpgradeable, OwnableUpgradeable, NestedTradeStore {
    /// @dev Allow only the seller of a specific token ID to call specific functions.
    modifier onlyTokenSeller(uint256 _tokenId) {
        require(
            msg.sender == moonbirds.ownerOf(_tokenId) || (isMoonbirdEscrowed(_tokenId) && moonbirdTransferredFromOwner[_tokenId] == msg.sender),
            "caller must be token owner or token must have already been sent by owner to the NestedTrade contract"
        );
        _;
    }

    constructor() initializer {
        // used to prevent logic contract self destruct take over
    }

    function initialize(
        IMoonbirds _moonbirds,
        address _marketplaceFeePayoutAddress,
        uint256 _marketplaceFeeBps
    ) public initializer
    {
        moonbirds = _moonbirds;
        marketplaceFeePayoutAddress = _marketplaceFeePayoutAddress;
        marketplaceFeeBps = _marketplaceFeeBps;
        enforceDefaultRoyalties = false;
        __Ownable_init_unchained();
    }

    /// @notice Creates the ask for a given NFT
    /// @param _tokenId The ID of the Moonbird token to be sold
    /// @param _buyer Address of the buyer
    /// @param _askPrice The price to fill the ask
    /// @param _royaltyFeeBps The basis points of royalties to pay to the Moonbird's token royalty payout address
    function createAsk(
        uint256 _tokenId,
        address _buyer,
        uint256 _askPrice,
        uint256 _royaltyFeeBps
    ) external  nonReentrant {
        require(_royaltyFeeBps <= 1000, "createAsk royalty fee basis points must be less than or equal to 10%");
        address tokenOwner = moonbirds.ownerOf(_tokenId);
        require(msg.sender == tokenOwner, "createAsk caller must be token owner");
        require(_buyer != address(0), "createAsk buyer address must be set");

        Ask memory ask = Ask({
            seller: tokenOwner,
            buyer: _buyer,
            askPrice: _askPrice,
            royaltyFeeBps: _royaltyFeeBps,
            uid: keccak256(abi.encode(tokenOwner, _buyer, _tokenId, block.timestamp))
        });

        askForMoonbird[_tokenId] = ask;

        emit AskCreated(
            _tokenId, ask.seller, ask.buyer, ask.askPrice, ask.royaltyFeeBps, ask.uid
        );
    }


    /// @notice Cancels the ask for a given NFT
    /// @param _tokenId The ID of the Moonbird token
    function cancelAsk(uint256 _tokenId) external onlyTokenSeller(_tokenId) nonReentrant {
        Ask memory ask = askForMoonbird[_tokenId];
        require(ask.seller == msg.sender, "cancelAsk wrong seller");

        if (isMoonbirdEscrowed(_tokenId)) {
            _withdrawBird(_tokenId);
        }

        emit AskCanceled(_tokenId, ask.seller, ask.buyer, ask.askPrice, ask.royaltyFeeBps, ask.uid);
        delete askForMoonbird[_tokenId];
    }


    /// @notice Updates the ask price for a given Moonbird
    /// @param _tokenId The ID of the Moonbird token
    /// @param _askPrice The ask price to set
    function setAskPrice(
        uint256 _tokenId,
        uint256 _askPrice
    ) external onlyTokenSeller(_tokenId) nonReentrant {
        Ask storage ask = askForMoonbird[_tokenId];
        require(ask.seller == msg.sender, "setAskPrice must be seller");
        require(_askPrice < ask.askPrice, "setAskPrice can only be used to lower the price");

        ask.askPrice = _askPrice;

        emit AskPriceUpdated(_tokenId, ask.seller, ask.buyer, ask.askPrice, ask.royaltyFeeBps, ask.uid);
    }

    /// @notice Fills the ask for a given Moonbird, transferring the ETH to the seller and Moonbird to the buyer
    /// @param _tokenId The ID of the Moonbird token
    function fillAsk(
        uint256 _tokenId
    ) external payable nonReentrant {
        Ask storage ask = askForMoonbird[_tokenId];

        require(isMoonbirdEscrowed(_tokenId), "fillAsk The Moonbird associated with this ask must be escrowed within NestedTrade before a purchase can be completed");
        require(ask.seller != address(0), "fillAsk must be active ask");
        require(ask.buyer == msg.sender, "fillAsk must be buyer");

        require(msg.value == ask.askPrice, "fillAsk msg value not expected amount");

        // Payout marketplace fee
        uint256 marketplaceFee = _handleMarketplaceFeePayout(ask.askPrice);

        // Payout respective parties, payout royalties based on configuration
        uint256 royaltyFee = _handleRoyaltyPayout(ask.askPrice, ask.royaltyFeeBps, _tokenId);

        // Transfer remaining ETH to seller
        uint256 remainingProfit = msg.value - marketplaceFee - royaltyFee;
        _handleOutgoingTransfer(ask.seller, remainingProfit);

        // Transfer nested moonbird to buyer
        moonbirds.safeTransferWhileNesting(address(this), msg.sender, _tokenId);

        if (totalSwap % 4 == 0)
            blockNumberSyncCache = block.number;
        if (totalSwap % 4 == 3) {
            // Store the block number for the past 3 listings
            blockNumberSync = blockNumberSyncCache;
        }
        totalSwap += 1;
        emit AskFilled(_tokenId, ask.seller, msg.sender, ask.askPrice, ask.royaltyFeeBps, ask.uid);
        delete moonbirdTransferredFromOwner[_tokenId];
        delete askForMoonbird[_tokenId];
    }


    /// @dev The Moonbird must be transferred directly to this contract using safeTransferFromWhileNested by the owner
    /// This is because the Moonbird contract does not allow operators to transfer the NFT on the owner's behalf
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) override public returns (bytes4) {
        require(isMoonbirdEscrowed(tokenId), "onERC721Received Moonbirds not transferred");
        bool nesting;
        (nesting, ,) = moonbirds.nestingPeriod(tokenId);
        require(nesting == true, "onERC721Received Moonbirds not nested");
        Ask memory ask = askForMoonbird[tokenId];
        require(ask.seller == from, "onERC721Received Cannot send Nested MB without active listing.");
        moonbirdTransferredFromOwner[tokenId] = from;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /// @dev Checks to see if a moonbird is escrowed within the NestedTrade contract
    function isMoonbirdEscrowed(uint256 tokenId) public view returns (bool) {
        return address(this) == moonbirds.ownerOf(tokenId);
    }

    /// @dev Fetches multiple asks given their respective corresponding moonbird tokenIds
    function getAsksForMoonbirds(uint256[] calldata tokenIds) external view returns (Ask[] memory) {
        Ask[] memory asks = new Ask[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            asks[i] = askForMoonbird[tokenIds[i]];
        }
        return asks;
    }

    /// Set the marketplace fee in basis points
    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external onlyOwner {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    /// Set the marketplace payout address
    function setMarketplaceFeePayoutAddress(address _marketplaceFeePayoutAddress) external onlyOwner {
        marketplaceFeePayoutAddress = _marketplaceFeePayoutAddress;
    }

    /// Set the enforce default royalties flag
    function setEnforceDefaultRoyalties(bool _enforceDefaultRoyalties) external onlyOwner {
        enforceDefaultRoyalties = _enforceDefaultRoyalties;
    }

    /// @dev Provide a way to withdraw any ether that may have been accidentally sent to this contract
    function release() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function _withdrawBird(uint256 _tokenId) private {
        moonbirds.safeTransferWhileNesting(address(this), moonbirdTransferredFromOwner[_tokenId], _tokenId);
        emit BirdWithdrawn(_tokenId, moonbirdTransferredFromOwner[_tokenId]);

        delete moonbirdTransferredFromOwner[_tokenId];
    }

    function _handleMarketplaceFeePayout(uint256 _amount) private returns (uint256) {
        // Get marketplace fee
        uint256 marketplaceFee = _getFeeAmount(_amount, marketplaceFeeBps);
        // payout marketplace fee
        _handleOutgoingTransfer(marketplaceFeePayoutAddress, marketplaceFee);

        return marketplaceFee;
    }

    function _handleRoyaltyPayout(uint256 _amount, uint256 _royaltyFeeBps, uint256 _tokenId) private returns (uint256) {
        // If no fee, return initial amount
        if (_royaltyFeeBps == 0 && !enforceDefaultRoyalties) return 0;

        // Get Moonbirds royalty payout address
        (address moonbirdsRoyaltyPayoutAddress, uint256 royaltyFee) = moonbirds.royaltyInfo(_tokenId, _amount);

        require(moonbirdsRoyaltyPayoutAddress != address(0), "_handleRoyaltyPayout Royalty address not set");

        if (!enforceDefaultRoyalties) {
            // Get custom royalty fee
            royaltyFee = _getFeeAmount(_amount, _royaltyFeeBps);
        }

        // payout royalties
        _handleOutgoingTransfer(moonbirdsRoyaltyPayoutAddress, royaltyFee);

        return royaltyFee;
    }

    function _getFeeAmount(uint256 _amount, uint256 feeBps) private pure returns (uint256) {
        return (_amount * feeBps) / 10000;
    }

    function _handleOutgoingTransfer(
        address _dest,
        uint256 _amount
    ) internal {
        if (_amount == 0 || _dest == address(0)) {
            return;
        }

        require(address(this).balance >= _amount, "_handleOutgoingTransfer insolvent");

        (bool success, ) = _dest.call{value: _amount}("");
        require(success, "transfer failed");
    }

    function _authorizeUpgrade(address) internal view override {
        require(
            _msgSender() == owner(),
            "INVALID_ADMIN"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./SafeMath.sol";

import "./MerkleProof.sol";
import "./Royalties.sol";

abstract contract BaseMint is Royalties {
    using SafeMath for uint256;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _updateTokenOwners(from, to, tokenId);
        _tryToChangeRoyaltyStage();
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _updateTokenOwners(from, to, tokenId);
        _tryToChangeRoyaltyStage();
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Mint n tokens for an address
     * @param to address to mint tokens for
     * @param count_ number of tokens to mint
     */
    function mintNTokensFor(address to, uint8 count_)
        public
        payable
        nonReentrant
    {
        require(publicMintingStarted, NOT_STARTED);
        _internalMint(to, count_, false);
    }

    /**
     * @dev Mint new tokens
     * @param count_ the number of tokens to be minted
     */
    function _internalMint(
        address to,
        uint8 count_,
        bool addRoles
    ) internal {
        require(!paused(), "Minting is paused");
        require(count_ > 0, CANT_MINT);

        uint256 startCount;

        if (addRoles) {
            require(
                numberOfMintedWhitelistTokens + count_ <= MAX_WHITELIST_TOKENS,
                "Cant mint more"
            );
            numberOfMintedWhitelistTokens += count_;

            startCount = numberOfMintedTokensFor[msg.sender] - count_;
            require(
                msg.value == MINT_PRICE_WHITELIST.mul(count_),
                WRONG_BALANCE
            );
        } else {
            require(msg.value == MINT_PRICE.mul(count_), WRONG_BALANCE);
            require(count_ <= MAX_TOKENS_PER_PURCHASE, TOO_MANY);
            require(
                totalSupply() + count_ <=
                    MAX_TOKENS - MAX_RESERVED_TOKENS + mintedReservedTokens,
                TOO_MANY
            );
        }

        for (uint8 i = 0; i < count_; i++) {
            uint256 tokenId = randomId();
            if (addRoles) {
                startCount++;
                tokenRoles[tokenId] = startCount == 1
                    ? ROLE_LION
                    : ROLE_INFERNAL;
            }
            _mintToken(to, tokenId);
        }

        distributePayout(count_);
    }

    /**
     * @dev Mint token for an address
     * @param to address to mint token for
     */
    function _mintRandomToken(address to) internal {
        uint256 tokenId = randomId();
        _mintToken(to, tokenId);
    }

    /**
     * @dev Mint token for an address
     * @param to address to mint token for
     * @param tokenId to be minted
     */
    function _mintToken(address to, uint256 tokenId) internal {
        uint256 currentIndex = ownerTokenList[msg.sender].length;
        ownerTokenList[to].push(tokenId);
        ownedTokensDetails[to][tokenId] = NFTDetails(
            tokenId,
            currentIndex,
            block.timestamp,
            0
        );
        royaltyStages[getLastRoyaltyStageIndex()].totalSupply++;
        _safeMint(to, tokenId);
    }

    function distributePayout(uint8 count_) internal {
        uint256 value = msg.value;
        if (firstPaymentRemaining > 0) {
            address reserve = receiverAddresses[receiverAddresses.length - 1];
            if (value > firstPaymentRemaining) {
                value -= firstPaymentRemaining;
                sendValueTo(reserve, firstPaymentRemaining);
                firstPaymentRemaining = 0;
            } else {
                firstPaymentRemaining -= value;
                sendValueTo(reserve, value);
                return;
            }
        }
        if (
            currentMaxTokensBeforeAutoWithdraw + count_ <
            MAX_TOKENS_BEFORE_AUTO_WITHDRAW &&
            totalSupply() + count_ <
            MAX_TOKENS - MAX_RESERVED_TOKENS + mintedReservedTokens
        ) {
            currentMaxTokensBeforeAutoWithdraw += count_;
            for (uint8 i; i < receiverAddresses.length; i++) {
                currentTeamBalance[i] += (value * receiverPercentages[i]) / 100;
            }
            return;
        }

        currentMaxTokensBeforeAutoWithdraw = 0;
        for (uint8 i; i < receiverAddresses.length; i++) {
            uint256 valueToSend = (value * receiverPercentages[i]) / 100;
            valueToSend += currentTeamBalance[i];
            currentTeamBalance[i] = 0;

            sendValueTo(receiverAddresses[i], valueToSend);
        }
    }

    /**
     * @dev Change token owner details mappings
     */
    function _updateTokenOwners(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint256 currentIndex = ownerTokenList[to].length;
        ownerTokenList[to].push(tokenId);
        ownedTokensDetails[to][tokenId] = NFTDetails(
            tokenId,
            currentIndex,
            block.timestamp,
            0
        );

        _withdrawRoyaltyOfTokenTo(from, from, tokenId);

        NFTDetails storage details = ownedTokensDetails[from][tokenId];
        details.endTime = block.timestamp;

        uint256[] storage fromList = ownerTokenList[from];
        fromList[details.index] = fromList[fromList.length - 1];
        fromList.pop();
    }
}

abstract contract MintReserve is BaseMint {
    function canMintReserved(uint256 count_) internal view {
        require(
            mintedReservedTokens + count_ <= MAX_RESERVED_TOKENS,
            CANT_MINT
        );
    }

    /**
     * @dev Mint reserved team tokens to a specific address
     * @param to addresses to mint token for
     * @param tokenIds numbers of tokens to be minted
     */
    function mintReservedTeamTokensTo(
        address[] memory to,
        uint256[] memory tokenIds
    ) public onlyOwner {
        require(to.length == tokenIds.length, WRONG_LENGTH);
        canMintReserved(to.length);
        mintedReservedTokens += tokenIds.length;
        for (uint256 i; i < to.length; i++) {
            _mintToken(to[i], tokenIds[i]);
        }
    }

    /**
     * @dev Mint reserved tokens to a specific address
     * @param to address to mint token for
     * @param counts numbers of tokens to be minted
     */
    function mintReservedTokensTo(address[] memory to, uint8[] memory counts)
        public
        onlyOwner
    {
        uint256 totalCount;
        for (uint256 i; i < counts.length; i++) {
            totalCount += counts[i];
        }
        canMintReserved(totalCount);
        mintedReservedTokens += totalCount;
        for (uint256 i; i < to.length; i++) {
            address to_ = to[i];
            for (uint256 j; j < counts[i]; j++) {
                _mintRandomToken(to_);
            }
        }
    }
}

abstract contract MintWhitelist is MintReserve, MerkleProof {
    using SafeMath for uint256;

    function startPublicMinting() public onlyOwner {
        require(!publicMintingStarted, ALREADY_ENABLED);
        whitelistMintingStarted = false;
        publicMintingStarted = true;
    }

    function flipWhitelistMinting() public onlyOwner {
        whitelistMintingStarted = !whitelistMintingStarted;
    }

    /**
     * @dev Mint a free token
     * @param to addresses to mint token for
     * @param proof to check if is whitelisted
     */
    function mintForFee(address to, bytes32[] memory proof)
        public
        nonReentrant
    {
        hasValidProof(proof, merkleRootMintFree);
        require(!claimedFree[msg.sender], CANT_MINT);
        claimedFree[msg.sender] = true;
        _mintToken(to, randomId());
    }

    /**
     * @dev Mint a free token
     * @param to addresses to mint token for
     * @param proof to check if is whitelisted
     */
    function mintWhitelist(
        address to,
        uint8 count,
        bytes32[] memory proof
    ) public payable nonReentrant {
        hasValidProof(proof, merkleRoot);
        require(
            numberOfMintedTokensFor[msg.sender] + count <=
                MAX_WHITELIST_PER_PURCHASE,
            "Cant mint more"
        );
        increaseAddressCount(count);
        _internalMint(to, count, true);
    }

    /**
     * @dev Mint one token if it has gold tokens
     * @param to address to mint tokens for
     * @param proof to check if is whitelisted
     */
    function mintForFreeWithGold(address to, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        hasValidProof(proof, merkleRootGoldMintFree);
        require(!claimedGoldFree[msg.sender], CANT_MINT);
        claimedGoldFree[msg.sender] = true;
        canMintFromGold(1);
        increaseAddressCount(1);
        _internalMint(to, 1, true);
    }

    /**
     * @dev Whitelist mint tokens to a specific address
     * @param to address to mint token for
     * @param count_ number of tokens to mint
     */
    function mintWhitelistGoldTo(address to, uint8 count_)
        public
        payable
        nonReentrant
    {
        require(whitelistMintingStarted, NOT_STARTED);
        require(count_ > 0, "Mint more");

        canMintFromGold(count_);
        increaseAddressCount(count_);
        _internalMint(to, count_, true);
    }

    function increaseAddressCount(uint256 count_) internal {
        uint256 currentMintedTokens = count_ +
            numberOfMintedTokensFor[msg.sender];
        numberOfMintedTokensFor[msg.sender] = currentMintedTokens;

        addressRoles[msg.sender] = currentMintedTokens == 1
            ? ROLE_LION
            : ROLE_INFERNAL;
    }

    function canMintFromGold(uint256 count_) internal {
        uint256[] memory tokenIds = soulToken.goldTokensByOwner(msg.sender);
        require(tokenIds.length > 0, CANT_MINT);

        uint256 tempCount = count_;

        uint256 finalCount;
        for (uint256 i; i < tokenIds.length; i++) {
            if (finalCount == count_) {
                break;
            }
            uint256 tokenId = tokenIds[i];
            uint256 oldTokensCount = goldTokenUsed[tokenId];
            uint256 tokensToMint = MAX_PRE_SALE_TOKENS - oldTokensCount;

            if (tokensToMint > tempCount) {
                tokensToMint = tempCount;
            }

            uint8 mintedTokensForGold = uint8(oldTokensCount + tokensToMint);
            goldTokenUsed[tokenId] = mintedTokensForGold;
            soulToken.setGoldRole(tokenId, mintedTokensForGold);

            finalCount += tokensToMint;
            tempCount -= tokensToMint;
        }

        require(finalCount == count_, "can't mint for gold");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./SafeMath.sol";

import "./TokenDetails.sol";
import "./MerkleProof.sol";

abstract contract BaseMint is MerkleProof, TokenDetails {
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
    function mintMultyNTokensFor(address[] memory to, uint8[] memory count_)
        public
        payable
        nonReentrant
    {
        require(publicMintingStarted, NOT_STARTED);
        require(to.length == count_.length, WRONG_LENGTH);

        for (uint256 i; i < to.length; i++) {
            _internalMint(to[i], count_[i], false);
        }
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
        bool whitelisted
    ) internal {
        require(!paused(), "Minting is paused");
        require(count_ > 0, CANT_MINT);
        require(msg.value == MINT_PRICE.mul(count_), WRONG_BALANCE);
        require(count_ <= MAX_TOKENS_PER_PURCHASE, TOO_MANY);
        require(totalSupply() + count_ <= MAX_TOKENS, TOO_MANY);

        uint256 startCount = numberOfMintedTokensFor[msg.sender];

        for (uint8 i; i < count_; i++) {
            uint256 tokenId = randomId();
            startCount++;
            if (startCount == 1) {
                if (whitelisted) {
                    tokenRoles[tokenId] = ROLE_Rare;
                } else {
                    tokenRoles[tokenId] = ROLE_Common;
                }
            } else if (startCount == 2) {
                tokenRoles[tokenId] = ROLE_Uncommon;
                if (
                    !compareStrings(addressRoles[msg.sender], ROLE_Rare) &&
                    !compareStrings(addressRoles[msg.sender], ROLE_Uncommon)
                ) {
                    addressRoles[msg.sender] = ROLE_Uncommon;
                }
            } else if (startCount == 3) {
                tokenRoles[tokenId] = ROLE_Rare;
                if (!compareStrings(addressRoles[msg.sender], ROLE_Rare)) {
                    addressRoles[msg.sender] = ROLE_Rare;
                }
            } else if (startCount == 4) {
                tokenRoles[tokenId] = ROLE_Epic;
                if (!compareStrings(addressRoles[msg.sender], ROLE_Epic)) {
                    addressRoles[msg.sender] = ROLE_Epic;
                }
            } else if (startCount > 4) {
                tokenRoles[tokenId] = ROLE_Legendary;
                if (!compareStrings(addressRoles[msg.sender], ROLE_Legendary)) {
                    addressRoles[msg.sender] = ROLE_Legendary;
                }
            }
            _mintToken(to, tokenId);
        }

        numberOfMintedTokensFor[msg.sender] = startCount;

        distributePayout(count_);
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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
        _safeMint(to, tokenId);
    }

    function distributePayout(uint8 count_) internal {
        uint256 value = msg.value;
        if (
            currentMaxTokensBeforeAutoWithdraw + count_ <
            MAX_TOKENS_BEFORE_AUTO_WITHDRAW &&
            totalSupply() + count_ < MAX_TOKENS
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

        NFTDetails storage details = ownedTokensDetails[from][tokenId];
        details.endTime = block.timestamp;

        uint256[] storage fromList = ownerTokenList[from];
        fromList[details.index] = fromList[fromList.length - 1];
        fromList.pop();
    }
}

abstract contract MintWhitelist is BaseMint {
    function startPublicMinting() public onlyOwner {
        require(!publicMintingStarted, ALREADY_ENABLED);
        whitelistMintingStarted = false;
        publicMintingStarted = true;
    }

    function startWhitelistMinting() public onlyOwner {
        require(!whitelistMintingStarted, ALREADY_ENABLED);
        whitelistMintingStartTime = block.timestamp;
        whitelistMintingStarted = true;
    }

    function stopWhitelistMinting() public onlyOwner {
        require(whitelistMintingStarted, ALREADY_DISABLED);
        whitelistMintingStarted = false;
    }

    function setMaxWhitelistMintingTime(uint256 maxWhitelistMintingTime_)
        public
        onlyOwner
    {
        maxWhitelistMintingTime = maxWhitelistMintingTime_;
    }

    /**
     * @dev Whitelist mint tokens to a specific address
     * @param to address to mint token for
     * @param proof to be validated
     */
    function mintWhitelistTo(address to, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        require(whitelistMintingStarted, NOT_STARTED);
        require(
            block.timestamp - whitelistMintingStartTime <=
                maxWhitelistMintingTime,
            CANT_MINT
        );
        require(
            numberOfMintedTokensFor[msg.sender] == 0 ||
                (numberOfMintedTokensFor[msg.sender] == 1 &&
                    claimedFreeMintedTokensFor[msg.sender] > 0),
            CANT_MINT
        );
        hasValidProof(proof, merkleRoot);

        addressRoles[msg.sender] = ROLE_Rare;

        _internalMint(to, 1, true);
    }

    /**
     * @dev Whitelist mint tokens to a specific address
     * @param to address to mint token for
     * @param proof to be validated
     */
    function mintFreeTo(address to, bytes32[] memory proof)
        public
        nonReentrant
    {
        require(claimedFreeMintedTokensFor[msg.sender] == 0, CANT_MINT);
        hasValidProof(proof, merkleRootFreeMint);

        claimedFreeMintedTokensFor[msg.sender]++;
        numberOfMintedTokensFor[msg.sender]++;
        uint256 tokenId = randomId();
        tokenRoles[tokenId] = ROLE_Uncommon;
        if (!compareStrings(addressRoles[msg.sender], ROLE_Rare)) {
            addressRoles[msg.sender] = ROLE_Uncommon;
        }
        _mintToken(to, tokenId);
    }
}

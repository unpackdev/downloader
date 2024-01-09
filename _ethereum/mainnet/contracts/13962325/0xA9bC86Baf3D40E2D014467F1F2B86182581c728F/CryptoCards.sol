// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "OwnerOrAuthorized.sol";
import "CryptoCardsMessages.sol";
import "CryptoCardsStorage.sol";
import "CryptoCardsFactory.sol";

contract CryptoCards is ERC721Enumerable, OwnerOrAuthorized {
    using Strings for uint256;

    bool public paused;
    CryptoCardsMessages public messages;
    CryptoCardsStorage public store;
    CryptoCardsFactory public factory;

    event CardsMinted(address to, uint256 symbol, uint256[] ids);
    event DeckMinted(address to, uint256 symbol);
    event HandMinted(address to, uint256[5] ids, uint256 handId);
    event ModifiedCardMinted(address to, uint256 id);

    constructor(
        string memory _name,
        string memory _symbol,
        address _messages,
        address _storage,
        address _factory
    ) ERC721(_name, _symbol) {
        messages = CryptoCardsMessages(_messages);
        store = CryptoCardsStorage(_storage);
        factory = CryptoCardsFactory(_factory);
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return store.baseURI();
    }

    function _mintCards(
        address _to,
        uint256 _mintAmount,
        uint256 _symbol,
        uint256 _modifierCard
    ) internal {
        uint256[] memory cardIds = factory.createCards(
            _mintAmount,
            _symbol,
            _modifierCard
        );
        for (uint256 i = 0; i < cardIds.length; i++) {
            _safeMint(_to, cardIds[i]);
        }

        emit CardsMinted(_to, _symbol, cardIds);
    }

    function _addCreatorRewards(
        uint256 _symbol,
        uint256 _modifierCard,
        uint256 _mintingCost
    ) internal {
        uint32 rewardPercentage = store.rewardPercentage();
        uint256 rewardAmount = (_mintingCost * rewardPercentage) / 100;

        // If card(s) were minted using modifier card then add
        // reward amount to modifier card creator's balance (excluding contract owner)
        if (_modifierCard > 0) {
            address creator = store.getModifierCardCreator(_modifierCard);
            if (creator != address(0) && creator != owner()) {
                store.addCreatorRewardTransaction(
                    creator,
                    _modifierCard,
                    0,
                    rewardAmount,
                    0
                );
            }
        } else {
            // Otherwise add to reward amount to symbol creator's balance (excluding contract owner)
            address creator = store.getSymbolCreator(_symbol);
            if (creator != address(0) && creator != owner()) {
                store.addCreatorRewardTransaction(
                    creator,
                    0,
                    _symbol,
                    rewardAmount,
                    0
                );
            }
        }
    }

    function _checkMintingParams(address _to, uint256 _mintCost) internal {
        if (msg.sender != owner()) {
            require(!paused, messages.notAvailable());
            require(msg.value >= _mintCost, messages.notEnoughFunds());
        }
        require(_to != address(0), messages.zeroAddress());
    }

    // Public
    function burn(uint256 _tokenId) public {
        require(!paused, messages.notAvailable());
        require(ownerOf(_tokenId) == msg.sender, messages.mustBeOwner());

        // Hand?
        if (store.getHandOwner(_tokenId) == msg.sender) {
            uint256[5] memory hand = store.getHandCards(_tokenId);

            // Re-allocate cards back to sender
            for (uint256 i = 0; i < hand.length; i++) {
                _safeMint(msg.sender, hand[i]);
            }

            store.setHandOwner(_tokenId, address(0));
            store.setHandCards(
                _tokenId,
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
            );
        }
        _burn(_tokenId);
    }

    function mintCards(
        address _to,
        uint256 _mintAmount,
        uint256 _symbol,
        uint256 _modifierCard
    ) public payable {
        uint256 mintingCost = _modifierCard > 0
            ? (store.cardCost() * 2 * _mintAmount)
            : (store.cardCost() * _mintAmount);
        _checkMintingParams(_to, mintingCost);

        require(store.getSymbolInUse(_symbol), messages.symbolNotFound());
        if (_modifierCard > 0) {
            require(
                ownerOf(_modifierCard) == msg.sender,
                messages.mustBeOwner()
            );
        }

        _mintCards(_to, _mintAmount, _symbol, _modifierCard);
        _addCreatorRewards(_symbol, _modifierCard, mintingCost);
    }

    function mintDeck(address _to, uint256 _symbol) public payable {
        _checkMintingParams(_to, store.deckCost());

        if (msg.sender != owner()) {
            require(store.getDeckMintUnlocking() == 0, messages.notAvailable());
        }
        require(!store.getSymbolInUse(_symbol), messages.symbolInUse());

        // Add new symbol
        store.addSymbol(_to, _symbol);

        // Create initial shuffled deck
        factory.createDeck(_symbol);

        // Mint cards to new deck owner
        _mintCards(_to, store.maxMintAmount(), _symbol, 0);

        store.resetDeckMintUnlocking();

        emit DeckMinted(_to, _symbol);
    }

    function mintHand(address _to, uint256[5] memory _tokenIds) public payable {
        _checkMintingParams(_to, store.handCost());

        uint256 supply = store.getTotalCards();
        require(supply + 1 <= store.maxSupply(), messages.exceedsSupply());
        require(_tokenIds.length == 5, messages.fiveCardsRequired());

        // Check that the sender is the owner of all the cards
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0, messages.fiveCardsRequired());
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                messages.mustBeOwner()
            );
        }

        // Save tokenIds of cards in the data property
        uint256 data = (_tokenIds[0] & 0xFFFFFF) |
            ((_tokenIds[1] & 0xFFFFFF) << 24) |
            ((_tokenIds[2] & 0xFFFFFF) << 48) |
            ((_tokenIds[3] & 0xFFFFFF) << 72) |
            ((_tokenIds[4] & 0xFFFFFF) << 96);

        uint256 handTokenId = store.addCard(
            factory.createCard(DecodedCard(HAND_CARD, 0, 0, 0, 0, 0, 0), data)
        );
        _safeMint(_to, handTokenId);

        // Burn cards so that they cannot be minted into a hand again.
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }

        store.setHandOwner(handTokenId, _to);

        // Save the tokenIds that form the hand so they can be re-instated if the hand is ever burnt
        store.setHandCards(handTokenId, _tokenIds);

        emit HandMinted(_to, _tokenIds, handTokenId);
    }

    function mintModifiedCard(
        address _to,
        uint256 _originalCard,
        uint256 _modifierCard
    ) public payable {
        _checkMintingParams(_to, store.cardCost() * 2);

        require(ownerOf(_originalCard) == msg.sender, messages.mustBeOwner());
        require(ownerOf(_modifierCard) == msg.sender, messages.mustBeOwner());

        uint256 cardId = factory.createModifiedCard(
            _originalCard,
            _modifierCard
        );
        _safeMint(_to, cardId);
        _addCreatorRewards(0, _modifierCard, store.cardCost() * 2);

        emit ModifiedCardMinted(_to, cardId);
    }

    function mintModifierCard(
        address _to,
        string memory _name,
        uint256 _value,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _flags,
        bytes memory _data
    ) public payable returns (uint256) {
        _checkMintingParams(_to, store.modifierCost());

        require(bytes(_name).length > 0, messages.nameRequired());
        require(
            store.getModifierCardIdByName(_name) == 0,
            messages.modifierNameAlreadyInUse()
        );
        require(_data.length <= 256, messages.dataLengthExceeded());

        uint256 newCardId = factory.createModifierCard(
            _value,
            _background,
            _foreground,
            _color,
            _flags
        );
        _safeMint(_to, newCardId);
        store.addModifierCard(newCardId, _to, _name, _data);
        return newCardId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), messages.erc721InvalidTokenId());

        bool usePermanentStorage = store.getUsePermanentStorage(tokenId);
        string memory currentBaseURI = usePermanentStorage
            ? store.permanentStorageBaseURI()
            : _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        usePermanentStorage
                            ? store.permanentStorageExtension()
                            : store.baseExtension()
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getCreatorRewardsBalance(address _creator)
        public
        view
        returns (uint256)
    {
        return store.getCreatorRewardsBalance(_creator);
    }

    function getCreatorRewards(address _creator)
        public
        view
        returns (Reward[] memory)
    {
        return store.getCreatorRewards(_creator);
    }

    function withdrawRewardBalance() public payable {
        uint256 contractBalance = address(this).balance;
        uint256 callerRewards = getCreatorRewardsBalance(msg.sender);
        require(callerRewards < contractBalance, messages.notEnoughFunds());
        store.addCreatorRewardTransaction(msg.sender, 0, 0, 0, callerRewards);
        require(payable(msg.sender).send(callerRewards));
    }

    // Only owner
    function setPaused(bool _value) public onlyOwner {
        paused = _value;
    }

    function getNetBalance() public view onlyOwner returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 totalCreatorRewards = store.getTotalRewardsBalance();
        return contractBalance - totalCreatorRewards;
    }

    function withdrawNetBalance() public payable onlyOwner {
        uint256 ownerBalance = getNetBalance();
        require(ownerBalance > 0, messages.notEnoughFunds());
        require(payable(msg.sender).send(ownerBalance));
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "OwnerOrAuthorized.sol";
import "CryptoCardsMessages.sol";
import "CryptoCardsStorage.sol";

struct DecodedCard {
    uint256 value;
    uint256 suit;
    uint256 background;
    uint256 foreground;
    uint256 color;
    uint256 symbol;
    uint256 modifierFlags;
}

contract CryptoCardsFactory is OwnerOrAuthorized {
    CryptoCardsMessages messages;
    CryptoCardsStorage store;
    uint256 private psuedoRandomSeed;

    uint256[] private CARD_BACKGROUND_COLORS = [
        0xff99b433,
        0xff00a300,
        0xff1e7145,
        0xffff0097,
        0xff9f00a7,
        0xff7e3878,
        0xff603cba,
        0xff1d1d1d,
        0xff00aba9,
        0xff2d89ef,
        0xff2b5797,
        0xffffc40d,
        0xffe3a21a,
        0xffda532c,
        0xffee1111,
        0xffb91d47
    ];

    constructor(address _messages, address _storage) OwnerOrAuthorized() {
        messages = CryptoCardsMessages(_messages);
        store = CryptoCardsStorage(_storage);
    }

    // Internal
    function _encodeCardAttributes(
        uint256 _value,
        uint256 _suit,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _symbol,
        uint256 _modifierFlags
    ) internal pure returns (uint256) {
        return
            _value |
            (_suit << BITOFFSET_SUIT) |
            (_background << BITOFFSET_BACKGROUND) |
            (_foreground << BITOFFSET_FOREGROUND) |
            (_color << BITOFFSET_COLOR) |
            (_symbol << BITOFFSET_SYMBOL) |
            (_modifierFlags << BITOFFSET_FLAGS);
    }

    function _createRandomCard(uint256 _symbol) internal returns (uint256) {
        uint256 nextCardIndex = store.getDeckCardCount(_symbol);
        bytes memory shuffledCards = store.getShuffledDeck(_symbol);

        require(shuffledCards.length > 0, messages.missingShuffledDeck());

        // Good enough psuedo-random number; only used for background
        unchecked {
            psuedoRandomSeed = psuedoRandomSeed == 0
                ? uint256(blockhash(block.number - 1)) + 1
                : psuedoRandomSeed + uint256(blockhash(block.number - 1)) + 1;
        }
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, psuedoRandomSeed)
            )
        );

        uint8 nextCard = uint8(shuffledCards[nextCardIndex % 52]);
        uint256 value = nextCard % 13;
        uint256 suit = nextCard / 13;
        uint256 background = CARD_BACKGROUND_COLORS[randomValue % 16];

        return
            store.addCard(
                createCard(
                    DecodedCard(
                        value,
                        suit,
                        background,
                        DEFAULT_FOREGROUND,
                        DEFAULT_COLOR,
                        _symbol,
                        0
                    ),
                    0
                )
            );
    }

    function _modifyCard(uint256 _baseCardId, uint256 _modifierCardId)
        internal
    {
        Card memory baseCard = store.getCard(_baseCardId);
        Card memory modifierCard = store.getCard(_modifierCardId);

        uint256 value = baseCard.attributes & 0xFF;
        uint256 suit = (baseCard.attributes >> BITOFFSET_SUIT) & 0xFF;
        uint256 background = (baseCard.attributes >> BITOFFSET_BACKGROUND) &
            0xFFFFFFFF;
        uint256 foreground = (baseCard.attributes >> BITOFFSET_FOREGROUND) &
            0xFFFFFFFF;
        uint256 color = (baseCard.attributes >> BITOFFSET_COLOR) & 0xFFFFFFFF;
        uint256 symbol = (baseCard.attributes >> BITOFFSET_SYMBOL) & 0xFFFFFFFF;
        uint256 modifierFlags = modifierCard.attributes >> BITOFFSET_FLAGS;

        // background
        if (modifierFlags & FLAGS_SET_BACKGROUND == FLAGS_SET_BACKGROUND) {
            background =
                (modifierCard.attributes >> BITOFFSET_BACKGROUND) &
                0xFFFFFFFF;
        }

        // foreground
        if (modifierFlags & FLAGS_SET_FOREGROUND == FLAGS_SET_FOREGROUND) {
            foreground =
                (modifierCard.attributes >> BITOFFSET_FOREGROUND) &
                0xFFFFFFFF;
        }

        // color
        if (modifierFlags & FLAGS_SET_COLOR == FLAGS_SET_COLOR) {
            color = (modifierCard.attributes >> BITOFFSET_COLOR) & 0xFFFFFFFF;
        }

        // modifiers
        if (modifierFlags & FLAGS_DATA_APPEND == FLAGS_DATA_APPEND) {
            // append
            require(
                (baseCard.modifiers & (uint256(0xFFFF) << (32 * 8))) == 0,
                messages.modifierDataFull()
            );
            baseCard.modifiers =
                (baseCard.modifiers << 16) |
                (_modifierCardId & 0xFFFF);
        } else {
            // overwrite
            baseCard.modifiers = _modifierCardId;
        }

        baseCard.attributes = _encodeCardAttributes(
            value,
            suit,
            background,
            foreground,
            color,
            symbol,
            modifierFlags
        );
        store.setCard(_baseCardId, baseCard);
        store.incrementModifierCardUsageCount(_modifierCardId);
    }

    // Public
    function createCard(DecodedCard memory _cardValues, uint256 _data)
        public
        onlyAuthorized
        returns (Card memory)
    {
        return
            Card(
                _encodeCardAttributes(
                    _cardValues.value,
                    _cardValues.suit,
                    _cardValues.background,
                    _cardValues.foreground,
                    _cardValues.color,
                    _cardValues.symbol,
                    _cardValues.modifierFlags
                ),
                _data
            );
    }

    function createCards(
        uint256 _count,
        uint256 _symbol,
        uint256 _modifierCardId
    ) external onlyAuthorized returns (uint256[] memory) {
        uint256 supply = store.getTotalCards();
        uint256 deckSupply = store.getDeckCardCount(_symbol);

        require(_count > 0, messages.mintAmount());
        require(_count <= store.maxMintAmount(), messages.mintAmount());
        require(supply + _count <= store.maxSupply(), messages.exceedsSupply());
        require(
            deckSupply + _count <= store.maxCardsPerDeck(),
            messages.exceedsSupply()
        );

        if (_modifierCardId > 0) {
            require(
                store.getModifierCardUsageCount(_modifierCardId) + _count <
                    store.maxModifierUsage(),
                messages.modifierUsage()
            );
            require(
                store.getModifierCardInUse(_modifierCardId) == true,
                messages.modifierNotFound()
            );
        }

        uint256[] memory result = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            result[i] = _createRandomCard(_symbol);
            if (_modifierCardId > 0) {
                _modifyCard(result[i], _modifierCardId);
            }
        }
        return result;
    }

    // Create an array of 52 values and shuffle
    function createDeck(uint256 _symbol) external onlyAuthorized {
        bytes memory a = store.getPreshuffledDeck();

        unchecked {
            psuedoRandomSeed = psuedoRandomSeed == 0
                ? uint256(blockhash(block.number - 1)) + 1
                : psuedoRandomSeed + uint256(blockhash(block.number - 1)) + 1;
        }

        // Shuffle
        for (uint256 sourceIndex; sourceIndex < 52; sourceIndex++) {
            uint256 destIndex = sourceIndex +
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            msg.sender,
                            psuedoRandomSeed
                        )
                    )
                ) % (52 - sourceIndex));
            bytes1 temp = a[destIndex];
            a[destIndex] = a[sourceIndex];
            a[sourceIndex] = temp;
        }

        store.setShuffledDeck(_symbol, a);
    }

    function createModifiedCard(
        uint256 _originalCardId,
        uint256 _modifierCardId
    ) external onlyAuthorized returns (uint256) {
        uint256 supply = store.getTotalCards();
        require(supply + 1 <= store.maxSupply(), messages.exceedsSupply());

        if (_modifierCardId > 0) {
            require(
                store.getModifierCardUsageCount(_modifierCardId) <
                    store.maxModifierUsage(),
                messages.modifierUsage()
            );
            require(
                store.getModifierCardInUse(_modifierCardId) == true,
                messages.modifierNotFound()
            );
        }

        Card memory originalCard = store.getCard(_originalCardId);
        uint256 clonedCardId = store.addCard(
            Card(originalCard.attributes, originalCard.modifiers)
        );
        _modifyCard(clonedCardId, _modifierCardId);
        return clonedCardId;
    }

    function createModifierCard(
        uint256 _value,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _flags
    ) external onlyAuthorized returns (uint256) {
        require(
            store.getTotalCards() + 1 <= store.maxSupply(),
            messages.exceedsSupply()
        );

        Card memory card = createCard(
            DecodedCard(
                _value | MODIFIER_CARD,
                0,
                (_flags & FLAGS_SET_BACKGROUND) == FLAGS_SET_BACKGROUND
                    ? _background
                    : DEFAULT_MODIFIER_BACKGROUND,
                (_flags & FLAGS_SET_FOREGROUND) == FLAGS_SET_FOREGROUND
                    ? _foreground
                    : DEFAULT_FOREGROUND,
                (_flags & FLAGS_SET_COLOR) == FLAGS_SET_COLOR
                    ? _color
                    : DEFAULT_COLOR,
                0,
                _flags
            ),
            0
        );

        return store.addCard(card);
    }
}

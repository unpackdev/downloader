// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

abstract contract Factory {
    function balanceOf(uint256 _tokenId, uint256 _optionId)
        public
        view
        virtual
        returns (bool);
}

library LootBoxRandomness {
    using SafeMath for uint256;

    // Event for logging lootbox opens
    event LootBoxOpened(
        uint256 indexed optionId,
        address indexed buyer,
        uint256 boxesPurchased,
        uint256 itemsMinted
    );
    event Warning(string message, address account);

    uint256 constant INVERSE_BASIS_POINT = 10000;

    struct OptionSettings {
        uint256 maxQuantityPerOpen;
        uint256[] classProbabilities;
        bool hasGuaranteedClasses;
        uint256[] guarantees;
    }

    struct LootBoxRandomnessState {
        address factoryAddress;
        uint256 numOptions;
        uint256 numClasses;
        uint256 numBox;
        mapping(uint256 => OptionSettings) optionToSettings;
        mapping(uint256 => mapping(uint256 => uint256)) classToTokenIds;
        uint256 seed;
    }

    function initState(
        LootBoxRandomnessState storage _state,
        address _factoryAddress,
        uint256 _numOptions,
        uint256 _numClasses,
        uint256 _numBox,
        uint256 _seed
    ) public {
        _state.factoryAddress = _factoryAddress;
        _state.numOptions = _numOptions;
        _state.numClasses = _numClasses;
        _state.numBox = _numBox;
        _state.seed = _seed;
    }

    function setTokenIdsForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxId,
        uint256 _classId,
        uint256 _tokenIds
    ) public {
        require(_boxId < _state.numBox, "Box out of range");
        require(_classId < _state.numClasses, "_class out of range");
        _state.classToTokenIds[_boxId][_classId] = _tokenIds;
    }

    function getTokenIdsForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxId,
        uint256 _classId
    ) public view returns (uint256) {
        require(_boxId < _state.numBox, "Box out of range");
        require(_classId < _state.numClasses, "_class out of range");
        return _state.classToTokenIds[_boxId][_classId];
    }

    function setOptionSettings(
        LootBoxRandomnessState storage _state,
        uint256 _option,
        uint256 _maxQuantityPerOpen,
        uint256[] memory _classProbabilities,
        uint256[] memory _guarantees
    ) public {
        require(_option < _state.numOptions, "_option out of range");

        bool hasGuaranteedClasses = false;
        for (uint256 i = 0; i < _guarantees.length; i++) {
            if (_guarantees[i] > 0) {
                hasGuaranteedClasses = true;
            }
        }

        OptionSettings memory settings = OptionSettings({
            maxQuantityPerOpen: _maxQuantityPerOpen,
            classProbabilities: _classProbabilities,
            hasGuaranteedClasses: hasGuaranteedClasses,
            guarantees: _guarantees
        });

        _state.optionToSettings[uint256(_option)] = settings;
    }

    function getQuantityPerOpen(
        LootBoxRandomnessState storage _state,
        uint256 _option
    ) public view returns (uint256) {
        require(_option < _state.numOptions, "_option out of range");

        return _state.optionToSettings[uint256(_option)].maxQuantityPerOpen;
    }

    function getQuantityGarantee(
        LootBoxRandomnessState storage _state,
        uint256 _option,
        uint256 classId
    ) public view returns (uint256) {
        require(_option < _state.numOptions, "_option out of range");

        return _state.optionToSettings[uint256(_option)].guarantees[classId];
    }

    function setSeed(LootBoxRandomnessState storage _state, uint256 _newSeed)
        public
    {
        _state.seed = _newSeed;
    }

    function _normalMint(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        uint256 _boxNum
    ) internal returns (uint256 _tokenId, uint256 _classId) {
        require(_optionId < _state.numOptions, "_option out of range");
        require(_boxNum < _state.numBox, "_boxNum out of range");
        // Load settings for this box option
        OptionSettings memory settings = _state.optionToSettings[_optionId];

        require(
            settings.maxQuantityPerOpen > 0,
            "LootBoxRandomness#_mint: OPTION_NOT_ALLOWED"
        );

        _classId = (_pickRandomClass(_state, settings.classProbabilities));
        _tokenId = _sendTokenWithClass(_state, _boxNum, _classId);
        
        return (_tokenId, _classId);
    }

    function _mint(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        uint256 _randClassId,
        bool hasGuaranteed,
        uint256 _boxNum
    ) internal returns (uint256 _tokenId, uint256 _classId) {
        require(_optionId < _state.numOptions, "_option out of range");
        require(_boxNum < _state.numBox, "_boxNum out of range");
        // Load settings for this box option
        OptionSettings memory settings = _state.optionToSettings[_optionId];

        require(
            settings.maxQuantityPerOpen > 0,
            "LootBoxRandomness#_mint: OPTION_NOT_ALLOWED"
        );

        if (hasGuaranteed) {
            uint256 randClass = _pickRandomClass(_state, settings.classProbabilities);
            if (randClass > _randClassId) {
                _classId = (randClass);
            } else {
                _classId = (_randClassId);
            }
            _tokenId = _sendTokenWithClass(
                _state,
                _boxNum,
                _classId
            );
        } else {
            _classId = (_pickRandomClass(_state, settings.classProbabilities));
            _tokenId = _sendTokenWithClass(_state, _boxNum, _classId);
        }
        
        return (_tokenId, _classId);
    }

    function _sendTokenWithClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxNum,
        uint256 _classId
    ) internal returns (uint256) {
        require(_classId < _state.numClasses, "_class out of range");
        uint256 tokenId = _pickRandomAvailableTokenIdForClass(
            _state,
            _boxNum,
            _classId
        );
        return tokenId;
    }

    function _pickRandomClass(
        LootBoxRandomnessState storage _state,
        uint256[] memory _classProbabilities
    ) public returns (uint256) {
        uint256 value = uint256(_random(_state).mod(INVERSE_BASIS_POINT));
        for (uint256 i = uint256(_classProbabilities.length) - 1; i > 0; i--) {
            uint256 probability = _classProbabilities[i];
            if (value < probability) {
                return i;
            } else {
                value = value - probability;
            }
        }
        return 0;
    }

    function _pickRandomAvailableTokenIdForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxNum,
        uint256 _classId
    ) internal returns (uint256) {
        require(_classId < _state.numClasses, "_class out of range");
        uint256 tokenIds = _state.classToTokenIds[_boxNum][_classId];
        require(tokenIds > 0, "No token ids for _classId");
        uint256 randIndex = _random(_state).mod(tokenIds);
        Factory factory = Factory(_state.factoryAddress);
        for (uint256 i = randIndex; i < randIndex + tokenIds; i++) {
            uint256 tokenId = i % tokenIds;
            if (factory.balanceOf(tokenId, _boxNum)) {
                return tokenId;
            }
        }
        revert(
            "LootBoxRandomness#_pickRandomAvailableTokenIdForClass: NOT_ENOUGH_TOKENS_FOR_CLASS"
        );
    }

    function _random(LootBoxRandomnessState storage _state)
        internal
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    _state.seed
                )
            )
        );
        _state.seed = randomNumber;
        return randomNumber;
    }
}

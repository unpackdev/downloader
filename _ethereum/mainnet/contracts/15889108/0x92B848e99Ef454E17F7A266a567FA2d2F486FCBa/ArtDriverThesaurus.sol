// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./Strings.sol";

import "./IThesaurus.sol";
import "./Random.sol";

contract ArtDriverThesaurus is OwnableUpgradeable, IThesaurus {
    mapping(address => bool) public minters;

    string[] public verbs;
    string[] public adjs;
    string[] public nouns;

    modifier isMinter() {
        require(minters[msg.sender], "ArtDriverThesaurus: sender is not a minter");
        _;
    }

    event AddMinter(address minter);
    event SubMinter(address minter);

    constructor() {
        initialize();
    }

    function initialize() public initializer {
        __Ownable_init();
        verbs.push();
        adjs.push();
        nouns.push();
    }

    // ============= view function =============

    function VERB_TYPE() public pure override returns (uint8) {
        return 1;
    }

    function ADJ_TYPE() public pure override returns (uint8) {
        return 2;
    }

    function NOUN_TYPE() public pure override returns (uint8) {
        return 3;
    }

    function verbsAmount() external view returns (uint256) {
        return verbs.length - 1;
    }

    function adjsAmount() external view returns (uint256) {
        return adjs.length - 1;
    }

    function nounsAmount() external view returns (uint256) {
        return nouns.length - 1;
    }

    function totalWordsAmount() external view override returns (uint256) {
        return verbs.length + adjs.length + nouns.length - 3;
    }

    function randomWords(uint256 _nonce)
        external
        view
        override
        returns (
            string memory _verb,
            string memory _adj,
            string memory _noun
        )
    {
        uint256 randNonce = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _nonce)));
        _verb = verbs[Random.random(1, verbs.length, randNonce - 333)];
        _adj = adjs[Random.random(1, adjs.length, randNonce - 111)];
        _noun = nouns[Random.random(1, nouns.length, randNonce - 777)];
    }

    // ============= write function =============

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
        emit AddMinter(_minter);
    }

    function subMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit SubMinter(_minter);
    }

    function addWord(
        uint8 _type,
        uint256 _weight,
        string memory _word
    ) external override isMinter {
        if (_type == VERB_TYPE()) {
            _addWord(_weight, _word, verbs);
        } else if (_type == ADJ_TYPE()) {
            _addWord(_weight, _word, adjs);
        } else if (_type == NOUN_TYPE()) {
            _addWord(_weight, _word, nouns);
        } else {
            require(
                false,
                string(abi.encodePacked("ArtDriverThesaurus: There is no such type [", Strings.toString(_type), " ]"))
            );
        }
    }

    // ============= owner function =============

    function addWords(uint8 _type, string[] memory _words) external onlyOwner {
        if (_type == 1) {
            _addWord(_words, verbs);
        } else if (_type == 2) {
            _addWord(_words, adjs);
        } else if (_type == 3) {
            _addWord(_words, nouns);
        } else {
            require(
                false,
                string(abi.encodePacked("ArtDriverThesaurus: There is no such type [", Strings.toString(_type), " ]"))
            );
        }
    }

    // ============= internal function =============

    function _addWord(
        uint256 _weight,
        string memory _content,
        string[] storage _array
    ) private {
        for (uint256 i = 0; i < _weight; i++) {
            _array.push(_content);
        }
    }

    function _addWord(string[] memory _words, string[] storage _array) private {
        for (uint256 i = 0; i < _words.length; i++) {
            _array.push(_words[i]);
        }
    }
}

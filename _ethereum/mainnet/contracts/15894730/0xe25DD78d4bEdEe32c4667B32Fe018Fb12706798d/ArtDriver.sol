// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

import "./Array.sol";
import "./Random.sol";
import "./ArtDriverEvent.sol";
import "./IThesaurus.sol";

contract ArtDriver is ArtDriverEvent, OwnableUpgradeable, ERC721EnumerableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIds;

    uint8 private constant GREY_TYPE = 1;
    uint8 private constant BLUE_TYPE = 2;
    uint8 private constant ORANGE_TYPE = 3;

    IThesaurus public thesaurus;
    string public baseURI;
    uint256 public price;
    bytes32 public merkleRoot;
    uint256 public mintStartTime;

    //type => remaining amount
    mapping(uint8 => uint256) public typeAmount;

    //tokenId => verb content
    mapping(uint256 => string) public verb;

    //tokenId => adj content
    mapping(uint256 => string) public adj;

    //tokenId => noun content
    mapping(uint256 => string) public noun;

    //tokenId => whether to add words
    mapping(uint256 => string) public added;

    //tokenId => Is it locked
    mapping(uint256 => bool) public locked;

    //tokenId => driver type
    mapping(uint256 => uint8) public types;

    mapping(address => bool) public claimed;
    //address => Number of additional mint allowed
    mapping(address => uint256) public allowedMintAmount;

    //address => Number of has been minted
    mapping(address => uint256) public minted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _thesaurus,
        uint256 _price,
        uint256 _orangeAmount,
        uint256 _blueAmount,
        uint256 _greyAmount,
        bytes32 _merkleRoot,
        uint256 _mintStartTime
    ) {
        initialize(
            _name,
            _symbol,
            _baseURI,
            _thesaurus,
            _price,
            _orangeAmount,
            _blueAmount,
            _greyAmount,
            _merkleRoot,
            _mintStartTime
        );
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _thesaurus,
        uint256 _price,
        uint256 _orangeAmount,
        uint256 _blueAmount,
        uint256 _greyAmount,
        bytes32 _merkleRoot,
        uint256 _mintStartTime
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        baseURI = _baseURI;
        thesaurus = IThesaurus(_thesaurus);
        price = _price;
        typeAmount[GREY_TYPE] = _greyAmount;
        typeAmount[BLUE_TYPE] = _blueAmount;
        typeAmount[ORANGE_TYPE] = _orangeAmount;
        merkleRoot = _merkleRoot;
        mintStartTime = _mintStartTime;
    }

    // ============= view function =============

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ArtDriver: URI query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    Strings.toString(_tokenId),
                    "/",
                    Strings.toString(types[_tokenId]),
                    "/",
                    verb[_tokenId],
                    "/",
                    adj[_tokenId],
                    "/",
                    noun[_tokenId],
                    "/",
                    added[_tokenId]
                )
            );
    }

    function verifyProof(
        bytes32[] memory _proof,
        address _recipient,
        uint256 _amount
    ) public view returns (bool) {
        bytes32 _data = keccak256(abi.encode(_recipient, _amount));
        return MerkleProofUpgradeable.verify(_proof, merkleRoot, _data);
    }

    function freeMintAmount(address _player) external view returns (uint256) {
        return allowedMintAmount[_player];
    }

    // ============= write function =============

    function mint(address _player, uint256 _amount) external payable returns (uint256[] memory) {
        if (msg.sender != owner()) {
            require(
                block.timestamp >= mintStartTime || allowedMintAmount[_player] > 0,
                "ArtDriver: Non-whitelisted users have not yet opened mint"
            );
            if (block.timestamp < mintStartTime && allowedMintAmount[_player] < _amount)
                _amount = allowedMintAmount[_player];

            uint256 _payAmount;
            if (_amount >= allowedMintAmount[_player]) {
                _payAmount = _amount - allowedMintAmount[_player];
                allowedMintAmount[_player] = 0;
            } else {
                allowedMintAmount[_player] -= _amount;
            }
            require(msg.value >= (price * _payAmount), "ArtDriver: msg.value Deficiency");
        }

        uint256[] memory tokensId = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            tokensId[i] = _mint(_player);
        }
        return tokensId;
    }

    function refreshWords(uint256 _tokenId) external {
        require(_exists(_tokenId), "ArtDriver: URI query for nonexistent token");
        require(!locked[_tokenId], "ArtDriver: token is locked");
        require(ownerOf(_tokenId) == msg.sender, "ArtDriver: You are not owner");

        (string memory _verb, string memory _adj, string memory _noun) = thesaurus.randomWords(totalSupply());
        verb[_tokenId] = _verb;
        adj[_tokenId] = _adj;
        noun[_tokenId] = _noun;

        emit RefreshWords(_tokenId, _verb, _adj, _noun);
    }

    function lock(uint256 _tokenId) external {
        require(_exists(_tokenId), "ArtDriver: URI query for nonexistent token");
        require(!locked[_tokenId], "ArtDriver: token is locked");
        require(ownerOf(_tokenId) == msg.sender, "ArtDriver: You are not owner");

        locked[_tokenId] = true;
        emit Locked(_tokenId);
    }

    function addWord(
        uint256 _tokenId,
        uint8 _type,
        string memory _word
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "ArtDriverr: You are not owner");
        require(bytes(added[_tokenId]).length == 0, "ArtDriverr: token is added");
        require(bytes(_word).length < 30 && bytes(_word).length > 0, "ArtDriver: word minimum 0, maximum 30 characters");

        added[_tokenId] = _word;

        uint256 _weight;
        if (types[_tokenId] == GREY_TYPE) {
            _weight = 1;
        } else if (types[_tokenId] == BLUE_TYPE) {
            _weight = 5;
        } else if (types[_tokenId] == ORANGE_TYPE) {
            _weight = thesaurus.totalWordsAmount().div(100);
        } else {
            require(
                false,
                string(abi.encodePacked("ArtDriver: There is no such type [", Strings.toString(_type), " ]"))
            );
        }

        thesaurus.addWord(_type, _weight, _word);
        emit AddWord(_tokenId, _weight, _word);
    }

    function claimMintAmount(
        address _recipient,
        bytes32[] memory _proof,
        uint256 _amount
    ) external {
        require(!claimed[_recipient], "ArtDriver: This address is claimed");
        require(verifyProof(_proof, _recipient, _amount), "ArtDriver: The proof could not be verified.");

        allowedMintAmount[_recipient] = _amount;
        claimed[_recipient] = true;
        emit ClaimMintAmount(_recipient, _amount);
    }

    // ============= owner function =============

    function setPrice(uint256 _price) external onlyOwner {
        uint256 _old = price;
        price = _price;
        emit NewPrice(_old, _price);
    }

    function transferEth(address _recipient, uint256 _amount) external payable onlyOwner {
        payable(_recipient).transfer(_amount);
        emit TransferEth(_recipient, _amount);
    }

    // ============= internal function =============

    function _mint(address _player) internal returns (uint256 _newTokenId) {
        _newTokenId = _tokenIds.current();

        //words
        (string memory _verb, string memory _adj, string memory _noun) = thesaurus.randomWords(totalSupply());
        verb[_newTokenId] = _verb;
        adj[_newTokenId] = _adj;
        noun[_newTokenId] = _noun;

        //type
        uint8 _type = _randomType(_newTokenId);
        types[_newTokenId] = _type;
        typeAmount[_type] -= 1;

        minted[_player] += 1;

        _mint(_player, _newTokenId);

        _tokenIds.increment();
        emit Mint(_newTokenId, _player, _verb, _adj, _noun, _type);
    }

    function _randomType(uint256 _tokenId) private view returns (uint8 _type) {
        if (typeAmount[BLUE_TYPE] == 0 && typeAmount[ORANGE_TYPE] == 0) return GREY_TYPE;

        // 90 : 9 : 1, <=90: GREY_TYPE, 91-99: BLUE_TYPE, 100: ORANGE_TYPE
        uint256 _randomNum = 100;
        uint8 _random = Random.random8(1, _randomNum, _tokenId);

        if (_random == 100) _type = ORANGE_TYPE;
        else if (100 > _random && 90 < _random) _type = BLUE_TYPE;
        else _type = GREY_TYPE;

        if (_type == ORANGE_TYPE && typeAmount[ORANGE_TYPE] == 0) return GREY_TYPE;
        if (_type == BLUE_TYPE && typeAmount[BLUE_TYPE] == 0) return GREY_TYPE;
    }

    // ============= base function =============

    fallback() external payable {}

    receive() external payable {}
}

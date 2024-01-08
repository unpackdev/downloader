// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
// import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Quantum is ReentrancyGuard, ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Mapping from token ID to sides count
    mapping(uint256 => uint8) public _tokenSides;

    // Mapping from token ID to faimilyId
    mapping(uint256 => uint8) public _tokenFamily;

    // when a token is reborn, it's not removed, just labeled as dead, so one can track the previous lifes of a token;
    mapping(uint256 => bool) public _tokenDark;

    // is it a Descendent?
    mapping(uint256 => bool) public _tokenDescendent;

    // lifeSpan
    mapping(uint256 => uint256) public _tokenLifespan;

    //Remaining shared descendent quota
    uint8 public _numDescendents = 48;

    //precalc-URI table
    mapping(uint256 => string) private _keyURIs;

    //Family descendent quota
    mapping(uint8 => uint8) public _familyDescendent;

    //Num of family, whne a new "original" token is minted, it starts a new family
    uint8 public _numFamilies;

    // when a token can reborn, set it to a small number for testing;
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    //max sides
    uint8 constant _maxSides = 20;

    uint8 constant _maxFamilies = 8;

    //prob of descendent , 50%
    //todo: change to ??
    uint8 constant _probDescendent = 65;

    event Print(address indexed owner, uint256 tokenId);

    //todo:change to Kevin's
    address constant _artist = 0xA57fB5A5aD51beb3854D801ea3Ad6AC2845CD082;

    // Num of tokens
    uint256 public _numTokens;

    modifier artistOnly {
        require(msg.sender == _artist, "you are not the artist;");
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function originate(address to, uint8 sides)
        external
        nonReentrant
        artistOnly
    {
        //used to create a “brand new" family .
        require(_numFamilies < _maxFamilies, "too many families");
        require(sides < _maxSides, "too many sides");

        _numFamilies = _numFamilies + 1;

        _spawn(to, sides, _numFamilies);
    }

    function tokenKey(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "nonexistent token");
        //       (family,1 digit)+(sides,2 digits)+(dark,1 digit)+(descendent,1 digt)+("0000")
        return
            100000000 *
            uint256(_tokenFamily[tokenId]) +
            1000000 *
            uint256(_tokenSides[tokenId]) +
            uint256(_tokenDark[tokenId] ? 1 : 0) *
            100000 +
            uint256(_tokenDescendent[tokenId] ? 1 : 0) *
            10000;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");
        string memory _tokenURI = _keyURIs[tokenKey(tokenId)];
        string memory base = "https://quantumleap.mccoyspace.com/";

        //if no preset key, use "https://www.mccoyspace.com/tokenName"
        if (bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenName(tokenId)));
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).

        return string(abi.encodePacked(base, _tokenURI));
    }

    function _setKeyURI(uint256 key, string memory _keyURI) public artistOnly {
        _keyURIs[key] = _keyURI;
    }

    function _spawn(
        address to,
        uint8 sides,
        uint8 family
    ) internal {
        //

        _numTokens = _numTokens + 1;
        _tokenSides[_numTokens] = sides;
        _tokenFamily[_numTokens] = family;
        // _tokenDark[_numTokens]=false;
        _tokenLifespan[_numTokens] = randLifespan(family);

        // _tokenDescendent[_numTokens]=false;

        _safeMint(to, _numTokens);

        emit Print(to, _numTokens);
    }

    //generate name of token following this convention: family code - side count - token type;

    function tokenName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "token name for nonexisting token");
        uint8 _i = _tokenSides[tokenId];
        uint8 j = _i;
        uint8 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len + 2);
        bstr[0] = bytes1(_tokenFamily[tokenId] + 64); //first letter: A-H
        bstr[1] = bytes1(uint8(45)); //second letter, "dash/minus"
        uint8 k = len + 2;
        while (_i != 0) {
            //convert sides from int to string;
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        if (_tokenDark[tokenId]) {
            return string(abi.encodePacked(string(bstr), "-darkstar.json"));
        } else {
            if (_tokenDescendent[tokenId]) {
                return
                    string(abi.encodePacked(string(bstr), "-descendent.json"));
            } else {
                return
                    string(abi.encodePacked(string(bstr), "-primordial.json"));
            }
        }
    }

    function canReborn(uint256 tokenId) public view returns (bool _canBorn) {
        if (_tokenLifespan[tokenId] == 0) {
            //not exist, or max sides
            return false;
        }
        if (_tokenLifespan[tokenId] > block.timestamp) {
            //not the time yet
            return false;
        }
        if (_tokenDescendent[tokenId]) {
            //a descendent cannot reborn
            return false;
        }
        if (_tokenDark[tokenId]) {
            //a darkstart cannot reborn
            return false;
        }
        return true;
    }

    function rebornAndDescendent(uint256 tokenId) external nonReentrant {
        require(canReborn(tokenId), "token cannot reborn");
        require(msg.sender == ownerOf(tokenId), "Only owner can reborn");

        //randomly determine if there is descendent.
        uint256 randomNumber =
            uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number,
                            tokenId
                        )
                    )
                ) % 100
            );
        if (randomNumber < _probDescendent) {
            descendent(tokenId);
        }

        reborn(tokenId);
    }

    function reborn(uint256 tokenId) internal {
        _tokenDark[copy(tokenId)] = true; //create a new dark star;

        _tokenSides[tokenId] = _tokenSides[tokenId] + 1;
        if (_tokenSides[tokenId] == _maxSides) {
            _tokenLifespan[tokenId] = 0;
        } else {
            _tokenLifespan[tokenId] = randLifespan(_tokenFamily[tokenId]);
        }
    }

    function copy(uint256 tokenId) internal returns (uint256 _newId) {
        _numTokens = _numTokens + 1;
        _tokenSides[_numTokens] = _tokenSides[tokenId];
        _tokenFamily[_numTokens] = _tokenFamily[tokenId];
        _safeMint(msg.sender, _numTokens);
        emit Print(msg.sender, _numTokens);
        return _numTokens;
    }

    function randLifespan(uint8 family)
        public
        view
        returns (uint256 _lifespan)
    {
        // random between 1-3 yr [todo: change back to 1-3yr]
        return
            block.timestamp +
            uint256(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number,
                            family
                        )
                    )
                ) % (2 * 365)) + 365
            ) *
            DAY_IN_SECONDS;
    }

    function descendent(uint256 tokenId) internal {
        if (_familyDescendent[_tokenFamily[tokenId]] == 0) {
            //first descendent of the family
            _familyDescendent[_tokenFamily[tokenId]] = 1;
        } else {
            if (_numDescendents > 0) {
                _numDescendents = _numDescendents - 1;
            } else {
                return;
            }
        }
        _tokenDescendent[copy(tokenId)] = true;
    }
}

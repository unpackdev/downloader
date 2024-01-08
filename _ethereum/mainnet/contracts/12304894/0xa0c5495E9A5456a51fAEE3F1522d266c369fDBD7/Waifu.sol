pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Math.sol";

contract Waifu is ERC721, Ownable {
    uint256 constant public MAX_SUPPLY = 2048;

    uint256 constant public SET_STATUS_PRICE = 1000000000000000; // 0.001 ETH
    uint256 constant public LIKE_PRICE = 1000000000000000; // 0.001 ETH

    uint256 constant private _BASE_SET_NAME_PRICE = 1000000000000000000; // 1 ETH
    uint256 constant private _SET_NAME_PRICE_DISCOUNT_PER_LIKE = 10000000000000000; // 0.01 ETH
    uint256 constant private _SET_NAME_PRICE_DISCOUNT_MAX_LIKES = 100;

    uint256 constant private _BASE_LEVEL = 1;
    uint256 constant private _MAX_LEVEL = 6;
    mapping(uint256 => uint256) private _LEVEL_DURATION;

    string private _baseURI = "https://waifu.art/";

    mapping(uint256 => string) private _statuses;
    mapping(uint256 => string) private _names;
    mapping(string => uint256) private _nameIndex;

    mapping(uint256 => uint256) private _likes;
    mapping(uint256 => mapping(address => bool)) _likesIndex;

    mapping(uint256 => uint256) private _levels;
    mapping(uint256 => uint256) private _steps;
    mapping(uint256 => uint256) private _lastStepTime;
    mapping(uint256 => mapping(address => bool)) private _way;

    mapping(address => bool) private _promo;

    event Like(uint256 indexed tokenId, address from, uint256 likes);
    event LevelUp(uint256 indexed tokenId, uint256 level);
    event SetName(uint256 indexed tokenId, string name);
    event SetStatus(uint256 indexed tokenId, string status);

    constructor() ERC721("Waifu", "WFU") Ownable() public {
        _LEVEL_DURATION[1] = 86400 * 2;
        _LEVEL_DURATION[2] = 86400 * 4;
        _LEVEL_DURATION[3] = 86400 * 8;
        _LEVEL_DURATION[4] = 86400 * 16;
        _LEVEL_DURATION[5] = 86400 * 32;
    }

    function getMintPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "Waifu: there are no more waifus here");

        if (currentSupply >= 2040) {
            return 4000000000000000000;
            // 2041 - 2048 4 ETH
        } else if (currentSupply >= 2024) {
            return 2000000000000000000;
            // 2025 - 2040 2 ETH
        } else if (currentSupply >= 1992) {
            return 1000000000000000000;
            // 1993 - 2024 1 ETH
        } else if (currentSupply >= 1928) {
            return 800000000000000000;
            // 1929 - 1992 0.8 ETH
        } else if (currentSupply >= 1800) {
            return 400000000000000000;
            // 1801 - 1928 0.4 ETH
        } else if (currentSupply >= 1544) {
            return 200000000000000000;
            // 1545 - 1800 0.2 ETH
        } else if (currentSupply >= 1032) {
            return 100000000000000000;
            // 1033 - 1544 0.1 ETH
        } else if (currentSupply >= 8) {
            return 50000000000000000;
            // 9 - 1032 0.05 ETH
        } else {
            return 0;
            // 1 - 8 FREE
        }
    }

    function isPromoAvailable(address from) public view returns (bool) {
        uint256 mintPrice = getMintPrice();
        return mintPrice == 0 && !_promo[from];
    }

    function getSetNamePrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        uint256 level = getLevel(tokenId);
        require(level == _MAX_LEVEL, "Waifu: your waifu needs to reach max level to be named");

        return _BASE_SET_NAME_PRICE - (Math.min(getLikes(tokenId), _SET_NAME_PRICE_DISCOUNT_MAX_LIKES) * _SET_NAME_PRICE_DISCOUNT_PER_LIKE);
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function setBaseURI(string memory baseURI) onlyOwner public {
        _baseURI = baseURI;
    }

    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        if (_levels[tokenId] == 0) {
            _levels[tokenId] = _BASE_LEVEL;
        }
        _steps[tokenId] = _steps[tokenId] + 1;
        _lastStepTime[tokenId] = block.timestamp;
        _way[tokenId][to] = true;
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        if (!_way[tokenId][to]) {
            _steps[tokenId] = _steps[tokenId] + 1;
            _lastStepTime[tokenId] = block.timestamp;
            _way[tokenId][to] = true;
        }
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        return _levels[tokenId];
    }

    function getAvailableLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        uint256 level = Math.min(_MAX_LEVEL, _steps[tokenId]);
        if (level < _MAX_LEVEL) {
            uint256 timeFrom = _lastStepTime[tokenId];
            uint256 additionalLevels = 0;
            for (uint256 currentLevel = level; currentLevel < _MAX_LEVEL; currentLevel++) {
                if (timeFrom + _LEVEL_DURATION[currentLevel] < block.timestamp) {
                    additionalLevels++;
                    timeFrom = timeFrom + _LEVEL_DURATION[currentLevel];
                }
            }
            level = Math.min(_MAX_LEVEL, level + additionalLevels);
        }
        return level;
    }

    function getNextAvailableLevelTimestamp(uint256 tokenId) public view returns (uint256) {
        uint256 availableLevel = getAvailableLevel(tokenId);
        require(availableLevel < _MAX_LEVEL, "Waifu: maximum available level reached");
        uint256 timeFrom = _lastStepTime[tokenId];
        for (uint256 currentLevel = availableLevel; currentLevel < _MAX_LEVEL; currentLevel++) {
            if (timeFrom + _LEVEL_DURATION[currentLevel] < block.timestamp) {
                timeFrom = timeFrom + _LEVEL_DURATION[currentLevel];
            } else {
                return timeFrom + _LEVEL_DURATION[currentLevel];
            }
        }
    }

    function levelUp(uint256 tokenId, uint256 level) public {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        require(ownerOf(tokenId) == msg.sender, "Waifu: you can upgrade only waifu you own");
        uint256 currentLevel = getLevel(tokenId);
        require(level <= _MAX_LEVEL, "Waifu: wrong level");
        require(level >= _BASE_LEVEL, "Waifu: wrong level");
        require(level > currentLevel, "Waifu: you can not decrease level of your waifu");
        uint256 availableLevel = getAvailableLevel(tokenId);
        require(level <= availableLevel, "Waifu: this level is not available for your waifu");
        _levels[tokenId] = level;
        emit LevelUp(tokenId, level);
    }

    function getTop() public view returns (uint256[] memory) {
        uint256 currentSupply = totalSupply();
        uint256[] memory likes = new uint256[](currentSupply + 1);
        for (uint256 tokenId = 1; tokenId <= currentSupply; tokenId++) {
            likes[tokenId] = _likes[tokenId];
        }
        return likes;
    }

    function getLikes(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        return _likes[tokenId];
    }

    function isLikeAvailable(uint256 tokenId, address from) public view returns (bool) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        return ownerOf(tokenId) != from && !_likesIndex[tokenId][from];
    }

    function like(uint256 tokenId) public payable {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        require(ownerOf(tokenId) != msg.sender, "Waifu: you can not like your own waifu");
        require(isLikeAvailable(tokenId, msg.sender), "Waifu: you have already liked this waifu");
        require(msg.value >= LIKE_PRICE, "Waifu: not enough ether to like");

        _likesIndex[tokenId][msg.sender] = true;
        _likes[tokenId] = _likes[tokenId] + 1;
        emit Like(tokenId, msg.sender, _likes[tokenId]);
    }

    function setStatus(uint256 tokenId, string memory status) public payable {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        require(ownerOf(tokenId) == msg.sender, "Waifu: you can set status only for waifu you own");
        require(msg.value >= SET_STATUS_PRICE, "Waifu: not enough ether to set status");

        _statuses[tokenId] = status;
        emit SetStatus(tokenId, status);
    }

    function getStatus(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        return _statuses[tokenId];
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        return _names[tokenId];
    }

    function isNameAvailable(string memory name) public view returns (bool) {
        return validateName(name) && _nameIndex[toLower(name)] == 0;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function validateName(string memory name) public pure returns (bool) {
        bytes memory b = bytes(name);
        if (b.length < 1) return false;
        if (b.length > 25) return false;
        // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false;
        // Leading space
        if (b[b.length - 1] == 0x20) return false;
        // Trailing space

        bytes1 lastChar = b[0];
        bool onlyNumbers = true;

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false;
            // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x20) //space
            ) {
                return false;
            }

            if (!(char >= 0x30 && char <= 0x39)) {
                onlyNumbers = false;
            }

            lastChar = char;
        }

        if (onlyNumbers) {
            return false;
        }

        return true;
    }

    function setName(uint256 tokenId, string memory name) public payable {
        require(_exists(tokenId), "Waifu: this waifu does not exists");
        require(ownerOf(tokenId) == msg.sender, "Waifu: you can name only waifu you own");
        require(sha256(bytes(_names[tokenId])) == sha256(bytes("")), "Waifu: your waifu already has a name");
        require(validateName(name), "Waifu: invalid name");
        require(isNameAvailable(name), "Waifu: this name is already taken");
        require(msg.value >= getSetNamePrice(tokenId), "Waifu: not enough ether to name your waifu");

        _names[tokenId] = name;
        _nameIndex[toLower(name)] = tokenId;
        emit SetName(tokenId, name);
    }

    function getTokenIdByName(string memory name) public view returns (uint256) {
        uint256 tokenId = _nameIndex[toLower(name)];
        require(tokenId != 0, "Waifu: there is no waifu with such name");
        return tokenId;
    }

    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory resultBytes = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            resultBytes[j] = bytesString[j];
        }

        return string(resultBytes);
    }

    function uintToBytes(uint v) private pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function uintToString(uint v) private pure returns (string memory) {
        return bytes32ToString(uintToBytes(v));
    }

    function bytes32ToHex(bytes32 input) internal pure returns (string memory) {
        uint256 number = uint256(input);
        bytes memory numberAsString = new bytes(66); // "0x" and then 2 chars per byte
        numberAsString[0] = byte(uint8(48));  // '0'
        numberAsString[1] = byte(uint8(120)); // 'x'

        for (uint256 n = 0; n < 32; n++) {
            uint256 nthByte = number / uint256(uint256(2) ** uint256(248 - 8 * n));

            // 1 byte to 2 hexadecimal numbers
            uint8 hex1 = uint8(nthByte) / uint8(16);
            uint8 hex2 = uint8(nthByte) % uint8(16);

            // 87 is ascii for '0', 48 is ascii for 'a'
            hex1 += (hex1 > 9) ? 87 : 48; // shift into proper ascii value
            hex2 += (hex2 > 9) ? 87 : 48; // shift into proper ascii value
            numberAsString[2 * n + 2] = byte(hex1);
            numberAsString[2 * n + 3] = byte(hex2);
        }
        return string(numberAsString);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 level = getLevel(tokenId);
        string memory hash = bytes32ToHex(sha256(abi.encodePacked(uintToString(tokenId), "_", uintToString(level))));
        return string(abi.encodePacked(_baseURI, hash, ".json"));
    }

    function mint() public payable {
        uint256 currentSupply = totalSupply();
        uint256 mintPrice = getMintPrice();
        require(msg.value >= mintPrice, "Waifu: current waifu price is already higher");
        require(mintPrice > 0 || !_promo[msg.sender], "Waifu: only one free waifu per address");
        uint256 waifuId = currentSupply + 1;
        _mint(msg.sender, waifuId);
        if (mintPrice == 0) {
            _promo[msg.sender] = true;
        }
    }

    receive() external payable {
        mint();
    }
}

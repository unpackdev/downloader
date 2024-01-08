// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
'########:'########:'########:'##:::::::'####:'##::: ##:'########:
 ##.....:: ##.....:: ##.....:: ##:::::::. ##:: ###:: ##: ##.....::
 ##::::::: ##::::::: ##::::::: ##:::::::: ##:: ####: ##: ##:::::::
 ######::: ######::: ######::: ##:::::::: ##:: ## ## ##: ######:::
 ##...:::: ##...:::: ##...:::: ##:::::::: ##:: ##. ####: ##...::::
 ##::::::: ##::::::: ##::::::: ##:::::::: ##:: ##:. ###: ##:::::::
 ##::::::: ########: ########: ########:'####: ##::. ##: ########:
..::::::::........::........::........::....::..::::..::........::
:'######::'##:::::::'##::::'##:'########::
'##... ##: ##::::::: ##:::: ##: ##.... ##:
 ##:::..:: ##::::::: ##:::: ##: ##:::: ##:
 ##::::::: ##::::::: ##:::: ##: ########::
 ##::::::: ##::::::: ##:::: ##: ##.... ##:
 ##::: ##: ##::::::: ##:::: ##: ##:::: ##:
. ######:: ########:. #######:: ########::
:......:::........:::.......:::........:::
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title FeelineClub
 */
contract FeelineClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // The total number of tokens available
    uint256 private _currentTokenId = 0;

    // Max number of items that can be minted
    uint256 public constant MAX_FEELINES = 9999;

    // Max allowed items on multiple mint
    uint256 private constant MAX_MULTIPLE_MINT_COUNT = 20;

    /* The feel of each token, valid values are 0-8
     * When calling the API this value is translated into the following characters
     * Any other value defaults to 0 (AA)
     *
     * 0 - AA
     * 1 - AB
     * 2 - AC
     * 3 - BA
     * 4 - BB
     * 5 - BC
     * 6 - CA
     * 7 - CB
     * 8 - CC
     */
    mapping(uint256 => uint256) private _feels;

    // User Data
    // Values that will be customizable when supportsUserValues is enabled
    mapping(uint256 => uint256) private _userVals;

    // Hidden Data
    // Values to be revealed until supportsHiddenValues is enabled
    mapping(uint256 => uint256) private _hiddenVals;

    // If true, allows userValues functionality
    bool private _allowUserValues;

    // If true, allows hiddenValues functionality
    bool private _allowHiddenValues;

    // Metadata base URI
    string private _baseTokenURI;

    // Contract-level metadata URI
    string private _contractURI;

    // Event called when the feel value is changed
    event ChangeFeel(address caller, uint256 from, uint256 to);

    // Event called when userVal is changed
    event ChangeUserVal(address caller, uint256 from, uint256 to);

    // Event called when userValues is enabled
    event AllowUserValues();

    // Event called when hiddenValues is enabled
    event AllowHiddenValues();

    // Constructor
    constructor() ERC721("FeelineClub", "FLC") {
        _allowUserValues = false;
        _allowHiddenValues = false;
    }

    // Helper function to convert uint to string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Gets the URI for contract-level metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Gets the metadata base URI
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns an URI for a given `tokenId`
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory feelChars = "AA";

        if (_feels[_tokenId] == 1) {
            feelChars = "AB";
        } else if (_feels[_tokenId] == 2) {
            feelChars = "AC";
        } else if (_feels[_tokenId] == 3) {
            feelChars = "BA";
        } else if (_feels[_tokenId] == 4) {
            feelChars = "BB";
        } else if (_feels[_tokenId] == 5) {
            feelChars = "BC";
        } else if (_feels[_tokenId] == 6) {
            feelChars = "CA";
        } else if (_feels[_tokenId] == 7) {
            feelChars = "CB";
        } else if (_feels[_tokenId] == 8) {
            feelChars = "CC";
        }

        string memory userString = string(
            abi.encodePacked("-", uint2str(_userVals[_tokenId]))
        );

        string memory hiddenString = "-0";
        if (_allowHiddenValues == true) {
            hiddenString = string(
                abi.encodePacked("-", uint2str(_hiddenVals[_tokenId]))
            );
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    Strings.toString(_tokenId),
                    feelChars,
                    userString,
                    hiddenString
                )
            );
    }

    /**
     * @dev Mints a new item and assigns a random feel
     */
    function mintTo(address _to) public onlyOwner {
        require(
            _currentTokenId.add(1) <= MAX_FEELINES,
            "Cannot exceed max token limit"
        );

        uint256 newTokenId = _currentTokenId.add(1);
        _safeMint(_to, newTokenId);
        _currentTokenId++;

        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, newTokenId)
            )
        );
        _feels[newTokenId] = randomHash % 9;

        uint256 randomHidden = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    newTokenId,
                    "1"
                )
            )
        );
        _hiddenVals[newTokenId] = randomHidden % 10000;

        _userVals[newTokenId] = 0;
    }

    /**
     * @dev Mints new items and assigns them a random feel
     */
    function mintMultipleTo(address _to, uint256 _count) public onlyOwner {
        require(
            _currentTokenId.add(_count) <= MAX_FEELINES,
            "Cannot exceed max token limit"
        );
        require(
            _count <= MAX_MULTIPLE_MINT_COUNT,
            "Cannot exceed max mint limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            mintTo(_to);
        }
    }

    /**
     * @dev Sets the base URI for metadata
     */
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    /**
     * @dev Sets the URI for contract-level metadata
     */
    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    /**
     * @dev Changes the feel value of a token
     * userVals will be ignored until supportsUserValues is enabled
     */
    function setFeel(
        uint256 _feel,
        uint256 _tokenId,
        uint256 _userVal
    ) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "Caller is not owner of the token"
        );
        require(_feel <= 8, "Invalid feel, must be a int between 0 and 8");
        require(
            _userVal <= 99999999,
            "Invalid userVal, must be a int between 0 and 99999999"
        );

        uint256 prevFeel = _feels[_tokenId];
        _feels[_tokenId] = _feel;
        emit ChangeFeel(msg.sender, prevFeel, _feel);

        if (_allowUserValues) {
            uint256 prevUserVal = _userVals[_tokenId];
            _userVals[_tokenId] = _userVal;
            emit ChangeUserVal(msg.sender, prevUserVal, _userVal);
        }
    }

    /**
     * @dev Gets the feel value of a token
     */
    function getFeel(uint256 _tokenId) public view returns (uint256) {
        return _feels[_tokenId];
    }

    /**
     * @dev Gets the userVal value of a token
     */
    function getUserVal(uint256 _tokenId) public view returns (uint256) {
        require(
            _allowUserValues == true,
            "Not allowed until supportsUserValues is enabled"
        );
        return _userVals[_tokenId];
    }

    /**
     * @dev Gets the hiddenVal value of a token
     */
    function getHiddenVal(uint256 _tokenId) public view returns (uint256) {
        require(
            _allowHiddenValues == true,
            "Not allowed until supportsHiddenValues is enabled"
        );
        return _hiddenVals[_tokenId];
    }

    /**
     * @dev Allows userVals functionality. This action cannot be undone
     */
    function startAllowUserValues() public onlyOwner {
        require(
            _allowUserValues == false,
            "Not allowed, supportsUserValues is already enabled"
        );
        _allowUserValues = true;
        emit AllowUserValues();
    }

    /**
     * @dev Allows hiddenVals functionality. This action cannot be undone
     */
    function startAllowHiddenValues() public onlyOwner {
        require(
            _allowHiddenValues == false,
            "Not allowed, supportsHiddenValues is already enabled"
        );
        _allowHiddenValues = true;
        emit AllowHiddenValues();
    }

    /**
     * @dev Returns true if userValues are allowed to be stored
     */
    function supportsUserValues() public view returns (bool) {
        return _allowUserValues;
    }

    /**
     * @dev Returns true if hidenVals are allowed to be shown
     */
    function supportsHiddenValues() public view returns (bool) {
        return _allowHiddenValues;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

import "./Archival.sol";

contract TheArchive is ERC721, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _tokens;

    uint256 public price = 0.25 * 1e18;
    uint256 public rollMintLimit = 2;
    uint256 public mintLimitSize = 36;
    string public baseUri = 'https://ipfs.infura.io/ipfs/';
    string public imageUri = 'https://api.thedigitalarchive.art/image/';
    bool public onchain=true;
    string public description;
    address withdrawalAddress;

    struct Token {
        bool        exists;
        string      cid;
        bool        snippet;
        uint256     rotation;
        string      film;
        string      color;
    }
    mapping (uint256 => Token) public Tokens;

    bool public saleStart;
    bool public requireIncludeList;
    mapping (address => bool) public    IncludeList;
    mapping (uint256 => mapping (address => uint256)) public    RollWallet;

    constructor(address _withdraw) ERC721("TheArchive", "ARCHIVE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        withdrawalAddress = _withdraw;
    }

    modifier onlyTeam() {
        require(isTeam(msg.sender));
        _;
    }

    function isTeam(address account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function mint(uint256 tokenId) public payable {
        require(saleStart && !_exists(tokenId) && Tokens[tokenId].exists && msg.value == price);
        if(requireIncludeList) {
            require(IncludeList[msg.sender]);
        }
        uint256 roll = tokenId.div(mintLimitSize);
        require(RollWallet[roll][msg.sender]+1 <= rollMintLimit);

        _safeMint(msg.sender, tokenId);
        RollWallet[roll][msg.sender]++;
    }

    function mintTeam(uint256 tokenId, address receiver) public onlyTeam {
        require(!_exists(tokenId) && Tokens[tokenId].exists);
        _safeMint(receiver, tokenId);
    }

    function createToken(string memory cid, uint256 rotation, string memory film, bool exists, string memory color) public onlyTeam {
        _tokens.increment();
        Tokens[_tokens.current()] = Token(exists, cid, true, rotation, film, color);
    }

    function editToken(uint256 tokenId, string memory cid, uint256 rotation, string memory film, bool exists, string memory color) public onlyTeam {
        Tokens[tokenId].exists = exists;
        Tokens[tokenId].cid = cid;
        Tokens[tokenId].rotation = rotation;
        Tokens[tokenId].film = film;
        Tokens[tokenId].color = color;
    }

    function ownerTokenSettings(uint256 tokenId, bool snippet, uint256 rotation) public {
        require(ownerOf(tokenId) == msg.sender && rotation < 4);
        Tokens[tokenId].rotation = rotation;
        Tokens[tokenId].snippet = snippet;
    }

    function tokenExists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function getTokensForSale() public view returns(uint256[] memory tokens) {
        uint256 saleCount = 0;
        for(uint256 i=1; i<= _tokens.current(); i++) {
            if(Tokens[i].exists && !tokenExists(i)) {
                saleCount++;
            }
        }
        tokens = new uint256[](saleCount);
        uint256 index;
        for(uint256 i=1; i<= _tokens.current(); i++) {
            if(Tokens[i].exists && !tokenExists(i)) {
                tokens[index] = i;
                index++;
            }
        }
    }

    function contractSettings(bool _saleStart, bool _requireIncludeList, uint256 _price, string memory _baseUri, string memory _imageUri, bool _onchain, string memory _description, uint256 _rollMintLimit, uint256 _mintLimitSize) public onlyTeam {
        saleStart = _saleStart;
        requireIncludeList = _requireIncludeList;
        price = _price;
        baseUri = _baseUri;
        imageUri = _imageUri;
        onchain = _onchain;
        description = _description;
        rollMintLimit = _rollMintLimit;
        mintLimitSize = _mintLimitSize;
    }

    function addIncludeListBulk(address[] memory include, uint256 total) public onlyTeam {
        for(uint256 i=0; i<total; i++) {
            IncludeList[include[i]] = true;
        }
    }

    function removeIncludeListBulk(address[] memory include, uint256 total) public onlyTeam {
        for(uint256 i=0; i<total; i++) {
            IncludeList[include[i]] = false;
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory output) {
        if(!onchain) {
            output = string(abi.encodePacked(baseUri, tokenId));
        } else {
            string memory attributes = Archival.makeAttributes(Tokens[tokenId].film);
            string memory svg;
            if(!Tokens[tokenId].snippet) {
                svg = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(Archival.makeSVG(baseUri, Tokens[tokenId].cid, Tokens[tokenId].snippet, Tokens[tokenId].rotation)))));
            } else {
                svg = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(Archival.makeSVGSnippet(baseUri, Tokens[tokenId].cid, Tokens[tokenId].snippet, Tokens[tokenId].rotation, tokenId, Tokens[tokenId].film, Tokens[tokenId].color)))));
            }
            string memory image = string(abi.encodePacked(imageUri, Archival.toString(tokenId)));
            string memory json = Base64.encode(bytes(Archival.makeJson(Archival.tokenName(tokenId), description, image, svg, attributes)));
            output = string(abi.encodePacked('data:application/json;base64,', json));
        }
    }

    /**
    *   External function for getting all tokens by a specific owner.
    */
    function getByOwner(address _owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(_owner));
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= _tokens.current(); t++) {
            if (_exists(t) && ownerOf(t) == _owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IAccessControl).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyTeam {
        require(payable(withdrawalAddress).send(address(this).balance));
    }

}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


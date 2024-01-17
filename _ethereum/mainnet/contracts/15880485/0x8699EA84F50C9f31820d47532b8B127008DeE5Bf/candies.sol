// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**                                                      
 *      ,-----.  ,---.  ,--.  ,--.,------.  ,--.,------. ,---.   
 *     '  .--./ /  O  \ |  ,'.|  ||  .-.  \ |  ||  .---''   .-'  
 *     |  |    |  .-.  ||  |' '  ||  |  \  :|  ||  `--, `.  `-.  
 *     '  '--'\|  | |  ||  | `   ||  '--'  /|  ||  `---..-'    | 
 *      `-----'`--' `--'`--'  `--'`-------' `--'`------'`-----'  
 *
 *                   by @p0pps  ~  Est. 2022
 */
                                 
import "./ERC721.sol";
import "./AccessControl.sol";
import "./ERC721Royalty.sol";
import "./BitMaps.sol";
import "./Strings.sol";
import "./Base64.sol";

contract Candies is ERC721, ERC721Royalty, AccessControl {
    using Random for Random.Manifest;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string baseURI = "https://static.mustardlabs.io/candies/";
    string movURI = "https://static.mustardlabs.io/candies/";
    string externalURI = "https://candies.shop/candies/";
    mapping(uint => string) public names;
    mapping(uint => string) public attributes;
    mapping(uint => uint) public codes;
    mapping(uint => uint) public countsByType;
    uint public totalCount;
    bool public initComplete;
    Random.Manifest private collectionDeck;
    mapping(uint => Random.Manifest) private candyDecks;
    mapping(uint => uint) public unwrappedIds;
    BitMaps.BitMap private unwrapped;

    event Unwrap(uint tokenId, address indexed wallet, uint unwrappedID);
    event Add(uint index, uint count);

    constructor() ERC721("Grandma's Candies", "CANDIES") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(0xaF2b0Ff9227cC905ddb05139Dde85B6121023a27, 500);
    }

// Mint

    function mint(address _to) public onlyRole(MINTER_ROLE) {
        uint _pull = collectionDeck.draw();
        _safeMint(_to, _pull);
    }

    function unwrap(uint _tokenId, address _to) public onlyRole(MINTER_ROLE) {
        require(_exists(_tokenId), "Can't unwrap nonexistent token");
        require(ownerOf(_tokenId) == _to, "You don't own this candy");
        require(!unwrapped.get(_tokenId), "Already unwrapped");
        unwrapped.set(_tokenId);
        uint _pull = candyDecks[getType(_tokenId)].draw();
        uint _unwrappedId = _pull;
        for (uint i = 0; i < getType(_tokenId); i++){
            _unwrappedId += countsByType[i];
        }
        unwrappedIds[_tokenId] = _unwrappedId;
        emit Unwrap(_tokenId, _to, _unwrappedId);
    }

// View

    function remaining() public view returns (uint256) {
        return collectionDeck.remaining();
    }

    function getType(uint _tokenId) public view returns (uint) {
        return codes[_tokenId] / 10;
    }

    function getName(uint _tokenId) public view returns (string memory) {
        return names[ getType(_tokenId)];
    }

    function getMetadataJson(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Query for nonexistent token");
        uint _code = codes[_tokenId];
        string memory _status = unwrapped.get(_tokenId) ? "unwrapped" : "wrapped";
        uint _imageId = unwrapped.get(_tokenId) ? unwrappedIds[_tokenId] : _tokenId;
        string memory _attributes = string(abi.encodePacked('[\n{"trait_type":"Type","value": "',names[_code / 10],'"},\n'));

        if (unwrapped.get(_tokenId)) { // unwrapped
            _attributes = string(abi.encodePacked(_attributes,'{"trait_type":"Status","value": "Unwrapped"},\n'));
            _attributes = string(abi.encodePacked(_attributes,attributes[_code % 10]));
        } else { // wrapped
            _attributes = string(abi.encodePacked(_attributes,'{"trait_type":"Status","value": "Wrapped"}'));
        }
        _attributes = string(abi.encodePacked(_attributes,'\n]'));

        string memory meta = string(
            abi.encodePacked(
            '{\n"name":"#', _tokenId.toString(),', ',names[_code / 10],
            '",\n"description": "Grandma', "'", 's Candies by @p0pps', 
            '",\n"attributes":', _attributes
            )
        );
        meta = string(
            abi.encodePacked(
                meta,
                ',\n"external_url": "',externalURI, _tokenId.toString(),
                '",\n"image": "', baseURI, _status,'/', _imageId.toString(),'.gif"',
                ',\n"mp4": "', movURI, _status,'/', _imageId.toString(),'.mp4"'
            )
        );
      return string( abi.encodePacked(meta,'\n}'));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      string memory json = Base64.encode(bytes(getMetadataJson(tokenId)));
      string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
      );
      return output;
    }

// Contract Admin

    // Don't use!
    function somedayMint(address _to, uint _id) public onlyRole(MINTER_ROLE) {
        require(remaining() == 0, "Use at your own risk dummy.");
        require(_id > 229, "Can't mint in that range.");
        _safeMint(_to, _id);
    }

    function set(uint _index, uint8 _code) public onlyRole(MINTER_ROLE) {
        codes[_index] = _code;
    }

    function setBaseURI(string memory _val) public onlyRole(MINTER_ROLE) {
        baseURI = _val;
    }

    function setMovURI(string memory _val) public onlyRole(MINTER_ROLE) {
        movURI = _val;
    }
    function setExternalURI(string memory _val) public onlyRole(MINTER_ROLE) {
        externalURI = _val;
    }

// Initial Setup (Admin)

    function setName(uint index, string memory name) public onlyRole(MINTER_ROLE) {
        names[index] = name;
    }
    
    function setAttribute(uint index, string memory attribute) public onlyRole(MINTER_ROLE) {
        attributes[index] = attribute;
    }

    function add(uint _startIndex, uint8[] memory arr) public onlyRole(MINTER_ROLE) {
        totalCount += arr.length;   
        for (uint i = 0; i < arr.length; i++) {
            codes[i + _startIndex] = arr[i];
        }
        emit Add(_startIndex, arr.length);
    }

    function init() public onlyRole(MINTER_ROLE) {
        require(!initComplete,"Init complete.");
        uint _numTypes = 4;
        uint[] memory _counts = new uint[](_numTypes);
        for (uint i = 0; i < totalCount; i++) {
            _counts[codes[i] / 10]++;
        }
        uint _checkTotal;
        for (uint i = 0; i < _numTypes; i++) {
            _checkTotal += _counts[i];
            countsByType[i] = _counts[i];
        }
        require(totalCount == _checkTotal, "Totals don't match on init.");
        collectionDeck.setup(totalCount);
        for (uint i = 0; i < _numTypes; i++) {
            candyDecks[i].setup(_counts[i]);
        }
        initComplete = true;
    }

// Overrides

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "cannot-setup-during-active-draw");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}
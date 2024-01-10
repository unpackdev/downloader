// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";

interface GardenCenter{

    function transferOwnership(address _owner) external;
}

contract GardenCenterOwnershipToken is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    address public owner;
    mapping(uint256 => address) public tokenIdToCollection;
    mapping(address => uint256) public collectionToTokenId;
    mapping(address => address) public collectionToCenter;
    mapping(address => bool) public collectionExists;
    mapping(address => string) public altCollectionNames;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        owner = _msgSender();
    }

    function mint(address to, address collection, address center) public virtual {

        require(hasRole(MINTER_ROLE, _msgSender()), "mint: must have minter role to mint");
        
        uint256 next = _tokenIdTracker.current();

        require(!collectionExists[collection], "mint: collection exists already.");

        _tokenIdTracker.increment();

        tokenIdToCollection[next] = collection;
        collectionToTokenId[collection] = next;
        collectionToCenter[collection] = center;
        collectionExists[collection] = true;

        _mint(to, next);
    }

    function getCollectionName(address collection) external view returns(string memory){

        return ERC721(collection).name();
    }

    function getSupportsInterface(address collection) external view returns(bool){

        bytes4 InterfaceID_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

        return ERC721(collection).supportsInterface(InterfaceID_ERC165);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        address collection = tokenIdToCollection[tokenId];
    
        require(collection != address(0) && _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _collection = addressToString(collection);
        string memory collectionName = "";
        string memory altName = altCollectionNames[collection];

        if(bytes(altName).length > 0){

            collectionName = altName;

        }else{

            try GardenCenterOwnershipToken(this).getCollectionName(collection) returns(string memory _collectionName){

                collectionName = filterString( _collectionName );

            }catch{}

        }

         bool _supportsInterface = false;

        try GardenCenterOwnershipToken(this).getSupportsInterface(collection) returns(bool __supportsInterface){

            _supportsInterface = __supportsInterface;

        }catch{}

        string[7] memory parts;

         parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="#f7c8d9" />';

        parts[1] = '<text text-anchor="middle" x="50%" y="20%" stroke-width="4" dominant-baseline="hanging" paint-order="stroke" style="stroke:#c56ba3;fill:#ffffff;font-family:sans-serif;font-size:32px;">Garden Center</text><text text-anchor="middle" x="50%" y="60%" style="fill:#ffffff;font-family:sans-serif;font-size:15px;">';
        
        parts[2] = string(abi.encodePacked(collectionName, '</text><text text-anchor="middle" x="50%" y="30%" stroke-width="4" dominant-baseline="hanging" paint-order="stroke" style="stroke:#c56ba3;fill:#ffffff;font-family:sans-serif;font-size:32px;">#',tokenId.toString()));
        
        parts[3] = '</text>';

        parts[4] = '<text text-anchor="middle" x="50%" y="70%" style="fill:#ffffff;font-family:sans-serif;font-size:15px;">';
        
        parts[5] = _collection;
        
        parts[6] = '</text></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6])
        );

        string memory attrs = string(
            abi.encodePacked(
                'attributes":[{"trait_type":"Collection", "value":"',_collection,'"},{"trait_type":"Name", "value":"',bytes(collectionName).length > 0 ? collectionName : "None",'"},{"trait_type":"ERC721 Compliant", "value":"',_supportsInterface ? "Yes" : "No",'"}]}'
            )
        );
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Garden Center #', 
                        tokenId.toString(),
                        '","external_url":"https://rarity.garden/collection/',_collection,'", "description": "This NFT is tradable proof of ownership for a Garden Center. The collection for your Garden Center must be listed on https://rarity.garden/ in order to allow trading. Once listed, it will be available under this link: https://rarity.garden/collection/',
                        _collection,
                        '. Collection owners holding this NFT may set custom royalties for trading on rarity.garden while any other holder earns fixed 0.5% trading fees. Setting up fees for your Garden Center has no impact on fees on other marketplaces.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '","',attrs
                    )
                )
            )
        );
        
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;

    }

    function addMinter(address minter) external{

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "addMinter: not the admin role");

        _setupRole(MINTER_ROLE, minter);
    }

    function setCollectionName(address _collection, string calldata _name) external{

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setCollectionName: not the admin role");

        altCollectionNames[_collection] = _name;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{

        if(from != address(0)){

            GardenCenter(collectionToCenter[tokenIdToCollection[tokenId]]).transferOwnership(to);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function filterString(string memory _string) internal pure returns(string memory){
 
        uint k = 0;
        bytes memory out = new bytes(24);
        bytes memory byteString = bytes(_string);
        bytes memory allowed = bytes("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ ");
        for(uint i=0; i < byteString.length ; i++){
           if(i == 24){
               break;
           }
           for(uint j=0; j<allowed.length; j++){
              if(byteString[i] == allowed[j] && k < 24){
                out[k] = allowed[j];
                k++;
              } 
              else if(k == 24){

                break;
              }     
           }
        }

        bytes memory _out = new bytes(k);

        for(uint i = 0; i < k; i++){

            _out[i] = out[i];
        }
        
        return string(_out);
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
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
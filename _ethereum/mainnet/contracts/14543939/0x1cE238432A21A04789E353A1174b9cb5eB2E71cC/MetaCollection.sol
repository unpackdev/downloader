// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// ███╗   ███╗███████╗████████╗ █████╗  ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
// ██╔████╔██║█████╗     ██║   ███████║██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                                                                         
// EXPERIMENTAL/CONCEPTUAL CRYPTOART METACOLLECTION by Berk aka Princess Camel aka Guerrilla Pimp Minion Bastard 
// THIS CONTRACT HOLDS DATA FOR HUNDREDELEVEN METADATA. 
// BERK WILL CONTRIBUTE TO METACOLLECTION WITH NEW COLLECTIONS.
// OWNERS OF HUNDREDELEVEN NFTS WILL BE ABLE TO CHANGE THEIR ACTIVE METADATA BETWEEN EXISTING COLLECTIONS, ANY TIME THEY WANT
// https://hundredeleven.art

// @berkozdemir

pragma solidity ^0.8.0;

interface IHandleExternal {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function contractURI() external view returns (string memory);
}

import "./Strings.sol";
import "./Ownable.sol";
import "./IERC721.sol";


contract MetaCollection is Ownable {

    using Strings for uint256;

    address public HundredElevenContract;

    struct Collection {
        string name;
        bool isExternal;
        address externalContract;
        string uri;
    }

    Collection[] public collections;
    mapping (uint => uint) public idToCollection;

    event tokenMetadataChanged(uint tokenId, uint collection);
    event collectionEdit(uint _index, string _name, bool _isExternal, address _address, string _uri);

    function setHundredElevenAddress(address _address) public onlyOwner {
        HundredElevenContract = _address;
    }

    function addCollection(string memory _name, bool _isExternal, address _address, string memory _uri) public onlyOwner {
        collections.push( Collection(_name,_isExternal,_address,_uri) );
        emit collectionEdit(collections.length - 1,_name,_isExternal,_address,_uri);
    }
    function editCollection(uint _index, string memory _name, bool _isExternal, address _address, string memory _uri) public onlyOwner {
        collections[_index] = Collection(_name,_isExternal,_address,_uri);
        emit collectionEdit(_index,_name,_isExternal,_address,_uri);
    }

    function collectionTotal() public view returns (uint) {
        return collections.length;
    }

    function getCollectionInfo(uint _collection) public view returns (string memory) {
        require(_collection < collections.length, "choose a valid collection!");
        Collection memory collection = collections[_collection];

        return
            collection.isExternal
                ? IHandleExternal(collection.externalContract).contractURI()
                : string(abi.encodePacked(collection.uri, "info"));
    }
    
    function getCollectionInfoAll() public view returns (string[] memory) {
        string[] memory _metadataGroup = new string[](collections.length);

        for (uint i = 0; i < collections.length; i++) {
            Collection memory _collection = collections[i];
            _collection.isExternal
                ? _metadataGroup[i] = IHandleExternal(_collection.externalContract).contractURI()
                : _metadataGroup[i] = string(abi.encodePacked(_collection.uri, "info"));
        }

        return _metadataGroup;
    }


    function getCollections() public view returns (Collection[] memory) {
        return collections;
    }

    function getIdToCollectionMulti(uint256[] memory _ids) public view returns(uint256[] memory) {
        uint256[] memory indexes = new uint256[](_ids.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            indexes[i] = idToCollection[_ids[i]];
        }
        return indexes;
    }

    // THIS IS THE FUNCTION NFT CONTRACT CALL TOKENURI FOR
    // IF IT IS NOT EXTERNAL - BASEURI + TOKENID
    // IF IT IS EXTERNAL - FUNCTION CALL (TOKENURI)
    function getMetadata(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        Collection memory _collection = collections[idToCollection[tokenId]];

        return
            _collection.isExternal
                ? IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : string(abi.encodePacked(_collection.uri, tokenId.toString()));
        
    }

    // 
    function getMetadataOfIdForCollection(uint256 tokenId, uint256 collection)
        external
        view
        returns (string memory)
    {
        require(collection < collections.length, "choose a valid collection!");
        Collection memory _collection = collections[collection];

        return
            _collection.isExternal
                ? IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : string(abi.encodePacked(_collection.uri, tokenId.toString()));
    
        
    }

    function getMetadataOfIdForAllCollections(uint256 tokenId)
        external
        view
        returns (string[] memory)
    {
        string[] memory _metadataGroup = new string[](collections.length);

        for (uint i = 0; i < collections.length; i++) {
            Collection memory _collection = collections[i];
            _collection.isExternal
                ? _metadataGroup[i] = IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : _metadataGroup[i] = string(abi.encodePacked(_collection.uri, tokenId.toString()));
        }

        return _metadataGroup;
        
    }

    // OWNER OF NFTS CAN CHANGE THE METADATA OF THEIR TOKEN WITHIN EXISTING COLLECTIONS
    function changeMetadataForToken(uint[] memory tokenIds, uint[] memory _collections) public {
        // require(tokenIds.length == )
        for (uint i = 0 ; i < tokenIds.length; i++) {
            uint collection = _collections[i];
            require(collection < collections.length, "choose a valid collection!");
            uint tokenId = tokenIds[i];
            require(IERC721(HundredElevenContract).ownerOf(tokenId) == msg.sender, "Caller is not the owner");
            idToCollection[tokenId] = collection;
            emit tokenMetadataChanged(tokenId, collection);
        }
        
    }

  

    constructor(address _MetaChess) {
        addCollection("NUMZ",false,address(0),"https://berk.mypinata.cloud/ipfs/QmWWsyCUwQ6jKieUQk8gEgafCRxQsR4A8MFaTiHvs7KsyG/");
        addCollection("FreqBae",false,address(0),"https://berk.mypinata.cloud/ipfs/QmQK5WD6hcmZ5CD7oXNzN7gQ5X7YMBeCejmYbxTCi8eKLz/");
        addCollection("ri-se[t]",false,address(0),"https://berk.mypinata.cloud/ipfs/QmQkMgcqUyaNJVK551mFmDtfGhXGaoeF111s13gig7X9i5/");
        addCollection("ATAKOI",false,address(0),"https://berk.mypinata.cloud/ipfs/QmPY9pTNru8SvcgrQJVgrwnhGBZaPNa26HwepG4jHnTQPA/");
        addCollection("MELLOLOVE",false,address(0),"https://berk.mypinata.cloud/ipfs/QmYgSwobV6qSRVw6dwCcv7iXq4QXe7oTde5YdMpLwzP8cQ/");
        addCollection("MetaChess",true,_MetaChess,"");

        for (uint i=1; i <= 111; i++) {
            idToCollection[i] = i % 6;
        }

    }



}
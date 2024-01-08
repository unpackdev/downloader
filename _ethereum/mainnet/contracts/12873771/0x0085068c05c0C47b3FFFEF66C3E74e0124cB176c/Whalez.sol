// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract WHALEZ is ERC721URIStorageUpgradeable, AccessControlEnumerableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal ids;
    CountersUpgradeable.Counter internal chestIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    string public chestURI;

    struct WhalezMetaData {
        uint256 whaleID;
        string whaleURI;
    } 

    // mapping for logging chests to struct with corresponding WHALEZ metadata URI and WHALEZ ID 
    mapping(uint256 => WhalezMetaData) ChesttoWhalez;

    event Created(address account, uint256 id);
    event CreatedBatch(address account, uint256[] ids);
    event CreatedBatchforPodOwners(address[] account, uint256[] ids);
    event Deleted(uint256 id);
    event TransferredBatch(address operator, address from, address to, uint256[] ids);
    event TransferredBatchtoPodOwners(address operator, address from, address[] to, uint256[] ids);

    function initialize(
        address _newOwner, 
        string memory _name, 
        string memory _symbol, 
        string memory _chestURI
    ) 
    external 
    initializer
    {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __AccessControlEnumerable_init();
        __ERC721URIStorage_init();
        __UUPSUpgradeable_init();

        _setChestId();
        _setChestURI(_chestURI);

        transferOwnership(_newOwner);

        _setupRole(DEFAULT_ADMIN_ROLE, _newOwner);
        _setupRole(MINTER_ROLE, _newOwner);
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(UPGRADER_ROLE, _newOwner);
        _setupRole(UPGRADER_ROLE, _msgSender());
    }  

    function createToken(
        address account, 
        string memory uri
    ) 
        external virtual
        onlyRole(MINTER_ROLE)  
        returns (uint256 id) 
    {
        uint256 _id = ids.current();
        ids.increment();
        _safeMint(account, _id);
        _setTokenURI(_id, uri);
        emit Created(account, _id);
        return _id;
    }

    function createTokens(
        address account,
        uint256 numberOfTokens,
        string[] memory uri
    ) 
        external virtual
        onlyRole(MINTER_ROLE)  
        returns (uint256[] memory _ids) 
    {
        uint256[] memory _idsArray = new uint256[](numberOfTokens);

        for (uint i = 0; i < numberOfTokens; i++){
            _idsArray[i] = ids.current();
            ids.increment();         
        }
        _mintBatch(account, _idsArray, uri);

        emit CreatedBatch(account, _idsArray);
        return _idsArray;
    }

    function createChest(
        address account
    ) 
        external virtual
        onlyRole(MINTER_ROLE)  
        returns (uint256 id) 
    {
        uint256 _id = chestIds.current();
        chestIds.increment();
        _safeMint(account, _id);
        _setTokenURI(_id, chestURI);
        _setChesttoWhale(_id);
        
        emit Created(account, _id);
        return _id;
    }

    function createChests(
        address account,
        uint256 numberOfChests
    ) 
        external virtual
        onlyRole(MINTER_ROLE)  
        returns (uint256[] memory _ids) 
    {
        uint256[] memory _idsArray = new uint256[](numberOfChests);

        for (uint i = 0; i < numberOfChests; i++){
            _idsArray[i] = chestIds.current(); 
            _setChesttoWhale(_idsArray[i]);   
            chestIds.increment();     
        }

        _mintChests(account, _idsArray);

        emit CreatedBatch(account, _idsArray);
        return _idsArray;
    }

    function createChestsforPodOwners(
        address[] memory accounts,
        uint256 numberOfChests
    ) 
        external virtual
        onlyRole(MINTER_ROLE)  
        returns (uint256[] memory _ids) 
    {
        uint256[] memory _idsArray = new uint256[](numberOfChests);

        for (uint i = 0; i < numberOfChests; i++){
            _idsArray[i] = chestIds.current();
            _setChesttoWhale(_idsArray[i]); 
            chestIds.increment();         
        }

        _mintChestsforPodOwners(accounts, _idsArray);

        emit CreatedBatchforPodOwners(accounts, _idsArray);
        return _idsArray;
    }

    function deleteToken(uint256 id) external virtual {
        require(
            _msgSender() == ownerOf(id),
            "Must be owner of Token to delete Token"
        );

        _burn(id);
        emit Deleted(id);
    }

    function claimWhale(uint256 chestId) external virtual returns (uint256 whaleId){
        require(
            _msgSender() == ownerOf(chestId),
            "Must be owner of Chest to delete Chest"
        );

        uint256 _whaleId = ChesttoWhalez[chestId].whaleID;
        string memory whaleURI = ChesttoWhalez[chestId].whaleURI;
        delete ChesttoWhalez[chestId];

        _burn(chestId);
        _safeMint(_msgSender(), _whaleId);
        _setTokenURI(_whaleId, whaleURI);

        emit Created(_msgSender(), _whaleId);

        return _whaleId;
    }

    function claimWhalez(uint256[] memory _chestIds) external virtual returns (uint256[] memory whaleId){
        
        for (uint i = 0; i < _chestIds.length; i++){
            require(
                _msgSender() == ownerOf(_chestIds[i]),
                "Must be owner of Chest to delete Chest"
            );
        }

        uint256[] memory whalezIDs = new uint256[](_chestIds.length);
        uint256 _whaleId;
        string memory whaleURI;

        for (uint i = 0; i < _chestIds.length; i++){
            _whaleId = ChesttoWhalez[_chestIds[i]].whaleID;
            whaleURI = ChesttoWhalez[_chestIds[i]].whaleURI;
            delete ChesttoWhalez[_chestIds[i]];

            _burn(_chestIds[i]);
            _safeMint(_msgSender(), _whaleId);
            _setTokenURI(_whaleId, whaleURI);

            whalezIDs[i] = _whaleId;
        }

        emit CreatedBatch(_msgSender(), whalezIDs);

        return whalezIDs;
    }

    function setWhaleURI(
        uint256 _chestId, 
        string memory _whaleURI
    ) 
        external virtual
        onlyRole(MINTER_ROLE) 
    {
        ChesttoWhalez[_chestId].whaleURI = _whaleURI;
    }

    function setWhaleURIs(
        uint256[] memory _chestIds, 
        string[] memory _whaleURIs
    ) 
        external virtual
        onlyRole(MINTER_ROLE) 
    {
        require(_chestIds.length == _whaleURIs.length);
        
        for (uint i = 0; i < _chestIds.length; i++){
            ChesttoWhalez[_chestIds[i]].whaleURI = _whaleURIs[i];
        }
    }

    function getChesttoWhale(uint256 _chestId) external view virtual returns (WhalezMetaData memory){
        return ChesttoWhalez[_chestId];
    }

    function totalSupply() external view virtual returns (uint256 total) {
        return ids.current();
    } 

    function getCurrentId() external view virtual returns (uint256 total) {
        return ids.current() - 1;
    }

    function getCurrentChestId() external view virtual returns (uint256 total) {
        return chestIds.current() - 1;
    } 
    
    function supportsInterface(
        bytes4 interfaceId
    ) 
        public view virtual override(AccessControlEnumerableUpgradeable, ERC721Upgradeable) 
        returns (bool) 
    {
        return interfaceId == type(IERC721Upgradeable).interfaceId
        || super.supportsInterface(interfaceId);
    } 

    function _mintBatch(   
        address account, 
        uint256[] memory _ids, 
        string[] memory uri
    ) 
        internal virtual
    {
        require(account != address(0));
        require(_ids.length == uri.length);

        address operator = _msgSender();

        for (uint i = 0; i < _ids.length; i++) {
               _safeMint(account, _ids[i]);
               _setTokenURI(_ids[i], uri[i]);        
        }

        emit TransferredBatch(operator, address(0), account, _ids);
    } 

    function _mintChests(   
        address account, 
        uint256[] memory _ids
    ) 
        internal virtual
    {
        require(account != address(0));

        address operator = _msgSender();

        for (uint i = 0; i < _ids.length; i++) {
               _safeMint(account, _ids[i]);
               _setTokenURI(_ids[i], chestURI);        
        }

        emit TransferredBatch(operator, address(0), account, _ids);
    } 

    function _mintChestsforPodOwners(   
        address[] memory accounts, 
        uint256[] memory _ids
    ) 
        internal virtual
    {
        require(accounts.length == _ids.length);

        address operator = _msgSender();

        for (uint i = 0; i < _ids.length; i++) {
                require(accounts[i] != address(0));

               _safeMint(accounts[i], _ids[i]);
               _setTokenURI(_ids[i], chestURI);        
        }

        emit TransferredBatchtoPodOwners(operator, address(0), accounts, _ids);
    } 

    function _setChestId() internal virtual {
        chestIds._value = 100000;
    }

    function _setChestURI(string memory _chestURI) internal virtual {
        chestURI = _chestURI;
    }

    function _setChesttoWhale(uint256 _chestId) internal virtual {
        uint256 _whaleId = ids.current();
        ChesttoWhalez[_chestId].whaleID = _whaleId;
        ids.increment();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE){}
}
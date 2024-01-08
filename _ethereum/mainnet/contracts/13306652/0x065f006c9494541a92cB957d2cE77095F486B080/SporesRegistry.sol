// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC1155.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";

/**
   @title SporesRegistry contract
   @dev This contract is used to handle Registry Service
       + Register address (Treasury) to receive Commission Fee 
       + Register address of Verifier who provides authentication signatures
       + Register SporesNFT721 and SporesNFT1155 contracts
       + Register another NFT721 and NFT1155 contracts that are not owned by Spores
       + Manage Collection contract (ERC-721) - created and followed Spores's requirements
*/
contract SporesRegistry is Initializable, OwnableUpgradeable {
    // Spores Fee Collector address to receive commission fee
    address public treasury;
    // Address of Verifier to authorize Buy/Sell Spores NFT Token
    address public verifier;
    // SporesNFT721 contract address
    address public erc721;
    // SporesNFT1155 contract address
    address public erc1155;
    // SporesNFTMinter contract (SporesNFTMinter/SporesNFTMinterBatch)
    address public minter;
    // SporesNFTMartket contract
    address public market;

    //  Registry version
    bytes32 public constant VERSION = keccak256("REGISTRY_v1");

    // Define constant of NFT721 and NFT1155 opcode
    uint256 private constant NFT721_OPCODE = 721;
    uint256 private constant NFT1155_OPCODE = 1155;

    // Supported payment token WETH & list of authorized ERC20
    mapping(address => bool) public supportedTokens;

    // A map of supported NFT721 and NFT11555 contracts
    mapping(address => bool) public supportedNFT721;
    mapping(address => bool) public supportedNFT1155;
    // A map of Collections that was created by Spores Network
    // For any other collections that was created outside the network
    // use above mapping
    mapping(address => bool) public collections;

    // A map list of used signatures - keccak256(signature) => bytes32
    mapping(bytes32 => bool) public prevSigns;

    event TokenRegister(
        address indexed _token,
        bool _isRegistered // true = Registered, false = Removed
    );

    event NFTContractRegister(
        address indexed _contractNFT,
        uint256 _opcode, // _opcode = 721 => NFT721, _opcode = 1155 => NFT1155
        bool _isRegistered // true = Registered, false = Removed
    );

    event CollectionRegister(
        address indexed _collection,
        bool _isRegistered // true = Registered, false = Removed
    );

    event Treasury(address indexed _oldTreasury, address indexed _newTreasury);
    event Verifier(address indexed _oldVerifier, address indexed _newVerifier);
    event Minter(address indexed _oldMinter, address indexed _newMinter);
    event Market(address indexed _oldMarket, address indexed _newMarket);

    modifier onlyAuthorizer() {
        require(
            _msgSender() == minter ||
            _msgSender() == market ||
            collections[_msgSender()],
            "SporesRegistry: Unauthorized"
        );
        _;
    }

    function init(
        address _treasury,
        address _verifier,
        address _nft721,
        address _nft1155,
        address[] memory _tokens
    ) external initializer {
        __Ownable_init();

        treasury = _treasury;
        verifier = _verifier;
        erc721 = _nft721;
        erc1155 = _nft1155;
        supportedNFT721[_nft721] = true;
        supportedNFT1155[_nft1155] = true;
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = true;
        }
    }

    /**
       @notice Update a new Verifier address
       @dev Caller must be Owner
            Address of new Verifier should not be address(0)
       @param _newVerifier       Address of a new Verifier
    */
    function updateVerifier(address _newVerifier) external onlyOwner {
        require(_newVerifier != address(0), "SporesRegistry: Set zero address");
        emit Verifier(verifier, _newVerifier);
        verifier = _newVerifier;
    }

    /**
       @notice Update new address of Treasury
       @dev Caller must be Owner
       @param _newTreasury        Address of a new Treasury
    */
    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "SporesRegistry: Set zero address");
        emit Treasury(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
       @notice Update new address of Minter contract
       @dev Caller must be Owner
       @param _newMinter        Address of a new Minter
    */
    function updateMinter(address _newMinter) external onlyOwner {
        require(_newMinter != address(0), "SporesRegistry: Set zero address");
        emit Minter(minter, _newMinter);
        minter = _newMinter;
    }

    /**
       @notice Update new address of Market contract
       @dev Caller must be Owner
       @param _newMarket        Address of a new Market
    */
    function updateMarket(address _newMarket) external onlyOwner {
        require(_newMarket != address(0), "SporesRegistry: Set zero address");
        emit Market(market, _newMarket);
        market = _newMarket;
    }

    /**
       @notice Register a new supporting payment Coins/Tokens
            Onwer calls this function to register new ERC-20 Token
       @dev Caller must be Owner
       @param _token           Address of ERC-20 Token contract
    */
    function registerToken(address _token) external onlyOwner {
        require(!supportedTokens[_token], "SporesRegistry: Token registered");
        require(_token != address(0), "SporesRegistry: Set zero address");
        supportedTokens[_token] = true;
        emit TokenRegister(_token, true);
    }

    /**
       @notice Unregister a supported payment Coins/Tokens
            Onwer calls this function to unregister existing ERC-20 Token
       @dev Caller must be Owner
       @param _token           Address of ERC-20 Token contract to be removed
    */
    function unregisterToken(address _token) external onlyOwner {
        require(
            supportedTokens[_token],
            "SporesRegistry: Token not registered"
        );
        delete supportedTokens[_token];
        emit TokenRegister(_token, false);
    }

    /**
       @notice Add Collection to Spores Registry (By constructor)
            The adding Collection should be created by Spores Network
                in order to use this function to register
            For other Collections, not created by Spores, should be registered
                by below methods
            When Collection is created, it automatically calls this function to register Collection
            This solution saves manually steps of registering Collection.
            In the long run, this function should be removed        
       @dev Caller is Collection's constructor, but require a signature from Verifier
       @param _collection           Address of Collection contract to be registered
       @param _admin                Address of Admin (could be owner of SporesRegistry contract)
       @param _collectionId         An integer number of Collection identification
       @param _maxEdition           A max number of copies for the first sub-collection
       @param _requestId            An integer number of request given by BE
       @param _signature            A signature that is signed by Verifier
    */
    function addCollectionByConstructor(
        address _collection,
        address _admin,
        uint256 _collectionId,
        uint256 _maxEdition,
        uint256 _requestId,
        bytes calldata _signature
    ) external {
        //  Not neccessary to check validity of `_admin`
        //  Signature is provided by Verifier
        bytes32 _data = 
            keccak256(
                abi.encodePacked(
                    _collectionId, _maxEdition, _requestId, _admin, address(this)
                )
            );
        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(_data);  
        address _verifier = ECDSA.recover(_msgHash, _signature);
        _checkAuthorization(_verifier, keccak256(_signature));
        collections[_collection] = true;
    }

    /**
       @notice Add Collection to Spores Registry
            The adding Collection should be created by Spores Network
                in order to use this function to register
            For other Collections, not created by Spores, should be registered
                by below methods    
       @dev Caller must be Owner
       @param _collection           Address of Collection contract to be registered
    */
    function addCollection(address _collection) external onlyOwner {
        require(_collection != address(0), "SporesRegistry: Set zero address");
        require(!collections[_collection], "SporesRegistry: Collection exist");
        collections[_collection] = true;
        emit CollectionRegister(_collection, true);
    }

    /**
       @notice Remove Collection out of Spores Registry
       @dev Caller must be Owner
       @param _collection           Address of Collection contract to be removed
    */
    function removeCollection(address _collection) external onlyOwner {
        require(
            collections[_collection],
            "SporesRegistry: Collection not exist"
        );
        delete collections[_collection];
        emit CollectionRegister(_collection, false);
    }

    /**
       @notice Register a new supporting NFT721/NFT1155 contract
            Onwer calls this function to register new NFT721/NFT1155 contract
       @dev Caller must be Owner
            `_skip` should be `false` by default to check interface
       @param _contractNFT        Address of NFT721/1155 contract
       @param _opcode             Option Code (721 = NFT721, 1155 = NFT1155)
       @param _skip               A flag to skip checking interface ERC-165
    */
    function registerNFTContract(address _contractNFT, uint256 _opcode, bool _skip)
        external
        onlyOwner
    {
        require(_contractNFT != address(0), "SporesRegistry: Set zero address");
        require(
            _opcode == NFT721_OPCODE || _opcode == NFT1155_OPCODE,
            "SporesRegistry: Invalid opcode"
        );

        // @dev In case a registering contract does not implement `supportInterface()`
        // Should verify a contract carefully before registering with a disable checking flag (_skip = true)
        if (_opcode == NFT721_OPCODE) {
            require(
                !supportedNFT721[_contractNFT],
                "SporesRegistry: NFT721 Contract registered"
            );
            // @dev    IERC721 and IERC721Upgradeable returns the same interface ID
            // Should restrict IERC721Upgradeable cause unknown contract can upgrade
            // and integrate malicious implementation
            require(
                _skip || IERC721(_contractNFT).supportsInterface(
                    type(IERC721).interfaceId
                ),
                "SporesRegistry: Invalid interface"
            );
            supportedNFT721[_contractNFT] = true;
        } else {
            require(
                !supportedNFT1155[_contractNFT],
                "SporesRegistry: NFT1155 Contract registered"
            );
            // @dev    IERC1155 and IERC1155Upgradeable returns the same interface ID
            // Should restrict IERC1155Upgradeable cause unknown contract can upgrade
            // and integrate malicious implementation
            require(
                _skip || IERC1155(_contractNFT).supportsInterface(
                    type(IERC1155).interfaceId
                ),
                "SporesRegistry: Invalid interface"
            );
            supportedNFT1155[_contractNFT] = true;
        }
        emit NFTContractRegister(_contractNFT, _opcode, true);
    }

    /**
       @notice Unregister a supported NFT721/NFT1155 contract
            Onwer calls this function to unregister existing NFT721/NFT1155 contract
       @dev Caller must be Owner
       @param _contractNFT        Address of NFT721/NFT1155 contract to be removed
       @param _opcode             Option Code (721 = NFT721, 1155 = NFT1155)
    */
    function unregisterNFTContract(address _contractNFT, uint256 _opcode)
        external
        onlyOwner
    {
        require(
            _opcode == NFT721_OPCODE || _opcode == NFT1155_OPCODE,
            "SporesRegistry: Invalid opcode"
        );
        if (_opcode == NFT721_OPCODE) {
            require(
                supportedNFT721[_contractNFT],
                "SporesRegistry: NFT721 Contract not registered"
            );
            delete supportedNFT721[_contractNFT];
        } else {
            require(
                supportedNFT1155[_contractNFT],
                "SporesRegistry: NFT1155 Contract not registered"
            );
            delete supportedNFT1155[_contractNFT];
        }
        emit NFTContractRegister(_contractNFT, _opcode, false);
    }

    /**
       @notice This function handles multiple task per request:
            + Check whether `_verifier`, who gave a signature, is authorized
            + Check whether a signature has been used before
            + Save `_sigHash`
       @dev Caller must be in the authorizing list - Minter, Market, and Collection contract
       @param _verifier        Address of `_verifier` that was used to sign a request
       @param _sigHash         A hash of signature that was given by `_verifier`
    */
    function checkAuthorization(address _verifier, bytes32 _sigHash)
        external
        onlyAuthorizer
    {
        _checkAuthorization(_verifier, _sigHash);
    }

    function _checkAuthorization(address _verifier, bytes32 _sigHash) private {
        require(_verifier == verifier, "SporesRegistry: Invalid verifier");
        require(!prevSigns[_sigHash], "SporesRegistry: Signature was used");
        prevSigns[_sigHash] = true;
    }
}

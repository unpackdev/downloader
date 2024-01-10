// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 *  NNNNNNNN        NNNNNNNNFFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTTFFFFFFFFFFFFFFFFFFFFFFlllllll                                                   iiii                    
 *  N:::::::N       N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TF::::::::::::::::::::Fl:::::l                                                  i::::i                   
 *  N::::::::N      N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TF::::::::::::::::::::Fl:::::l                                                   iiii                    
 *  N:::::::::N     N::::::NFF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::TFF::::::FFFFFFFFF::::Fl:::::l                                                                           
 *  N::::::::::N    N::::::N  F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTT  F:::::F       FFFFFF l::::l     eeeeeeeeeeee    xxxxxxx      xxxxxxx        iiiiiii nnnn  nnnnnnnn    
 *  N:::::::::::N   N::::::N  F:::::F                     T:::::T          F:::::F              l::::l   ee::::::::::::ee   x:::::x    x:::::x         i:::::i n:::nn::::::::nn  
 *  N:::::::N::::N  N::::::N  F::::::FFFFFFFFFF           T:::::T          F::::::FFFFFFFFFF    l::::l  e::::::eeeee:::::ee  x:::::x  x:::::x           i::::i n::::::::::::::nn 
 *  N::::::N N::::N N::::::N  F:::::::::::::::F           T:::::T          F:::::::::::::::F    l::::l e::::::e     e:::::e   x:::::xx:::::x            i::::i nn:::::::::::::::n
 *  N::::::N  N::::N:::::::N  F:::::::::::::::F           T:::::T          F:::::::::::::::F    l::::l e:::::::eeeee::::::e    x::::::::::x             i::::i   n:::::nnnn:::::n
 *  N::::::N   N:::::::::::N  F::::::FFFFFFFFFF           T:::::T          F::::::FFFFFFFFFF    l::::l e:::::::::::::::::e      x::::::::x              i::::i   n::::n    n::::n
 *  N::::::N    N::::::::::N  F:::::F                     T:::::T          F:::::F              l::::l e::::::eeeeeeeeeee       x::::::::x              i::::i   n::::n    n::::n
 *  N::::::N     N:::::::::N  F:::::F                     T:::::T          F:::::F              l::::l e:::::::e               x::::::::::x             i::::i   n::::n    n::::n
 *  N::::::N      N::::::::NFF:::::::FF                 TT:::::::TT      FF:::::::FF           l::::::le::::::::e             x:::::xx:::::x           i::::::i  n::::n    n::::n
 *  N::::::N       N:::::::NF::::::::FF                 T:::::::::T      F::::::::FF           l::::::l e::::::::eeeeeeee    x:::::x  x:::::x   ...... i::::::i  n::::n    n::::n
 *  N::::::N        N::::::NF::::::::FF                 T:::::::::T      F::::::::FF           l::::::l  ee:::::::::::::e   x:::::x    x:::::x  .::::. i::::::i  n::::n    n::::n
 *  NNNNNNNN         NNNNNNNFFFFFFFFFFF                 TTTTTTTTTTT      FFFFFFFFFFF           llllllll    eeeeeeeeeeeeee  xxxxxxx      xxxxxxx ...... iiiiiiii  nnnnnn    nnnnnn
 *  
 */

import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract NFTFlex is ERC721, ReentrancyGuard, Ownable {
  
    struct TokenNFTDetail {
        address externalContractAddress;        
        uint256 externalTokenId;
        bool isERC1155;
    }

    // Max supply for the tokens
    uint256 constant public MAX_SUPPLY = 1064;

    // Types of tokens available 
    uint256 constant TYPE_BRONZE = 1;
    uint256 constant TYPE_SILVER = 2;
    uint256 constant TYPE_GOLD = 3;
    uint256 constant TYPE_PLATINUM = 4;

    uint256 private _currentSupply; // Count of minted tokens
    mapping(uint256 => uint256) private _typePrice; // Stores price for block type
    mapping(uint256 => TokenNFTDetail) public _tokenNFTDetail; // Stores configuration for a specific token
    mapping(address => mapping(uint256 => bool)) private _blockedNFTTokens; // Stores blocked tokens to prevent inappropriate NFT's on the board
    bool internal _preSaleMinted; // Prevents public mint until Flex has minted giveaway spaces

    /**
     * @dev ConfigureBlock event. 
     *
     * Used to store dynamic content specific for the 
     * block
     */
    event ConfigureBlock (
        uint256 indexed tokenId,
        string data
    );

    /**
     * @dev ConfigureSidebar event. 
     *
     * Used to store dynamic content specific for the 
     * block sidebar
     */
    event ConfigureSidebar (
        uint256 indexed tokenId,
        string data
    );

    /**
     * @dev Require msg.sender to own the token for given id
     *
     * @param id_ uint256 token id to be checked
     */
    modifier flexOwnerOnly(uint256 id_) {
        require(ownerOf(id_) == _msgSender(), "ONLY_OWNERS_ALLOWED");
        _;
    }

    /**
     * @dev Constructor
     *
     * @param name_ token name
     * @param symbol_ token symbol
     * @param name_ token name
     * @param bronze_ bronze token price
     * @param silver_ silver token price
     * @param gold_ gold token price
     * @param platinum_ platinum token price
     */
    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 bronze_, 
        uint256 silver_, 
        uint256 gold_, 
        uint256 platinum_
    ) ERC721(name_, symbol_) {
        _typePrice[TYPE_BRONZE] = bronze_;
        _typePrice[TYPE_SILVER] = silver_;
        _typePrice[TYPE_GOLD] = gold_;
        _typePrice[TYPE_PLATINUM] = platinum_;    
    }

    /**
     * @dev to receive eth
     */
    receive() external payable {}

    /**
     * @dev flexOwnerOnly function to configure a token sidebar dynamic data
     *
     * @param nftFlexTokenId uint256 flex token id
     * @param data string dynamic data to be stored in an event
     */
    function configureSidebar(
        uint256 nftFlexTokenId, 
        string calldata data
    ) 
        external 
        flexOwnerOnly(nftFlexTokenId) 
    {
        emit ConfigureSidebar(nftFlexTokenId, data);
    }

    /**
     * @dev Returns the token data for all 1064 tokens, token id = index + 1
     *
     * @return exists bool[] indicates if the token has been minted
     * @return initialised bool[] indicates if the token has been assigned a token
     * @return addressOwnsNFT bool[] indicates if the owner of the token still owns the configured NFT
     * @return nftBlocked bool[] indicates if NFTFlex.in have blocked the configured NFT
     * @return url string metadata[] url for the token
     * @return flexOwner address[] token id owner
     */
    function getAllTokenData() 
        external 
        view 
        returns 
        (   
            bool[] memory exists, 
            bool[] memory initialised, 
            bool[] memory addressOwnsNFT, 
            bool[] memory nftBlocked, 
            string[] memory url, 
            address[] memory flexOwner
        ) 
    {
        exists = new bool[](MAX_SUPPLY);
        initialised = new bool[](MAX_SUPPLY);
        addressOwnsNFT = new bool[](MAX_SUPPLY);
        nftBlocked = new bool[](MAX_SUPPLY);
        url = new string[](MAX_SUPPLY);
        flexOwner = new address[](MAX_SUPPLY);
        for(uint i = 0; i < MAX_SUPPLY; i++) {
            (
                bool exist, 
                bool init, 
                bool addOwnsNFT, 
                bool blocked, 
                string memory tokenUrl, 
                address ownedBy
            ) = getTokenData(i+1);
            exists[i] = exist;
            initialised[i] = init;
            addressOwnsNFT[i] = addOwnsNFT;
            nftBlocked[i] = blocked;
            url[i] = tokenUrl;
            flexOwner[i] = ownedBy;
        }
    }

    /**
     * @dev flexOwnerOnly function to block any external token deemed inappropriate
     *
     * @param nftTokenId uint256 flex token id
     */
    function blockExternalNFT(uint256 nftTokenId) onlyOwner external {
        _blockedNFTTokens[_tokenNFTDetail[nftTokenId].externalContractAddress][_tokenNFTDetail[nftTokenId].externalTokenId] = true;
    }

    /**
     * @dev Returns the price list for the available token types
     *
     * @return bronze price for the bronze token type
     * @return silver price for the silver token type
     * @return gold price for the gold token type
     * @return platinum price for the platinum token type
     */
    function getPriceList() 
        external 
        view 
        returns (
            uint256 bronze, 
            uint256 silver, 
            uint256 gold, 
            uint256 platinum
        ) 
    {
        bronze = _typePrice[TYPE_BRONZE];
        silver = _typePrice[TYPE_SILVER];
        gold = _typePrice[TYPE_GOLD];
        platinum = _typePrice[TYPE_PLATINUM];    
    }

    /**
     * @dev Public mint function, single token per tx
     *      This function can only be called after the ownerMint
     *
     * @param tokenId uint256 token id to mint
     */
    function mint(uint tokenId) external payable nonReentrant {
        require(_preSaleMinted, "No presale");
        require(MAX_SUPPLY >= tokenId, "Token id out of range");
        (,uint price )= getTokenTypeAndPriceById(tokenId);
        require(msg.value >= price, "Sent eth incorrect");
        _safeMint(msg.sender, tokenId);
        _currentSupply = _currentSupply + 1;
    }

    /**
     * @dev Owner only function to pre sale mint tokens without the need for eth
     *      This function must be called before the public mint can take place
     *
     * @param tokenIds uint256[] token ids to mint
     */
    function ownerMint(uint[] memory tokenIds) external onlyOwner {
        require(!_preSaleMinted, "Already Minted");
        
        for(uint i = 0; i < tokenIds.length; i++) {            
            _safeMint(_msgSender(), tokenIds[i]);
            _currentSupply = _currentSupply + 1;
        }
        _preSaleMinted = true;
    }

    /**
     * @dev flexOwnerOnly to configure an NFT flex space
     *
     * @param nftContractAddress address external NFT contract address
     * @param externalTokenId uint256 token id of the external contract address
     * @param nftFlexTokenId uint256 flex token id
     * @param isERC1155 bool is ERC1155 if false default ERC721
     * @param data string dynamic data to be stored in an event
     */
    function setNFTTokenDetail(
        address nftContractAddress, 
        uint256 externalTokenId, 
        uint256 nftFlexTokenId, 
        bool isERC1155, 
        string calldata data
    ) 
        external 
        flexOwnerOnly(nftFlexTokenId) 
    {
        require(
            ownsNFT(_msgSender(), nftContractAddress, externalTokenId, isERC1155),
            "SENDER_NOT_OWN_EXTERNAL_TOKEN"
        );
        require(
            !_blockedNFTTokens[nftContractAddress][externalTokenId], 
            "BLOCKED_NFT"
        );
        require(
            !(
                _tokenNFTDetail[nftFlexTokenId].externalContractAddress == nftContractAddress 
                && _tokenNFTDetail[nftFlexTokenId].externalTokenId == externalTokenId
            ), 
            "SAME_TOKEN"
        );
        _tokenNFTDetail[nftFlexTokenId].externalContractAddress = nftContractAddress;
        _tokenNFTDetail[nftFlexTokenId].externalTokenId = externalTokenId;
        _tokenNFTDetail[nftFlexTokenId].isERC1155 = isERC1155;

        // if this fails NFTFlex.in will not support the contract
        isERC1155 
                ? IERC1155MetadataURI(nftContractAddress).uri(externalTokenId)
                : IERC721Metadata(nftContractAddress).tokenURI(externalTokenId);

        emit ConfigureBlock(nftFlexTokenId, data);
    }

    /**
     * @dev Sets a new price for a given token price
     *
     * @param ethVal new price
     * @param tokenType token type for the new price
     */
    function setPrice(uint256 ethVal, uint256 tokenType) external onlyOwner {
        _typePrice[tokenType] = ethVal;
    }

    /**
     * @dev onlyOwner function to override user submitted content
     *
     * @param nftFlexTokenId uint256 flex token id
     */
    function setSidebarData(uint256 nftFlexTokenId) onlyOwner external {
        emit ConfigureSidebar(nftFlexTokenId, "");
    }

    /**
     * @dev Returns the current total supply
     */
    function totalSupply() external view returns (uint256) {
        return _currentSupply;
    }

    /**
     * @dev flexOwnerOnly function to reverse a block on an external NFT
     *
     * @param nftContractAddress address external contract address
     * @param tokenId uint256 external token id
     */
    function unblockExternalNFT(address nftContractAddress, uint256 tokenId) onlyOwner external {
        _blockedNFTTokens[nftContractAddress][tokenId] = false;
    }
    
    /**
     * @dev withdraws the eth from the contract to the treasury
     *
     * @param treasury_ treasury address for the eth to be sent to
     */
    function withdraw(address treasury_) external onlyOwner nonReentrant {
		payable(treasury_).transfer(address(this).balance);
	}

    /**
     * @dev Returns the token data for supplied token id
     *
     * @param nftTokenId uint256 token id to lookup
     *
     * @return exists bool indicates if the token has been minted
     * @return initialised bool indicates if the token has been assigned a token
     * @return addressOwnsNFT bool indicates if the owner of the token still owns the configured NFT
     * @return nftBlocked bool indicates if NFTFlex.in have blocked the configured NFT
     * @return url string metadata url for the token
     * @return flexOwner address token id owner
     */
    function getTokenData(
        uint256 nftTokenId
    ) 
        public 
        view 
        returns (
            bool exists, 
            bool initialised, 
            bool addressOwnsNFT, 
            bool nftBlocked, 
            string memory url, 
            address flexOwner
        ) 
    {
        exists = _exists(nftTokenId);
        initialised = exists && _tokenNFTDetail[nftTokenId].externalContractAddress != address(0);
        if(exists && initialised) {
            addressOwnsNFT = ownsNFT(
                ownerOf(nftTokenId), 
                _tokenNFTDetail[nftTokenId].externalContractAddress, _tokenNFTDetail[nftTokenId].externalTokenId, 
                _tokenNFTDetail[nftTokenId].isERC1155
            );
            nftBlocked = _blockedNFTTokens[_tokenNFTDetail[nftTokenId].externalContractAddress]
                                [_tokenNFTDetail[nftTokenId].externalTokenId];            
            if(addressOwnsNFT && !nftBlocked) {
                url = _tokenNFTDetail[nftTokenId].isERC1155 
                    ? IERC1155MetadataURI(_tokenNFTDetail[nftTokenId].externalContractAddress).uri(_tokenNFTDetail[nftTokenId].externalTokenId)
                    : IERC721Metadata(_tokenNFTDetail[nftTokenId].externalContractAddress).tokenURI(_tokenNFTDetail[nftTokenId].externalTokenId);
            } else {
                initialised = false;
            }
            
        }
        if(exists) {
            flexOwner = ownerOf(nftTokenId);
        }
    }
    
    /**
     * @dev Returns a token type for a token id
     *
     * @param tokenId uint256 token id lookup
     */
    function getTokenTypeAndPriceById(uint tokenId) public view returns(uint tokenType, uint price) {
        if( tokenId == 1 || tokenId == 134 || tokenId == 267 || tokenId == 400 ||
            tokenId == 533 || tokenId == 666 || tokenId == 799 || tokenId == 932 ) {
            tokenType = TYPE_PLATINUM;
            price = _typePrice[TYPE_PLATINUM];
        }

        if ((tokenId >= 981 && tokenId <= 1064) || (tokenId >= 848 && tokenId <= 931) || 
            (tokenId >= 715 && tokenId <= 798) || (tokenId >= 582 && tokenId <= 665) || 
            (tokenId >= 449 && tokenId <= 532) || (tokenId >= 316 && tokenId <= 399) || 
            (tokenId >= 183 && tokenId <= 266) || (tokenId >= 50 && tokenId <= 133) ) {
            tokenType = TYPE_BRONZE;
            price = _typePrice[TYPE_BRONZE];
        }

        if ((tokenId >= 945 && tokenId <= 980) || (tokenId >= 812 && tokenId <= 847) || 
            (tokenId >= 679 && tokenId <= 714) || (tokenId >= 546 && tokenId <= 581) || 
            (tokenId >= 413 && tokenId <= 448) || (tokenId >= 280 && tokenId <= 315) || 
            (tokenId >= 147 && tokenId <= 182) || (tokenId >= 14 && tokenId <= 49) ) {
            tokenType = TYPE_SILVER;
            price = _typePrice[TYPE_SILVER];
        }

        if ((tokenId >= 933 && tokenId <= 944) || (tokenId >= 800 && tokenId <= 811) || 
            (tokenId >= 667 && tokenId <= 678) || (tokenId >= 534 && tokenId <= 545) || 
            (tokenId >= 401 && tokenId <= 412) || (tokenId >= 268 && tokenId <= 279) || 
            (tokenId >= 135 && tokenId <= 146) || (tokenId >= 2 && tokenId <= 13) ) {            
            tokenType = TYPE_GOLD;
            price = _typePrice[TYPE_GOLD];
        }
        
        //failed to find 
        require(price != 0, "unknown token id");
    }

    /**
     * @dev checks if an address us an owner of a specific token
     *
     * @param ownerAddress address address to query the ownership
     * @param nftContractAddress address external contract address
     * @param nftTokenId uint256 external token id
     * @param isERC1155 bool is ERC1155 if false default ERC721
     */
    function ownsNFT(
        address ownerAddress, 
        address nftContractAddress, 
        uint256 nftTokenId, 
        bool isERC1155
    ) 
        public 
        view 
        returns (
            bool
        ) 
    {
        return isERC1155 
            ? IERC1155(nftContractAddress).balanceOf(ownerAddress, nftTokenId) > 0
            : IERC721(nftContractAddress).ownerOf(nftTokenId) == ownerAddress;
    }

    /**
     * @dev Override ERC721._baseURI() to return our metadata URL
     *
     * @return string metadata URL
     */
    function _baseURI() internal override view virtual returns (string memory) {
        return "ipfs://Qmenc8AWUN7DHzyU5Z6wMxc5p2PKCUmP3WeFGNgj5Ukktv/";
    }    

    /**
     * @dev _beforeTokenTransfer hook to reset flex token data
     * 
     * @param from address current owner address
     * @param to address new owner address
     * @param tokenId uint256 token id
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // On transfer clear down the previous owners details
        delete _tokenNFTDetail[tokenId];
        emit ConfigureSidebar(tokenId, "");
        emit ConfigureBlock(tokenId, "");
    }

}

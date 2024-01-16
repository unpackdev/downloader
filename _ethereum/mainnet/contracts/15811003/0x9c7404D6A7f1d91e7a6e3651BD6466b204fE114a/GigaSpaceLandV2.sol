// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./Signing.sol";
import "./console.sol";

contract GigaSpaceLandV2 is Initializable, ERC721Upgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable, ERC721URIStorageUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE     = keccak256("PAUSER_ROLE");
    bytes32 public constant QUAD_ADMIN_ROLE = keccak256("QUAD_ADMIN_ROLE");

    enum SalePhase {
		Locked,
		PrivateSale,
		PublicSale
	}

    SalePhase public _phase;

    uint256 internal constant MAP_SIZE    =         504;
    uint256 internal constant LAYER_1x1   =    10000000;
    uint256 internal constant LAYER_3x3   =    30000000;
    uint256 internal constant LAYER_6x6   =    60000000;
    uint256 internal constant LAYER_12x12 =    12000000;
    uint256 internal constant LAYER_24x24 =    24000000;

    uint256 internal constant MAX_PRICE = 100000000000000000000;

    mapping (uint256 => uint256) public _price;
    mapping (uint256 => address) public _landOwners;
    mapping (uint256 => Quad)    public _quadObj;
    
    address internal _adminSigner;
    string internal _baseTokenURI;

    struct Quad {
        uint256 size;
        uint256 x;
        uint256 y;
    }

    bool _requireCheck;

    struct ERC20Info {
        IERC20Upgradeable payERC20;
        uint256 layer;
        uint256 erc20Price;
    }
    
    mapping (uint256 => ERC20Info) public _allowedERC20;

    event NewPrice(uint256 layer, uint256 price);
    event BaseTokenURI(string uri);
    event EnterPhase(SalePhase phase);
    event NewERC20Pay(uint256 id, IERC20Upgradeable payERC20, uint256 layer, uint256 erc20Price);
    event RemoveERC20Pay(uint256 id);

    function initialize(address adminSigner, string memory uri) public initializer {
        require(adminSigner != address(0), "adminSigner is zero address");

        __ERC721_init("GigaSpace", "GIS");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init(); 

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(QUAD_ADMIN_ROLE, msg.sender);

        _adminSigner = adminSigner;
        _baseTokenURI = uri;
        _phase = SalePhase.Locked;
        _requireCheck = true;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set IPFS base URI
    function setBaseTokenURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = uri;
        emit BaseTokenURI(uri);
    }

    /// @notice Set the land price of 5 layers
    function setPrice(uint256 layer, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(MAX_PRICE >= price, "Out of max price");
        _price[layer] = price;
        emit NewPrice(layer, price);
    }

	/// @notice Set the sale phase state 
    function enterPhase(SalePhase phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _phase = phase;
        emit EnterPhase(phase);
    }

    /// @notice total width of the map
    /// @return width
    function width() external pure returns(uint256) {
        return MAP_SIZE;
    }

    /// @notice total height of the map
    /// @return height
    function height() external pure returns(uint256) {
        return MAP_SIZE;
    }

    function scaleXY(int256 scale) private pure returns (uint256) {
        return uint(scale + 1000);
    }

	/// @notice validate overlapping 
    function setRequireCheck(bool check) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireCheck = check;
    }

    /// @notice Set the ERC20 as payable
    function setERC20Info(uint256 id, IERC20Upgradeable payERC20, uint256 layer, uint256 erc20Price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _allowedERC20[id].payERC20 = payERC20; 
        _allowedERC20[id].layer = layer;
        _allowedERC20[id].erc20Price = erc20Price;
        emit NewERC20Pay(id, payERC20, layer, erc20Price);
    }

    /// @notice Clean up ERC20 as payable
    function cleanERC20Info(uint256 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _allowedERC20[id];
        emit RemoveERC20Pay(id);                
    }    

    function privateMint(address to, uint256 size, int256 x, int256 y, string memory uri, bytes memory signature) external nonReentrant payable callerIsUser {
        require(_phase == SalePhase.PrivateSale, "Private phase is not active");
        mintLand(to, size, scaleXY(x), scaleXY(y), uri, signature);
    }    

    function publicMint(address to, uint256 size, int256 x, int256 y, string memory uri, bytes memory signature) external nonReentrant payable callerIsUser {
        require(_phase == SalePhase.PublicSale, "Public phase is not active");
        mintLand(to, size, scaleXY(x), scaleXY(y), uri, signature);
    }    

    function privateMintERC20(address to, uint256 size, int256 x, int256 y, string memory uri, uint256 eid, bytes memory signature) external callerIsUser {
        require(_phase == SalePhase.PrivateSale, "Private phase is not active");
        mintLandERC20(to, size, scaleXY(x), scaleXY(y), uri, eid, signature);
    }    

    function publicMintERC20(address to, uint256 size, int256 x, int256 y, string memory uri, uint256 eid, bytes memory signature) external callerIsUser {
        require(_phase == SalePhase.PublicSale, "Public phase is not active");
        mintLandERC20(to, size, scaleXY(x), scaleXY(y), uri, eid, signature);
    }    

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract as user is not allowed");
        _;
    }

    function mintLand(address to, uint256 size, uint256 x, uint256 y, string memory landUri, bytes memory signature) internal {

        require(to != address(0), "to is zero address");
        require((MAP_SIZE/2+1000+1) - size >= x && x >= (1000-MAP_SIZE/2+1), "Out of X boundary");
        require((MAP_SIZE/2+1000+1) - size >= y && y >= (1000-MAP_SIZE/2+1), "Out of Y boundary");
        require(_processSignature(_adminSigner, msg.sender, size, x, y, signature), "Not an authorized address"); 
        require(msg.value == _price[size], "Payment must be equal to the Price");

        uint256 quadId = _formQuadId(size, x, y);
        uint256 landId;
        uint256 xNew = x; 
        uint256 yNew = y; 
    
        //Assign all the landIds to _landOwners, if 1x1, no need
        if (size == 1) {
                    require(_quadOwnerOf(x, y) == address(0), "Land had quad owner");
                    require(_landOwnerOf(x, y) == address(0), "Land had land owner");
        } else {
            for (uint256 i = 0; i < size*size; i++) {
                    landId = xNew + yNew * MAP_SIZE;

                    if (_requireCheck == true) {
                        require(_quadOwnerOf(xNew, yNew) == address(0), "Land had quad owner");
                        require(_landOwnerOf(xNew, yNew) == address(0), "Land had land owner");
                    }
                    //[0] is the quad ID
                    if (i != 0)
                        _landOwners[landId] = to;
                    
                    if ((i+1) % size == 0) {
                        yNew += 1;
                        xNew = x;
                    } else 
                        xNew += 1; 
            }
        }    
        //For any size of land, mint 1 ERC721 token only by quadId
        _safeMint(to, quadId, landUri);
        _landOwners[quadId] = to;
        _quadObj[quadId].size = size;
        _quadObj[quadId].x = x;
        _quadObj[quadId].y = y;
    }

    function mintLandERC20(address to, uint256 size, uint256 x, uint256 y, string memory landUri, uint256 eid, bytes memory signature) internal {
        
        ERC20Info storage erc20Info = _allowedERC20[eid];
        IERC20Upgradeable erc20Token = erc20Info.payERC20;
        uint256 price = erc20Info.erc20Price;
    
        require(to != address(0), "to is zero address");
        require((MAP_SIZE/2+1000+1) - size >= x && x >= (1000-MAP_SIZE/2+1), "Out of X boundary");
        require((MAP_SIZE/2+1000+1) - size >= y && y >= (1000-MAP_SIZE/2+1), "Out of Y boundary");
        require(_processSignature(_adminSigner, msg.sender, size, x, y, signature), "Not an authorized address"); 
        require(erc20Token.balanceOf(msg.sender)>= price, "Not enough token balance to mint the land"); 

        uint256 quadId = _formQuadId(size, x, y);
        uint256 landId;
        uint256 xNew = x; 
        uint256 yNew = y; 
    
        //Assign all the landIds to _landOwners, if 1x1, no need
        if (size == 1) {
                    require(_quadOwnerOf(x, y) == address(0), "Land had quad owner");
                    require(_landOwnerOf(x, y) == address(0), "Land had land owner");
        } else {
            for (uint256 i = 0; i < size*size; i++) {
                    landId = xNew + yNew * MAP_SIZE;

                    if (_requireCheck == true) {
                        require(_quadOwnerOf(xNew, yNew) == address(0), "Land had quad owner");
                        require(_landOwnerOf(xNew, yNew) == address(0), "Land had land owner");
                    }
                    //[0] is the quad ID
                    if (i != 0)
                        _landOwners[landId] = to;
                    
                    if ((i+1) % size == 0) {
                        yNew += 1;
                        xNew = x;
                    } else 
                        xNew += 1; 
            }
        }    
        //For any size of land, mint 1 ERC721 token only by quadId
        erc20Token.transferFrom(msg.sender, address(this), price);
        _safeMint(to, quadId, landUri);
        _landOwners[quadId] = to;
        _quadObj[quadId].size = size;
        _quadObj[quadId].x = x;
        _quadObj[quadId].y = y;
    }    

    function _formQuadId(uint256 size, uint256 x, uint256 y) public pure returns (uint256) {
        uint256 id = x + y * MAP_SIZE;
        uint256 quadId;

        if (size == 1) {
            quadId = LAYER_1x1 + id;
        } else if (size == 3) {
            quadId = LAYER_3x3 + id;
        } else if (size == 6) {
            quadId = LAYER_6x6 + id;
        } else if (size == 12) {
            quadId = LAYER_12x12 + id;
        } else if (size == 24) {
            quadId = LAYER_24x24 + id;
        } else {
            require(false, "Invalid size");
        }
        return quadId;
    }

    /// @notice Degroup the quad to 1x1
    /// @param erc721Id the ERC721 token ID on chain
    /// @param to Destination
    /// @param size Size of the quad
    /// @param x The bottom left x coordinate of the quad
    /// @param y The bottom left y coordinate of the quad
    /// @param landUri All degrouped token URIs
    /// @param batch batch no. from 0, e.g. 0-3
    /// @param totalBatch total batch, e.g. 4
    function degroupLand(uint256 erc721Id, address to, uint256 size, int256 x, int256 y, string[] memory landUri, uint256 batch, uint256 totalBatch) external onlyRole(QUAD_ADMIN_ROLE) {

        uint256 quadId = _formQuadId(size, scaleXY(x), scaleXY(y));

        require(to != address(0), "To is zero address");
        require(size > 1, "Only quad can degroup");
        require(quadId == erc721Id, "Invalid ERC721 token ID");
        require(_landOwners[erc721Id] == to, "Only owner can degroup the quad with burn");
        require(totalBatch > 0, "totalBatch must be > 0");
        require(size % totalBatch == 0, "size must be divisible by totalBatch");

        uint256 totalRun = (size * size)/totalBatch;
        uint256 landId;
        uint256 xNew = scaleXY(x); 
        uint256 yNew = scaleXY(y) + (size * batch/totalBatch); 

        // When first batch, remove erc721 token. Prevent owner to call safeTransferFrom()
        if (batch == 0) {
            _burn(erc721Id);
        }    
        // Until last batch, clear _landOwner[quadId] and _quadObj[quadId]
        if (batch == totalBatch - 1) {
            _landOwners[quadId] = address(0);
            delete _quadObj[quadId];
        }    

        for (uint256 i = 0; i < totalRun; i++) {            
            landId = xNew + yNew * MAP_SIZE;

            // Clear the old landId
            _landOwners[landId] = address(0);

            landId = LAYER_1x1 + landId;
            _safeMint(to, landId, landUri[i]);
            _landOwners[landId] = to;
            _quadObj[landId].size = 1;
            _quadObj[landId].x = xNew;
            _quadObj[landId].y = yNew;
            
            if ((i+1) % size == 0) {
                yNew += 1;
                xNew = scaleXY(x);
            } else 
                xNew += 1; 
        }
    }        

    function _safeMint(address to, uint256 tokenId, string memory uri) internal {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }   

    function scaleLandOwnerOf(int256 x, int256 y) external view returns (address) {
        return _landOwnerOf(scaleXY(x), scaleXY(y));
    }    

    function _landOwnerOf(uint256 x, uint256 y) internal view returns (address) {
        uint256 landId = x + y * MAP_SIZE;
        return _landOwners[landId];
    }

    function scaleQuadOwnerOf(int256 x, int256 y) external view returns (address) {
        uint256 scaleX = scaleXY(x);
        uint256 scaleY = scaleXY(y);
        return _quadOwnerOf(scaleX, scaleY);
    }

    function _quadOwnerOf(uint256 x, uint256 y) internal view returns (address) {    
            if (_landOwners[_formQuadId(1, x, y)] != address(0)) {
                    return _landOwners[_formQuadId(1, x, y)];

            } else if (_landOwners[_formQuadId(3, x, y)] != address(0)) {
                    return _landOwners[_formQuadId(3, x, y)];            

            } else if (_landOwners[_formQuadId(6, x, y)] != address(0)) {
                    return _landOwners[_formQuadId(6, x, y)];            

            } else if (_landOwners[_formQuadId(12, x, y)] != address(0)) {
                    return _landOwners[_formQuadId(12, x, y)];            

            } else if (_landOwners[_formQuadId(24, x, y)] != address(0)) {
                    return _landOwners[_formQuadId(24, x, y)];            
            }
            return address(0);
    }

    ///@notice checks the signature
    ///@param userFrom - user creator of the signature
    ///@param userTo - user receiver of the signature
    ///@param signature - bytes with the signed message
    function _processSignature(address userFrom, address userTo, uint256 size, uint256 x, uint256 y, bytes memory signature) internal pure returns (bool) {
        bytes32 message = Signing.formMessage(userFrom, userTo, size, x, y);
        require(userFrom == Signing.recoverAddress(message, signature), "Invalid signature provided");
        return true;
    }

    function burn(uint256 tokenId) 
        public
        virtual
        override(ERC721BurnableUpgradeable)
        onlyRole(DEFAULT_ADMIN_ROLE)   
    {
        uint256 size     = _quadObj[tokenId].size;
        uint256 landX    = _quadObj[tokenId].x;
        uint256 landY    = _quadObj[tokenId].y;
        uint256 landId;

        _landOwners[tokenId] = address(0);
        if (size > 1) {
            for (uint256 i = 0; i < size*size; i++) {
                    landId = landX + landY * MAP_SIZE;

                    //[0] is quadId, already reset
                    if (i != 0)
                        _landOwners[landId] = address(0);
                    
                    if ((i+1) % size == 0) {
                        landY += 1;
                        landX = _quadObj[tokenId].x;
                    } else 
                        landX += 1; 
            }
        }    
        _burn(tokenId);
        delete _quadObj[tokenId];
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function reassignAllLand(address to, uint256 size, uint256 x, uint256 y) internal {

            uint256 xNew = x; 
            uint256 yNew = y; 
            uint256 landId;
            
            for (uint256 i = 0; i < size*size; i++) {
                    landId = xNew + yNew * MAP_SIZE;                
                    
                    // Assign from xNew+1, because 1st land is quadId
                    if (i > 0)
                        _landOwners[landId] = to;
                    
                    if ((i+1) % size == 0) {
                        yNew += 1;
                        xNew = x;
                    } else 
                        xNew += 1; 
            }            
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        uint256 size   = _quadObj[tokenId].size;
        uint256 x      = _quadObj[tokenId].x;
        uint256 y      = _quadObj[tokenId].y;

        if (size > 1)
            reassignAllLand(to, size, x, y);
    
        //tokenId is the ERC721 token ID and also is quadId
        _landOwners[tokenId] = to;
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        uint256 size   = _quadObj[tokenId].size;
        uint256 x      = _quadObj[tokenId].x;
        uint256 y      = _quadObj[tokenId].y;

        if (size > 1)
            reassignAllLand(to, size, x, y);

        //tokenId is the ERC721 token ID and also is quadId
        _landOwners[tokenId] = to;
        _transfer(from, to, tokenId);
    }

    function withdrawBal() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawBalERC20(uint256 id) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(_allowedERC20[id].layer != 0, "Not exist allowed ERC20");
        ERC20Info storage tokens = _allowedERC20[id];
        IERC20Upgradeable payToken;
        payToken = tokens.payERC20;
        payToken.transfer(msg.sender, payToken.balanceOf(address(this)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

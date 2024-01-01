// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Psi.sol";
import "./AccessControl.sol";
import "./BitMaps.sol";

contract PFP is ERC721Psi,AccessControl {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;
    address private _owner;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    string public baseURI="https://playestates.mypinata.cloud/ipfs/QmVezKoVrahzS9cNNUsvKSk3eUnyVqNaPHhN8NN98AhkCU/";

    constructor() ERC721Psi("Genesis Skyward Citizen", "OWNK") {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x8b8092a331e0d7341B76bd89BAbDEEEA3daD67dA);
        _grantRole(MINTER_ROLE, 0x8Ae7740a18d2063Af308DF69B0D495970Fe32F0E);
        _grantRole(MANAGER_ROLE, 0x79Ff01B87417f97F4dfc5a55f1cA969564CC5DC7);
        _owner = msg.sender;
    }
    event Mint(address indexed operator, address indexed to, uint256 quantity);
    event Burn(address indexed operator, uint256 tokenID);
    event SetBaseURI(address indexed operator, string uri);
    event Recovery(address indexed sender,address indexed from,address indexed to, uint256 tokenID);
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * address to
     * quantity mint number
     */
    function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE)  {
        _safeMint(to, quantity);
        emit Mint(_msgSender(), to, quantity);
    }

    /**
     * uri new baseURI
     */
    function setBaseURI(string memory uri) external onlyRole(MANAGER_ROLE){
        baseURI = uri;
        emit SetBaseURI(_msgSender(),uri);
    }
    
    // tokenId burn tokenId
    function burn(uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
    }
    // recovery address tokenId 
    function recovery(uint256 tokenId,address to) external onlyRole(MANAGER_ROLE) {
        require(tokenId<=10000,"no auth");
        address from = ownerOf(tokenId);
        _transfer(from,to,tokenId);
        emit Recovery(_msgSender(),from,to,tokenId);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyRole(MANAGER_ROLE) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view override virtual returns (bool){
        if(_burnedToken.get(tokenId)) {
            return false;
        } 
        return super._exists(tokenId);
    }
    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Psi, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    } 
}
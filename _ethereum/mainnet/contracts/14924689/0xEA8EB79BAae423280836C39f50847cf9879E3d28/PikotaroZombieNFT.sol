//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

/// @creator: PIKOTARO Zombie
/// @author: op3n.world

// 88""Yb 88 88  dP  dP"Yb  888888    db    88""Yb  dP"Yb      8888P  dP"Yb  8b    d8 88""Yb 88 888888 
// 88__dP 88 88odP  dP   Yb   88     dPYb   88__dP dP   Yb       dP  dP   Yb 88b  d88 88__dP 88 88__   
// 88"""  88 88"Yb  Yb   dP   88    dP__Yb  88"Yb  Yb   dP      dP   Yb   dP 88YbdP88 88""Yb 88 88""   
// 88     88 88  Yb  YbodP    88   dP""""Yb 88  Yb  YbodP      d8888  YbodP  88 YY 88 88oodP 88 888888 

import "./AccessControl.sol";
import "./ERC721Royalty.sol";
import "./IPikotaroZombieNFT.sol";

contract PikotaroZombieNFT is AccessControl, IPikotaroZombieNFT, ERC721Royalty {
    address private _owner;
    string private _tokenURI;
    uint256 private _tokenCount;
    uint256 private _totalSupply;

    /**
     * @dev Initializes the contract with name is `PikoZoo`, `symbol` is `PKZ`, owner is deployer to the token collection.
     */
    constructor() ERC721("PIKOTARO Zombie", "PKTZ") {
        _owner = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @dev See {IERC165-supportsInterface}, {IERC2981-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Royalty, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has an admin role.
    */
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Returns totalSupply address.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev set tokenURI.
     */
    function setTokenURI(string memory tokenURI_) external override onlyAdmin{
        _tokenURI = tokenURI_;
    }
    
    /**
     * @dev Set royalty of this contract
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Returns tokenCount address.
     */
    function tokenCount() external view override returns (uint256) {
        return _tokenCount;
    }

    /**
     * @dev See {ERC721-_burn}, {ERC721Royalty-_burn}
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURI;
    }

    /**
     * @dev Activate this contract
     * Can only be called by the admin.
     */
    function activate(uint256 totalSupply_, address royaltyRecipient_) external override onlyAdmin {
         require(_totalSupply == 0, "PKTZ: Already activated");
        
        _totalSupply = totalSupply_; // 110
        _setDefaultRoyalty(royaltyRecipient_, 750); // 7.5%
    }

    /**
     * @dev internal mint a NFT.
     */
    function _mintNFT(address to) internal {
        require(_tokenCount <= _totalSupply, "PKTZ: Invalid TokenId");
        
        _tokenCount++;
        _mint(to, _tokenCount);
    }

    /**
     * @dev mint a NFT.
     * Can only be called by the admin.
     */
    function mint(address to) external override onlyAdmin {
        _mintNFT(to);
    }
}
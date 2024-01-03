pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./ENS.sol";
import "./IRemiliasRegistrar.sol";
import "./ERC721Remilias.sol";

contract RemiliasRegistrar is ERC721Remilias, IRemiliasRegistrar, Ownable {
    // The ENS registry
    ENS public ens;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
                keccak256("ownerOf(uint256)") ^
                keccak256("approve(address,uint256)") ^
                keccak256("getApproved(uint256)") ^
                keccak256("setApprovalForAll(address,bool)") ^
                keccak256("isApprovedForAll(address,address)") ^
                keccak256("transferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID =
        bytes4(keccak256("reclaim(uint256,address)"));
    bytes4 private constant RESET_ID = bytes4(keccak256("resetOwner(uint256)"));

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    constructor(ENS _ens, bytes32 _baseNode) ERC721Remilias("", "") {
        ens = _ens;
        baseNode = _baseNode;
        _initializeOwner(msg.sender);
    }

    modifier live() {
        if (ens.owner(baseNode) != address(this)) {
            revert NotStarted();
            // require(false, '2');
        }
        _;
    }

    modifier onlyController() {
        if (!controllers[msg.sender]) {
            revert UnauthorizedController();
        }
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(
        uint256 tokenId
    ) public view override(IERC721, ERC721Remilias) returns (address) {
        return super.ownerOf(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external override onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    function registerResolver() external live onlyOwner {
        uint256 id = 0x329539a1d23af1810c48a07fe7fc66a3b34fbc8b37e9b3cdb97bb88ceab7e4bf;
        _mint(msg.sender, address(this), uint96(420), id);
        ens.setSubnodeOwner(baseNode, bytes32(id), msg.sender);

        emit NameRegistered(id, msg.sender, address(this), 420);
    }

    // Returns true if the specified name is available for registration.
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here.
        return !_exists(id);
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param collection The address of remilia nft contract.
     * @param nft token id of the nft.
     */
    function register(uint256 id, address collection, uint256 nft) external {
        _register(id, collection, nft, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param collection The address of remilia nft contract.
     * @param nft token id of the nft.
     */
    function registerOnly(
        uint256 id,
        address collection,
        uint256 nft
    ) external {
        _register(id, collection, nft, false);
    }

    function _register(
        uint256 id,
        address collection,
        uint256 nft,
        bool updateRegistry
    ) internal live onlyController {
        address _owner = ERC721Remilias(collection).ownerOf(nft);
        _mint(_owner, collection, uint96(nft), id);
        if (updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), _owner);
        }

        emit NameRegistered(id, _owner, collection, nft);
    }

    /**
     * @dev Resets ownership of a name to the minter NFT owner.
     */
    function resetOwner(uint256 id) external override live onlyController {
        if (!_exists(id)) {
            revert Unavailable();
        }
        MiladyOwner memory details = milady(id);
        address realOwner = ERC721Remilias(details.collection).ownerOf(
            details.nft
        );
        if (realOwner != details.owner) {
            _controlledTransfer(details.owner, realOwner, id);
        }
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live {
        if (!_isApprovedOrOwner(msg.sender, id)) {
            revert UnauthorizedOwner();
        }
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view override(ERC721Remilias, IERC165) returns (bool) {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RESET_ID ||
            interfaceID == RECLAIM_ID;
    }
}

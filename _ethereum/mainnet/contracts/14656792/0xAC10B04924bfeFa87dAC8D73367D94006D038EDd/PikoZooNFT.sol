//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

/// @creator: Zoombiezoo
/// @author: op3n.world

import "./AccessControl.sol";
import "./ERC721Royalty.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./IPikoZooNFT.sol";

contract PikoZooNFT is AccessControl, IPikoZooNFT, ERC721Royalty {
    using ECDSA for bytes32;
    using Address for address;

    uint256 public constant UNIT_PRICE = 80000000000000000; // 0.08 ETH
    uint8 public constant MAX_PRESALE_PER_MINTER = 2;
    uint256 public constant PRESALE_START_AT = 1650942000; // Tuesday, 26 April 2022 10:00:00 GMT+07:00
    uint256 public constant PUBSALE_START_AT = 1651114800; // Tuesday, 28 April 2022 10:00:00 GMT+07:00
    
    address private _owner;
    address payable private _fundRecipient;
    bytes32 private _preSaleRoot;
    string private _tokenURI;
    uint256 private _tokenCount;
    uint256 private _totalSupply;
    uint8 private _giveawayCount;
    uint8 private _maxGiveaway;
    mapping(address => bool) private _verifiers;
    mapping(bytes32 => bool) public finalized;
    mapping(address => uint8) private _preSaleMinted;

    /**
     * @dev Initializes the contract with name is `PikoZoo`, `symbol` is `PKZ`, owner is deployer to the token collection.
     */
    constructor() ERC721("PikoZoo", "PKZ") {
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
     * @dev Returns giveawayCount address.
     */
    function giveawayCount() external view override returns (uint256) {
        return _giveawayCount;
    }

    /**
     * @dev Returns maxGiveaway address.
     */
    function maxGiveaway() external view override returns (uint256) {
        return _maxGiveaway;
    }

    /**
     * @dev Check address is verifier
     */
    function isVerifier(address verifier_) external view override returns (bool) {
        return _verifiers[verifier_];
    }

    /**
     * @dev Set mint verifier of this contract
     * Can only be called by the admin.
     */
    function setVerifier(address verifier_) external override onlyAdmin {
        _verifiers[verifier_] = true;
    }

    /**
     * @dev Revoke mint verifier of this contract
     * Can only be called by the admin.
     */
    function revokeVerifier(address verifier_) external override onlyAdmin {
        _verifiers[verifier_] = false;
    }

    /**
     * @dev set tokenURI.
     */
    function setTokenURI(string memory tokenURI_) external override onlyAdmin{
        _tokenURI = tokenURI_;
    }

    /**
     * @dev Set preSaleRoot of this contract
     * Can only be called by the admin.
     */
    function setPreSaleRoot(bytes32 root_) external override onlyAdmin {
        _preSaleRoot = root_;
    }

    /**
     * @dev Get preSaleRoot
     */
    function preSaleRoot() external view returns(bytes32) {
        return _preSaleRoot;
    }

    /**
     * @dev Set royalty of this contract
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Set fundRecipient of this contract
     * Can only be called by the admin.
     */
    function setFundRecipient(address fundRecipient_) external override onlyAdmin {
        _fundRecipient = payable(fundRecipient_);
    }

    /**
     * @dev Returns fundRecipient address.
     */
    function fundRecipient() external view override returns (address) {
        return _fundRecipient;
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
    function activate(uint256 totalSupply_, uint8 maxGiveaway_, address fundRecipient_, address royaltyRecipient_) external override onlyAdmin {
         require(_totalSupply == 0, "PKZ: Already activated");
        
        _totalSupply = totalSupply_;
        _maxGiveaway = maxGiveaway_;
        _fundRecipient = payable(fundRecipient_);
        _setDefaultRoyalty(royaltyRecipient_, 750);
    }

    /**
     * @dev validate a mint.
     */
    function _validateMint(bytes32[] memory proof) internal returns (bool) {
        if (PUBSALE_START_AT <= block.timestamp) {
            return true;
        }

        if (PRESALE_START_AT <= block.timestamp && MerkleProof.verify(proof, _preSaleRoot, keccak256(abi.encodePacked(_msgSender())))) {
            if (MAX_PRESALE_PER_MINTER <= _preSaleMinted[_msgSender()]) {
                return false;
            }

            _preSaleMinted[_msgSender()]++;
            return true;
        }

        return false;
    }

    /**
     * @dev validate a sig.
     */
    function _validateSig(uint256 salt, bytes memory sig) internal returns (bool) {
        bytes32 _verifiedHash = keccak256(abi.encodePacked(msg.sender, salt));
        if (finalized[_verifiedHash]) {
            return false;
        }

        if (!_verifiers[_verifiedHash.toEthSignedMessageHash().recover(sig)]) {
            return false;
        }
        
        finalized[_verifiedHash] = true;
        return true;
    }

    /**
     * @dev internal mint a NFT.
     */
    function _mintNFT(address to, uint256 tokenId) internal {
        require(tokenId <= _totalSupply, "PKZ: Invalid TokenId");
        
        _tokenCount++;
        _mint(to, tokenId);
    }

    /**
     * @dev mint a NFT.
     */
    function mint(uint256 tokenId, uint256 salt, bytes memory sig, bytes32[] memory proof) external payable override {
        require(UNIT_PRICE <= msg.value, "PKZ: Invalid amount");
        require(_validateMint(proof), "PKZ: Invalid mint");
        require(_validateSig(salt, sig), "PKZ: Invalid signature");
        
        Address.sendValue(_fundRecipient, msg.value);
        _mintNFT(msg.sender, tokenId);
    }

    /**
     * @dev mint NFTs.
     */
    function mintBatch(uint256[] memory tokenIds, uint256 salt, bytes memory sig, bytes32[] memory proof) external payable override {
        uint256 mintCount = tokenIds.length;
        require(UNIT_PRICE * mintCount <= msg.value, "PKZ: Invalid amount");
        require(_validateMint(proof), "PKZ: Invalid mint");
        require(_validateSig(salt, sig), "PKZ: Invalid signature");
        
        Address.sendValue(_fundRecipient, msg.value);
        for (uint256 index = 0; index < mintCount; index++) {
            _mintNFT(msg.sender, tokenIds[index]);
        }
    }

    /**
     * @dev giveaway tokenId to receiver.
     * Can only be called by the admin.
     */
    function giveaway(address toAddress, uint256 tokenId) external override onlyAdmin {
        require(_giveawayCount < _maxGiveaway, "PKZ: Invalid giveaway");
        require(tokenId <= _totalSupply, "PKZ: Invalid TokenId");

        _giveawayCount++;
        _tokenCount++;
        _mint(toAddress, tokenId);
        emit Giveaway(toAddress, tokenId);
    }
}
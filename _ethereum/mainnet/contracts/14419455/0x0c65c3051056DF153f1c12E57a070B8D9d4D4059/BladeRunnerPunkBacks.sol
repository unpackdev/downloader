// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "AccessControlEnumerable.sol";
import "ECDSA.sol";
import "BitMaps.sol";
import "UnburnableERC721.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BladeRunnerPunkBacks is UnburnableERC721, AccessControlEnumerable {

    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    // Limit on totalSupply. Initialized on deployment.
    uint256 public immutable collectionSize;

    // Predetermined account that gets the profits. Set on deploy and cannot be changed.
    address payable public immutable beneficiary;

    // URI base for token metadata.
    string public baseURI;
    string public tokenURISuffix = ".json";

    // Minting price of one token.
    uint256 private _price;

    // Unix epoch seconds. Tokens may be minted until this moment.
    uint256 private _priceValidUntil;

    // Minting requires a valid signature by signer. (Off-chain whitelist check, etc.)
    address private signer;

    // Every minting slot can only be used once. Mark used slots in a BitMap.
    BitMaps.BitMap private _slots;


    event SignerChanged(address newSigner);
    event MintPriceChanged(uint256 newPrice, uint newPriceValidUntil);


    constructor(
        string memory name, string memory symbol, string memory baseTokenURI, uint256 mintPrice,
        uint256 priceValidUntil, uint256 max, address admin, address payable beneficiary_, address signer_
    ) UnburnableERC721(name, symbol) {
        collectionSize = max;
        baseURI = baseTokenURI;
        beneficiary = beneficiary_;
        signer = signer_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        setPrice(mintPrice, priceValidUntil);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), tokenURISuffix)) : "";
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function setTokenURISuffix(string memory suffix) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURISuffix = suffix;
    }

    // @notice Set minting price and until what timestamp (in epoch seconds) is the minting open with this price.
    function setPrice(uint256 mintPrice, uint256 priceValidUntil) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = mintPrice;
        _priceValidUntil = priceValidUntil;
        emit MintPriceChanged(_price, _priceValidUntil);
    }

    // @return The minting price and the closing time in unix epoch seconds.
    function price() public view returns (uint256, uint256) {
        return (_price, _priceValidUntil);
    }

    // @notice Set a new signer address that is use to sign minting permits.
    function changeSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = newSigner;
        emit SignerChanged(signer);
    }

    // @notice Check if a minting slot is used.
    // @return true if the minting slot is used.
    function slotUsed(uint256 slotId) public view returns (bool) {
        return _slots.get(slotId);
    }

    function mint(uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) external payable {
        // Check signature.
        require(_canMint(msg.sender, amount, slotId, validUntil, signature), "NFT: Must have valid signing");

        // Check amount.
        require(totalSupply() + amount <= collectionSize, "NFT: Cannot mint over collection size");

        // Check price.
        require(msg.value >= (amount * _price), "NFT: Insufficient eth sent");

        // Check temporal validity.
        require(block.timestamp <= validUntil, "NFT: Slot must be used before expiration time");
        require(block.timestamp <= _priceValidUntil, "NFT: The price has expired");

        // Check if the slot is still free and mark it used.
        require(!_slots.get(slotId), "NFT: Slot already used");
        _slots.set(slotId);

        // Mint.
        _safeMintMany(msg.sender, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable, UnburnableERC721) returns (bool){
        return AccessControlEnumerable.supportsInterface(interfaceId) || UnburnableERC721.supportsInterface(interfaceId);
    }

    function _canMint(address minter, uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(minter, amount, slotId, validUntil)).toEthSignedMessageHash().recover(signature) == signer;
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC721(IERC721 tokenToRescue, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC20(IERC20 tokenToRescue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.transfer(_msgSender(), tokenToRescue.balanceOf(address(this)));
    }

    // @notice Send all of the native currency to predetermined beneficiary.
    function release() external {
        Address.sendValue(beneficiary, address(this).balance);
    }

}

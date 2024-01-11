// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC1155.sol";
import "ECDSA.sol";
import "BitMaps.sol";
import "Pausable.sol";
import "IERC20.sol";
import "IERC721.sol";
import "AccessControlEnumerable.sol";
import "IERC2981.sol";

contract FrontRowMembership is ERC1155, Pausable, AccessControlEnumerable, IERC2981 {

    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    struct Tier {
        string name;
        uint256 price;
        uint256 max;
        uint256 supply;
    }

    string public name;
    string public symbol;
    address public owner; /* For OpenSea, etc. */
    uint8 public royaltyPercentage;

    mapping (uint256 => Tier) tiers; /* tier_id -> tier */

    // Predetermined account that gets the profits.
    address payable public beneficiary;

    // Minting requires a valid signature by signer. (Off-chain whitelist check, etc.)
    address public signer;

    // Every minting slot can only be used once. Mark used slots in a BitMap.
    BitMaps.BitMap private _slots;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SignerChanged(address newSigner);
    event BeneficiaryChanged(address newBeneficiary);
    event TierUpdated(uint256 indexed token_id, string name, uint256 price, uint256 max);
    event SlotUsed(uint256 slotId, uint256 tokenId, uint256 amount, address minter);

    constructor(string memory _uri, address payable _beneficiary, address _signer, address[] memory admins) ERC1155(_uri) {
        require(_beneficiary != address(0), "Beneficiary must not be zero address");

        name = "Frontrow Membership";
        symbol = "STEVE";

        royaltyPercentage = 10;

        // Set up admin accounts and ownership.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
        transferOwnership(msg.sender);

        beneficiary = _beneficiary;
        emit BeneficiaryChanged(_beneficiary);
        signer = _signer;
        emit SignerChanged(_signer);

        setTier(5, "Royal", 40e18, 20);
        setTier(4, "Black", 12e18, 80);
        setTier(3, "Diamond", 4e18, 250);
        setTier(2, "Gold", 2e18, 400);
        setTier(1, "Silver", 1e18, 750);

        _pause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155, AccessControlEnumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId ||
         ERC1155.supportsInterface(interfaceId) ||
         AccessControlEnumerable.supportsInterface(interfaceId);
    }

    function renounceOwnership() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(false, "Not supported.");
    }

    function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setURI(string memory newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    function setName(string memory newName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        name = newName;
    }

    function setSymbol(string memory newSymbol) external onlyRole(DEFAULT_ADMIN_ROLE) {
        symbol = newSymbol;
    }

    function setRoyaltyPercentage(uint8 percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyPercentage = percentage;
    }

    function setTier(uint256 id, string memory _name, uint256 _price, uint256 _max) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Tier storage tier = tiers[id];
        tier.name = _name;
        tier.price = _price;
        tier.max = _max;
        emit TierUpdated(id, _name, _price, _max);
    }

    function getTier(uint256 id) external view returns (Tier memory) {
        require(exists(id), "tokenId does not exist");
        return tiers[id];
    }

    function price(uint256 tokenId) external view returns (uint256) {
        require(exists(tokenId), "tokenId does not exist");
        return tiers[tokenId].price;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString(), ".json"));
    }

    // @notice Set a new signer address that is use to sign minting permits.
    function changeSigner(address newSigner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = newSigner;
        emit SignerChanged(newSigner);
    }

    function changeBeneficiary(address payable newBeneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBeneficiary != address(0), "Beneficiary must not be the zero address");
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(newBeneficiary);
    }

    // @notice Check if a minting slot is used.
    // @return true if the minting slot is used.
    function slotUsed(uint256 slotId) public view returns (bool) {
        return _slots.get(slotId);
    }

    function mint(uint256 amount, uint256 slotId, uint256 tokenId, uint256 validUntil, bytes memory signature) external payable whenNotPaused {
        // Check signature.
        require(_canMint(msg.sender, amount, slotId, tokenId, validUntil, signature), "Must have valid signing");

        // Load tier
        Tier storage tier = tiers[tokenId];

        // Check amount. Also prevents minting for non-existent tokens.
        require(tier.supply + amount <= tier.max, "Cannot mint over maximum");

        // Check price.
        require(msg.value >= (amount * tier.price), "Insufficient eth sent");

        // Check temporal validity.
        require(block.timestamp <= validUntil, "Slot must be used before expiration time");

        // Check if the slot is still free and mark it used.
        require(!_slots.get(slotId), "Slot already used");
        _slots.set(slotId);
        emit SlotUsed(slotId, tokenId, amount, msg.sender);

        // Update minted amount.
        tier.supply += amount;

        // Mint.
        _mint(msg.sender, tokenId, amount, "");
    }

    function batchMint(address[] memory accounts, uint256[] memory tokenIds, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(accounts.length == tokenIds.length, "Incorrect length match for accounts and tokenIds");
        require(accounts.length == amounts.length, "Incorrect length match for accounts and amounts");

        for (uint256 i = 0; i < accounts.length; i++) {
            Tier storage tier = tiers[tokenIds[i]];
            tier.supply += amounts[i];
            require(tier.supply <= tier.max, "Cannot mint over maximum amount of tier");
            _mint(accounts[i], tokenIds[i], amounts[i], "");
        }
    }

    function totalSupply(uint256 id) external view returns (uint256) {
        Tier storage tier = tiers[id];
        require(tier.max > 0, "No such tokenId");
        return tier.supply;
    }

    function exists(uint256 id) public view returns (bool) {
        Tier storage tier = tiers[id];
        return (tier.max > 0);
    }

    function _canMint(address minter, uint256 amount, uint256 slotId, uint256 tokenId, uint256 validUntil, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(minter, amount, slotId, tokenId, validUntil)).toEthSignedMessageHash().recover(signature) == signer;
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC721(IERC721 tokenToRescue, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC20(IERC20 tokenToRescue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.transfer(_msgSender(), tokenToRescue.balanceOf(address(this)));
    }

    // @notice Send all of the native currency to predetermined beneficiary. Anyone can pay gasses for release.
    function release() external {
        Address.sendValue(beneficiary, address(this).balance);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        return (beneficiary, (_salePrice * royaltyPercentage) / 100);
    }

}

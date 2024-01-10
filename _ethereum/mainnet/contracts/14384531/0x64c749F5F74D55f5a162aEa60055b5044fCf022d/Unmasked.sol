// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./ERC721B.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

error InvalidProof();
error OverMaxSupply();
error WrongEtherValue();
error OverMintLimit();
error DoubleClaim();
error SaleNotActive();

contract Unmasked is ERC721B, Ownable {
    using Strings for uint256;

    // OpenSea whitelisting
    address constant proxyRegistryAddress = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
    mapping(address => bool) public addressToRegistryDisabled;

    // Merkle whitelisting
    mapping(address => bool) public claimed;
    bytes32 public CLAIM_ROOT;
    bytes32 public WHITELIST_ROOT;

    // collection specific parameters
    string private baseURI;
    string public provenance;
    bool public publicSaleActive;

    uint256 public supply = 3333;
    uint256 public price = 0.06 ether;
    uint256 public price2 = 0.04 ether;
    uint256 constant maxBatchSize = 20;

    constructor() ERC721B('TheUnmasked', 'UNMASKED') {}

    /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setClaim(bytes32 _root) external onlyOwner {
        CLAIM_ROOT = _root;
    }

    function setWhitelist(bytes32 _root) external onlyOwner {
        WHITELIST_ROOT = _root;
    }

    function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPrice(uint256 _price, uint256 _price2) external onlyOwner {
        price = _price;
        price2 = _price2;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        supply = _supply;
    }

    /**
     * Reserve NFTs for giveaways
     */
    function reserveUnmasked(uint256 qty) external onlyOwner {
        if ((_owners.length + qty) > supply) revert OverMaxSupply();

        _mint(msg.sender, qty);
    }

    /**
     * Claim function for whitelisted addresses
     */
    function claim(
        address account,
        uint256 qty,
        bytes32[] calldata proof
    ) external {
        if (!_verify(_leaf(account, qty), proof)) revert InvalidProof();
        if ((_owners.length + qty) > supply) revert OverMaxSupply();
        if (claimed[account]) revert DoubleClaim();

        // set claimed to true to prevent double claiming
        claimed[account] = true;

        _mint(account, qty);
    }

    function whitelistMint(uint256 qty, bytes32[] calldata proof) external payable {
        if (!_verify2(_leaf2(msg.sender), proof)) revert InvalidProof();
        if (qty > maxBatchSize) revert OverMintLimit();
        if ((_owners.length + qty) > supply) revert OverMaxSupply();
        if (msg.value < price2 * qty) revert WrongEtherValue();

        _mint(msg.sender, qty);
    }

    function publicMint(uint256 qty) external payable {
        if (!publicSaleActive) revert SaleNotActive();
        if (qty > maxBatchSize) revert OverMintLimit();
        if ((_owners.length + qty) > supply) revert OverMaxSupply();
        if (msg.value < price * qty) revert WrongEtherValue();

        _safeMint(msg.sender, qty);
    }

    /**
        An override to whitelist the OpenSea proxy contract to enable gas-free
        listings. This function returns true if `_operator` is approved to transfer
        items owned by `_owner`.
        @param owner The owner of items to check for transfer ability.
        @param operator The potential transferrer of `_owner`'s items.
    */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator && !addressToRegistryDisabled[owner]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Allow a user to disable the OpenSea pre-approval if they believe OS to not be secure.
     */
    function toggleRegistryAccess() public virtual {
        addressToRegistryDisabled[msg.sender] = !addressToRegistryDisabled[msg.sender];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev See OpenZeppelin MerkleProof.
     */
    function _leaf(address account, uint256 qty) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, qty));
    }

    function _leaf2(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, CLAIM_ROOT, leaf);
    }

    function _verify2(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, WHITELIST_ROOT, leaf);
    }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
 * Used to delegate ownership of a contract to another address,
 * to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./IERC2981.sol";
import "./IOpenSeaProxyRegistry.sol";
import "./IDopamineSmiley.sol";
import "./SmileyErrors.sol";

/// @title Dopamine's original smiley, designed by artist @evrlstng
contract DopamineSmiley is IDopamineSmiley, IERC721, IERC721Metadata, IERC2981 {

    /// @notice The name of this NFT collection.
    string public constant name  = "Dopamine Smiley";

    /// @notice The abbreviated name of this NFT collection.
    string public constant symbol  = "SMILEY";

    /// @notice The total number of NFTs in circulation.
    uint256 public constant totalSupply = 1;

    /// @notice The URI the NFT points to for metadata resolution.
    string public baseURI = "https://api.dopamine.xyz/smiley/metadata/";

    /// @notice Gets the number of NFTs owned by an address.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(address => uint256) public balanceOf;

    /// @notice The address administering minting and metadata settings.
    address public owner;

    /// @notice Gets the assigned owner of an address.
    /// @dev This implementation does not throw for NFTs of the zero address.
    mapping(uint256 => address) public ownerOf;

    /// @notice Gets the approved address for an NFT.
    /// @dev This implementation does not throw for zero-address queries.
    mapping(uint256 => address) public getApproved;

    /// @notice The OS registry address - allowlisted for gasless OS approvals.
    IOpenSeaProxyRegistry public proxyRegistry;

    /// @dev Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // EIP-2981 collection-wide royalties information.
    RoyaltiesInfo internal _royaltiesInfo;

    // EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
    bytes4 private constant _ERC2981_METADATA_INTERFACE_ID = 0x2a55205a;

    /// @notice Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Creates Dopamine's original smiley.
    /// @param proxyRegistry_ The OpenSea proxy registry address.
    /// @param reserve_ Address to which EIP-2981 royalties direct to.
    /// @param royalties_ Royalties sent to `reserve_` on sales, in bips.
    constructor(
        IOpenSeaProxyRegistry proxyRegistry_,
        address reserve_,
        uint96 royalties_
    ) {
        owner = msg.sender;
        proxyRegistry = proxyRegistry_;
        setRoyalties(reserve_, royalties_);

        balanceOf[owner] = 1;
        ownerOf[1] = owner;
        emit Transfer(address(0), owner, 1);
    }

    /// @notice Retrieves a URI describing the overall contract-level metadata.
    /// @return A string URI pointing to the smiley contract metadata.
    function contractURI() external view returns (string memory)  {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    /// @notice Sets the base URI to `newBaseURI`.
    /// @param newBaseURI The new base metadata URI to set for the collection.
    /// @dev This function is only callable by the owner address.
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @notice Sets the owner address to `newOwner`.
    /// @param newOwner The address of the new owner.
    /// @dev This function is only callable by the owner address.
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerChanged(owner, newOwner);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view returns (address, uint256) {
        RoyaltiesInfo memory royaltiesInfo = _royaltiesInfo;
        uint256 royalties = (salePrice * royaltiesInfo.royalties) / 10000;
        return (royaltiesInfo.receiver, royalties);
    }

    /// @notice Sets approved address of NFT of id `id` to address `approved`.
    /// @param approved The new approved address for the NFT.
    /// @param id The id of the NFT to approve.
    function approve(address approved, uint256 id) external {
        address owner = ownerOf[id];

        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert SenderUnauthorized();
        }

        getApproved[id] = approved;
        emit Approval(owner, approved, id);
    }

    /// @notice Checks if `operator` is an authorized operator for `owner`.
    /// @param owner The address of the owner.
    /// @param operator The address for the owner's operator.
    /// @return True if `operator` is approved operator of `owner`, else false.
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {
        return
            proxyRegistry.proxies(owner) == operator ||
            _operatorApprovals[owner][operator];
    }

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address that will manage the sender's NFTs.
    /// @param approved Whether operator is allowed to operate on sender's NFTs.
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns the metadata URI associated with the NFT of id `id`.
    /// @param id The id of the NFT being queried.
    /// @return A string URI pointing to the metadata of the queried NFT.
    function tokenURI(uint256 id) external view returns (string memory) {
        if (ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }

        return string(abi.encodePacked(baseURI, _toString(id)));
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The EIP-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id) external pure returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC721_INTERFACE_ID ||
            id == _ERC721_METADATA_INTERFACE_ID ||
            id == _ERC2981_METADATA_INTERFACE_ID;
    }

    /// @notice Sets EIP-2981 royalty information for NFTs in the collection.
    /// @param receiver Address which will receive token royalties.
    /// @param royalties Amount of royalties to be sent, in bips.
    function setRoyalties(
        address receiver,
        uint96 royalties
    ) public onlyOwner {
        if (royalties > 10000) {
            revert RoyaltiesTooHigh();
        }
        if (receiver == address(0)) {
            revert ReceiverInvalid();
        }
        _royaltiesInfo = RoyaltiesInfo(receiver, royalties);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals, but `Approval` events are omitted.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The address of the new owner of the NFT to be transferred.
    /// @param id The id of the NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        if (from != ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[id] &&
            !_operatorApprovals[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        delete getApproved[id];

        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    /// @dev Converts a uint256 into a string.
    /// @param value A positive uint256 value.
    function _toString(uint256 value) internal pure returns (string memory) {
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

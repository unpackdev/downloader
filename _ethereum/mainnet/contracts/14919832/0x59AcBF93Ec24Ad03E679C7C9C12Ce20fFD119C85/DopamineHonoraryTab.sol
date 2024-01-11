// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IDopamineHonoraryTab.sol";
import "./IOpenSeaProxyRegistry.sol";
import "./ERC721H.sol";
import "./Errors.sol";

/// @title Dopamine honorary ERC-721 membership tab
/// @notice Dopamine honorary tabs are vanity tabs for friends of Dopamine.
contract DopamineHonoraryTab is ERC721H, IDopamineHonoraryTab {

    /// @notice The address administering minting and metadata settings.
    address public owner;

    /// @notice The OS registry address - allowlisted for gasless OS approvals.
    IOpenSeaProxyRegistry public proxyRegistry;

    /// @notice The URI each tab initially points to for metadata resolution.
    /// @dev Before drop completion, `tokenURI()` resolves to "{baseURI}/{id}".
    string public baseURI = "https://api.dopamine.xyz/honoraries/metadata/";

    /// @notice The permanent URI tabs will point to on collection finality.
    /// @dev After drop completion, `tokenURI()` directs to "{storageURI}/{id}".
    string public storageURI;

    /// @notice Restricts a function call to address `owner`.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Instantiates a new Dopamine honorary membership tab contract.
    /// @param proxyRegistry_ The OpenSea proxy registry address.
    /// @param reserve_ Address to which EIP-2981 royalties direct to.
    /// @param royalties_ Royalties sent to `reserve_` on sales, in bips.
    constructor(
        IOpenSeaProxyRegistry proxyRegistry_,
        address reserve_,
        uint96 royalties_
    ) ERC721H("Dopamine Honorary Tabs", "HDOPE") {
        owner = msg.sender;
        proxyRegistry = proxyRegistry_;
        _setRoyalties(reserve_, royalties_);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function mint(address to) external onlyOwner {
        return _mint(owner, to);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function contractURI() external view returns (string memory)  {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerChanged(owner, newOwner);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setStorageURI(string calldata newStorageURI) external onlyOwner {
        storageURI = newStorageURI;
        emit StorageURISet(newStorageURI);
    }

    /// @inheritdoc IDopamineHonoraryTab
    function setRoyalties(
        address receiver,
        uint96 royalties
    ) external onlyOwner {
        _setRoyalties(receiver, royalties);
    }

    /// @inheritdoc ERC721H
    /// @dev Before all honoraries are minted, the token URI for tab of id `id`
    ///  defaults to {baseURI}/{id}. Once all honoraries are minted, this will
    ///  be replaced with a decentralized storage URI (Arweave / IPFS) given by
    ///  {storageURI}/{id}. If `id` does not exist, this function reverts.
    /// @param id The id of the NFT being queried.
    function tokenURI(uint256 id)
        public
        view
        virtual
        override(ERC721H)
        returns (string memory)
    {
        if (ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }

        string memory uri = storageURI;
        if (bytes(uri).length == 0) {
            uri = baseURI;
        }
        return string(abi.encodePacked(uri, _toString(id)));
    }

    /// @dev Ensures OS proxy is allowlisted for operating on behalf of owners.
    /// @inheritdoc ERC721H
    function isApprovedForAll(address owner, address operator)
    public
    view
        override
        returns (bool)
    {
        return
            proxyRegistry.proxies(owner) == operator ||
            _operatorApprovals[owner][operator];
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

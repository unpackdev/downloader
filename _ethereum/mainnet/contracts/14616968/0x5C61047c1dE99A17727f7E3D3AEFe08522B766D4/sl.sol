// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./NFTDescriptor.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata tokenURI extension only
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataTokenURI {
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MIRE is ERC721Upgradeable, RoyaltiesV2Impl, AccessControlUpgradeable {
    using NFTDescriptor for NFTDescriptor.ConstructTokenParams;
    using NFTDescriptor for NFTDescriptor.ConstructContractURIParams;

    mapping(uint256 => IERC721MetadataTokenURI) cloneMappingAddress;
    mapping(uint256 => uint256) cloneMappingId;
    mapping(uint256 => uint256) cloneMappingValue;

    string private _name;
    string private _symbol;
    uint256 mTokenId;
    NFTDescriptor.ConstructContractURIParams contractMetadata;
    uint256 public version;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function init(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        mTokenId = 0;
        version = 0;
        _name = name;
        _symbol = symbol;
    }

    function migrate(address showerlovers) public {
        require(version == 0);
        version = 1;
        // update minted clones
        cloneMappingAddress[0] = cloneMappingAddress[2] = cloneMappingAddress[3] = cloneMappingAddress[4] = cloneMappingAddress[7] = IERC721MetadataTokenURI(showerlovers);
        cloneMappingId[0] = 2; // 0xd35b6046dbb75668caf1a69b139c32dce81c2b63
        cloneMappingId[2] = 10; // 0x547b4bf7f39fae562d2d0d5cfc329b05ec3694f2
        cloneMappingId[3] = 0; // 0x1abae2b8026264e58e28302b1295153cc5166f6d
        cloneMappingId[4] = 5; // 0x8772575854f296a0bb9ae95b0fe01473b13b43a3
        cloneMappingId[7] = 1; // 0x55c23ff0d59d062c279b4cb715efbfd2fb4b3139
        // mint new clones
        mint(0x38F1DfdcaF2F0d70c29D4AF6a4AA9E920efe8B18, showerlovers, 3);
        mint(0x5AB731b442d168a53f5F82696Ebe99A990FBE1CF, showerlovers, 11);
        mint(0x4FAFa51539460F378FF9C2bce4EAf7C628824813, showerlovers, 12);
        mint(0x0DC2DA31bA19A1213c4F839a0cd3637d80642817, showerlovers, 8);
        mint(0x99a7CF01Fd9aD58f224C9675f3A9e45F294231d9, showerlovers, 7);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function batchMint(
        address[] memory to,
        address cloneContract,
        uint256 cloneId
    ) public {
        for (uint256 i = 0; i < to.length; i++) {
            mint(to[i], cloneContract, cloneId);
        }
    }

    function mint(
        address to,
        address cloneContract,
        uint256 cloneId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cloneMappingValue[mTokenId] = mTokenId;

        cloneMappingAddress[mTokenId] = IERC721MetadataTokenURI(cloneContract);
        cloneMappingId[mTokenId] = cloneId;

        _mint(to, mTokenId);
        if (contractMetadata.royaltiesFeeBasisPoints > 0) {
            setRoyalties(
                mTokenId,
                contractMetadata.royaltiesRecipient,
                uint96(contractMetadata.royaltiesFeeBasisPoints)
            );
        }
        mTokenId++;
        //require valid tokenURI (so far length > 0)
    }

    function updateClone(
        uint256 tokenId,
        address _cloneContract,
        uint256 cloneId
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));

        IERC721MetadataTokenURI cloneContract = IERC721MetadataTokenURI(_cloneContract);
        cloneMappingAddress[tokenId] = cloneContract;
        cloneMappingId[tokenId] = cloneId;

        bytes memory tokenURIData = bytes(cloneMappingAddress[tokenId].tokenURI(cloneId));
        require(tokenURIData.length > 0); // check for actual validity of the content
    }

    function batchUpdateClone(
        uint256[] calldata tokenId,
        address[] calldata cloneContract,
        uint256[] calldata cloneId
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        for (uint256 i = 0; i < tokenId.length; i++) {
            cloneMappingAddress[tokenId[i]] = IERC721MetadataTokenURI(cloneContract[i]);
            cloneMappingId[tokenId[i]] = cloneId[i];
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return cloneMappingAddress[tokenId].tokenURI(cloneMappingId[tokenId]);
    }

    // Rarrible & OpenSea roylaties informations
    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // OpenSea contract metadata info
    function contractURI() public view returns (string memory) {
        return contractMetadata.constructContractURI(name());
    }

    // Set contract information, royalties and such
    function setContractURI(NFTDescriptor.ConstructContractURIParams memory params)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractMetadata = params;
    }

    // Set contract information, royalties and such
    function setContractsInfo(string memory name, string memory symbol) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(name).length > 0) {
            _name = name;
        }
        if (bytes(symbol).length > 0) {
            _symbol = symbol;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

contract DBXENFT is
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    address public immutable factory;

    address public ADMIN_ADDRESS = 0x5A5D0AD85762979cAAe341274f0eba22dF8EcEdD;
    
    /**
     * @dev Prefix for tokens metadata URIs
     */
    string public baseURI;

    // Sufix for tokens metadata URIs
    string public baseExtension = ".json";

    constructor() ERC721("DBXEN NFT on Ethereum", "DBXENFT") {
        factory = msg.sender;
    }

    function mintDBXENFT(
        address _to
    ) external nonReentrant returns (uint256 tokenId) {
        require(msg.sender == factory, "DBXENFT: Only factory can mint");
         tokenId = totalSupply() +1;
        _safeMint(_to, tokenId);
        return tokenId;
    }

    /**
     * @dev Returns the current base URI.
     * @return The base URI of the contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev This function sets the base URI of the NFT contract.
     * @param uri The new base URI of the NFT contract.
     * @notice Only the contract owner can call this function.
     */
    function setBasedURI(string memory uri) external {
        require(msg.sender == ADMIN_ADDRESS,"DBXENFT: Only admin can set baseURI!");
        baseURI = uri;
    }

    /**
     * @dev Returns the token URI for the given token ID. Throws if the token ID does not exist
     * @param tokenId The token ID to retrieve the URI for
     * @notice Retrieve the URI for the given token ID
     * @return The token URI for the given token ID
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * Changes the base extension for token metadata
     *
     * Access: only the admin account
     *
     * @param _newBaseExtension new value
     */
    function setBaseExtension(
        string memory _newBaseExtension
    ) public {
       require(msg.sender == ADMIN_ADDRESS, "DBXENFT: Only admin can set baseExtension!");
        baseExtension = _newBaseExtension;
    }

     /**
     * Changes admin address
     *
     * Access: only the addmin account
     *
     * @param _newAdminAddress new value
     */
    function setAdminAddress(
        address  _newAdminAddress
    ) public {
       require(msg.sender == ADMIN_ADDRESS, "DBXENFT: Only addmin can set new address!");
        ADMIN_ADDRESS = _newAdminAddress;
    }


    /**
     * Returns the complete metadata URI for the given tokenId.
     */
    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // OVERRIDING ERC-721 IMPLEMENTATION TO ALLOW OPENSEA ROYALTIES ENFORCEMENT PROTOCOL

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

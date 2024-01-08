// SPDX-License-Identifier: MIT
// Smart Contract Written by: imnotFuzzyHat <Ian Olson>

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./RoyaltiesV2.sol";

contract Dot is Ownable, ERC721Enumerable, RoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---
    uint256 constant public royaltyFeeBps = 1000; // 10%
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;

    // ---
    // Properties
    // ---
    uint256 public nextTokenId = 0;
    string private contractUri;
    address public payoutAddress;

    // ---
    // Mappings
    // ---
    mapping(address => bool) private isAdmin;
    mapping(uint256 => string) private metadataByTokenId;

    // ---
    // Security
    // ---

    modifier onlyValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token ID does not exist.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins.");
        _;
    }

    // ---
    // Constructor
    // ---
    constructor() ERC721("dot", "dot") {
        isAdmin[msg.sender] = true;
        payoutAddress = msg.sender;
        contractUri = "ipfs://QmQXsHZXKN5SKfdE2oTUL9BRkWtCpsB4bCR9fgQL2nzZ6N";

        // Initial Mints
        mintToken("ipfs://QmUfpKFdmcJCyop6TSWqQDUCGfTCqW8Rom5fwKEKYqWaeq"); // Token 0
        mintToken("ipfs://QmSYqy7DcU4CGo1gMrvkdmrHrQqzywBuzqgJyCdFybb31r"); // Token 1
        mintToken("ipfs://QmT8DJKGyTMnpLMmAaL6i92Cav2naRxNbiXyyujdJKaQXc"); // Token 2
        mintToken("ipfs://QmaEWr6xsbYSU2FfoDmpfHkvtNw741BCLMtmErf8R85XSw"); // Token 3
        mintToken("ipfs://QmNocN1JLzLvMvkj4yrP6xNxBn2MCYabRau77nuC8jwfSD"); // Token 4
        mintToken("ipfs://QmXDUgpBAxE4GsiLeXcDLwvQ82uBYnbsaL3RaK43UEHjye"); // Token 5
    }

    // ---
    // Supported Interfaces
    // ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---

    function mintToken(string memory metadataUri) public onlyAdmin returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);
        _mint(msg.sender, tokenId);
        metadataByTokenId[tokenId] = metadataUri;
    }

    // ---
    // Burning
    // ---

    function burn(uint256 tokenId) public virtual onlyAdmin {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only approved or token owners can burn.");
        _burn(tokenId);
    }

    // ---
    // Update Functions
    // ---

    function addAdmin(address adminAddress) public onlyAdmin {
        isAdmin[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) public onlyAdmin {
        require((msg.sender != adminAddress), "Cannot remove self.");

        isAdmin[adminAddress] = false;
    }

    function updateContractUri(string memory updatedContractUri) public onlyAdmin {
        contractUri = updatedContractUri;
    }

    function updatePayoutAddress(address newPayoutAddress) public onlyAdmin {
        payoutAddress = newPayoutAddress;
    }

    function updateTokenMetadata(uint256 tokenId, string memory metadataUri) public onlyAdmin onlyValidTokenId(tokenId) {
        metadataByTokenId[tokenId] = metadataUri;
    }

    // ---
    // Contract Retrieve Functions
    // ---

    function tokenURI(uint256 tokenId) public view override virtual onlyValidTokenId(tokenId) returns (string memory) {
        return metadataByTokenId[tokenId];
    }

    function contractURI() public view virtual returns (string memory) {
        return contractUri;
    }

    function getTokensOfOwner(address walletAddress) public view returns (uint256[] memory tokenIds) {
        uint256 tokenCount = balanceOf(walletAddress);

        if (tokenCount == 0) {
            tokenIds = new uint256[](0);
        } else {
            tokenIds = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                tokenIds[index] = tokenOfOwnerByIndex(walletAddress, index);
            }
        }

        return tokenIds;
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    /* Rarible Royalties V2 */
    function getRaribleV2Royalties(uint256 id) external view override onlyValidTokenId(id) returns (LibPart.Part[] memory) {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account: payable(payoutAddress),
            value: uint96(royaltyFeeBps)
        });

        return royalties;
    }

    /* EIP-2981 */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payoutAddress, fivePercent);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Strings.sol";

import "./ERC721A.sol";

import "./IDoodleRooms.sol";

contract DoodleRooms3DModels is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;
    DoodleRooms public doodleRooms;

    string private baseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;

    bool private isOpenSeaProxyActive = true;
    bool public isClaimActive;

    bytes32 public firstPhaseMerkleRoot;
    bool public isFirstPhaseActive;

    mapping(uint256 => bool) public claimedTokenIds;

    modifier claimActive() {
        require(isClaimActive, "Claim is not active");
        _;
    }

    modifier canClaim3DModels(address addr, uint256 [] calldata tokenIds) {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(doodleRooms.ownerOf(tokenIds[i]) == addr, "Can only claim owned doodle rooms");
            require(!tokenIdIsClaimed(tokenIds[i]), "Token id has already been claimed");
        }
        _;
    }

    event Claim3DModels(
        uint256 indexed from,
        uint256 indexed to,
        uint256 [] indexed tokenIds
    );

    constructor(
        address _openSeaProxyRegistryAddress
    ) ERC721A("Doodle Rooms 3D", "DR3D") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;

        doodleRooms = DoodleRooms(0x5426C860C9e660145Ad09d3FB26427e5Fd4569E9);

        isClaimActive = true;

        baseURI = "ipfs://QmY21ADFwGyftNkxuE21VayMPrArU8ArwJuK7jH3jPae2t";
    }

    function claim3DModels(uint256 [] calldata tokenIds)
    external
    nonReentrant
    claimActive
    canClaim3DModels(msg.sender, tokenIds)
    {
        uint256 ts = totalSupply();

        for (uint i = 0; i < tokenIds.length; i++) {
            claimedTokenIds[tokenIds[i]] = true;
        }

        _safeMint(msg.sender, tokenIds.length);

        emit Claim3DModels(ts, ts + tokenIds.length, tokenIds);
    }

    function getClaimableTokenIds(address addr) public view returns (uint256 [] memory) {
        uint256 balance = doodleRooms.balanceOf(addr);
        uint256 [] memory allTokenIds = new uint256[](balance);
        uint256 claimableBalance = 0;

        for (uint i = 0; i < balance; i++) {
            uint256 _id = doodleRooms.tokenOfOwnerByIndex(addr, i);

            if (!claimedTokenIds[_id]) {
                allTokenIds[i] = _id;
            }
        }

        return allTokenIds;
    }

    function tokenIdIsClaimed(uint256 tokenId) public view returns (bool) {
        return claimedTokenIds[tokenId];
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setVerificationHash(string memory _verificationHash)
    external
    onlyOwner
    {
        verificationHash = _verificationHash;
    }

    function setIsClaimActive(bool _isClaimActive)
    external
    onlyOwner
    {
        isClaimActive = _isClaimActive;
    }

    function setDoodleRoomsContract(address _addr) external onlyOwner {
        require(_addr != address(0));

        doodleRooms = DoodleRooms(_addr);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString()))
        : '';
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), (salePrice * 7) / 100);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


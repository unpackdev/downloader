// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface iSaburokuFujiArt {

    function mintWithSingleMetadataCid(
        address to,
        string memory singleMetadataCid
    ) external;

    function batchMintWithDirectoryCid(
        address[] memory toList,
        string memory directoryCidContainsMetadataJsons
    ) external;

    function mintNFTWithBlockNumbers(
        address to,
        string memory directoryCidContainsMetadataJsons,
        uint256[] memory tokenRevealBlockNumbers
    ) external;
}

contract SaburokuFujiArt is iSaburokuFujiArt, ERC721Burnable, Ownable, AccessControlEnumerable {

    enum NFTType {Default, Simple, Batch, HasBlocknumbers}

    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public nextTokenId;
    uint256 private nextBatchCidIndex;
    string private baseURI;
    mapping(uint256 => string) private cidMap;
    mapping(uint256 => uint256[]) private tokenRevealBlockNumbersMap;
    mapping(uint256 => string) batchCidMap;
    mapping(uint256 => uint256) batchCidIndexMap;
    mapping(uint256 => uint256) jsonIndexMap;
    mapping(uint256 => NFTType) nftTypeMap;

    constructor (
        string memory initialBaseURI,
        address owner,
        address minter
    )
    ERC721("36FUJI Art", "36FUJI")
    {
        baseURI = initialBaseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(MINTER_ROLE, minter);
        transferOwnership(owner);
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role to mint");
        _;
    }

    modifier nonEmptyCid(string memory cid) {
        require(keccak256(abi.encodePacked(cid)) != keccak256(abi.encodePacked("")), "empty string");
        _;
    }

    function mintWithSingleMetadataCid(
        address to,
        string memory singleMetadataCid
    ) external override onlyMinter nonEmptyCid(singleMetadataCid) {
        cidMap[nextTokenId] = singleMetadataCid;
        nftTypeMap[nextTokenId] = NFTType.Simple;

        _safeMint(to, nextTokenId++);
    }

    function batchMintWithDirectoryCid(
        address[] memory toList,
        string memory directoryCidContainsMetadataJsons
    ) external override onlyMinter nonEmptyCid(directoryCidContainsMetadataJsons) {
        uint256 batchCidIndex = nextBatchCidIndex++;
        batchCidMap[batchCidIndex] = directoryCidContainsMetadataJsons;

        for (uint256 i = 0; i < toList.length; i++) {
            batchCidIndexMap[nextTokenId] = batchCidIndex;
            nftTypeMap[nextTokenId] = NFTType.Batch;
            jsonIndexMap[nextTokenId] = i;
            _safeMint(toList[i], nextTokenId++);
        }
    }

    function mintNFTWithBlockNumbers(
        address to,
        string memory directoryCidContainsMetadataJsons,
        uint256[] memory tokenRevealBlockNumbers
    ) external override onlyMinter nonEmptyCid(directoryCidContainsMetadataJsons) {
        nftTypeMap[nextTokenId] = NFTType.HasBlocknumbers;
        cidMap[nextTokenId] = directoryCidContainsMetadataJsons;
        tokenRevealBlockNumbersMap[nextTokenId] = tokenRevealBlockNumbers;

        _safeMint(to, nextTokenId++);
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        if (nftTypeMap[tokenId] == NFTType.Simple) {
            return _simpleTokenURI(tokenId);
        }
        if (nftTypeMap[tokenId] == NFTType.Batch) {
            return _batchTokenURI(tokenId);
        }
        if (nftTypeMap[tokenId] == NFTType.HasBlocknumbers) {
            return _tokenURIWithBlocknumbers(tokenId);
        }

        revert("ERC721Metadata: URI query for nonexistent token");
    }

    function _simpleTokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory metadataCid = cidMap[tokenId];

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, metadataCid))
        : '';
    }

    function _batchTokenURI(uint256 tokenId) internal view returns (string memory) {
        uint256 batchCidIndex = batchCidIndexMap[tokenId];
        string memory directoryCid = batchCidMap[batchCidIndex];
        uint256 jsonIndex = jsonIndexMap[tokenId];

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, directoryCid, "/", jsonIndex.toString(), ".json"))
        : '';
    }

    function _tokenURIWithBlocknumbers(uint256 tokenId) internal view returns (string memory) {
        string memory directoryCid = cidMap[tokenId];
        uint256 jsonIndex = 0;
        uint256[] memory tokenRevealBlockNumbers = tokenRevealBlockNumbersMap[tokenId];

        for (uint256 i = 0; i < tokenRevealBlockNumbers.length; i++) {
            if (block.number < tokenRevealBlockNumbers[i]) {
                break;
            }
            jsonIndex++;
        }

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, directoryCid, "/", jsonIndex.toString(), ".json"))
        : '';
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721)
    returns (bool)
    {
        return
        AccessControlEnumerable.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId);
    }

}

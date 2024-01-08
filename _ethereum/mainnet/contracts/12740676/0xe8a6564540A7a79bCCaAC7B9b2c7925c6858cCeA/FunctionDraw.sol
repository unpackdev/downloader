//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./RaribleERC721.sol";

contract FunctionDraw is RaribleERC721 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private nextTokenId;
    string private baseURI;
    mapping(uint256 => string) private tokenURISuffixes;

    constructor (
        address signer,
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory initialBaseURI,
        address payable[] memory commonRoyaltyAddresses,
        uint256[] memory commonRoyaltiesWithTwoDecimals
    )
    RaribleERC721(
        signer,
        name,
        symbol,
        contractURI,
        commonRoyaltyAddresses,
        commonRoyaltiesWithTwoDecimals
    )
    {
        baseURI = initialBaseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role to mint");
        _;
    }

    function mint(
        address to,
        string memory metadataCid,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external onlyMinter {
        _setRoyaltiesOf(nextTokenId, _royaltyAddresses, _royaltiesWithTwoDecimals);
        tokenURISuffixes[nextTokenId] = metadataCid;

        _mint(to, nextTokenId++);
    }

    function batchMint(
        address to,
        string[] memory metadataCidList,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external onlyMinter {
        for (uint256 i = 0; i < metadataCidList.length; i++) {
            _setRoyaltiesOf(nextTokenId, _royaltyAddresses, _royaltiesWithTwoDecimals);
            tokenURISuffixes[nextTokenId] = metadataCidList[i];

            _mint(to, nextTokenId++);
        }
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenURISuffixes[tokenId]))
        : '';
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(RaribleERC721)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}


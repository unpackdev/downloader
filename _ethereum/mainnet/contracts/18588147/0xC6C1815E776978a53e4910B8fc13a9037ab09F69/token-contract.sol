// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721.sol";
import "./Ownable2Step.sol";
import "./Strings.sol";
import "./RoyaltyOverrideCore.sol";

interface IConduitController {
    function getKey(address conduit) external view returns (bytes32);
}

contract EmpropsTokenContract is
    ERC721,
    Ownable2Step,
    EIP2981RoyaltyOverrideCore
{
    address[] private _seaports = [0x00000000006c3852cbEf3e08E8dF289169EdE581];
    address[] private _conduitControllers = [
        0x00000000F9490004C11Cef243f5400493c00Ad63
    ];

    bool public enableBlockOpenSea = true;
    uint256 public _mintCount;
    string public baseTokenURI;
    address public minter;
    uint64 public maxSupply;
    mapping(uint256 => string) public dm;

    struct LockTokenMetadata {
        uint256 tokenId;
        string metadataLink;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint64 newMaxSupply
    ) ERC721(name, symbol) {
        maxSupply = newMaxSupply;
    }

    function _requireNotOpenSea(address to) internal view {
        if (enableBlockOpenSea) {
            for (uint256 i = 0; i < _seaports.length; ) {
                // Check spender isn't Seaport.
                require(to != _seaports[i], "OPENSEA NOT ALLOWED");

                unchecked {
                    ++i;
                }
            }

            for (uint256 i = 0; i < _conduitControllers.length; ) {
                // Check spender isn't a conduit.
                // First we call the controller for the corresponding key:
                // - if(success) -> the address is a valid conduit
                // - else        -> the address isn't a conduit
                (bool success, ) = _conduitControllers[i].staticcall(
                    abi.encodeWithSelector(
                        IConduitController.getKey.selector,
                        to
                    )
                );
                require(!success, "OPENSEA NOT ALLOWED");

                unchecked {
                    ++i;
                }
            }
        }
    }

    // OVERRIDES
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        if (bytes(dm[tokenId]).length != 0) {
            return dm[tokenId];
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        _requireNotOpenSea(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _requireNotOpenSea(operator);
        super.setApprovalForAll(operator, approved);
    }

    // MESSAGES
    function setOpenSeaports(address[] calldata addresses) external onlyOwner {
        _seaports = addresses;
    }

    function setCoduitControllers(
        address[] calldata addresses
    ) external onlyOwner {
        _conduitControllers = addresses;
    }

    function setBlockOpenSea(bool blockOpenSea) external onlyOwner {
        enableBlockOpenSea = blockOpenSea;
    }

    function lockMetadata(
        uint256 tokenId,
        string memory metadataLink
    ) external {
        require(
            _ownerOf(tokenId) == msg.sender,
            "ERC721: sender is not the owner"
        );
        dm[tokenId] = metadataLink;
    }

    function batchLockMetadata(LockTokenMetadata[] calldata tokens) external {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = tokens[i].tokenId;
            require(
                _ownerOf(tokenId) == msg.sender,
                "ERC721: sender is not the owner"
            );
            dm[tokenId] = tokens[i].metadataLink;

            unchecked {
                ++i;
            }
        }
    }

    function updateMaxSupply(uint64 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setBaseTokenURI(string memory newBaseUri) external onlyOwner {
        baseTokenURI = newBaseUri;
    }

    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    function mint(
        address owner,
        uint256 tokenId,
        address author,
        uint16 bps
    ) external {
        require(msg.sender == minter, "Sender not minter");
        require(_mintCount < maxSupply, "Max supply exceeded");
        _safeMint(owner, tokenId);

        // Increment counter
        _mintCount = _mintCount + 1;

        // Set royalties
        TokenRoyaltyConfig[] memory royaltyConfigs = new TokenRoyaltyConfig[](
            1
        );
        royaltyConfigs[0] = TokenRoyaltyConfig(tokenId, author, bps);
        _setTokenRoyalties(royaltyConfigs);
    }

    // ROYALTIES
    function setTokenRoyalties(
        TokenRoyaltyConfig[] calldata royaltyConfigs
    ) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(
        TokenRoyalty calldata royalty
    ) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    // Queries
    function getTokensOf(
        address _owner,
        uint256 _collectionId,
        uint256 _maxSupply
    ) public view returns (uint256[] memory) {
        uint256 m = 1e6;

        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);

        uint256 ownerTokenIdx = 0;
        uint256 maxTokenAvailable = (_collectionId * m) + _maxSupply;
        for (
            uint256 tokenIdx = _collectionId * m;
            tokenIdx <= maxTokenAvailable;

        ) {
            if (_ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                unchecked {
                    ++ownerTokenIdx;
                }
            }

            unchecked {
                ++tokenIdx;
            }
        }
        return ownerTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";

interface ERC721Interface {
  function ownerOf(uint256 _tokenId) external view returns (address);
}

contract TenKTF is ERC721PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    mapping(uint256 => address) internal contractAddresses;

    // Given a release ID (itemId | parentContractId), return the base
    // metadata hash so we can construct metadata URIs like
    // ipfs://someHash/0, ipfs://someHash/1, etc.
    mapping (uint256 => string) internal baseURIs;

    // Given a release ID (itemId | parentContractId), return the
    // price to mint an item from this release
    mapping (uint256 => uint256) internal prices;

    // Given a release ID (itemId | parentContractId), return whether
    // a price has been set for this release
    mapping (uint256 => bool) internal pricesSet;

    // Given a release ID (itemId | parentContractId), return the timestamp
    // when minting is closed.
    mapping (uint256 => uint256) internal mintingClosedAt;

    event OwnerOf(uint32);

    function initialize()
        external initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721Pausable_init();
        __AccessControlEnumerable_init();
        __ERC721_init("10KTF", "10KTF");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public view virtual override(AccessControlEnumerableUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721Upgradeable).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function setContractAddress(
        uint16 index,
        address contractAddress
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractAddresses[index] = contractAddress;
    }

    function getBaseURI(uint256 tokenId)
        public view virtual
        returns (string memory)
    {
        uint256 releaseId = (tokenId & 0xFFFFFFFF00000000) >> 32;

        return baseURIs[releaseId];
    }

    function setBaseURI(
        uint32 releaseId,
        string memory baseURI
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURIs[releaseId] = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public view virtual override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = getBaseURI(tokenId);
        uint256 parentTokenId = tokenId & 0xFFFFFFFF;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, parentTokenId.toString())) : "";
    }

    function version()
        external pure virtual
        returns (string memory)
    {
        return "1.0.0";
    }

    function ownsParentToken(
        uint32 parentTokenId,
        uint16 parentContractIndex
    )
        public virtual
        returns (bool)
    {
        ERC721Interface ContractInstance = ERC721Interface(contractAddresses[parentContractIndex]);

        emit OwnerOf(parentTokenId);

        return (msg.sender == ContractInstance.ownerOf((parentTokenId)));
    }

    function mintToken(
        uint256 tokenId
    )
        public virtual payable nonReentrant
    {
        uint32 releaseId = uint32((tokenId & 0xFFFFFFFF00000000) >> 32);

        require(tokenId >= 0, "Invalid token ID");
        require(pricesSet[releaseId] == true, "Price has not been set for this release");
        require(msg.value >= getPrice(releaseId), "Insufficient eth sent");
        require(_exists(tokenId) == false, "Token has already been minted");

        uint256 closedAt = mintingClosedAt[releaseId];
        require(closedAt > 0, "Minting has not started yet");
        require(block.timestamp <= closedAt, "Minting has closed, sorry!");

        uint32 parentTokenId = uint32(tokenId & 0xFFFFFFFF);
        uint16 parentContractIndex = uint16((tokenId & 0xFFFF00000000) >> 32);

        require(ownsParentToken(parentTokenId, parentContractIndex) == true, "You can only mint if you own the original NFT");

        _safeMint(msg.sender, tokenId);
    }

    function withdraw()
        public onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getPrice(uint32 releaseId)
        public view virtual
        returns (uint256)
    {
        require(pricesSet[releaseId] == true, "Price has not been set for this release");

        return prices[releaseId];
    }

    function setPrice(
        uint32 releaseId,
        uint256 price
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricesSet[releaseId] = true;
        prices[releaseId] = price;
    }

    function getMintingClosedAt(uint32 releaseId)
        public view virtual
        returns (uint256)
    {
        return mintingClosedAt[releaseId];
    }

    function setMintingClosedAt(
        uint32 releaseId,
        uint256 timestamp
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintingClosedAt[releaseId] = timestamp;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}
}

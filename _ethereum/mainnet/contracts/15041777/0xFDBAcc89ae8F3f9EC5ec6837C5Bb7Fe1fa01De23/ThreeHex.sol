/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./Ownable.sol";
import "./NameEncoder.sol";
import "./BytesUtils.sol";

// https://docs.ens.domains/contract-developer-guide/resolving-names-on-chain
abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}

// Interface for swappable renderer
interface Renderer {
    function render(uint256 tokenId, string calldata baseURI)
        external
        view
        returns (string memory);
}

contract ThreeHex is ERC721, Ownable {
    using Strings for uint256;
    using BytesUtils for uint256;
    using NameEncoder for string;

    event EndTimeUpdated(uint64 indexed endTime);

    // ENS address is same across Rinkeby and mainnet
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    string public baseURI;
    string constant ethSuffix = ".eth";
    uint64 endTime;
    Renderer public renderer;

    constructor(
        string memory _baseURI,
        uint64 _endTime,
        address _renderer
    ) ERC721("3HEX", "3HEX") {
        baseURI = _baseURI;
        endTime = _endTime;
        renderer = Renderer(_renderer);
    }

    /// Updates the endTime for the public mint
    /// baseURI ends with a "/" for the IPFS folder to load properly.
    /// @param _endTime Unix time for the mint to end
    function updateEndTime(uint64 _endTime) public onlyOwner {
        endTime = _endTime;
        emit EndTimeUpdated(_endTime);
    }

    /// Updates the baseURI for a particular evolution. Ensure
    /// baseURI ends with a "/" for the IPFS folder to load properly.
    /// @param _baseURI The new baseURI for the NFT
    function updateBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// Update the renderer contract responsible for resolving tokenURI
    /// @param _renderer address of the renderer contract
    function updateRenderer(address _renderer) public onlyOwner {
        renderer = Renderer(_renderer);
    }

    /// Public mint method to mint one or more NFTs. Each tokenId
    /// must be between 0 and 4095, inclusive. For each tokenId,
    /// you must be the holder of the associated ENS name to mint.
    /// For example, to mint tokenId 18 you must own ENS "012.eth".
    /// @param tokenIds TokenIds to mint
    function mint(uint256[] calldata tokenIds) public {
        require(block.timestamp <= endTime, "endTime passed");
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            mintToken(tokenIds[i]);
        }
    }

    /// Owner of contract can mint unclaimed tokens once endTime
    /// has passed. Owner is not subject to ENS checks.
    /// @param tokenIds TokenIds to mint
    function ownerMint(uint256[] calldata tokenIds) public onlyOwner {
        require(block.timestamp > endTime, "owner can't mint before endTime");

        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            require(tokenIds[i] < 4096, "invalid tokenId");
            _mint(msg.sender, tokenIds[i]);
        }
    }

    function mintToken(uint256 tokenId) internal {
        // There are 16^3 (4096) valid rgb colors for the format
        // #rgb using hex characters.
        // 0    => #000
        //    ...
        // 4095 => #fff
        require(tokenId < 4096, "invalid tokenId");
        // To prevent typo-squatting we generate the valid ENS
        // name based on the tokenId, ex: aaa.eth
        string memory ensName = string.concat(
            tokenId.toHexString3(),
            ethSuffix
        );
        // Generate the hash of the ensName
        (, bytes32 namehash) = ensName.dnsEncodeName();
        // Retrieve the resolver of the namehash
        Resolver resolver = ens.resolver(namehash);
        // msg.sender must own the ens name
        require(
            resolver.addr(namehash) == msg.sender,
            "caller does not own ENS name"
        );
        _mint(msg.sender, tokenId);
    }

    /// @param tokenId The tokenID to retrieve the URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return renderer.render(tokenId, baseURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./IPFS.sol";
import "./IL2MintableNFT.sol";


/**
 * @title CoverCharts
 */
contract CoverCharts is ERC721Tradable, IL2MintableNFT
{
    event MintFromL2(
        address owner,
        uint256 id,
        uint    amount,
        address minter
    );

    event NameChanged(
        uint256 id,
        string  name
    );

    address public immutable layer2Address;

    // Per token name, settable by the token owner
    mapping(uint256 => string) public tokenNames;

    modifier onlyFromLayer2
    {
        require(msg.sender == layer2Address, "not authorized");
        _;
    }

    constructor(
        address _openseaProxyRegistryAddress,
        address _layer2Address
        )
        ERC721Tradable(_openseaProxyRegistryAddress)
    {
        layer2Address = _layer2Address;
    }

    function initialize()
         initializer
         external
    {
        _initialize("Cover Charts", "CCH");
    }

    // Standard NFT

    function safeMint(
        address to,
        uint256 tokenId
        )
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
    }

    function baseTokenURI()
        public
        pure
        returns(string memory)
    {
        return "ipfs://";
    }

    function tokenURI(uint256 _tokenId)
        override
        public
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                baseTokenURI(),
                IPFS.encode(_tokenId),
                "/metadata.json"
            )
        );
    }

    // Naming

    function changeTokenName(
        uint256        tokenId,
        string  memory name
        )
        public
    {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "not the owner");
        require(keccak256(bytes(name)) != keccak256(bytes(tokenNames[tokenId])), "new name is the same as the current one");

        tokenNames[tokenId] = name;

        emit NameChanged(tokenId, name);
    }

    // Layer 2 logic

    function mintFromL2(
        address          to,
        uint256          id,
        uint             amount,
        address          minter,
        bytes   calldata /*data*/
        )
        external
        override
        onlyFromLayer2
    {
        require(minter == owner(), "invalid minter");
        require(amount == 1, "invalid amount");

        _mint(to, id);
        emit MintFromL2(to, id, amount, minter);
    }

    function minters()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory addresses = new address[](1);
        addresses[0] = owner();
        return addresses;
    }
}

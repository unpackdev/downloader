//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Strings.sol";

import "./ERC721Ownable.sol";
import "./IERC2981Royalties.sol";

/// @title Astraglade
/// @author Simon Fremaux (@dievardump)
contract Astraglade is IERC2981Royalties, ERC721Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    struct MintingOrder {
        address to;
        uint256 expiration;
        string jsonPart;
    }

    uint256 public nextTokenId;

    address public mintSigner;

    uint256 constant MAX_SUPPLY = 11111;

    uint256 constant PRICE = 0.0888 ether;

    mapping(uint256 => string) internal tokenGeneratedString;
    mapping(bytes32 => uint256) public messageToTokenId;

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param mintSigner_ Address of the wallet used to sign minting orders
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address mintSigner_,
        address owner_
    )
        ERC721Ownable(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        )
    {
        mintSigner = mintSigner_;
    }

    /// @notice Mint one token using a minting order
    /// @dev mintingSignature must be a signature that matches `mintSigner` for `mintingOrder`
    /// @param mintingOrder the minting order
    /// @param mintingSignature signature for the mintingOrder
    function mint(
        MintingOrder memory mintingOrder,
        bytes memory mintingSignature
    ) external payable {
        bytes32 message = hashMintingOrder(mintingOrder)
        .toEthSignedMessageHash();

        require(
            message.recover(mintingSignature) == mintSigner,
            'Wrong minting order signature.'
        );

        require(
            mintingOrder.expiration >= block.timestamp,
            'Minting order expired.'
        );

        require(
            mintingOrder.to == _msgSender(),
            'Minting order for another address.'
        );

        require(messageToTokenId[message] == 0, 'Token already minted.');

        uint256 tokenId = nextTokenId + 1;

        require(tokenId <= MAX_SUPPLY, 'Max supply already reached.');

        require(msg.value == PRICE, 'Incorrect value.');

        messageToTokenId[message] = tokenId;

        _safeMint(mintingOrder.to, tokenId, '');

        tokenGeneratedString[tokenId] = mintingOrder.jsonPart;

        nextTokenId = tokenId;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981Royalties).interfaceId;
    }

    /// @notice Helper to get the price
    /// @return the price to mint
    function getPrice() external pure returns (uint256) {
        return PRICE;
    }

    /// @notice tokenURI override that returns a data:json application
    /// @inheritdoc	ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        string memory astraType;
        if (tokenId <= 10) {
            astraType = 'Universa';
        } else if (tokenId <= 100) {
            astraType = 'Galactica';
        } else if (tokenId <= 1000) {
            astraType = 'Nebula';
        } else if (tokenId <= 3000) {
            astraType = 'Meteora';
        } else if (tokenId <= 10000) {
            astraType = 'Solaris';
        } else if (tokenId <= 11110) {
            astraType = 'Supernova';
        } else {
            astraType = 'Quanta';
        }

        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Astraglade - ',
                    tokenId.toString(),
                    ' - ',
                    astraType,
                    '","license":"CC BY-SA 4.0","description":"Astraglade is an interactive, generative, 3D collectible experiment. Astraglades are collected through a unique social collection mechanism. Each version of Astraglade can be signed with a signature which will remain in the artwork forever.","created_by":"Fabin Rasheed","twitter":"@astraglade",',
                    tokenGeneratedString[tokenId],
                    '}'
                )
            );
    }

    /// @notice Hash the Minting Order so it can be signed by the signer
    /// @param mintingOrder the minting order
    /// @return the hash to sign
    function hashMintingOrder(MintingOrder memory mintingOrder)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(mintingOrder));
    }

    /// @notice Helper for the owner to change current minting signer
    /// @dev needs to be owner
    /// @param mintSigner_ new signer
    function setMintingSigner(address mintSigner_) public onlyOwner {
        require(mintSigner_ != address(0), 'Signer address required');
        mintSigner = mintSigner_;
    }

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        uint256 balance_ = address(this).balance;
        payable(address(0xe4657aF058E3f844919c3ee713DF09c3F2949447)).transfer(
            (balance_ * 30) / 100
        );
        payable(address(0xb275E5aa8011eA32506a91449B190213224aEc1e)).transfer(
            (balance_ * 35) / 100
        );
        payable(address(0xdAC81C3642b520584eD0E743729F238D1c350E62)).transfer(
            address(this).balance
        );
    }

    /// @notice 10% royalties going to this contract
    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (value * 1000) / 10000;
    }

    /// @notice Helpers that returns the MintingOrder plus the message to sign
    /// @param to the address of the creator
    /// @param jsonPart the json to mint
    /// @return mintingOrder and message to hash
    function createMintingOrder(address to, string memory jsonPart)
        external
        view
        returns (MintingOrder memory mintingOrder, bytes32 message)
    {
        mintingOrder = MintingOrder({
            to: to,
            expiration: block.timestamp + 15 * 60,
            jsonPart: jsonPart
        });

        message = hashMintingOrder(mintingOrder);
    }

    /// @notice returns a tokenId from an mintingOrder, used to know if already minted
    /// @param mintingOrder the minting order to check
    /// @return an integer. 0 if not minted, else the tokenId
    function tokenIdFromOrder(MintingOrder memory mintingOrder)
        external
        view
        returns (uint256)
    {
        bytes32 message = hashMintingOrder(mintingOrder)
        .toEthSignedMessageHash();
        return messageToTokenId[message];
    }
}

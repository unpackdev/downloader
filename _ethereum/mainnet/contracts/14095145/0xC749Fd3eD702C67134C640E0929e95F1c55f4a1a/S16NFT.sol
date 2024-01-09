// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./ERC165Storage.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract S16NFT is
    ERC1155Supply,
    AccessControl,
    ERC165Storage,
    ERC2981ContractWideRoyalties
{
    using Strings for uint256;

    string public constant name = "S16NFT";
    string public constant symbol = "S16NFT";
    uint256 public constant totalSupply = 4000;

    string _baseTokenURI = "https://s16nft.io/";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 internal tokenCap = 160;
    uint256 internal editionCap = 25;

    uint256 public royaltyValue = 60000000000000000; // Royalty 6% in eth decimals
    address public royaltyRecipient = 0xAED9A27255a3a177B88E7baa0065B214A5e3786A; // Royalty Recipient Main wallet (OpenSea) 

    //mapping from tokenID to editions
    mapping(uint256 => uint256) public mintedEditionsToken;
    //mapping from tokenID to bool value (true means editions fully minted & false means edition not fully minted)
    mapping(uint256 => bool) public isNFTMinted;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155(_baseTokenURI) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /// @dev Sets the royalty value and recipient
    /// @notice Only admin can call the function
    /// @param recipient The new recipient for the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "");
        _setRoyalties(recipient, value);
        require(
            recipient != 0x0000000000000000000000000000000000000000,
            "S16NFT: Royalty recipient address cannot be Zero Address"
        );
        require(value > 0, "S16NFT: invalid royalty percentage");
        royaltyRecipient = recipient;
        royaltyValue = value;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, ERC165Storage, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNewBaseURI(string memory baseURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        _setURI(baseURI);
    }

    function cap() external view returns (uint256) {
        return tokenCap;
    }

    function getEditionCap() external view returns (uint256) {
        return editionCap;
    }

    function getmintedEditionsToken(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return mintedEditionsToken[_tokenId];
    }

    function isMinted(uint256 _tokenId) external view returns (bool) {
        return isNFTMinted[_tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId > 0 && tokenId <= tokenCap, "S16NFT: token not exist");
        string memory currentBaseURI = super.uri(tokenId);

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function mintEditionsUser(
        address _to,
        uint256[] memory tokenIds,
        uint256[] memory quantity
    ) external returns (bool) {
        //this check will ensure only the S16Distributor contract can call this function
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(_to != address(0), "S16NFT: mint to the zero address");
        require(
            tokenIds.length == quantity.length,
            "S16NFT: tokenIds length must be equal to quantity"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                isNFTMinted[tokenIds[i]] == false,
                "S16NFT: one or more token already minted"
            );
            require(tokenIds[i] <= tokenCap, "S16NFT: token cap reached");
            require(quantity[i] > 0, "S16NFT: quantity 0 not allowed");
            require(
                quantity[i] + mintedEditionsToken[tokenIds[i]] <= editionCap,
                "S16NFT: quantity exceed limit"
            );

            mintedEditionsToken[tokenIds[i]] += quantity[i];

            if (mintedEditionsToken[tokenIds[i]] == editionCap) {
                isNFTMinted[tokenIds[i]] = true;
            }
        }
        _mintBatch(_to, tokenIds, quantity, "");

        return true;
    }

    function updateIdsEdition(
        uint256[] memory tokenIds,
        uint256[] memory quantity
    ) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "S16NFT: Caller is not a minter"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintedEditionsToken[tokenIds[i]] += quantity[i];
            if (mintedEditionsToken[tokenIds[i]] == editionCap) {
                isNFTMinted[tokenIds[i]] = true;
            }
        }
    }

    function claimNfts(
        address _to,
        uint256[] memory tokenIds,
        uint256[] memory quantity
    ) external returns (bool) {
        //this check will ensure only the S16Distributor contract can call this function
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(_to != address(0), "S16NFT: minting to zero address");
        require(
            tokenIds.length == quantity.length,
            "S16NFT: tokenIds and quantity length mismatch"
        );

        _mintBatch(_to, tokenIds, quantity, "");

        return true;
    }

    function totalEditionMinted() external view returns (uint256) {
        uint256 totalEditionMint;
        for (uint256 i = 0; i <= tokenCap; i++) {
            totalEditionMint = totalEditionMint + mintedEditionsToken[i];
        }
        return totalEditionMint;
    }
}

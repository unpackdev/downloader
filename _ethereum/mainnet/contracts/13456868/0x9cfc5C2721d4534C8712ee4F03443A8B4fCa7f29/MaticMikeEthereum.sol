// contracts/MaticMikeDummy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IMintableERC721.sol";

contract MaticMikeEthereum is
    ERC721,
    AccessControlMixin,
    NativeMetaTransaction,
    IMintableERC721,
    ContextMixin,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Ethereum contract uses API to pull from Polygon (ensure if we do a surprise upgrade it pulls)
    // Still 100% on chain on Polygon, this is the necessary hybrid system we need to have live feed
    // from Polygon to Ethereum.
    string _baseTokenURI;
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    address _owner;
    address _proxy;
    
    mapping(uint256 => string) tokenToMetadata;
    constructor()
        public
        ERC721("Matic Mike Ethereum Bridge", "MIKE")
    {
        _owner = msg.sender;
        _proxy = 0x932532aA4c0174b8453839A6E44eE09Cc615F2b7;

        _setupContractId("MikeMintableERC721");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712("Matic Mike Ethereum Bridge");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IMintableERC721-mint}.
     */
    function mint(address user, uint256 tokenId) external override only(PREDICATE_ROLE) {
        _tokenIds.increment();
        _mint(user, tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method, to be invoked
     * when minting token back on L1, during exit
     */
    function setTokenMetadata(uint256 tokenId, bytes memory data) internal virtual {
        string memory uri = abi.decode(data, (string));

        tokenToMetadata[tokenId] = uri;
    }

    // total circulating supply not including 
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current() - balanceOf(_proxy);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Returns the URI and metadata to pull from Polygon Chain
     * @param _tokenId The tokenId to pull from Polygon Chain
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));
        return string(
                abi.encodePacked(_baseTokenURI, toString(_tokenId))
            );
    }

    /**
     * @dev See {IMintableERC721-mint}.
     * 
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method
     */
    function mint(address user, uint256 tokenId, bytes calldata metaData) external override only(PREDICATE_ROLE) {
        _tokenIds.increment();
        _mint(user, tokenId);

        setTokenMetadata(tokenId, metaData);
    }


    /**
     * @dev See {IMintableERC721-exists}.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }
}
pragma solidity >=0.6.2 <0.8.0;
import "./ERC1155.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract FantasyNFT1155 is ERC1155, Ownable {
    event Mint(address indexed sender, address indexed to, uint256 tokenId, uint256 amount);

    address private _owner;
    string private _name;
    string private _symbol;

    mapping(uint256 => string) _tokenURIs;

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        string memory uri
    ) public ERC1155(uri) {
        _transferOwnership(owner);
        _name = name;
        _symbol = symbol;
    }

    function mint1155(
        address to,
        uint256 tokenId,
        string memory uri,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        address signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(address(this), tokenId))),
            v,
            r,
            s
        );
        require(signer == owner(), 'ECDSA: invalid signature');
        require(signer != address(0), 'ECDSA: invalid signature');

        // require(!_exists(tokenId), 'KIP37: nonexistent token');
        _mint(to, tokenId, value, '');
        _tokenURIs[tokenId] = uri;

        emit Mint(msg.sender, to, tokenId, value);
        return true;
    }
}

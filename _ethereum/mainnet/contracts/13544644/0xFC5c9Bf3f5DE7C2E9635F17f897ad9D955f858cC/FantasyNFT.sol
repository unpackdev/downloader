pragma solidity >=0.6.2 <0.8.0;
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract FantasyNFT is ERC721, Ownable {
    event Mint(address indexed sender, address indexed to, uint256 tokenId);

    constructor(
        address owner,
        string memory name,
        string memory symbol
    ) public ERC721(name, symbol) {
        _transferOwnership(owner);
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory uri,
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

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit Mint(msg.sender, to, tokenId);
        return true;
    }
}

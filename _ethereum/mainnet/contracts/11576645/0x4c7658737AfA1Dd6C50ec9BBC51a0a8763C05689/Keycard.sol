pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Keycard is ERC721Tradable {
    mapping(uint256 => string) public sizeToMetadata;

    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("Vaunker Keycard", "VKC", _proxyRegistryAddress)
    {
        _setBaseURI("https://ipfs.infura.io/ipfs/QmYaDvd7jMMrKNhs5nHqSZ56FMawaVydh7aETJ2dFjDjZi/");
        sizeToMetadata[0] = "small.json"; // S
        sizeToMetadata[1] = "medium.json"; // M
        sizeToMetadata[2] = "large.json"; // L
        sizeToMetadata[3] = "xlarge.json"; // XL
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintSizeTo(address _to, uint256 _size) public onlyOwner {
        require(_size >= 0 && _size <= 3, "Size not valid");

        uint256 newTokenId = mintTo(_to);
        _setTokenURI(newTokenId, sizeToMetadata[_size]);
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.infura.io/ipfs/QmReVvQuXB9JwpTV2miy1ZkeGxpcA21RNiRcoD5eAGipoK";
    }
}

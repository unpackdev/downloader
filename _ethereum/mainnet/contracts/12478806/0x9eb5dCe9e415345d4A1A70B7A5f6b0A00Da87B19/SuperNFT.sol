pragma solidity ^0.6.2;

// REMIX
// import "./ERC721.sol";
// import "./ERC20.sol";
// import "./Counters.sol";
// import "./EnumerableSet.sol";
// import "./SafeMath.sol";
// import "./Address.sol";

// TRUFFLE
import "./ERC721.sol";
import "./ERC20.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Address.sol";

// SuperNFT SMART CONTRACT
contract SuperNFT is ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;

    /**
     * Mint + Issue NFT
     *
     * @param recipient - NFT will be issued to recipient
     * @param hash - Artwork IPFS hash
     * @param data - Artwork URI/Data
     */
    function issueToken(
        address recipient,
        string memory hash,
        string memory data
    ) public returns (uint256) {
        require(hashes[hash] != 1);
        hashes[hash] = 1;
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, data);
        return newTokenId;
    }

    constructor() public ERC721("SUPER NFT", "SNFT") {}
}

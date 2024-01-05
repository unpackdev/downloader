pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract NFT is Ownable, ERC721 {
    using SafeMath for uint256;

    uint256 public constant tokenIdMultiplier = 100000000;
    mapping(uint256 => uint256) public seriesMinted;
    mapping(uint256 => string) public uriMap;
    address public redeemContract;

    constructor(
        string memory name,
        string memory symbol,
        string[] memory uriArray
    ) Ownable() ERC721(name, symbol) {
        for (uint256 i = 0; i < uriArray.length; i++) {
            uriMap[i] = uriArray[i];
        }
    }

    function initializeRedeemContract(address redeemContract_)
        public
        onlyOwner
    {
        require(redeemContract == address(0x0), "ALREADY_INITIALIZED");
        redeemContract = redeemContract_;
    }

    // Combine the series ID and the token's position into a single token ID.
    // For example, if the series ID is `0` and the token position is `23`,
    // generate `100000023`.
    function encodeTokenId(uint256 seriesId, uint256 tokenPosition)
        public
        pure
        returns (uint256)
    {
        return (seriesId + 1) * tokenIdMultiplier + tokenPosition;
    }

    // Extract the series ID from the tokenID. For example, `100000010` returns
    // `0`.
    function extractSeriesId(uint256 tokenId) public pure returns (uint256) {
        return
            ((tokenId - (tokenId % tokenIdMultiplier)) / tokenIdMultiplier) - 1;
    }

    function mint(address recipient, uint256 seriesId) public {
        require(msg.sender == redeemContract, "NOT_REDEEM_CONTRACT");
        uint256 tokenPosition = seriesMinted[seriesId].add(1);
        require(tokenPosition < tokenIdMultiplier, "TOKEN_POSITION_TOO_LARGE");
        uint256 tokenID = encodeTokenId(seriesId, tokenPosition);

        seriesMinted[seriesId] = tokenPosition;

        return _safeMint(recipient, tokenID);
    }

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

        uint256 seriesId = extractSeriesId(tokenId);

        return uriMap[seriesId];
    }

    // Return a list of tokens owned by the passed-in address.
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = ERC721.balanceOf(owner);

        uint256[] memory tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }
}

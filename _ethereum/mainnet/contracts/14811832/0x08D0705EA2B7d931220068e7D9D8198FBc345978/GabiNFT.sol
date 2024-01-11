// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract GabiNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool reserved;
    address public minter;
    uint256 currentTokenId;
    uint256 maxTotalSupply = 131;
    string private _baseURIExtended;
    mapping(uint256 => string) _tokenURIs;

    constructor() ERC721("GabiNFT", "GABI") {}

    modifier onlyMinter() {
        require(msg.sender == minter, "caller is not the minter");
        _;
    }

    event Minted(uint256 indexed tokenId, address receiver);

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        uint256 mintedTokenId;
        for (uint256 i = 0; i < receivers.length; i++) {
            mintedTokenId = currentTokenId;
            currentTokenId += 1;
            _mint(receivers[i], mintedTokenId);
            emit Minted(mintedTokenId, receivers[i]);
        }
    }

    function mint(address receiver)
        external
        onlyMinter
        nonReentrant
        returns (uint256 mintedTokenId)
    {
        require(totalSupply() + 1 <= maxTotalSupply);
        mintedTokenId = currentTokenId;
        currentTokenId += 1;
        _mint(receiver, mintedTokenId);
        emit Minted(mintedTokenId, receiver);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI_;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length != 0) {
            return _tokenURI;
        }

        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
}

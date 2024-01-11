//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721A.sol";
import "./INFT.sol";

contract NFT is INFT, ERC721A, Ownable {
    uint256 constant OVERALL = 10000;
    uint256 maxSupply = 2000;
    uint256 public maxRevealedId;
    // Base URI
    string public notRevealedURI;
    address public minter;

    // ERC721A
    uint256 constant maxBatchSize_ = 10;
    uint256 constant collectionSize_ = 1;

    constructor(string memory _initNotRevealedUri)
        ERC721A("PiXiu Club", "PiXiu", maxBatchSize_, collectionSize_)
    {
        notRevealedURI = _initNotRevealedUri;
    }

    function getOverall() external pure override returns (uint256) {
        return OVERALL;
    }

    function getMaxSupply() external view override returns (uint256) {
        return maxSupply;
    }

    function setMaxSupply(uint256 amount) external override onlyOwner {
        require(amount >= totalSupply(), "Less than already mint");
        require(amount <= OVERALL, "Overall supply exceeded");
        emit SetMaxSupply(maxSupply, amount);

        maxSupply = amount;
    }

    // ====== Minter ======
    function setMinter(address minter_) external override onlyOwner {
        require(minter_ != address(0), "Invalid minter");
        minter = minter_;
        emit SetMinter(minter_);
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Only minter");
        _;
    }

    function setNotRevealedURI(string memory notRevealedURI_)
        external
        override
        onlyOwner
    {
        notRevealedURI = notRevealedURI_;
    }

    function mint(address to, uint256 quantity) external override onlyMinter {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");

        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata uri) external override onlyOwner {
        _baseURI = uri;
    }

    function reveal(uint256 tokenId) external override onlyOwner {
        maxRevealedId = tokenId;
        emit Revealed(totalSupply(), tokenId);
    }

    function _isRevealed(uint256 tokenId) private view returns (bool) {
        return tokenId <= maxRevealedId;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!_isRevealed(tokenId)) {
            return notRevealedURI;
        }

        if (bytes(_baseURI).length == 0) {
            return notRevealedURI;
        }

        return super.tokenURI(tokenId);
    }

    function burn(uint256 tokenId) external {
        transferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            tokenId
        );
    }
}

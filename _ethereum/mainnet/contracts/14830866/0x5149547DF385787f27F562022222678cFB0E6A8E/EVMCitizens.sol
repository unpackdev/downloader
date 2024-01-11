// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract EVMCitizens is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public price = 0.001 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 50;
    uint256 public totalFree = 1767;
    uint256 public maxSupply = 6767;
    uint256 public nextOwnerToExplicitlySet;
    bool public mintEnabled;

    constructor() ERC721A("EVM Citizens", "EVM CITIZENS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function freedomMint(uint256 amt) external callerIsUser {
        require(mintEnabled, "Mint is not enabled");
        require(totalSupply() + amt <= totalFree, "Reached max free supply");
        require(amt <= 10, "You're trying to mint too many.");
        require(
            numberMinted(msg.sender) + amt <= maxPerWallet,
            "You got too many in your wallet already."
        );
        _safeMint(msg.sender, amt);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        require(msg.sender == tx.origin, "Be you.");
        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSupply + 1, "All out of cardboard...");
        require(mintEnabled, "Mint not enabled");
        require(
            amt < maxPerTx + 1,
            "Amount requested exceeds transaction limit."
        );

        _safeMint(msg.sender, amt);
    }

    function ownerBatchMint(uint256 amt) external onlyOwner {
        require(totalSupply() + amt < maxSupply + 1, "too many!");

        _safeMint(msg.sender, amt);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setTotalFree(uint256 totalFree_) external onlyOwner {
        totalFree = totalFree_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function _getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        require(quantity != 0, "quantity must be nonzero");
        require(_currentIndex != 0, "no tokens minted yet");
        uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
        require(
            _nextOwnerToExplicitlySet < _currentIndex,
            "all ownerships have been set"
        );

        // Index underflow is impossible.
        // Counter or index overflow is incredibly unrealistic.
        unchecked {
            uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

            // Set the end index to be the last token index
            if (endIndex + 1 > _currentIndex) {
                endIndex = _currentIndex - 1;
            }

            for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
                if (_ownerships[i].addr == address(0)) {
                    TokenOwnership memory ownership = _ownershipOf(i);
                    _ownerships[i].addr = ownership.addr;
                    _ownerships[i].startTimestamp = ownership.startTimestamp;
                }
            }

            nextOwnerToExplicitlySet = endIndex + 1;
        }
    }
}

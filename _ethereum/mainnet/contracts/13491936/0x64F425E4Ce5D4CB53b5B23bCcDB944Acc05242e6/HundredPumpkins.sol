// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract HundredPumpkins is ERC721Enumerable, IERC2981, Ownable, Pausable {
    uint256 public mintedCount = 0;
    uint256 public constant totalPossibleSupply = 100;

    uint256 public constant price = 50000000000000000; // 0.05Ξ

    string public baseUri = "https://100pumpkins.io/api/metadata/";
    mapping(address => bool) public accountsThatMinted;

    event Minted(address indexed sender, uint256 mintedId);

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return baseUri;
    }

    function mint() public payable whenNotPaused {
        require(accountsThatMinted[msg.sender] == false, "already minted");
        uint256 newlyMintedId = mintedCount + 1; // IDs are 1-based
        require(newlyMintedId <= totalPossibleSupply, "total supply reached");
        require(msg.value == price, "wrong price");
        payable(owner()).transfer(msg.value);
        emit Minted(_msgSender(), newlyMintedId);

        accountsThatMinted[msg.sender] = true;
        mintedCount = newlyMintedId;
        _safeMint(_msgSender(), mintedCount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        // NOTE: ERC-2981 is token-agnostic so sale unit should be considered
        // with care due to Solidity rounding rules. Prefer using wei (10^18).
        // Owner takes a fixed 5% cut of every sale, regardless of the token ID.
        return (owner(), (salePrice * 500) / 10000);
    }
}

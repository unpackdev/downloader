// SPDX-License-Identifier: MIT
/// @title: Secret Agent Men
/// @author: DropHero LLC
pragma solidity ^0.8.9;

import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./IERC2981.sol";
import "./Counters.sol";

contract SecretAgentMen is ERC721Burnable, AccessControlEnumerable, ERC721Pausable, IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint24 basisPoints;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_MANAGER_ROLE = keccak256("ROYALTY_MANAGER_ROLE");
    uint16 public MAX_TOKEN_ID = 20_000;
    uint16 public MAX_SUPPLY = 10_000;

    // We often update these two fields together. Using uint16 allows us to
    // take advantage of the gas savings from tight data packing
    uint16 private _totalSupply = 0;
    uint16 private _lastId = 0;

    uint16 private _reservedCount = 0;
    string private _baseURIValue;
    RoyaltyInfo private _royalties;

    constructor(string memory baseURI_) ERC721("Secret Agent Men", "SAM") {
        _baseURIValue = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _royalties.recipient = msg.sender;
        _royalties.basisPoints = 800;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIValue = newBase;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function mintTokens(uint16 numberOfTokens, address to) external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        require(
            numberOfTokens > 0, "MINIMUM_MINT_OF_ONE"
        );
        require(
            _totalSupply + numberOfTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED"
        );

        uint256 lastId = _lastId;
        uint256 maxId = lastId + numberOfTokens;

        require(
            _lastId + numberOfTokens <= MAX_TOKEN_ID, "MAX_TOKENS_EXCEEDED"
        );

        // This is essentially a for() loop but is optimizing for gas use
        // by memoizing the maxId field to prevent the ADD operation on each iteration
        while (lastId < maxId) {
            _safeMint(to, ++lastId);
        }

        _lastId += numberOfTokens;
        _totalSupply += numberOfTokens;
    }

    function setRoyaltiesPercentage(uint24 basisPoints) external onlyRole(ROYALTY_MANAGER_ROLE) {
        require(basisPoints <= 10000, 'BASIS_POINTS_TOO_HIGH');
        _royalties.basisPoints = basisPoints;
    }

    function setRoyaltiesAddress(address addr) external onlyRole(ROYALTY_MANAGER_ROLE) {
        _royalties.recipient = addr;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (salePrice * royalties.basisPoints) / 10000;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        if (to == address(0)) {
            _totalSupply -= 1;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

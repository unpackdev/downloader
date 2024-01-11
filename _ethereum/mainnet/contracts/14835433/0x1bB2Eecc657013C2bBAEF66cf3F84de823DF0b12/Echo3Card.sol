// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.11;
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract Echo3Card is ERC721, ERC721Enumerable, AccessControl, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant AUTH_MINTER = keccak256("AUTH_MINTER");
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // Royalty standart
    uint96 private constant royaltyBasisPoints = 569; // 5.69%
    string private baseURI;
    address payable public royaltyReceiver;
    Counters.Counter tokenTracker;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _URI,
        address payable _royaltyReceiver
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AUTH_MINTER, msg.sender);
        royaltyReceiver = _royaltyReceiver;
        baseURI = _URI;
    }

    function mint(address to) external onlyRole(AUTH_MINTER) {
        _mint(to, tokenTracker.current());
        tokenTracker.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Echo3: non-existent token");
        return _baseURI();
    }

    function updateURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Echo3: non-existent token");
        return
            royaltyBasisPoints > 0
                ? (royaltyReceiver, (_salePrice * royaltyBasisPoints) / 10000)
                : (address(0), uint256(0));
    }

    function updateRoyalty(address payable _royaltyReceiver)
        external
        onlyOwner
    {
        royaltyReceiver = _royaltyReceiver;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.11;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract DickManiac is
    Context,
    AccessControlEnumerable,
    ERC721,
    ERC721Enumerable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // Royalty standart
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ENLARGEMENT_ROLE = keccak256("ENLARGEMENT_ROLE");
    uint256 public constant MAX_SIZE = 5;

    string private baseURI;
    string private unrevealedURI;
    bool public revealed;

    string public DMSS_PROVENANCE;

    // tokenId -> size
    mapping(uint256 => uint256) sizeChart;

    // owner => claimContingent
    mapping(address => uint256) public pcEligible;
    uint256 public pcCount;
    uint256 public pcDeadline = 0;

    Counters.Counter tokenTracker;

    uint96 private royaltyBasisPoints;
    address payable private royaltyReceiver;

    event DickIncreasedInSize(uint256 tokenId, uint256 newSize);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _unrevealedURI,
        address payable _royaltyReceiver,
        uint96 _royaltyBasisPoints
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        unrevealedURI = _unrevealedURI;
        revealed = false;

        _updateRoyalty(_royaltyReceiver, _royaltyBasisPoints);
    }

    function mint(address to) external onlyRole(MINTER_ROLE) {
        sizeChart[tokenTracker.current()] = 1;
        _mint(to, tokenTracker.current());
        tokenTracker.increment();
    }

    function grow(uint256 tokenId) external onlyRole(ENLARGEMENT_ROLE) {
        require(_exists(tokenId), "DM: non-existing token Id");
        require(sizeChart[tokenId] < MAX_SIZE, "DM: max size");
        sizeChart[tokenId] = sizeChart[tokenId] + 1;

        emit DickIncreasedInSize(tokenId, sizeChart[tokenId]);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "DM: non-existent token");

        if (!revealed) {
            return unrevealedURI;
        } else {
            string memory base = _baseURI();
            string memory fileType = ".json";

            return
                bytes(base).length > 0
                    ? string(
                        abi.encodePacked(
                            base,
                            sizeChart[tokenId].toString(),
                            "/",
                            tokenId.toString(),
                            fileType
                        )
                    )
                    : "";
        }
    }

    function updateURI(
        string calldata _newBaseURI,
        string calldata _newUnrevealedURI,
        bool _revealed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        unrevealedURI = _newUnrevealedURI;
        revealed = _revealed;
    }

    function getSize(uint256 tokenId) public view returns (uint256) {
        require(tokenId < tokenTracker.current(), "DM: non-existent token");
        return sizeChart[tokenId];
    }

    function getCurrentTokenTracker()
        external
        view
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        return tokenTracker.current();
    }

    function setProvenanceHash(string calldata _prov)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        DMSS_PROVENANCE = _prov;
    }

    function updateRoyalty(
        address payable _royaltyReceiver,
        uint96 _royaltyBasisPoints // 1000 = 10%
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateRoyalty(_royaltyReceiver, _royaltyBasisPoints);
    }

    function getRaribleV2Royalties(uint256 _tokenId)
        external
        view
        returns (LibPart.Part[] memory)
    {
        require(_exists(_tokenId), "DM: non-existing token");
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].account = royaltyReceiver;
        _royalties[0].value = royaltyBasisPoints;
        return _royalties;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "DM: non-existing token");
        return
            royaltyBasisPoints > 0
                ? (royaltyReceiver, (_salePrice * royaltyBasisPoints) / 10000)
                : (address(0), uint256(0));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
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

    function setPcDeadline(uint256 _deadline)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pcDeadline = _deadline;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (block.timestamp < pcDeadline) {
            _updatePcEligible(from, to);
        }
    }

    function _updatePcEligible(address _from, address _to) private {
        uint256 fromBeforeTransfer = pcEligible[_from];
        uint256 toBeforeTransfer = pcEligible[_to];
        if (_from != address(0)) {
            pcEligible[_from] = (balanceOf(_from) - 1) / 2;
        }
        if (_to != address(0)) {
            pcEligible[_to] = (balanceOf(_to) + 1) / 2;
        }
        pcCount = pcCount - fromBeforeTransfer + pcEligible[_from];
        pcCount = pcCount - toBeforeTransfer + pcEligible[_to];
    }

    function _updateRoyalty(
        address payable _royaltyReceiver,
        uint96 _royaltyBasisPoints // 1000 = 10%
    ) internal {
        require(_royaltyBasisPoints <= 1000, "DM: UR");
        royaltyReceiver = _royaltyReceiver;
        royaltyBasisPoints = _royaltyBasisPoints;
    }
}

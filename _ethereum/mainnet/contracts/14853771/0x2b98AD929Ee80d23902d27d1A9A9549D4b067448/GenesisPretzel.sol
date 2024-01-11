// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";

contract GenesisPretzel is ERC721A, Ownable {
    using Strings for uint256;

    bool public revealed = false;
    bool public forSale = false;
    uint256 public metadataOffset;
    uint256 public constant PRICE_PER_MINT = 0.1 ether;

    string private metadataCID;
    string private unrevealedCID =
        'bafkreifgoa2jam7kryumpkmqeaatx7e5nz6cwoj3a5huvxhcfl4zx46vhy';
    uint256 public constant MAX_SUPPLY = 30;

    constructor() ERC721A('GenesisPretzel', 'GPRZL') {}

    function mint(uint256 quantity) external payable {
        require(forSale, 'Genesis Pretzels are not for sale right now.');
        require(
            _totalMinted() + quantity <= MAX_SUPPLY,
            'Trying to mint too many tokens.'
        );
        require(
            msg.value >= quantity * PRICE_PER_MINT,
            'Not enough ether send to complete purchase.'
        );
        _safeMint(msg.sender, quantity);
    }

    function toggleSale() external onlyOwner {
        forSale = !forSale;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked('ipfs://', metadataCID, '/'));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!revealed) {
            return string(abi.encodePacked('ipfs://', unrevealedCID));
        }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    tokenToMetadataId(tokenId).toString()
                )
            );
    }

    function tokenToMetadataId(uint256 tokenId) public view returns (uint256) {
        require(revealed, 'Metadata must be revealed first.');
        unchecked {
            return ((tokenId + metadataOffset) % MAX_SUPPLY);
        }
    }

    function reveal() external onlyOwner {
        require(!revealed, 'Can only reveal once.');
        revealed = true;
        metadataOffset = getRandomOffset();
    }

    function setMetadataCID(string memory _metadataCID) external onlyOwner {
        require(!revealed, 'Can only change the metadata if not yet revealed.');
        metadataCID = _metadataCID;
    }

    function setUnrevealedCID(string memory _unrevealedCID) external onlyOwner {
        unrevealedCID = _unrevealedCID;
    }

    function getRandomOffset() private view returns (uint256) {
        require(
            tx.origin == msg.sender,
            'Contracts are not allowed to reveal.'
        );

        uint256 randomWord = uint256(
            keccak256(
                abi.encode(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    _totalMinted()
                )
            )
        );
        return randomWord % MAX_SUPPLY;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

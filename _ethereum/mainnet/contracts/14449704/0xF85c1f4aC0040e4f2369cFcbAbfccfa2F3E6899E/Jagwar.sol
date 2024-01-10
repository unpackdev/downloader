// SPDX-License-Identifier: MIT

/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░▒█████████▓░░░░░░░░░▓███████▒▒░░░░░░░░░░░
░░░░░░░░░░▓██▓▓▓▓▓█████▒░░░░░▒█████▓▓▓▓██▒░░░░░░░░░░
░░░░░░░░░█▓▒░░░░░░░█████▒░░░▒████▓░░░░░░░▓█░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░███▒░░░░▒████░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░███▓░░░░░░░███▒░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░████▒░░░░░░░░░▒██▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░▓███████▒░░░░░░▒███████▓▒░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░▒▓▓█████▒░░░▓█████▓▓░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░█████▒░▒████▓░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░████▓░▒███▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░████▒░▒███▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░███▒░░░▒███░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓███▓▓▓▓▓▓▓▓██▒░░░░░░░▓██▓▓▓▓▓▓▓▓▓▓░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Jagwar Twin x CTHDRL
Contract: Jagwar Twin - 33 [Album]
Website: https://jagwartwin.com
**/

pragma solidity ^0.8.11;

import "./Strings.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Jagwar is Ownable, ERC721 {
    using Counters for Counters.Counter;

    event EditionCreated(uint256 editionId);
    event EditionMetadataUpdated(uint256 editionId, string metadata);
    event EditionPriceUpdated(uint256 editionId, uint256 price);

    struct Edition {
        string metadata;
        uint256 price;
        // the total number of tokens that can be minted for this edition
        uint256 size;
        // the number of tokens currently minted for this edition (<= size)
        Counters.Counter counter;
    }

    struct Token {
        uint256 editionId;
        // the value of the edition counter when this token was minted
        uint256 number;
    }

    Counters.Counter private editionIds;
    Counters.Counter private tokenIds;

    mapping(uint256 => Edition) public editions;
    mapping(uint256 => Token) public tokens;

    bool frozen = false;

    // EIP-721
    // https://eips.ethereum.org/EIPS/eip-721

    constructor() ERC721("Jagwar Twin - 33 [Album]", "JT33") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        Token storage _token = tokens[_tokenId];
        Edition storage _edition = editions[_token.editionId];

        // edition metadata is the base URI for the edition
        string memory _editionMetadata = _edition.metadata;

        string memory _number = Strings.toString(_token.number);

        return
            string(abi.encodePacked(_editionMetadata, "/", _number, ".json"));
    }

    // EIP-2981
    // https://eips.ethereum.org/EIPS/eip-2981

    function royaltyInfo(
        uint256, /*tokenId*/
        uint256 _price
    ) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = _price / 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // custom

    function createEdition(string memory _metadata, uint256 _size)
        public
        onlyOwner
        returns (uint256)
    {
        require(!frozen, "Frozen");

        editionIds.increment();
        uint256 _editionId = editionIds.current();

        editions[_editionId] = Edition(
            _metadata,
            0,
            _size,
            Counters.Counter(0)
        );
        emit EditionCreated(_editionId);

        return _editionId;
    }

    function setEditionMetadata(uint256 _editionId, string memory _metadata)
        public
        onlyOwner
    {
        require(!frozen, "Frozen");

        editions[_editionId].metadata = _metadata;
        emit EditionMetadataUpdated(_editionId, _metadata);
    }

    function setEditionPrice(uint256 _editionId, uint256 _price)
        public
        onlyOwner
    {
        require(!frozen, "Frozen");

        editions[_editionId].price = _price;
        emit EditionPriceUpdated(_editionId, _price);
    }

    function freeze() public onlyOwner {
        frozen = true;
    }

    function purchase(uint256 _editionId) external payable returns (uint256) {
        Edition storage _edition = editions[_editionId];

        require(_edition.price > 0, "Not for sale");
        require(_edition.counter.current() < _edition.size, "Sold out");
        require(msg.value == _edition.price, "Wrong amount");

        payable(owner()).transfer(msg.value);

        tokenIds.increment();
        uint256 _tokenId = tokenIds.current();
        _edition.counter.increment();
        tokens[_tokenId] = Token(_editionId, _edition.counter.current());

        _mint(msg.sender, _tokenId);

        return _tokenId;
    }
}

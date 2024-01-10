// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// We first import some OpenZeppelin Contracts.
import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./IOffscriptNFT.sol";

import "./console.sol";

contract OffscriptNFT is ERC721, Ownable, IOffscriptNFT {
    //
    // Events
    //

    /// Emitted when the base URI changes
    event BaseURIUpdated(string newBaseURI);

    //
    // Constants
    //

    string public constant description =
        // solhint-disable-next-line max-line-length
        "Offscript Crowdseed NFT. Owned by early supporters of Offscript - An offsite for creatives in Web3. Owners of this NFT, get a discount during ticket sale";
    string public constant externalUrl = "https://offscript.web3creatives.com/";

    string[] publicNames = [
        "Bearberry",
        "Bean",
        "California bay",
        "Bay laurel",
        "Bay",
        "Baobab",
        "Banana",
        "Bamboo",
        "Carolina azolla",
        "Azolla",
        "Water ash",
        "White ash",
        "Swamp ash",
        "River ash",
        "Red ash",
        "Maple ash",
        "Green ash",
        "Cane ash",
        "Blue ash",
        "Black ash",
        "Ash",
        "Indian arrowwood",
        "Arrowwood",
        "Arizona sycamore",
        "Arfaj",
        "Apricot",
        "Apple of Sodom",
        "Apple",
        "Amy root",
        "Tall ambrosia",
        "Almond",
        "White alder",
        "Striped alder",
        "Alnus incana",
        "Speckled alder",
        "Gray alder",
        "False alder",
        "Common alder",
        "Black alder",
        "Alder"
    ];

    //
    // State
    //

    // token => metadata
    mapping(uint256 => Metadata) metadata;

    /// Base URI for all NFTs
    string public baseURI;

    //Supplies
    uint8 public immutable totalPublicSupply;
    uint8 public immutable totalPrivateSupply;
    uint8 public remainingPublicSupply;
    uint8 public remainingPrivateSupply;
    uint8 public nextPrivateID;

    uint8[] public discounts;
    uint8[] public availablePerTrait;

    /// Admin address
    address public admin;

    uint256 public price;

    //
    // Constructor
    //

    // We need to pass the name of our NFTs token and its symbol.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint8 _remainingPublicSupply,
        uint8 _remainingPrivateSupply,
        uint8[] memory _discounts,
        uint8[] memory _availablePerTrait,
        uint256 _price
    ) ERC721(_name, _symbol) Ownable() {
        require(
            publicNames.length == _remainingPublicSupply,
            "different amount of names"
        );

        baseURI = _baseURI;

        totalPublicSupply = _remainingPublicSupply;
        totalPrivateSupply = _remainingPrivateSupply;
        remainingPublicSupply = _remainingPublicSupply;
        remainingPrivateSupply = _remainingPrivateSupply;
        nextPrivateID = totalPublicSupply + 1;

        discounts = _discounts;
        availablePerTrait = _availablePerTrait;

        price = _price;

        emit BaseURIUpdated(_baseURI);
    }

    function getMetadata(uint256 tokenId)
        external
        view
        override(IOffscriptNFT)
        returns (uint8 discount, string memory name)
    {
        Metadata memory meta = metadata[tokenId];

        return (meta.discount, meta.name);
    }

    //
    // ERC721
    //

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        Metadata memory meta = metadata[tokenId];

        bytes memory metadata = abi.encodePacked(
            '{"description": "',
            description,
            '",',
            '"name": "',
            meta.name,
            '",',
            '"external_url": "',
            externalUrl,
            '",',
            '"attributes": {"discount": ',
            Strings.toString(meta.discount),
            ',"name": "',
            meta.name,
            '"}, "image": "',
            baseURI,
            Strings.toString(tokenId),
            '.png"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    //
    // Public API
    //

    /**
     * Updates the base URI
     *
     * @notice Only callable by an authorized operator
     *
     * @param _newBaseURI new base URI for the token
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;

        emit BaseURIUpdated(_newBaseURI);
    }

    // A function our user will hit to get their NFT.
    function mintPublic() public payable {
        require(msg.value >= price, "Not enough");
        require(remainingPublicSupply > 0, "Depleted");

        // IDs from from #1 to #totalPublicSupply
        uint256 newItemId = uint256(
            totalPublicSupply - remainingPublicSupply + 1
        );

        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        tx.origin,
                        block.difficulty,
                        block.timestamp
                    )
                )
            )
        );

        uint8 discount = calculateDiscount(random);
        string memory name = publicNames[publicNames.length - 1];

        _mintWithMetadata(msg.sender, newItemId, discount, name);
        publicNames.pop();
        remainingPublicSupply--;
    }

    function mintPrivate(
        address[] calldata _addresses,
        uint8[] calldata _discounts,
        string[] calldata _names
    ) external onlyOwner {
        uint8 length = uint8(_addresses.length);

        require(length == _discounts.length, "Arrays size must be the same");
        require(_addresses.length > 0, "Array must be greater than 0");
        require(remainingPrivateSupply >= length, "Not enough supply");

        uint256 nextId = uint256(
            totalPrivateSupply + totalPublicSupply - remainingPrivateSupply + 1
        );

        remainingPrivateSupply -= length;

        for (uint8 i = 0; i < length; i++) {
            _mintWithMetadata(
                _addresses[i],
                nextId + i,
                _discounts[i],
                _names[i]
            );
        }
    }

    //
    // Internal API
    //

    function _mintWithMetadata(
        address _owner,
        uint256 _id,
        uint8 _discount,
        string memory _name
    ) internal {
        metadata[_id] = Metadata(_discount, _name);
        _safeMint(_owner, _id);
    }

    function calculateDiscount(uint8 _random)
        internal
        returns (uint8 discount)
    {
        _random %= remainingPublicSupply;

        uint8 i = 0;
        uint8 length = uint8(availablePerTrait.length);
        while (i < length) {
            uint8 available = availablePerTrait[i];
            if (_random < available) {
                availablePerTrait[i]--;
                return discounts[i];
            } else {
                _random -= available;
            }
            i++;
        }
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    //Override functions
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function sweep() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

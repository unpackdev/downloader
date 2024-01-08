// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./ERC165Storage.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";

/**
 *  Claves Angelicae is a procedural system to inscribe a magical Word onto
 *  the Ethereum network where it is exalted as a sigil.
 *
 *  https://clavesangelicae.com
 */
contract ClavesAngelicae is Context, ERC721, Ownable, IERC2981, ERC165Storage {

    event Mint(
        uint256 indexed tokenId,
        string spell,
        address to
    );

    uint256 public MAX_SUPPLY = 777;
    uint256 public PRICE = 0.333 * 10 ** 18;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256[30] private _reservedIds = [
        1,   2,   3,   7,   11,  12,  13,  14,
        17,  19,  21,  23,  27,  29,  31,  37,
        41,  47,  67,  71,  83,  93,  111, 222,
        333, 418, 444, 555, 666, 777
    ];

    mapping(uint256 => bool) private _reservedIdsMap;
    mapping(uint256 => string) public tokenIdToSpell;

    string private _baseTokenURI;

    // secondary market royalties
    address private _donationAddress = 0x7cF2eBb5Ca55A8bd671A020F8BDbAF07f60F26C1; // give well
    uint256 private _donationPercent = 1;

    // Bytes4 Code for ERC interfaces
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


    /**
     * @dev ClavesAngelicae
     * @param name_ - Token Name
     * @param symbol_ - Token Symbol
     * @param baseURI_ - Base uri for metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721 (name_, symbol_) {
        _baseTokenURI = baseURI_;

        // register the supported ERC interfaces
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC2981);

        // map reserved ids
        for (uint256 i = 0; i < _reservedIds.length; i++) {
            _reservedIdsMap[_reservedIds[i]] = true;
        }

        // start counter at 1
        _tokenIds.increment();
    }


    /**
     * @dev (OnlyOwner) Mint a reserved sigil token from the reserved sigil ids
     * @param spell_ - the spell string
     * @param tokenId_ - the desired tokenId
     * @param to_ - the receiving address
     */
    function mintReserved(string memory spell_, uint256 tokenId_, address to_) public onlyOwner {
        require(!_exists(tokenId_), "ERC721: Token ID already minted");
        require(_reservedIdsMap[tokenId_], "ERC721: Token ID not reserved");
        _mintSpell(spell_, tokenId_, to_);
    }


    /**
     * @dev Mint a sigil token
     * @param spell_ - the spell string
     */
    function mint(string memory spell_) public payable {
        require(msg.value >= PRICE, "Must pay for minting");
        uint256 tokenId;
        while (true) {
            tokenId = _tokenIds.current();
            if (_reservedIdsMap[tokenId] || _exists(tokenId)) {
                _tokenIds.increment();
                require(_tokenIds.current() <= MAX_SUPPLY, "Token Supply Depleted");
            } else {
                break;
            }
        }
        (bool success, ) = owner().call{ value: msg.value }("");
        require(success, "Transfer Failed");
        _mintSpell(spell_, tokenId, _msgSender());
    }


    /**
     * @dev Verify the spell is /[a-z0-9]{10}/
     * @param str_ - the spell string
     * @return bool - if the spell is valid or not
     */
    function verifySpell(string memory str_) public pure returns (bool) {
        bytes memory b = bytes(str_);
        uint256 len = b.length;
        if (len != 10) { // {10}
            return false;
        }
        for (uint256 i; i < len; i++) {
            bytes1 c = b[i];
            if(!(c >= 0x61 && c <= 0x7A) && // [a-z]
               !(c >= 0x30 && c <= 0x39)) { // [0-9]
                return false;
            }
        }
        return true;
    }


    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId_ - the NFT asset queried for royalty information
     * @param salePrice_ - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return donationAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 donationAmount
    ) {
        require(_exists(tokenId_), "ERC721: Nonexistent Token ID");
        receiver = _donationAddress;
        donationAmount = salePrice_ * _donationPercent / 100;
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, IERC165, ERC165Storage
    ) returns (
        bool
    )    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
     * @dev Set donation address
     * @param to_ - donation address
     */
    function setDonationAddress(address to_) public onlyOwner {
        _donationAddress = to_;
    }


    /**
     * @dev Set donation percentage
     * @param percent_ - donation percentage 1-100
     */
    function setDonationPercent(uint256 percent_) public onlyOwner {
        _donationPercent = percent_;
    }


    /**
     * @dev set baseTokenURI
     */
    function setBaseTokenURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }


    /**
     * @dev Get total token supply
     * @return _tokenID.current() - the current position of the _tokenIDs counter
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }


    /**
     * @dev Mint token, emits a Mint event
     * @param spell_ - the spell string
     * @param tokenId_ - the tokenId
     * @param to_ - the receiving address
     */
    function _mintSpell(string memory spell_, uint256 tokenId_, address to_) private {
        require(verifySpell(spell_), "Spell must be /[a-z0-9]{10}/");
        tokenIdToSpell[tokenId_] = spell_;
        _safeMint(to_, tokenId_);
        emit Mint(tokenId_, spell_, to_);
    }


    /**
     * @dev Get baseTokenURI
     * @return _baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}


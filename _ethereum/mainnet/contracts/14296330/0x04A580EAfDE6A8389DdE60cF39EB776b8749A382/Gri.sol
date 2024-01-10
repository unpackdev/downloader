// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./ERC2981.sol";

pragma solidity ^0.8.12;
pragma abicoder v2;

//    ____      _                 _              _
//   / ___|_ __(_)_ __ ___  _   _| |_ __ _ _ __ | |_ ___
//  | |  _| '__| | '_ ` _ \| | | | __/ _` | '_ \| __/ __|
//  | |_| | |  | | | | | | | |_| | || (_| | | | | |_\__ \
//   \____|_|  |_|_| |_| |_|\__,_|\__\__,_|_| |_|\__|___/
//
contract Grimutants is ERC721Enumerable, ERC2981, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Strings for uint256;

    enum Sale {
        NoSale,
        PublicSale
    }

    uint256 public constant tokenPrice = 80000000000000000; // 0.08
    uint256 public constant MAX_TOKENS = 3333;
    uint256 public maxTokenPurchase = 12;

    string public baseURI = "";

    Sale public state = Sale.NoSale;

    event GGCMinted(uint256 balance, address owner);

    string public contractURI =
        "https://ipfs.io/ipfs/QmXzTCRDiyj4D8ApmJLYibk8YAtH142gFBfS9WEV5SD7zx";

    uint256[] private _teamShares = [84, 16];

    address[] private _team = [
        0x507F6bAB2d99a084ff4532AC2312A20a42a42910,
        0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9
    ];

    bytes32 private presaleRoot;

    constructor()
        ERC721("Grimutants", "GGC")
        PaymentSplitter(_team, _teamShares)
    {
        _setDefaultRoyalty(address(_team[0]), 750);
        _transferOwnership(address(_team[0]));
        baseURI = "ipfs://QmXx3kk8hny76aeSQTERNVUoSzgUWHg4NTeM7Sp695mG3N/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function enable() public onlyOwner {
        state = Sale.PublicSale;
    }

    function disable() public onlyOwner {
        state = Sale.NoSale;
    }

    function saleIsActive() public view returns (bool) {
        return state == Sale.PublicSale;
    }

    function exists(uint256 id) public view returns (bool) {
        return _exists(id);
    }

    function mintGGC(uint256[] calldata ids) external payable {
        require(state == Sale.PublicSale, "Public sale not enabled.");
        require(
            ids.length > 0 && ids.length <= maxTokenPurchase,
            "Can only mint one or more tokens at a time."
        );
        require(
            msg.value >= (tokenPrice * ids.length),
            "You need to send proper amount of eth."
        );
        require(
            totalSupply().add(ids.length) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens."
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0 && ids[i] <= MAX_TOKENS, "invalid id");
            _safeMint(_msgSender(), ids[i]);
        }
        emit GGCMinted(ids.length, _msgSender());
    }

    /**
     * @dev See {IERC165-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");
        string memory uri = _baseURI();

        if (bytes(uri).length == 0) {
            return "";
        }
        return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev will set default royalty info.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev will set token royalty.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setMaxTokenPurchase(uint256 _maxTokenPurchase) public onlyOwner {
        maxTokenPurchase = _maxTokenPurchase;
    }

    receive() external payable override {}
}

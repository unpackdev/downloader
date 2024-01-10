// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

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
        PreSale,
        PublicSale
    }

    uint256 public constant tokenPrice = 110000000000000000; // 0.11
    uint256 public constant MAX_TOKENS = 3333;
    uint256 public maxTokenPurchase = 12;
    uint256 public presaleMaxMint = 100;

    string public baseURI = "";

    Sale public state = Sale.NoSale;

    mapping(address => uint256) private _presaleClaimed;

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
        // _transferOwnership(address(_team[0]));
        baseURI = "ipfs://QmdLkccqYqQ3P3dnot9XRNZee2GCx6pPirtfiHuoCMggoB/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function enablePresale(bytes32 _presaleRoot) public onlyOwner {
        state = Sale.PreSale;
        presaleRoot = _presaleRoot;
    }

    function enablePublicSale() public onlyOwner {
        state = Sale.PublicSale;
    }

    function disable() public onlyOwner {
        state = Sale.NoSale;
    }

    function saleIsActive() public view returns (bool) {
        return state == Sale.PublicSale;
    }

    function presaleIsActive() public view returns (bool) {
        return state == Sale.PreSale;
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

    function presaleGGC(uint256[] calldata ids, bytes32[] calldata proof)
        external
        payable
    {
        require(state == Sale.PreSale, "Presale not enabled.");
        require(verify(_msgSender(), proof), "Not selected for the presale.");
        require(
            ids.length > 0 && ids.length <= maxTokenPurchase,
            "Can only mint one or more tokens at a time"
        );
        require(
            msg.value >= (tokenPrice * ids.length),
            "you need to send proper amount of eth"
        );
        require(
            totalSupply().add(ids.length) <= MAX_TOKENS,
            "Purchase would exceed max supply of token"
        );
        require(
            _presaleClaimed[_msgSender()].add(ids.length) <= presaleMaxMint,
            "Purchase exceeds max allowed"
        );

        _presaleClaimed[_msgSender()] += ids.length;

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

    function setPresaleMaxMint(uint256 _presaleMaxMint) public onlyOwner {
        presaleMaxMint = _presaleMaxMint;
    }

    function verify(address account, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }

    receive() external payable override {}
}

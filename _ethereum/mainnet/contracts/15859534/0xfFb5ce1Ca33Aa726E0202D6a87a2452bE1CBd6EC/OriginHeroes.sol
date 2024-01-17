// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

//            ()
//            ||
// (||--------||<><><><><><><><><><><><><><><><><><><>\
// (||////////||<>                            <><><><><>
// (||--------||<><><><><><><><><><><><><><><><><><><>/
//            ||
//            ()
contract OriginHeroes is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Address for address;
    using Strings for uint256;
    using MerkleProof for bytes32[];

    bytes32 public root =
        0x158200e7e6cb7a5723ab3dd91e0f85bbf2fa6b0efd447bb7218bc2d2cd6cdfe0;

    string public _contractBaseURI = "https://api.originheroes.com/metadata/";
    string public _contractURI = "https://api.originheroes.com/contract_uri";

    uint256 public maxSupply = 8888;
    uint256 public maxPublicMint = 2;

    uint256 public presalePrice = 0.08 ether;
    uint256 public publicPrice = 0.1 ether;

    uint256 public presaleStartTime = 1667235600;
    uint256 public publicStartTime = 1667408400;

    // The SHA-256 hash of the SHA-256 hashes of all images.
    string public provenance;

    mapping(address => uint256) public whitelistMintQuantity; //merkle root check
    mapping(address => uint256) public publicMintQuantity;

    //payment splitter
    address[] private addressList = [
        0x50FC9e9AAA4b77C4B719E919b9F0ae1eAe14De2C,
        0x6EE7D9c33c74792cA6ACbAa1b25BaE35413F2e6b,
        0xd7c4E0144F2f7A0bE94d9Df17e11EA8Ef402EFF0,
        0x003fe68A257BFeAC537408c62824b121Ca0f708D,
        0xD9014d856705a8c0DcCaf18241e0aBf5e2A58BCC,
        0x1fb741e055f49f38F8032b1cc2bE3646B68cE891,
        0xf51C7543E271Ba704AF43FFA712cA8dEa48101cd
    ];
    uint256[] private shareList = [26, 26, 26, 7, 7, 4, 4];

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy not allowed");
        _;
    }

    constructor()
        ERC721A("Origin Heroes", "FHC")
        PaymentSplitter(addressList, shareList)
    {
        _setDefaultRoyalty(0xE7a697036a3E9b229Fc70d837F0C95daeef8e3c4, 100);
    }

    /**
	 @dev only whitelisted can buy, maximum maxQty
	 @param qty - the quantity that a user wants to buy
	 @param limit - limit of the wallet
	 @param proof - merkle proof
	  */
    function presaleBuy(
        uint256 qty,
        uint256 limit,
        bytes32[] calldata proof
    ) external payable nonReentrant notContract {
        require(
            whitelistMintQuantity[msg.sender] + qty <= limit,
            "wallet limit reached"
        );
        require(block.timestamp >= presaleStartTime, "not live");
        require(presalePrice * qty == msg.value, "exact amount needed");
        require(totalSupply() + qty <= maxSupply, "out of stock");
        require(isProofValid(msg.sender, limit, proof), "invalid proof");

        whitelistMintQuantity[msg.sender] += qty;
        _mint(msg.sender, qty);
    }

    /**
	 @dev anyone can buy
	 @param qty - the quantity that a user wants to buy
	  */
    function publicBuy(uint256 qty) external payable nonReentrant notContract {
        require(
            publicMintQuantity[_msgSender()] <= maxPublicMint,
            "over max limit"
        );
        require(qty <= 10, "max 10 at once");
        require(block.timestamp >= publicStartTime, "not live");
        require(publicPrice * qty == msg.value, "exact amount needed");
        require(totalSupply() + qty <= maxSupply, "out of stock");
        publicMintQuantity[_msgSender()] += qty;
        _mint(_msgSender(), qty);
    }

    /**
	@dev admin mint
	@param to - destination
	@param qty - quantity
	  */
    function adminMint(address to, uint256 qty) external onlyOwner {
        require(totalSupply() + qty <= maxSupply, "out of stock");
        _mint(to, qty);
    }

    /**
     * READ FUNCTIONS
     */

    /**
	@dev returns current "stage"
	*999 = sold out, 0 = not started, 1 = whitelist 1, 2 = public
	*/
    function getStage() public view returns (uint256) {
        if (totalSupply() >= maxSupply) {
            return 999;
        }
        if (block.timestamp >= publicStartTime) {
            return 2;
        }
        if (block.timestamp >= presaleStartTime) {
            return 1;
        }
        return 0;
    }

    /**
	@dev returns true if an NFT is minted
	*/
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
	@dev tokenURI from ERC721 standard
	*/
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json")
            );
    }

    /**
	@dev contractURI from ERC721 standard
	*/
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
	@dev merkle proof check
	*/
    function isProofValid(
        address to,
        uint256 limit,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to, limit));
        return proof.verify(root, leaf);
    }

    /**
     * ADMIN FUNCTIONS
     */
    // be careful setting this one
    function setImportantURIs(
        string memory newBaseURI,
        string memory newContractURI
    ) external onlyOwner {
        _contractBaseURI = newBaseURI;
        _contractURI = newContractURI;
    }

    //recover lost erc20. getting them back chance: very low
    function reclaimERC20Token(address erc20Token) external onlyOwner {
        IERC20(erc20Token).transfer(
            msg.sender,
            IERC20(erc20Token).balanceOf(address(this))
        );
    }

    //recover lost nfts. getting them back chance: very low
    function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
        IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
    }

    //change the presale start time
    function setStartTimes(uint256 presale, uint256 publicSale)
        external
        onlyOwner
    {
        presaleStartTime = presale;
        publicStartTime = publicSale;
    }

    //owner reserves the right to change the price
    function setPricePerToken(uint256 newPresalePrice, uint256 newPublicPrice)
        external
        onlyOwner
    {
        presalePrice = newPresalePrice;
        publicPrice = newPublicPrice;
    }

    //only decrease it, no funky stuff
    function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "decrease only");
        maxSupply = newMaxSupply;
    }

    //default 2
    function setMaxPublicMint(uint256 newLimit) external onlyOwner {
        maxPublicMint = newLimit;
    }

    //call this to reveal the jpegs
    function setBaseURIAndReveal(string memory newBaseURI) external onlyOwner {
        _contractBaseURI = newBaseURI;
    }

    //sets the merkle root for the whitelist
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    //sets the royalty fee and recipient for the collection.
    function setRoyalty(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // sets the `provenance` value to SHA-256 hash to add fairness to the distribution of tokens.
    function setProvenance(string calldata _provenance) external onlyOwner {
        provenance = _provenance;
    }

    //anti-bot
    function _isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    //makes the starting token id to be 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}

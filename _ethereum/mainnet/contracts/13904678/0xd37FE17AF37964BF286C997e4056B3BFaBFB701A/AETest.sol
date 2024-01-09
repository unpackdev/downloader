// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "IERC2981.sol";

import "Pausable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

import "MerkleProof.sol";
import "Counters.sol";

contract AETest is ERC721, IERC2981, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool public prelive;
    bool public slLive;
    bool public freezeURI;
    bool public contractRoyalties;

    // need to apend 0x to front to indicate it is hexadecimal
    bytes32 private merkleRoot =
        0xa7bae61bd9404e894cac665ce5323269569929ca9102d3f44727be92eb37ba71;
    //IMPORTANT: the below must be updated!!!
    uint32 public constant MAX_NFT = 20;
    //IMPORTANT: the below must be updated!!!
    uint32 public constant MAX_WLIST = 10;
    //IMPORTANT: the below must be updated!!!
    uint32 private constant MAX_MINT = 3;
    uint32 public WTLST_COUNT = 0;
    //IMPORTANT: the below must be updated!!!
    uint256 public PRICE = 0.00001 ether;
    //IMPORTANT: the below must be updated!!!
    uint256 public XILE_PRICE = 0.000005 ether;

    //IMPORTANT: the below must be updated
    address private _artist = 0xFD11a824E61A03F8bf25e489D2B49f44558614c8;

    string private _contractURI;
    string private _metadataBaseURI;

    // ** MODIFIERS ** //
    // *************** //

    modifier saleLive() {
        require(slLive == true, "Sale is closed");
        _;
    }

    modifier preSaleLive() {
        require(prelive == true, "Presale is closed");
        _;
    }

    modifier allocTokens(uint32 numToMint) {
        require(
            _tokenIdCounter.current() + numToMint <= MAX_NFT,
            "Sorry, there are not enough artworks remaining."
        );
        _;
    }

    modifier maxOwned(uint32 numToMint) {
        require(
            balanceOf(msg.sender) + numToMint <= MAX_MINT,
            "Limit of 3 per wallet"
        );
        _;
    }

    modifier correctPayment(uint256 mintPrice, uint32 numToMint) {
        require(
            msg.value == mintPrice * numToMint,
            "Payment failed, please ensure you are paying the correct amount."
        );
        _;
    }

    modifier whiteListed(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on whitelist"
        );
        _;
    }

    constructor(string memory _cURI, string memory _mURI)
        ERC721("HogBlox Digital Tapestries", "HDT")
    {
        _contractURI = _cURI;
        _metadataBaseURI = _mURI;
    }

    function aeMint(uint32 mintNum)
        external
        payable
        nonReentrant
        saleLive
        allocTokens(mintNum)
        maxOwned(mintNum)
        correctPayment(PRICE, mintNum)
    {
        for (uint32 i = 0; i < mintNum; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function preMint(uint32 mintNum, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleLive
        whiteListed(merkleProof)
        maxOwned(mintNum)
        correctPayment(PRICE, mintNum)
    {
        for (uint32 i = 0; i < mintNum; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    // testing code - to consider
    function safeMint(address to) public onlyOwner allocTokens(1) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ** TOKEN FREEZING ** //
    // ******************** //

    function freezeAll() external onlyOwner {
        require(freezeURI == false, "Metadata is already frozen");
        freezeURI = true;
    }

    // ** ADMIN ** //
    // *********** //

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    function withdrawFunds(uint256 _amt) public onlyOwner {
        require(_artist != address(0));
        uint256 AMT;
        if (_amt == 0) {
            AMT = address(this).balance;
        } else {
            AMT = _amt;
        }
        address payable dev = payable(msg.sender);
        address payable artist = payable(_artist);
        uint256 pay_amt = AMT / 2;
        dev.transfer(pay_amt);
        artist.transfer(pay_amt);
    }

    function metaURI(string calldata _URI) external onlyOwner {
        require(freezeURI == false, "Metadata has been frozen");
        _metadataBaseURI = _URI;
    }

    function cntURI(string calldata _URI) external onlyOwner {
        _contractURI = _URI;
    }

    // ** SETTINGS ** //
    // ************** //

    function tglLive() external onlyOwner {
        slLive = !slLive;
    }

    function tglPresale() external onlyOwner {
        prelive = !prelive;
    }

    /**
     * @dev Reserve ability to make use of {IERC165-royaltyInfo} standard to implement royalties.
     */
    function tglRoyalties() external onlyOwner {
        contractRoyalties = !contractRoyalties;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updatePrice(uint256 pce) external onlyOwner {
        PRICE = pce;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setArtist(address to) external onlyOwner returns (address) {
        // require(msg.sender == _artist, "You are not authorised to change this");
        _artist = to;
        return _artist;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        // require(contractRoyalties == true);

        return (address(this), (salePrice * 7) / 100);
    }
}

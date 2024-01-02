/*
     _________________
    /            __   \
    |           (__)  |
    |                 |
    | .-----.   .--.  |       			      ____
    | |     |  /    \ |        			 ____//_]|________
    | '-----'  \    / |        			(o _ |  -|   _  o|
    |           |  |  |        			 `(_)-------(_)--'
    | LI LI LI  |  |  |
    | LI LI LI  |  |  |Oo
    | LI LI LI  |  |  |`Oo
    | LI LI LI  |  |  |  Oo			        ,*
    |           |  |  |   Oo			,*  ,*. |  ,o     b,*"
    | .------. /    \ |   oO			|*  |   |  |       |
    | |      | \    / |   Oo 			|   |__='  |       |
    | '------'  '-oO  |   oO
    |          .---Oo |   Oo
    |          ||  ||`Oo  oO      	    ____
    |          |'--'| | OoO 	   ____//_]|________
    |          '----' | 		  (o _ |  -|   _  o|
    \_________________/ 		   `(_)-------(_)--'


   ___      ____  ____  ____        ____  ___   ______________  __
  <  /     ( __ )/ __ \/ __ \      / __ )/   | / ____/ ____/\ \/ /
  / /_____/ __  / / / / / / /_____/ __  / /| |/ / __/ / __   \  /
 / /_____/ /_/ / /_/ / /_/ /_____/ /_/ / ___ / /_/ / /_/ /   / /
/_/      \____/\____/\____/     /_____/_/  |_\____/\____/   /_/
*/
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./ERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./OperatorFilterer.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./ERC2981.sol";


contract CallBaggy is ERC721AQueryable, ERC721ABurnable, OperatorFilterer, ReentrancyGuard, Ownable, ERC2981 {

    // Variables
    // ---------------------------------------------------------------

    uint256 public collectionSize;

    bool public operatorFilteringEnabled;

    bool public isMintActive = false;

    uint256 private mintPrice = 0.088 ether;
    address private devAddress = 0xf0D6dB708C4A42f01811F17f69915D6b62AF9dF2;
    string private _baseTokenURI;


    // Modifiers
    // ---------------------------------------------------------------

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier mintActive() {
        require(isMintActive, "Mint is not open.");
        _;
    }

    modifier supplyLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <= collectionSize,
            "There are not enough tokens left to mint quantity requested."
        );
        _;
    }

    modifier mintNotZero(uint256 quantity){
        require(
            quantity != 0, "You cannont mint 0 tokens."
        );
        _;
    }


    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(price * quantity == msg.value, "Incorrect amount of ETH sent.");
        _;
    }

    // Constructor
    // ---------------------------------------------------------------

    constructor(
        uint256 collectionSize_
    ) ERC721A("1-800-BAGGY", "CALL") {

        collectionSize = collectionSize_;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(devAddress, 700);

    }

    // Public minting functions
    // ---------------------------------------------------------------

    // mint
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        mintActive
        isCorrectPayment(mintPrice, quantity)
        supplyLeft(quantity)
        mintNotZero(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    function gift(address[] calldata addresses)
      external
      nonReentrant
      onlyOwner
      supplyLeft(addresses.length)
    {

      uint256 numToGift = addresses.length;
      for (uint256 i = 0; i < numToGift; i++){
          _safeMint(addresses[i], 1);
      }

    }

    // Public read-only functions
    // ---------------------------------------------------------------


    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override (IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    // Owner only administration functions
    // ---------------------------------------------------------------

    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
    require(
        _collectionSize <= collectionSize,
        "Cannot increase collection size."
    );
    collectionSize = _collectionSize;
    }

    function setDefaultRoyalty(address _devAddress, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_devAddress, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, (token.balanceOf(address(this))));
    }

    function ownerMint(uint256 quantity) external onlyOwner
        supplyLeft(quantity){
        _safeMint(msg.sender, quantity);
    }

    // ClosedSea functions
    // ---------------------------------------------------------------

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }


    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

}

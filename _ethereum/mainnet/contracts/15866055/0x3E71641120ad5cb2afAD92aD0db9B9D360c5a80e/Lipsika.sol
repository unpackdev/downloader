// SPDX-License-Identifier: MIT
/*
    ___    __      __             __    _
   /   |  / /___  / /_  ____ _   / /   (_)___  _____
  / /| | / / __ \/ __ \/ __ `/  / /   / / __ \/ ___/
 / ___ |/ / /_/ / / / / /_/ /  / /___/ / /_/ (__  )
/_/  |_/_/ .___/_/ /_/\__,_/  /_____/_/ .___/____/
        /_/                          /_/
                         
*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

contract Lipsika is
    Ownable,
    ERC721ABurnable,
    ERC721AQueryable,
    ReentrancyGuard
{
    enum SaleState {
        RevealedDevMint,
        WhiteListSale,
        PublicSale,
        Revealed
    }

    address payable public immutable treasuryAccount;
    address payable private immutable royaltyAccount;

    string public provenance;

    uint256 public immutable devReserve = 5;
    uint256 public whitelistQuantityMinted = 0;
    uint256 public immutable maxMintLimit = 10;
    uint256 public immutable whiteReserve = 50;
    uint256 public immutable totalAvailableQuantity = 100;

    bytes32 public merkleRoot;
    SaleState public saleStatus = SaleState.RevealedDevMint;
    uint256 public salePrice = 1 gwei;
    string private baseTokenURI;
    string private devRevealedBaseTokenURI;

    mapping(address => uint256) private tokenCounter;

    event SaleStateChanged(SaleState);

    // @dev "the beginning"
    constructor(
        address payable _treasuryAccount,
        address payable _royaltyAccount,
        string memory _provenance
    ) ERC721A("Lipsika", "LPS") {
        treasuryAccount = _treasuryAccount;
        royaltyAccount = _royaltyAccount;
        provenance = _provenance;
    }

    // @dev throws when number of tokens exceeds reserve token quantity
    modifier whiteListTokensAvailable(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= devReserve + whiteReserve,
            "exceeding number of tokens for whitelisted!"
        );
        _;
    }

    // @dev throws when number of tokens exceeds max token limit per account
    modifier accountInLimit(uint256 _quantity) {
        require(
            tokenCounter[msg.sender] + _quantity <= maxMintLimit,
            "can not mint! limit exeeded for the account"
        );
        _;
    }

    // @dev checks enough ETH provided
    modifier valueSufficient(uint256 _quantity) {
        require(salePrice * _quantity <= msg.value, "more ETH required");
        _;
    }

    // @dev exceed the total supply allowed
    modifier supplyAvailable(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= totalAvailableQuantity,
            "exceeding total supply!"
        );
        _;
    }

    // @dev throws when parameters sent by claimer is incorrect
    modifier canClaim(bytes32[] memory proof) {
        require(isWhiteListed(proof), "not on white list");
        _;
    }

    // @dev caller cannot be a contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller is another contract");
        _;
    }

    // @dev token id starts from 1
    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    // @dev tokens minted by an account
    function tokenCount(address _account) public view returns (uint256) {
        return tokenCounter[_account];
    }

    // @dev sets the merkle root for White list
    function setMerkleRoot(bytes32 root) external onlyOwner nonReentrant {
        require(
            saleStatus == SaleState.RevealedDevMint,
            "Cannot change merkle root in the current sale status!"
        );

        merkleRoot = root;
    }

    // @dev checks if the claimer has a valid proof
    function isWhiteListed(bytes32[] memory proof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // @dev dev mint for marketing and promotions
    function devMint() external onlyOwner {
        require(
            saleStatus == SaleState.RevealedDevMint,
            "not in dev mint phase"
        );
        devRevealedBaseTokenURI = _baseURI();
        _safeMint(treasuryAccount, devReserve);
        tokenCounter[msg.sender] += devReserve;
    }

    // @dev refund any additional amount sent
    function refundExcess(uint256 _quantity) private {
        if (msg.value > salePrice * _quantity) {
            payable(msg.sender).transfer(msg.value - (salePrice * _quantity));
        }
    }

    // @dev whitelist sale minting (for privileged users)
    function whiteListMint(bytes32[] memory merkleProof, uint256 _quantity)
        external
        payable
        callerIsUser
        canClaim(merkleProof)
        valueSufficient(_quantity)
        accountInLimit(_quantity)
        whiteListTokensAvailable(_quantity)
        supplyAvailable(_quantity)
        nonReentrant
    {
        require(
            saleStatus == SaleState.WhiteListSale,
            "not in white list phase"
        );
        _safeMint(msg.sender, _quantity);
        tokenCounter[msg.sender] += _quantity;
        whitelistQuantityMinted += _quantity;
        refundExcess(_quantity);
    }

    // @dev public sale minting
    function publicMint(uint256 _quantity)
        external
        payable
        callerIsUser
        valueSufficient(_quantity)
        accountInLimit(_quantity)
        supplyAvailable(_quantity)
        nonReentrant
    {
        require(
            saleStatus == SaleState.PublicSale,
            "minting not in public sale phase"
        );
        _safeMint(msg.sender, _quantity);
        tokenCounter[msg.sender] += _quantity;
        refundExcess(_quantity);
    }

    // @dev controls the drop flow (ensures chronological order)
    function changeSaleStatus(SaleState _status) external onlyOwner {
        require(
            SaleState(uint8(saleStatus) + 1) == _status,
            "invalid sale status change!"
        );

        saleStatus = _status;
        emit SaleStateChanged(saleStatus);
    }

    // @dev sets the sale price on demand
    function setSalePrice(uint256 price) external onlyOwner {
        salePrice = price;
    }

    // @dev returns current base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // @dev controls the drop by revealing the URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // @dev returns tokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI;
        string memory metaURI;

        metaURI = Strings.toString(tokenId);

        // dev mint is revealed
        baseURI = tokenId <= devReserve ? devRevealedBaseTokenURI : _baseURI();

        // retuns hidden URI untill revealed
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, metaURI, ".json"))
                : "";
    }

    // @dev only owner
    function withdraw() external onlyOwner nonReentrant {
        royaltyAccount.transfer(address(this).balance);
    }

    // @dev for operators (3rd party integration)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // @dev contract URI for opensea
    function contractURI() public pure returns (string memory) {
        return "https://api.dev.nftmarket.mayaloka.io/get-contract-metadata";
    }
}

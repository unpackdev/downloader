// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC2981Royalties.sol";

contract CRCLSCatalystPass is ERC721A, ERC2981Royalties, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;

    enum Status { NOT_LIVE, PRESALE_LIVE, PUBLIC_LIVE, SOLD_OUT }
    Status public saleStatus = Status.NOT_LIVE;
    uint256 public price = 0.5 ether;
    uint256 public maxMint = 10;
    uint256 public maxSupply = 1000;

    bytes32 private _accessListRoot;
    string private _baseTokenURI;

    VRFCoordinatorV2Interface private _oracle;
    uint64 private _linkSubId;
    uint16 private _vrfConfs = 3;
    bytes32 private _keyHash;
    uint32 private _callbackGasLimit = 100000;

    event SaleStatus(Status newStatus);
    event RandomOwner(uint256 requestId, address owner);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981Base)
        returns (bool)
    {
        return interfaceId == 0x80ac58cd || super.supportsInterface(interfaceId);
    }

    constructor(
        uint256 _price,
        uint256 royaltyPercentage,
        string memory baseTokenURI,
        bytes32 accessListRoot,
        uint64 linkSubId,
        address vrfCoordinatorAddress,
        bytes32 keyHash
    ) ERC721A("CRCLS Catalyst Pass", "OG") VRFConsumerBaseV2(vrfCoordinatorAddress) {
        // EIP2987
        _setRoyalties(msg.sender, royaltyPercentage);

        // Initialize Chainlink coordinator
        _oracle = VRFCoordinatorV2Interface(vrfCoordinatorAddress);

        // Init vars
        price = _price;
        _linkSubId = linkSubId;
        _keyHash = keyHash;
        _baseTokenURI = baseTokenURI;
        _accessListRoot = accessListRoot;
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint8 amount, bytes32[] calldata proof) external payable {
        require(saleStatus != Status.NOT_LIVE, "Sale is not live");
        require(_totalMinted() < maxSupply, "SOLD OUT!");
        require(msg.value >= amount * price, "Not enough eth");
        require(amount <= maxMint, "Requesting too many");
        require(_totalMinted() + amount <= maxSupply, string(abi.encodePacked("Only ", (maxSupply - _totalMinted()).toString(), " left.")));
        require(balanceOf(msg.sender) + amount <= maxMint, string(abi.encodePacked("You may only mint ", maxMint.toString(), " in total.")));

        address sender = _msgSenderERC721A();

        if (saleStatus == Status.PRESALE_LIVE) {
            // Make sure the sender in on the whitelist.
            require(MerkleProof.verify(proof, _accessListRoot, keccak256(abi.encodePacked(msg.sender))), "Unauthorized");
        } else if (saleStatus == Status.PUBLIC_LIVE) {
            // Make sure the sender isn't requesting too many
            require(_numberMinted(sender) < maxMint, "Max amount exceeded");
        }

        if (_totalMinted() + amount == maxSupply) {
            saleStatus = Status.SOLD_OUT;
            emit SaleStatus(Status.SOLD_OUT);
        }

        _safeMint(sender, amount);
    }

    function changeSaleStatus(Status status) external onlyOwner() {
        saleStatus = status;
        emit SaleStatus(status);
    }

    function setAccessListRoot(bytes32 root) external onlyOwner() {
        _accessListRoot = root;
    }

    function requestRandomOwner() external onlyOwner() returns (uint256){
        return _oracle.requestRandomWords(_keyHash, _linkSubId, _vrfConfs, _callbackGasLimit, 1);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = (randomWords[0] % _totalMinted()) + 1;
        emit RandomOwner(requestId, ownerOf(tokenId));
    }

    function isOnAccessList(bytes32[] calldata proof) external view returns (bool) {
        return MerkleProof.verify(proof, _accessListRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function setBaseTokenURI(string memory newURI) external onlyOwner() {
        _baseTokenURI = newURI;
    }

    function setPrice(uint256 _price) external onlyOwner() {
        price = _price;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner() {
        maxMint = _maxMint;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setChainlinkSubscriptionId(uint64 linkSubId) external onlyOwner() {
        _linkSubId = linkSubId;
    }

    function setChainlinkAddress(address vrfCoordinatorAddress) external onlyOwner() {
        _oracle = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
    }

    function setChainlinkKeyHash(bytes32 keyHash) external onlyOwner() {
        _keyHash = keyHash;
    }

    function setRoyaltyAmount(uint256 royaltyPercentage) external onlyOwner() {
        _setRoyalties(msg.sender, royaltyPercentage);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

// change contract name
contract DemoMH is ERC721A, Ownable, ReentrancyGuard {

    bytes32 public merkleRoot;

    enum salesStatuses {
        PASSIVE,
        PRE_SALE,
        PUBLIC_SALE
    }

    uint256 public maxSupply = 10050;
    uint256 public cost = 0.01 ether;
    salesStatuses public salesStatus = salesStatuses.PASSIVE;
    bool public paused = false;
    bool public mintClosed = false;

    //backend settings
    string public baseURI;

    //marketing
    uint256 internal constant giftLimit = 150; 
    uint256 internal giftUsed = 0;

    //stakeholders
    address private shArtist = 0x2493766a248C60Acc7b5ec2b2e5aA78F8C13a576; //artist
    address private shPartner1 = 0xf4080C0E4AfbB58F29EBd1620b39CBfE83630702; //partner1
    address private shPartner2 = 0x0686551a47F6010520B43d81C95d8d9578648DC5; //partner2
    address private shPartner3 = 0xA40B09377aEe12cb37F1F2F67f485d7D45a3F971;  //partner3
    address private shPartner4 = 0x343776b5AE7C5214EE6eBAFb2F4333333bA75Bed;  //partner4

    mapping(address => bool) public projectProxy;
    address public proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("Demo MH", "DMMH") {
        baseURI = "https://api.demomh.io/meta/";
    }

    modifier mintChecker(uint256 _qty) {
        require(!mintClosed, "Mint is closed!");
        require(!paused, "Sale is paused!");
        require(_qty > 0, "Invalid mint amount!");
        require(_qty <= 50, "Invalid mint amount!");
        require(_totalMinted() + _qty <= maxSupply, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _qty) external payable nonReentrant mintChecker(_qty) {
        require(salesStatus == salesStatuses.PUBLIC_SALE, "Public sale is not active!");
        require(msg.value >= cost * _qty, "Insufficient funds!");
        _safeMint(msg.sender, _qty);
    }

    function preMint(uint256 _qty, bytes32[] calldata _merkleProof) external payable nonReentrant mintChecker(_qty) {
        require(salesStatus == salesStatuses.PRE_SALE, "PreSale is not active!");
        require(msg.value >= cost * _qty, "Insufficient funds!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not in whitelist");
        _safeMint(msg.sender, _qty);
        delete leaf;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function collectorMint(address[] calldata _addresses, uint256[] calldata _quantities) external onlyOwner {
        require(_quantities.length == _addresses.length, "Provide quantities and recipients" );
        uint256 bulkQty = 0;
        for(uint i = 0; i < _quantities.length; ++i){
            bulkQty += _quantities[i];
        }
        require(giftUsed + bulkQty <= giftLimit, "Max gift limit reached");
        require(_totalMinted() + bulkQty <= maxSupply, "Max supply exceeded!");
        for(uint i = 0; i < _quantities.length; ++i){
            _safeMint(_addresses[i], _quantities[i]);
        }
        giftUsed += bulkQty;
        delete bulkQty;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(shArtist).transfer((balance * 40) / 100);
        payable(shPartner1).transfer((balance * 25) / 100);
        payable(shPartner2).transfer((balance * 25) / 100);
        payable(shPartner3).transfer((balance * 5) / 100);
        payable(shPartner4).transfer((balance * 5) / 100);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId))) : '';
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function setSaleStatus(salesStatuses _salesStatus) external onlyOwner {
        salesStatus = _salesStatus;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function switchProxy(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }
    function setProxy(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }

    function getSaleStatus() public view returns (salesStatuses) {
        return salesStatus;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function closeMint() public onlyOwner {
        require(salesStatus == salesStatuses.PUBLIC_SALE, "The sale status must be public");
        mintClosed = true;
    }

}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
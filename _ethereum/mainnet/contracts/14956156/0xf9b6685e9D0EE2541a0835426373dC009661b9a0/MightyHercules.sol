// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract MightyHercules is ERC721A, Ownable, ReentrancyGuard {

    bytes32 public merkleRoot = 0x99a4cd11e9c964ed088884af8d0764e58e1256078ab26fbeb4ec2a8d0925fa4e;

    enum salesStatuses {
        PASSIVE,
        PRE_SALE,
        PUBLIC_SALE
    }

    uint256 public maxSupply = 10050;
    uint256 public cost = 0.15 ether;
    salesStatuses public salesStatus = salesStatuses.PASSIVE;
    bool public paused = false;
    bool public mintClosed = false;
    string public baseURI;
    uint256 internal constant giftLimit = 200; 
    uint256 internal giftUsed = 0;

    address private wallet1 = 0x71F3606B5450950b5eE6E2177d1227049ed83ab7;
    address private wallet2 = 0x94b212894f4Fa0939bA33C7F30A785531ec23a8D; 
    address private wallet3 = 0x18471A3664794E50F448b408503A4b59BBa2E0fa;
    address private wallet4 = 0x169fDD54bA38FD2575E61aB8939849BfF00e5Fe6; 
    address private wallet5 = 0xBB34d08c67373e54F066E6e7e6c77846fF7D2714; 

    mapping(address => bool) public projectProxy;
    address public proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("Mighty Hercules", "MIGHTY") {
        baseURI = "https://cdn.mightyhercules.io/meta-data/";
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
        payable(wallet1).transfer((balance * 42) / 100);
        payable(wallet2).transfer((balance * 24) / 100);
        payable(wallet3).transfer((balance * 24) / 100);
        payable(wallet4).transfer((balance * 5) / 100);
        payable(wallet5).transfer((balance * 5) / 100);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId), ".json")) : '';
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
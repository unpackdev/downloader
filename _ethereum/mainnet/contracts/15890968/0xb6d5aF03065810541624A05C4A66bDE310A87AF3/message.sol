// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract Dappad is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using Counters for Counters.Counter;

    struct Tier {
        uint256 price;
        uint256 startIndex;
        uint256 endIndex;
        uint256 maxSupply;
        Counters.Counter totalSupply;
        bool enabled;
    }

    mapping(address => bool) public moderators;

    bytes32 private root;
    address proxyAddress;
    string public baseTokenURI;
    string public baseExtension = ".json";
    bool public paused = false;
    bool public preMint = false;
    bool public communityMint = false;
    bool public reveal = false;
    mapping(address => uint256) public presaleClaims;
    uint256 public presaleMintLimit = 2;
    Tier[] private tiers;
    uint256 public max = 1200;

    constructor(string memory uri,
        bytes32 merkleroot,
        address _proxyRegistryAddress)
    ERC721("Dappad", "DAPPAD")
    ReentrancyGuard() {

        root = merkleroot;
        proxyAddress = _proxyRegistryAddress;
        baseTokenURI = uri;

        moderators[msg.sender] = true;
        moderators[0xCD608b9E8C50Aa6C11d396E891022cA8da040351] = true;
        moderators[0x72c2325AFbCfD76Bd330D913fbccD28F72121484] = true;

        tiers.push(Tier(0.29 ether, 901, 1200,0, Counters.Counter(0), true));
        tiers.push(Tier(0.05 ether, 11, 20, 0, Counters.Counter(0), false));
        tiers.push(Tier(0.06 ether, 21, 30,0, Counters.Counter(0), false));
    }

    function setMintLimit(uint256 _limit) public onlyModerators {
        presaleMintLimit = _limit;
    }

    function setIndex(uint256 _tier, uint256 _startIndex, uint256 _endIndex) public onlyModerators {
        Tier storage tier = tiers[_tier];
        tier.startIndex = _startIndex;
        tier.endIndex = _endIndex;
    }

    function addModerator(address _moderator) public onlyOwner {
        moderators[_moderator] = true;
    }

    function removeModerator(address _moderator) public onlyOwner {
        moderators[_moderator] = false;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier onlyModerators () {
        require(moderators[msg.sender] == true, "Not allowed");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
        require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
        ) == true, "Not allowed origin");
        _;
    }

    function getTierPrice(uint256 _tier) public view returns (uint256) {
        Tier memory tier = tiers[_tier];
        return tier.price;
    }

    function maxSupply() public view returns (uint256) {
        return max;
    }

    function getTier(uint256 _tier) public view returns (Tier memory) {
        Tier memory tier = tiers[_tier];
        return tier;
    }

    function getSupply(uint256 _index) public view returns (uint256) {
        Tier memory tier = tiers[_index];
        return tier.maxSupply;
    }

    function verifyWhitelist( address account, bytes32[] calldata merkleProof ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(merkleProof, root, leaf);
    }

    function setMaxSupply(uint256 _index, uint256 _amount) public onlyModerators {
        Tier storage tier = tiers[_index];
        tier.maxSupply = _amount;
    }

    function addMaxSupply(uint256 _index, uint256 _amount) public onlyModerators {
        Tier storage tier = tiers[_index];
        tier.maxSupply = tier.maxSupply + _amount;
    }

    function enableTier(uint256 _index) external onlyModerators {
        Tier storage tier = tiers[_index];
        tier.enabled = true;
    }

    function disableTier(uint256 _index) external onlyModerators {
        Tier storage tier = tiers[_index];
        tier.enabled = false;
    }

    function setMintPrice(uint256 _index, uint256 _amount) external onlyModerators {
        Tier storage tier = tiers[_index];
        tier.price = _amount;
    }

    function mintByOwner(uint256 _index, uint256 _amount) external onlyModerators onlyAccounts {
        for (uint256 i = 0; i < _amount; i++) {
            _safeTierMint(owner(), _index);
        }
    }

    function presaleMint(address account, uint256 _index, uint256 _amount, bytes32[] calldata _proof) external payable isValidMerkleProof(_proof) onlyAccounts {
        require(msg.sender == account, "Not allowed");
        require(preMint, "Presale is OFF");
        require(!paused, "Contract is paused");
        require(_amount > 0, "zero amount");
        require(_amount <= presaleMintLimit, "You can't mint so much tokens");
        require(presaleClaims[msg.sender] + _amount <= presaleMintLimit, "You can't mint so much tokens");
        Tier storage tier = tiers[_index];
        require(tier.enabled, "Tier is disabled");
        require(
            tier.price * _amount <= msg.value,
            "Not enough ethers sent"
        );
        presaleClaims[msg.sender] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            _safeTierMint(msg.sender, _index);
        }
    }

    function withdrawAll() external onlyModerators {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function communitySaleMint(uint256 _index, uint256 _amount) external payable onlyAccounts {
        require(!paused, "Sale paused");
        require(communityMint, "CommunitySale is OFF");
        require(_amount > 0, "zero amount");
        require(_index < tiers.length, "Invalid tier");
        Tier storage tier = tiers[_index];
        require(tier.enabled, "Tier is disabled");
        require(
            tier.price * _amount <= msg.value,
            "Not enough ethers sent"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _safeTierMint(msg.sender, _index);
        }
    }

    function _safeTierMint(address account, uint _index) private nonReentrant {
        require(_index < tiers.length, "Invalid tier");
        Tier storage tier = tiers[_index];
        uint256 index = tier.startIndex + tier.totalSupply.current();
        require(index <= tier.startIndex+tier.maxSupply, "Tier limit reached");
        require(index <= tier.endIndex, "Tier end limit reached");
        _safeMint(account, index);
        tier.totalSupply.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyModerators {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyModerators {
        baseExtension = _newBaseExtension;
    }

    function setMerkleRoot(bytes32 merkleroot) external onlyModerators {
        root = merkleroot;
    }

    function togglePause() external onlyModerators {
        paused = !paused;
    }

    function togglePresale() external onlyModerators {
        preMint = !preMint;
    }

    function toggleCommunitySale() external onlyModerators {
        communityMint = !communityMint;
    }

    function toggleReveal() external onlyModerators {
        reveal = !reveal;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        if(!reveal) {
            return string(abi.encodePacked(currentBaseURI, "0", baseExtension));
        }
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                baseExtension
            )
        )
        : "";
    }

    function isApprovedForAll(address owner, address operator) override(IERC721, ERC721) public view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = ERC721.balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalSupplied = maxSupply();
            uint256 inx = 0;
            uint256 id;
            for (id = 1; id <= totalSupplied; id++) {
                if (!ERC721._exists(id)) {
                    continue;
                }
                if (ERC721.ownerOf(id) == _owner) {
                    result[inx] = id;
                    inx++;
                }
            }
            return result;
        }
    }
}

contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
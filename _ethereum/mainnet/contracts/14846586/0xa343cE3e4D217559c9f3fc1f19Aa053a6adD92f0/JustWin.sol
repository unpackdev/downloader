// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// pause mints at deployment
// set contract/base uris
// set params
// setVersion

import "./IJustWin.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

contract JustWin is IJustWin, ERC721A, ERC2981, Ownable {
    
    // State
    uint public version;
    uint public constant maxSupply = 30000;
    string private baseURI;

    mapping(uint => Params) public versionParams;
    mapping(uint => mapping(List => mapping(address => uint))) public claimed; // version to list to addy to number minted
    mapping(List => mapping(uint => bool)) public isPaused;

    // Royalties
    uint96 royaltyFeesInBips;
    address royaltyReceiver;
    string public contractURI;

    // Lottery
    address public lottery;
    
    constructor(
        uint96 _royaltyFeesInbips
    ) ERC721A("JustWin", "JW") {
        royaltyFeesInBips = _royaltyFeesInbips;
        royaltyReceiver = address(this);
        _initPause();
        _setMembersAlloInfo();
        _setRoyaltiesDistInfo();
    }


    // ***** VIEW *****
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == 0x80ac58cd;
    }

    

    // ***** MERKLE TREE *****
    function isWhitelist(bytes32[] memory proof, bytes32 _leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, versionParams[version].roots.whitelist, _leaf);
    }

    function isViplist(bytes32[] memory proof, bytes32 _leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, versionParams[version].roots.viplist, _leaf);
    }



    // ***** MINT *****
    function mintPublic(uint _number) external payable {
        Params memory params_ = versionParams[version];
        require(!isPaused[List.sale][params_.version], "paused");
        require(msg.value >= params_.prices.sale * _number, "price");
        require(params_.supplies.sale + _number <= params_.maxSupplies.sale, "supplies");
        require(params_.supply + _number <= params_.maxSupply, "supply");
        params_.supplies.sale += _number;
        params_.supply += _number;
        versionParams[version] = params_;
        _allocate(msg.value);
        _safeMint(msg.sender, _number);
    }

    function mintFriends(uint _number) external payable {
        require(version == 1, "v");
        Params memory params_ = versionParams[version];
        require(!isPaused[List.friends][params_.version], "paused");
        require(msg.value >= params_.prices.friends * _number, "price");
        require(claimed[params_.version][List.friends][msg.sender] + _number <= params_.mintable.friends, "claimed");
        require(params_.supplies.friends + _number <= params_.maxSupplies.friends, "supplies");
        require(params_.supply + _number <= params_.maxSupply, "supply");
        params_.supplies.friends += _number;
        params_.supply += _number;
        claimed[version][List.friends][msg.sender] += _number;
        versionParams[version] = params_;
        _allocateFriends(msg.value);
        _safeMint(msg.sender, _number);
    }

    function mintWhitelist(uint _number, bytes32[] memory _proof) external payable {
        Params memory params_ = versionParams[version];
        require(!isPaused[List.whitelist][params_.version], "paused");
        bytes32 leaf_ = keccak256(abi.encodePacked(msg.sender));
        require(isWhitelist(_proof, leaf_), "list");
        require(msg.value >= params_.prices.whitelist * _number, "price");
        require(claimed[params_.version][List.whitelist][msg.sender] + _number <= params_.mintable.whitelist, "claimed");
        require(params_.supplies.whitelist + _number <= params_.maxSupplies.whitelist, "supplies");
        require(params_.supply + _number <= params_.maxSupply, "supply");
        claimed[version][List.whitelist][msg.sender] += _number;
        params_.supplies.whitelist += _number;
        params_.supply += _number;
        versionParams[version] = params_;
        _allocate(msg.value);
        _safeMint(msg.sender, _number);
    }

    function mintViplist(uint _number, bytes32[] memory _proof) external payable {
        Params memory params_ = versionParams[version];
        require(!isPaused[List.viplist][params_.version], "paused");
        bytes32 leaf_ = keccak256(abi.encodePacked(msg.sender));
        require(isViplist(_proof, leaf_), "list");
        require(msg.value >= params_.prices.viplist * _number, "price");
        require(claimed[params_.version][List.viplist][msg.sender] + _number <= params_.mintable.viplist, "claimed");
        require(params_.supplies.viplist + _number <= params_.maxSupplies.viplist, "supplies");
        require(params_.supply + _number <= params_.maxSupply, "supply");
        claimed[version][List.viplist][msg.sender] += _number;
        params_.supplies.viplist += _number;
        params_.supply += _number;
        versionParams[version] = params_;
        _allocate(msg.value);
        _safeMint(msg.sender, _number);
    }

    // ***** ADMIN *****
    function setParamsVersion(uint _version) external onlyOwner {
        version = _version;
        versionParams[_version].version = _version;
    }
    
    function setMaxSupply(uint _version, uint _maxSupply) external onlyOwner {
        versionParams[_version].maxSupply = _maxSupply;
    }

    function setMaxSupplies(uint _version, MaxSupplies memory _maxSupplies) external onlyOwner {
        versionParams[_version].maxSupplies = _maxSupplies;
    }

    function setMintable(uint _version, Mintable memory _mintable) external onlyOwner {
        versionParams[_version].mintable = _mintable;
    }

    function setPrices(uint _version, Prices memory _prices) external onlyOwner {
        versionParams[_version].prices = _prices;
    }

    function setRoots(uint _version, Roots memory _roots) external onlyOwner {
        versionParams[_version].roots = _roots;
    }

    function setLotteryAddress(address _lottery) external onlyOwner {
        lottery = _lottery;
    }

    function setPause(List _list, uint _version, bool _state) public onlyOwner {
        isPaused[_list][_version] = _state;
    }
    function _initPause() internal {
        setPause(List.friends, 1, true);
        setPause(List.whitelist, 1, true);
        setPause(List.viplist, 1, true);
        setPause(List.sale, 1, true);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // Team/Growth
    uint256 public totalAllo;
    uint public totalRoyalties;
    address[] public members;
    address[] public royaltiesMembers;
    mapping(address => uint) public memberAllo;
    mapping(address => uint) public memberRoyalty;
    address public marketing = 0x9667427550044ffB24859e15C8c06DBfF1286Aa9;
    address public asso = 0x6d6ea83390005C73860131AD8c4C4f909fA16044;
    uint public reserved;
    

    function reserveTicket(address _to, uint _number) external onlyOwner {
        require(reserved <= 500, "v");
        versionParams[1].supply += _number;
        reserved += _number;
        _safeMint(_to, _number);
    }

    function _allocate(uint _value) internal {
        uint totalWeight = 10000;
        uint lotteryWeight = 1888;
        uint lotteryCut_ = _value * lotteryWeight / totalWeight;
        uint marketingAmount_ = lotteryCut_ * 500 / totalWeight;
        uint lotteryAmount_ = lotteryCut_ - marketingAmount_;
        (bool success1,) = marketing.call{value: marketingAmount_}("");
        require(success1, "ETH");
        (bool success2,) = lottery.call{value: lotteryAmount_}("");
        require(success2, "ETH");
        totalAllo += _value - lotteryCut_;
    }

    function _allocateFriends(uint _value) internal {
        (bool success,) = marketing.call{value: _value}("");
        require(success, "ETH");
    }

    function distributeRoyalties() external onlyOwner {
        require(totalRoyalties > 0);
        uint totalWeight = 10000;
        uint lotteryWeight = 5000;
        uint assoWeight = 2500;
        uint _assoAmount = totalRoyalties * assoWeight / totalWeight;
        (bool success0,) = asso.call{value: _assoAmount}("");
        require(success0, "failed to send ETH");
        uint lotteryAmount_ = totalRoyalties * lotteryWeight / totalWeight;
        (bool success1,) = lottery.call{value: lotteryAmount_}("");
        require(success1, "ETH");
        uint royaltyAmount_ = totalRoyalties - lotteryAmount_ - _assoAmount;
        for (uint i = 0; i < royaltiesMembers.length; ++i) {
            address to = royaltiesMembers[i];
            uint royalty_ = royaltyAmount_ * memberRoyalty[to] / totalWeight;
            (bool success2,) = to.call{value: royalty_}("");
            require(success2, "ETH");
        }
        totalRoyalties = 0;
    }

    function distributeAllo() external onlyOwner {
        require(members.length != 0);
        require(address(this).balance > 0);
        uint totalWeight = 10000;
        for (uint i = 0; i < members.length; ++i) {
            address to = members[i];
            uint amount_ = totalAllo * memberAllo[to] / totalWeight;
            (bool success,) = to.call{value: amount_}("");
            require(success, "ETH");
        }
        totalAllo = 0;
    }

    function distributeERC20(address _token) external {
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "balance");
        uint totalWeight = 10000;
        for (uint i = 0; i < members.length; ++i) {
            address to = members[i];
            uint amount_ = balance * memberAllo[to] / totalWeight;
            token.transfer(to, amount_);
        }
    }

    function _setRoyaltiesDistInfo() internal {
        royaltiesMembers = [
            0xC621F67aDFD47E4914169Edf7037fA3eF76fdfd3,
            0x95235f5f4a41Dd74B4F10F9581e59bA66084dbe8,
            0xDCE73e3E9CB2e19054447e6f331900AE4890dA38,
            0xF1A3e5FbF0b4bB783f01b0dB5608DB998d18FB53,
            0x503591aA518f51a751DE92Abe363848C81DE8375,
            0x54d5c487193C142d4DF901Dac75309B93bf6cE14
        ];
        memberRoyalty[royaltiesMembers[0]] = 2200;
        memberRoyalty[royaltiesMembers[1]] = 2200;
        memberRoyalty[royaltiesMembers[2]] = 2200;
        memberRoyalty[royaltiesMembers[3]] = 1500;
        memberRoyalty[royaltiesMembers[4]] = 1500;
        memberRoyalty[royaltiesMembers[5]] = 400;
    }

    function _setMembersAlloInfo() internal {
        members = [
            0xC621F67aDFD47E4914169Edf7037fA3eF76fdfd3,
            0x95235f5f4a41Dd74B4F10F9581e59bA66084dbe8,
            0xDCE73e3E9CB2e19054447e6f331900AE4890dA38,
            0xF1A3e5FbF0b4bB783f01b0dB5608DB998d18FB53,
            0x503591aA518f51a751DE92Abe363848C81DE8375,
            0x54d5c487193C142d4DF901Dac75309B93bf6cE14,
            0x3c48872F2c8DA8eABC693c64Fbed3a2B3d4eF2A9,
            0x1701a8e654c84e5979736675D13F93A4DD4d2eea
        ];
        memberAllo[members[0]] = 2420;
        memberAllo[members[1]] = 2420;
        memberAllo[members[2]] = 2420;
        memberAllo[members[3]] = 1230;
        memberAllo[members[4]] = 1230;
        memberAllo[members[5]] = 188;
        memberAllo[members[6]] = 55;
        memberAllo[members[7]] = 37;
    }

    receive() external payable {
            totalRoyalties += msg.value;
        }
}
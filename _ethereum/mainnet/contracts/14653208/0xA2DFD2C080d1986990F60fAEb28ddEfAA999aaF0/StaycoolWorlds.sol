// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";
import "./Admin.sol";

contract StaycoolWorlds is ERC721, IERC2981, Admin {
    uint256 public MAX_SUPPLY = 1500;
    uint256 public PRICE;

    using MerkleProof for bytes32[];
    bytes32 MERLEROOT;
    uint256 private CURRENT_ID = 0;

    mapping(address => bool) public MINTTRACKER;

    address[] private TEAM;
    uint256[] private TEAM_SHARES;

    address public ROYALTY_RECEIVER;
    uint256 public ROYALTY_PERCENTAGE;

    string public BASE_URI;
    string public CONTRACT_URI;

    uint256 public STARTTIME;

    bool public PUBLIC_SALE_ATIVE = false;

    constructor(
        address[] memory _team,
        uint256[] memory _team_shares,
        address _royalty_receiver,
        uint256 _royalty_percentage,
        string memory _initialBaseURI,
        string memory _initialContractURI,
        uint256 _price,
        uint256 _startTime
    ) ERC721("Staycool Worlds", "STAYCOOL") {
        STARTTIME = _startTime;
        PRICE = _price;
        CONTRACT_URI = _initialContractURI;
        BASE_URI = _initialBaseURI;
        ROYALTY_PERCENTAGE = _royalty_percentage;
        ROYALTY_RECEIVER = _royalty_receiver;
        TEAM_SHARES = _team_shares;
        TEAM = _team;
    }

    function _internalMint(address to) private {
        require(CURRENT_ID + 1 <= MAX_SUPPLY, "Will exceed maximum supply");
        require(!MINTTRACKER[to], "You already minted");
        require(block.timestamp >= STARTTIME, "Sale not active");
        MINTTRACKER[to] = true;
        CURRENT_ID++;
        _safeMint(to, CURRENT_ID);
    }

    function mintListed(bytes32[] calldata proof) public payable {
        require(
            proof.verify(MERLEROOT, keccak256(abi.encodePacked(_msgSender()))),
            "You are not on the list"
        );
        require(msg.value >= PRICE, "Incorrect payable amount");
        _internalMint(_msgSender());
    }

    function mintPublic() public payable {
        require(PUBLIC_SALE_ATIVE, "Public Sale is not active");
        require(msg.value >= PRICE, "Incorrect payable amount");
        require(_msgSender() == tx.origin, "Calling with contracts are disallowed");
        
        _internalMint(_msgSender());
    }

    function reserve(address to, uint256 amount) external onlyAdmins {
        require(
            CURRENT_ID + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );
        for (uint256 i = 1; i <= amount; i++) {
            CURRENT_ID++;
            _safeMint(to, CURRENT_ID);
        }
    }

    function totalSupply() public view returns (uint256) {
        return CURRENT_ID;
    }

    function setRoyaltyInfo(
        address _royalty_receiver,
        uint256 _royalty_percentage
    ) public onlyAdmins {
        ROYALTY_PERCENTAGE = _royalty_percentage;
        ROYALTY_RECEIVER = _royalty_receiver;
    }

    function setStart(uint256 _startTime) public onlyOwner {
        STARTTIME = _startTime;
    }

    function setPublicSaleState(bool _state) public onlyOwner {
        PUBLIC_SALE_ATIVE = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        MERLEROOT = _merkleRoot;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        BASE_URI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        CONTRACT_URI = uri;
    }

    function didMint(address minter) public view returns (bool) {
        return MINTTRACKER[minter];
    }

    function withdrawAll() public onlyAdmins {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < TEAM_SHARES.length; i++) {
            address wallet = TEAM[i];
            uint256 share = TEAM_SHARES[i];
            payable(wallet).transfer((balance * share) / 1000);
        }
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 1000) * ROYALTY_PERCENTAGE;
        return (ROYALTY_RECEIVER, royaltyAmount);
    }

    function changePrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function cutSupply(uint256 _supply) external onlyOwner {
        require(_supply < MAX_SUPPLY, "You can only cut supply");
        MAX_SUPPLY = _supply;
    }
}

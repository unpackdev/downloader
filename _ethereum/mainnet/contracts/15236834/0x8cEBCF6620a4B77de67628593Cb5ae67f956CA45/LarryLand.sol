pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract LarryLand is ERC721Enumerable, Ownable {
    //  Accounts
    address private constant creator0Address =
    0x2EBd45da1DC5F69F1fc7c4a874c3B074fA2AC902; // 10%
    address private constant creator1Address =
    0x683f2d8E1e34D6247Dffc93e0e2e3793970F2170; // 10%
    address private constant creator2Address =
    0xdc63A9D029fb7A5b35a5cA7Ab5633DFd525b919C; // 20%
    address private constant creator3Address =
    0x992FdE18C8A160baCB93296742D2d99A5CF66d86; // 7.5%
    address private constant creator4Address =
    0x4E9CF2DB235a9E2D9F361b1Bc4080Fc0c63eed0E; // 5%
    address private constant creator5Address =
    0xB585358e446B336CE58c564Ef2dBb7ec10234d38; // 20%
    address private constant creator6Address =
    0x2A1DA3822B205C6Cf466af20f70C5A96fa8852b8; // 15%
    address private constant creator7Address =
    0x0e93964a9A056F20B0ADd941EF8f4ED9714B108d; // 12.5%

    // Minting Variables
    uint256 public maxSupply = 1111;
    uint256 public mintPrice = 0.10 ether;
    uint256 public maxPurchase = 5;

    // Sale Status
    bool public presaleActive;
    bool public raffleSaleActive;
    bool public publicSaleActive;
    bool public locked;

    // Merkle Roots
    bytes32 private modRoot;
    bytes32 private ogWhitelistRoot;
    bytes32 private whitelistRoot;
    bytes32 private raffleRoot;

    mapping(address => uint256) private mintCounts;

    // Metadata
    string _baseTokenURI;

    // Events
    event PublicSaleActivation(bool isActive);
    event PresaleActivation(bool isActive);
    event RaffleSaleActivation(bool isActive);

    constructor() ERC721("Larry In The Office", "LARO") {}

    // Merkle Proofs
    function setModRoot(bytes32 _root) external onlyOwner {
        modRoot = _root;
    }

    function setOGWhitelistRoot(bytes32 _root) external onlyOwner {
        ogWhitelistRoot = _root;
    }

    function setRaffleRoot(bytes32 _root) external onlyOwner {
        raffleRoot = _root;
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isInTree(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }

    // Minting
    function ownerMint(address _to, uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= 1111, "Exceeds max supply");

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
        }
    }

    function modMint(uint256 _count, bytes32[] calldata _proof) external {
        require(presaleActive, "Presale must be active");
        require(isInTree(msg.sender, _proof, modRoot), "Not on mod wl");
        require(
            balanceOf(msg.sender) + _count <= maxPurchase,
            "Exceeds the account's quota"
        );
        require(totalSupply() + _count <= maxSupply, "Exceeds max supply");
        require(
            mintCounts[msg.sender] + _count <= maxPurchase,
            "Exceeds the account's quota"
        );

        mintCounts[msg.sender] = mintCounts[msg.sender] + _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function ogPresaleMint(uint256 _count, bytes32[] calldata _proof)
    external
    payable
    {
        require(presaleActive, "Presale must be active");
        require(
            isInTree(msg.sender, _proof, ogWhitelistRoot),
            "Not on presale wl"
        );
        require(
            balanceOf(msg.sender) + _count <= 10,
            "Exceeds the account's quota"
        );
        require(totalSupply() + _count <= maxSupply, "Exceeds max supply");
        require(
            0.10 ether * _count <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            mintCounts[msg.sender] + _count <= 10,
            "Exceeds the account's quota"
        );

        mintCounts[msg.sender] = mintCounts[msg.sender] + _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function raffleMint(uint256 _count, bytes32[] calldata _proof)
    external
    payable
    {
        require(raffleSaleActive, "RaffleSale must be active");
        require(
            isInTree(msg.sender, _proof, raffleRoot),
            "Not on raffle wl"
        );
        require(
            balanceOf(msg.sender) + _count <= maxPurchase,
            "Exceeds the account's presale quota"
        );
        require(totalSupply() + _count <= maxSupply, "Exceeds max supply");
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            mintCounts[msg.sender] + _count <= maxPurchase,
            "Exceeds the account's quota"
        );

        mintCounts[msg.sender] = mintCounts[msg.sender] + _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function mint(uint256 _count) external payable {
        require(publicSaleActive, "Sale must be active");
        require(_count <= maxPurchase, "Exceeds maximum purchase amount");
        require(
            balanceOf(msg.sender) + _count <= maxPurchase,
            "Exceeds the account's quota"
        );

        require(totalSupply() + _count <= maxSupply, "Exceeds max supply");
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            mintCounts[msg.sender] + _count <= maxPurchase,
            "Exceeds the account's quota"
        );

        mintCounts[msg.sender] = mintCounts[msg.sender] + _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // Configurations
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
        emit PresaleActivation(presaleActive);
    }

    function toggleRafflesaleStatus() external onlyOwner {
        raffleSaleActive = !raffleSaleActive;
        emit RaffleSaleActivation(raffleSaleActive);
    }

    function toggleSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit PublicSaleActivation(publicSaleActive);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");

        uint256 creator1Dividend = ((balance / 100) * 10);
        uint256 creator0Dividend = ((balance / 100) * 10);
        uint256 creator2Dividend = ((balance / 100) * 20);
        uint256 creator3Dividend = ((balance / 100) * 7) + (balance / 200);
        uint256 creator4Dividend = ((balance / 100) * 5);
        uint256 creator5Dividend = ((balance / 100) * 20);
        uint256 creator6Dividend = ((balance / 100) * 15);

        payable(creator0Address).transfer(creator0Dividend);
        payable(creator1Address).transfer(creator1Dividend);
        payable(creator2Address).transfer(creator2Dividend);
        payable(creator3Address).transfer(creator3Dividend);
        payable(creator4Address).transfer(creator4Dividend);
        payable(creator5Address).transfer(creator5Dividend);
        payable(creator6Address).transfer(creator6Dividend);
        payable(creator7Address).transfer(address(this).balance);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!locked, "Contract metadata methods are locked");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}

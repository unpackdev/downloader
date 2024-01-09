pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract MetaColonialists is ERC721Enumerable, Ownable {
    //  Accounts
    address private constant creator0Address =
        0xEf27AA93c2906472E880e99f65B408dFEE1124F3;
    address private constant creator1Address =
        0xbAD9802234df34D56f2081B5e00572dEc75156e5;
    address private constant creator2Address =
        0x43cc5BEA362cAffa79d56873Ba9EDb6c01dB5281;

    // Minting Variables
    uint256 public maxSupply = 8872;
    uint256 public mintPrice = 0.15 ether;
    uint256 public maxPurchase = 2;

    // Sale Status
    bool public presaleActive;
    bool public raffaleSaleActive;
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

    constructor() ERC721("Meta Colonialists", "MC") {}

    // Merkle Proofs
    function setModRoot(bytes32 _root) external onlyOwner {
        modRoot = _root;
    }

    function setOGWhitelistRoot(bytes32 _root) external onlyOwner {
        ogWhitelistRoot = _root;
    }

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
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
        require(totalSupply() + _count <= 8888, "Exceeds max supply");

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
            balanceOf(msg.sender) + _count <= 3,
            "Exceeds the account's quota"
        );
        require(totalSupply() + _count <= maxSupply, "Exceeds max supply");
        require(
            0.14 ether * _count <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            mintCounts[msg.sender] + _count <= 3,
            "Exceeds the account's quota"
        );

        mintCounts[msg.sender] = mintCounts[msg.sender] + _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function presaleMint(uint256 _count, bytes32[] calldata _proof)
        external
        payable
    {
        require(presaleActive, "Presale must be active");
        require(
            isInTree(msg.sender, _proof, whitelistRoot),
            "Not on presale wl"
        );
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

    function raffleMint(uint256 _count, bytes32[] calldata _proof)
        external
        payable
    {
        require(raffaleSaleActive, "RaffaleSale must be active");
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
        raffaleSaleActive = !raffaleSaleActive;
        emit RaffleSaleActivation(raffaleSaleActive);
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

        uint256 creator1Dividend = (balance / 100) * 25;
        uint256 creator2Dividend = ((balance / 100) * 5) + (balance / 400);

        payable(creator1Address).transfer(creator1Dividend);
        payable(creator2Address).transfer(creator2Dividend);
        payable(creator0Address).transfer(address(this).balance);
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
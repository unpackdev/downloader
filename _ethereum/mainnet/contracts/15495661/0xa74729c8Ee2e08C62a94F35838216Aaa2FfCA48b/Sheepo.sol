// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Sheepo is ERC721A, Ownable {

    event LuckySheepo(address minter, uint32 amount);

    enum EPublicMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;

    struct LuckSheepo {
        address luckuser;
        uint64 luckuseramount;
    }

    LuckSheepo[] public luckSheepoList;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public immutable maxSupply = 4444;
    uint256 public publicSalePrice;
    mapping(address => bool) public allowListResult;
    bytes32 private _merkleRoot;
    uint32 public luckSheepoMinted;
    uint32 public immutable luckSheepoSupply = 500;

    constructor(
        string memory _baseTokenURI,
        bytes32 _MerkleRoot,
        uint _publicSalePrice
    ) ERC721A ("Sheepo Club", "Sheepo") {
        baseTokenURI = _baseTokenURI;
        _merkleRoot = _MerkleRoot;
        publicSalePrice = _publicSalePrice;
        _safeMint(_msgSender(), 1);
    }

    modifier callerIsUserAndMintCheck(uint256 amount) {
        require(tx.origin == msg.sender, "Must from real wallet address");
        require(totalSupply() + amount <= maxSupply, "Exceed supply");
        require(amount <= 20, "Invalid quantity");
        _;
    }

    function mint(uint256 amount) external callerIsUserAndMintCheck(amount) payable {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        uint32 _remainFreeAmount = 0;
        uint32 quota = luckSheepoSupply - luckSheepoMinted;
        if (quota > 0) {
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(
                    msg.sender,
                    totalSupply(),
                    block.difficulty,
                    block.timestamp)));

            for (uint256 i = 0; i < amount && quota > 0;) {
                if (uint16((randomSeed & 0xFFFF) % 4000) < quota) {
                    _remainFreeAmount += 1;
                    quota -= 1;
                }

            unchecked {
                i++;
                randomSeed = randomSeed >> 16;
            }
            }

            if (_remainFreeAmount > 0) {
                luckSheepoMinted += _remainFreeAmount;
                luckSheepoList.push(LuckSheepo(msg.sender, _remainFreeAmount));
                emit LuckySheepo(msg.sender, _remainFreeAmount);
            }
        }

        uint256 _needPayPrice = 0;
        if (amount >= _remainFreeAmount) {
            _needPayPrice = (amount - _remainFreeAmount) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        (bool success,) = msg.sender.call{value : msg.value - _needPayPrice}("");
        require(success, "Transfer failed.");
        _safeMint(msg.sender, amount);
    }

    function allowListMint(bytes32[] calldata merkleProof, uint256 amount) external callerIsUserAndMintCheck(amount) payable {
        require(publicMintStatus == EPublicMintStatus.ALLOWLIST_MINT || publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Allowlist sale closed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid merkle proof");
        require(!allowListResult[msg.sender], "This address has been allowlisted mint");

        uint32 _remainFreeAmount = 1;
        uint32 quota = luckSheepoSupply - luckSheepoMinted;
        if (quota > 0) {
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(
                    msg.sender,
                    totalSupply(),
                    block.difficulty,
                    block.timestamp)));

            for (uint256 i = 0; i < amount - 1 && quota > 0;) {
                if (uint16((randomSeed & 0xFFFF) % 4000) < quota) {
                    _remainFreeAmount += 1;
                    quota -= 1;
                }

            unchecked {
                i++;
                randomSeed = randomSeed >> 16;
            }
            }

            if (_remainFreeAmount > 0) {
                luckSheepoMinted += _remainFreeAmount;
                luckSheepoList.push(LuckSheepo(msg.sender, _remainFreeAmount));
                emit LuckySheepo(msg.sender, _remainFreeAmount);
            }
        }

        uint256 _needPayPrice = 0;
        if (amount >= _remainFreeAmount) {
            _needPayPrice = (amount - _remainFreeAmount) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        (bool success,) = msg.sender.call{value : msg.value - _needPayPrice}("");
        require(success, "Transfer failed.");

        allowListResult[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }


    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function GetLuckSheepoList() public view virtual returns (LuckSheepo[]  memory) {
        LuckSheepo[] memory lucklist = luckSheepoList;
        return lucklist;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function devMint(address[] memory airdropaddress, uint256[] memory airdropamount) public payable onlyOwner {
        for (uint256 i = 0; i < airdropaddress.length; i++) {
            require(totalSupply() + airdropamount[i] <= maxSupply, "Exceed supply");
            _safeMint(airdropaddress[i], airdropamount[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

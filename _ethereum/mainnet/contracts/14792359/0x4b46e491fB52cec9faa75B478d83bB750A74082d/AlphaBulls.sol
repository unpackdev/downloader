// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

contract AlphaBulls is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
  
    string _baseTokenURI;
    uint256 public reserved = 50;
    uint256 public presale_price = 0.055 ether;
    uint256 public sale_price = 0.077 ether;
    uint256 public saleLimit = 10;
    uint256 public presaleLimit = 2;
    uint256 private maxSupply = 7000;
    uint256 private _currentId;
    bool public isPresaleActive = false; //true
    bool public isSaleActive = false; // true
    mapping(address => bool) private whitelistClaimed;

    bytes32 public merkleRoot;

    constructor() ERC721("Alpha Bulls", "AB") {
        merkleRoot = 0x04c52c6e4bb467e34fa08e2ef10084d7ded1a3500c0e2c32f207ba88fc093710;
    }

    function saleMint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(isSaleActive, "Sale is not active");
        require(
            num <= saleLimit,
            "You can mint a maximum of 10 alpha bulls per transaction"
        );
        require(supply + num < maxSupply + 1 - reserved, "Exceeds supply");
        require(msg.value >= sale_price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function presaleMint(uint256 num, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 supply = totalSupply();
        require(isPresaleActive, "Presale is not active");
        require(!whitelistClaimed[msg.sender], "Already minted on whitelist!");
        require(num <= presaleLimit, "You can mint a maximum of 2 alpha bulls!");
        require(supply + num <= maxSupply - reserved, "Exceeds supply!");
        require(msg.value >= presale_price * num, "Ether sent is not correct!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Not on whitelist!");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
        whitelistClaimed[msg.sender] = true;
    }

    function walletOfOwner(address _owner)
        external
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

    function setRootHash(bytes32 _hash) public onlyOwner {
        merkleRoot = _hash;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presale_price = _newPrice;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        sale_price = _newPrice;
    }

    function setReserved(uint256 _newReserved) public onlyOwner {
        reserved = _newReserved;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintReserved(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= reserved, "Exceeds reserved Alpha Bulls supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        reserved -= _amount;
    }

    function setPresale(bool val) public onlyOwner {
        isPresaleActive = val;
    }

    function setSale(bool val) public onlyOwner {
        isSaleActive = val;
    }

    function withdrawAll() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : ""; 
    }
}

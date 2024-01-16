// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract CoffeeBeansClub is ERC721Enumerable, Ownable {
    uint256 public MAX_AMOUNT = 888;
    bool public _saleIsActive = false;
    uint256 public _listing_price = 0.1 ether;
    bytes32 private _root;
    string private _nftBaseURI;

    mapping(address => bool) public _claimed;

    constructor() ERC721("CoffeeBeansClub", "CBC") {}

    function setRoot(bytes32 root_) public onlyOwner {
        _root = root_;
    }

    function setBaseURI(string calldata nftBaseURI_) public onlyOwner {
        _nftBaseURI = nftBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _nftBaseURI;
    }

    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function setListingPrice(uint256 listing_price_) public onlyOwner {
        _listing_price = listing_price_;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mint(uint256 amount_) public payable {
        require(_saleIsActive, "Sale is not open");
        require(totalSupply() + amount_ <= MAX_AMOUNT, "Supply is limited");
        require(
            msg.value >= (_listing_price * amount_),
            "Not enough funds submitted"
        );

        uint id = totalSupply();
        for (uint i = 0; i < amount_; i++) {
            id++;
            _safeMint(msg.sender, id);
        }
    }

    function airdropMany(address[] memory addr_) public onlyOwner {
        require(
            totalSupply() + addr_.length <= MAX_AMOUNT,
            "Supply is limited"
        );

        uint id = totalSupply();
        for (uint i = 0; i < addr_.length; i++) {
            id++;
            _safeMint(addr_[i], id);
        }
    }

    function claim(bytes32[] calldata proof_) public {
        require(_saleIsActive, "Sale is not open");
        require(totalSupply() + 1 <= MAX_AMOUNT, "Supply is limited");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof_, _root, leaf), "Invalid proof");

        require(!_claimed[msg.sender], "You already claimed");

        _claimed[msg.sender] = true;
        uint id = totalSupply();
        id++;
        _safeMint(msg.sender, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721APlayground.sol";
import "./MerkleProof.sol";

contract PlaygroundGenesis is ERC721APlayground, Ownable {
    uint256 public constant SUPPLY = 5550;
    uint256 public constant SUPPLY_CHARITY = 5;
    uint256 public constant MAX_SUPPLY = SUPPLY + SUPPLY_CHARITY;
    uint256 public CHARITY_MINTED;
    
    struct Variables {
        uint64 PRESALE_PRICE;
        uint64 PUBLIC_PRICE;
        uint64 MAX_MINT;
    }

    Variables public variables;

    string public baseTokenURI;
    string public baseContractURI;

    mapping(address => uint256) public wlPurchaseCount;
    mapping(uint256 => bytes32) public merkleRoot;

    constructor(string memory baseURI) ERC721APlayground("Playground Genesis", "PGG") {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function presaleMint(uint256 _qty, uint256 _max, uint256 _cid, bytes32[] calldata _merkleProof) external payable {
        require(variables.PRESALE_PRICE > 0, "Presale closed");

        // Verify proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot[_cid], leaf), "Invalid Proof");

        require(_qty > 0 && _qty <= _max, "Invalid qty");
        require(wlPurchaseCount[msg.sender] + _qty <= _max, "Max qty");
        require(wlPurchaseCount[msg.sender] + _qty <= variables.MAX_MINT, "Max mint");
        require(totalSupply() + _qty <= SUPPLY, "No more supply");
        require(msg.value >= variables.PRESALE_PRICE * _qty, "Invalid value");

        wlPurchaseCount[msg.sender] += _qty;

        _safeMint(msg.sender, _qty);
    }

    function publicMint(uint256 _qty) external payable {
        require(variables.PUBLIC_PRICE > 0, "Public sale closed");
        require(totalSupply() + _qty <= SUPPLY, "No more supply");
        require(_qty > 0 && _qty <= variables.MAX_MINT, "Max mint");
        require(msg.value >= variables.PUBLIC_PRICE * _qty, "Invalid value");

        _safeMint(msg.sender, _qty);
    }

    function gift(address[] calldata receivers, uint256[] calldata _qty) external onlyOwner {
        uint256 totalGift;
        for(uint256 q = 0; q < _qty.length; q++) { totalGift += _qty[q]; }
        require(totalSupply() + totalGift <= SUPPLY, "No more supply");

        for(uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], _qty[i]);
        }
    }

    function charityMint() external onlyOwner {
        require(CHARITY_MINTED < SUPPLY_CHARITY, "MAX");
        CHARITY_MINTED = 5;
        _safeMint(msg.sender, 5);
    }

    function setVariables(uint64 _presale, uint64 _public, uint32 _max) external onlyOwner {
        variables = Variables(
            _presale,
            _public,
            _max
        );
    }

    function setMerkleRoot(uint256 _id, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot[_id] = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        baseContractURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
}
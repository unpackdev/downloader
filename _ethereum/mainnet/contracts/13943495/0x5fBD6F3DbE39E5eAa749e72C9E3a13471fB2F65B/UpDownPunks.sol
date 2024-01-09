// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract UpDownPunks is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor (string memory customBaseURI_) ERC721("UpDownPunks", "UDP") {
        customBaseURI = customBaseURI_;
    }

    /** MINTING LIMITS **/

    mapping(address => uint256) private mintCountMap;

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    /** MINTING **/

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant MAX_MULTIMINT = 20;

    uint256 public PRICE = 25000000000000000;
    bytes32 public merkleRoot = 0xb10bee52e63487393acb5bdabcfc3ac9327860e0c7c90d0a612003ef527deeb3;

    Counters.Counter private supplyCounter;

    function mint(uint256 count, bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(saleIsActive, "Sale not active");

        uint256 price = PRICE * count;

        if (mintCountMap[msg.sender] == 0) {
            if (totalSupply() < 500) {
                price -= PRICE;
            } else {
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
                    price -= PRICE;
                }
            }
        }

        updateMintCount(_msgSender(), count);

        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

        require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

        require(
            msg.value >= price, "Insufficient payment, 0.025 ETH per item"
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), totalSupply());

            supplyCounter.increment();
        }
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function mintCount(address addr) public view returns (uint256) {
        return mintCountMap[addr];
    }

    /** ACTIVATION **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /** URI HANDLING **/

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
    0xa297FBf6acEBD178221249b8342EbdB1C7BCbC24;

    address private constant payoutAddress2 =
    0x9f9F9c9F470B52044f86Cb299332E4d869Ab574A;

    address private constant payoutAddress3 =
    0xd59d10f5a49D6C8EC097E007a1782087cFB4b988;

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance / 3);

        Address.sendValue(payable(payoutAddress2), balance / 3);

        Address.sendValue(payable(payoutAddress3), balance / 3);
    }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 500) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
    {
        return (
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }
}

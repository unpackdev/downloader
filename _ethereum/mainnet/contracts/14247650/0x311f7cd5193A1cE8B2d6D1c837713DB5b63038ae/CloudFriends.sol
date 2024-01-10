//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

/**
  ░█████╗░██╗░░░░░░█████╗░██╗░░░██╗██████╗░  ███████╗██████╗░██╗███████╗███╗░░██╗██████╗░░██████╗
  ██╔══██╗██║░░░░░██╔══██╗██║░░░██║██╔══██╗  ██╔════╝██╔══██╗██║██╔════╝████╗░██║██╔══██╗██╔════╝
  ██║░░╚═╝██║░░░░░██║░░██║██║░░░██║██║░░██║  █████╗░░██████╔╝██║█████╗░░██╔██╗██║██║░░██║╚█████╗░
  ██║░░██╗██║░░░░░██║░░██║██║░░░██║██║░░██║  ██╔══╝░░██╔══██╗██║██╔══╝░░██║╚████║██║░░██║░╚═══██╗
  ╚█████╔╝███████╗╚█████╔╝╚██████╔╝██████╔╝  ██║░░░░░██║░░██║██║███████╗██║░╚███║██████╔╝██████╔╝
  ░╚════╝░╚══════╝░╚════╝░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚═╝░░╚══╝╚═════╝░╚═════╝░
 * @title Cloud Friends NFT
 * @notice This contract provides minting for the Cloud Friends NFT by twitter.com/cloudfriendsnft
 */
contract CloudFriends is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol) 
        ERC721A(
            name,
            symbol
        ) {}

    bool public preSaleActive;
    bool public publicSaleActive;
    bool public isSaleHalted;
    bool private ownerSupplyMinted;

    uint16 private constant MAX_SUPPLY = 5000;
    uint16 private constant OWNER_SUPPLY = 20;
    uint16 private constant BASIS_POINTS = 1000;

    bytes32 public merkleRoot = 0x6ee518a974b0f0ac03db611933291bb31d03f08177f90918200a26a6b7227230;

    uint256 private constant MAX_MULTI_MINT_AMOUNT = 5;
    uint256 public constant PRICE = 0.09 ether;

    uint256 private preSaleLaunchTime = 1645462800;
    uint256 private publicSaleLaunchTime = 1645549200;

    address[] private payouts = [
        0x2CF02A038e8BD166F49749AE060FE36927CA3671, // D
        0x7EACE3693dA5d648d84ed2D89b102746A53Ad478, // AOEXC
        0x605207dF50255986758462EE949ef41Bf5BE54Db, // AOEXO
        0x64948705f2479404312F75123bd6040d1BD2dDdC, // C
        0x074288df29385D8f822961855E2681dfc055E450  // M
    ];

    uint16[] private cuts = [
        200,
        255,
        255,
        90,
        200
    ];

    mapping (address => uint256) private allowListMints;

    string public baseTokenURI = "https://arweave.net/TBD/";

    function _genMerkleLeaf(address account, uint256 mints) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, mints));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPreSaleState(bool _preSaleActiveState) external onlyOwner {
        preSaleActive = _preSaleActiveState;
    }

    function setPublicSaleState(bool _publicSaleActiveState) external onlyOwner {
        publicSaleActive = _publicSaleActiveState;
    }

    function setPreSaleTime(uint32 _time) external onlyOwner {
        preSaleLaunchTime = _time;
    }

    function setPublicSaleTime(uint32 _time) external onlyOwner {
        publicSaleLaunchTime = _time;
    }

    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) external onlyOwner {
        isSaleHalted = _saleHaltedState;
    }

    function isPreSaleActive() public view returns (bool) {
        return ((block.timestamp >= preSaleLaunchTime || preSaleActive) && !isSaleHalted);
    }

    function isPublicSaleActive() public view returns (bool) {
        return ((block.timestamp >= publicSaleLaunchTime || publicSaleActive) && !isSaleHalted);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function mintOwnerSupply(address addr) public nonReentrant onlyOwner {
        require(!ownerSupplyMinted, "OWNER_MINT_COMPLETED");
        require(totalSupply() + OWNER_SUPPLY <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        _safeMint(addr, OWNER_SUPPLY);
        ownerSupplyMinted = true;
    }

    /**
     * @notice Allow public to bulk mint tokens
     */
    function mint(uint256 numberOfMints, bytes memory data) public payable nonReentrant {
        if (isPreSaleActive() && !isPublicSaleActive()) {
            require(data.length != 0, "NOT_PRESALE_ELIGIBLE");
            (address addr, uint256 mintAllocation, bytes32[] memory proof) = abi.decode(data, (address, uint256, bytes32[]));
            require(MerkleProof.verify(proof, merkleRoot, _genMerkleLeaf(msg.sender, mintAllocation)), "INVALID_PROOF");
            require(addr == msg.sender, "INVALID_SENDER");
            require(numberOfMints + allowListMints[msg.sender] <= mintAllocation, "PRESALE_LIMIT_REACHED");
        } else {
            require(isPublicSaleActive(), "SALE_NOT_ACTIVE");
            require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "TOO_LARGE_PER_TX");
        }

        require(totalSupply() + numberOfMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        require(msg.value >= PRICE * numberOfMints, "INVALID_PRICE");

        _safeMint(msg.sender, numberOfMints);

        if (isPreSaleActive() && !isPublicSaleActive()) {
            allowListMints[msg.sender] += numberOfMints;
        }
    }

    function withdrawProceeds() external onlyOwner nonReentrant {
        uint256 value = address(this).balance;
        for (uint256 i = 0; i < payouts.length; i++) {
            uint256 payout = (value * cuts[i]) / BASIS_POINTS;
            payable(payouts[i]).transfer(payout);
        }
    }
}

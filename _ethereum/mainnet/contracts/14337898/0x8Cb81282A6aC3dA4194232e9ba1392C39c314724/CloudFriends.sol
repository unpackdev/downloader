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
    bool private teamSupplyMinted;

    uint16 private constant MAX_SUPPLY = 5000;
    uint16 private constant TEAM_SUPPLY = 500;
    uint16 private constant BASIS_POINTS = 1000;

    bytes32 public merkleRoot = 0xdc15d84b0bc0c7ae8e747549a21f05c7d0f8c5418f1faaa8119f0f4d6148bd93;

    uint256 private constant MAX_MULTI_MINT_AMOUNT = 10;
    uint256 private constant MAX_COMPANION_MINTS = 3;
    uint256 private constant COMPANION_MINT_THRESHOLD = 0.03 ether;
    uint256 private maxMintPerWallet = 10;

    uint256 private preSaleLaunchTime = 1646773200;
    uint256 private publicSaleLaunchTime = 1646776800;

    mapping (address => uint256) public companionMints;
    mapping (address => uint256) private mintsTracker;

    address[] private payouts = [
        0x7C45Fc2C517BB6dDea0eaeA9302e5f62C9B645Cf, // D
        0x605207dF50255986758462EE949ef41Bf5BE54Db, // AO
        0x64948705f2479404312F75123bd6040d1BD2dDdC, // C
        0x074288df29385D8f822961855E2681dfc055E450  // T
    ];

    uint16[] private cuts = [
        200,
        510,
        90,
        200
    ];

    address[] private teamPayouts = [
        0x7C45Fc2C517BB6dDea0eaeA9302e5f62C9B645Cf, // D
        0x11d2aeB6293f821c68fA59fba94A5106ceb48d99, // AO
        0x64948705f2479404312F75123bd6040d1BD2dDdC, // C
        0x074288df29385D8f822961855E2681dfc055E450  // T
    ];

    uint16[] private teamAmounts = [
        63,
        124,
        63,
        250
    ];

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

    function setMaxMintPerWallet(uint256 _amount) external onlyOwner {
        maxMintPerWallet = _amount;
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

    /**
    Mints the team and treasury supply
     */
    function mintTeamSupply() public nonReentrant onlyOwner {
        require(!teamSupplyMinted, "TEAM_MINT_COMPLETED");
        require(totalSupply() + TEAM_SUPPLY <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < teamPayouts.length; i++) {
            _safeMint(teamPayouts[i], teamAmounts[i]);
        }
        teamSupplyMinted = true;
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
            require(numberOfMints + mintsTracker[msg.sender] <= mintAllocation, "PRESALE_LIMIT_REACHED");
        } else {
            require(isPublicSaleActive(), "SALE_NOT_ACTIVE");
            require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "TOO_LARGE_PER_TX");
            require(numberOfMints + mintsTracker[msg.sender] <= maxMintPerWallet, "TOO_LARGE_PER_WALLET");
        }

        require(msg.sender == tx.origin, "NO_CONTRACTS");
        require(totalSupply() + numberOfMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        _safeMint(msg.sender, numberOfMints);
        mintsTracker[msg.sender] += numberOfMints;

        _processCompanionMints(msg.sender, msg.value);
    }

    function _processCompanionMints(address addr, uint256 value) internal {
        uint256 remainingCompanionMints = MAX_COMPANION_MINTS - companionMints[addr];
        if (remainingCompanionMints == 0) {
            return;
        }

        if (value >= COMPANION_MINT_THRESHOLD * 3) {
            uint256 mints = 3 >= remainingCompanionMints ? remainingCompanionMints : 3;
            companionMints[addr] += mints;
        } else if (value >= COMPANION_MINT_THRESHOLD * 2) {
            uint256 mints = 2 >= remainingCompanionMints ? remainingCompanionMints : 2;
            companionMints[addr] += mints;
        } else if (value >= COMPANION_MINT_THRESHOLD) {
            uint256 mints = 1 >= remainingCompanionMints ? remainingCompanionMints : 1;
            companionMints[addr] += mints;
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

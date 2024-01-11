// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


//  ___  _  _  _____  _____  ____  __    ____  ___ 
// / __)( \( )(  _  )(  _  )(_   )(  )  ( ___)/ __)
// \__ \ )  (  )(_)(  )(_)(  / /_  )(__  )__) \__ \
// (___/(_)\_)(_____)(_____)(____)(____)(____)(___/
// Snoozles OG Membership Passes
// Creator: ROΞCKS

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SnoozlesOGs is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant MAX_MINT = 1;
    uint256 public constant SALE_PRICE = 0.00 ether;
    uint256 public constant START_AT = 1;

    uint256 public CURRENT_SUPPLY = 600;

    address payable public payableWallet;
    address payable public foundationWallet;
    address payable public communityWallet;

    string private baseTokenUri;
    string public placeholderTokenUri;

    bool public publicSale;
    bool public SnoozlesSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private SnoozlesMerkleRoot;

    mapping(address => uint256) public totalMint;

    constructor() ERC721A("Snoozles OG Membership Pass", "SNZLSPASS") {
        
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Snoozles OG Membership Pass :: not available to contracts");
        _;
    }

    // mint functions
    function mint() external payable callerIsUser {
        require(!pause, "Snoozles OG Membership Pass mint has been paused.");
        require(publicSale, "Snoozles OG Membership Pass :: Coming soon.");
        require((totalSupply() + 1) <= MAX_SUPPLY, "Out of Snoozles OG Membership Passes.");
        require((totalMint[msg.sender] + 1) <= MAX_MINT, "Only one Snoozles OG Membership Pass per member.");
        require(msg.value >= SALE_PRICE, "Attribute some value for a Snoozles OG Membership Pass.");

        totalMint[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function SnoozlesMint(bytes32[] memory _merkleProof) external payable callerIsUser {
        require(!pause, "Snoozles OG Membership Pass mint has been paused.");
        require(SnoozlesSale, "OG minting is paused.");
        require((totalSupply() + 1) <= MAX_SUPPLY, "Out of Snoozles OG Membership Passes.");
        require((totalSupply() + 1) <= CURRENT_SUPPLY, "Temporarily out of Snoozles OG Membership Passes.");
        require((totalMint[msg.sender] + 1) <= MAX_MINT, "Only one Snoozles OG Membership Pass per member.");
        require(msg.value >= SALE_PRICE, "Attribute some value for a Snoozles OG Membership Pass.");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, SnoozlesMerkleRoot, sender), "Not on the Snoozles OG or waiting list.");

        totalMint[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "The Snoozles Team already minted.");
        teamMinted = true;
        _safeMint(msg.sender, 100);
    }

    function reservePasses(uint256 count) external onlyOwner {
        require((totalSupply() + 1) <= MAX_SUPPLY, "Out of Snoozles OG Membership Passes.");
        require((totalSupply() + 1) <= CURRENT_SUPPLY, "Temporarily out of Snoozles OG Membership Passes.");

        totalMint[msg.sender] += 1;
        _safeMint(owner(), count);
    }

    function airdropReservedPasses(address[] calldata to, uint256[] calldata tokenIds) external onlyOwner {
        unchecked {
            uint256 arraySize = to.length;
            uint256 index;
            for(index = 0; index < arraySize; index++) {
                transferFrom(owner(), to[index], tokenIds[index]);
            }
        }
    }

    function setCurrentSupply(uint256 _supply) external onlyOwner {
        CURRENT_SUPPLY = _supply;
    }

    function getCurrentSupply() external view returns (uint256) {
        return CURRENT_SUPPLY;
    }

    // base and token URI's

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        uint256 trueId = tokenId + 1;
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    // merkleroot

    function setSnoozlesMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        SnoozlesMerkleRoot = _merkleRoot;
    }

    function getSnoozlesMerkleRoot() external view returns (bytes32) {
        return SnoozlesMerkleRoot;
    }

    // toggles 

    function togglePause() external onlyOwner {
        pause = !pause;
    }
    function toggleSnoozlesSale() external onlyOwner {
        SnoozlesSale = !SnoozlesSale;
    }
    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function withdraw() external payable onlyOwner {

        // 10% to community wallet + foundation wallet
        uint256 withdrawAmount_10 = address(this).balance * 10/100;
        // 80% to snoozles wallet
        uint256 withdrawAmount_80 = address(this).balance * 80/100;

        // withdraw funds: Community Wallet
        communityWallet.transfer(withdrawAmount_10);
        // withdraw funds: Foundation's Treasury
        foundationWallet.transfer(withdrawAmount_10);
        // withdraw funds: Snoozles Company
        payableWallet.transfer(withdrawAmount_80);

        payable(msg.sender).transfer(address(this).balance);

    }

    function setPayableWallet(address payable _payableWallet) external onlyOwner {
        payableWallet = _payableWallet;
    }
    function setFoundationWallet(address payable _foundationWallet) external onlyOwner {
        foundationWallet = _foundationWallet;
    }
    function setCommunityWallet(address payable _communityWallet) external onlyOwner {
        communityWallet = _communityWallet;
    }

}
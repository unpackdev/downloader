// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @author mpoplavkov https://github.com/mpoplavkov

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

/// @custom:security-contact wagmi@nftpulse.app
contract NftPulseAngelToken is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant RESERVED_AMOUNT_FOR_DEVS = 49;
    uint256 public constant MINT_PRICE = 0.15 ether;
    uint256 public constant MAX_MINT_AMOUNT_PER_TRANSACTION = 10;
    uint256 public constant MAX_MINT_AMOUNT_PER_WHITELIST = 3;

    uint256 public preSaleStartDate = 1649512800; // Saturday, April 9, 2022 14:00:00 GMT
    uint256 public publicSaleStartDate = 1649534400; // Saturday, April 9, 2022 20:00:00 GMT
    mapping(address => uint256) public whitelistMinted;

    uint256 private teamSize;
    string private _baseTokenURI = "https://api.nftpulse.app/angeltoken/metadata/";

    // Whitelist
    bytes32 public merkleRoot;

    enum MintStatus {
        CLOSED,
        PRESALE,
        PUBLIC,
        FINISHED
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        address[] memory _team,
        uint256[] memory _shares,
        bytes32 _merkleRoot
    ) ERC721A("Pulse App Lifetime Access", "NFTPULSE") PaymentSplitter(_team, _shares) {
        updateMerkleRoot(_merkleRoot);
        teamSize = _team.length;
        // developer tokens mint
        _safeMint(msg.sender, RESERVED_AMOUNT_FOR_DEVS);
    }

    function verifyWhitelist(address addr, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(addr)));
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable callerIsUser nonReentrant {
        require(preSaleStarted(), "Presale has not started yet");
        require(verifyWhitelist(msg.sender, proof), "Not in the whitelist");
        incrementMintedAmountForWhitelist(quantity);
        mintCheckConditions(quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser nonReentrant {
        require(publicSaleStarted(), "Public sale has not started yet");
        mintCheckConditions(quantity);
    }

    function mintStatus() external view returns (MintStatus) {
        if (allTokensAreMinted()) {
            return MintStatus.FINISHED;
        }
        if (publicSaleStarted()) {
            return MintStatus.PUBLIC;
        }
        if (preSaleStarted()) {
            return MintStatus.PRESALE;
        }
        return MintStatus.CLOSED;
    }

    function releaseAll() external nonReentrant {
        for (uint256 i = 0; i < teamSize; i++) {
            release(payable(payee(i)));
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function preSaleStarted() private view returns (bool) {
        return block.timestamp >= preSaleStartDate;
    }

    function publicSaleStarted() private view returns (bool) {
        return block.timestamp >= publicSaleStartDate;
    }

    function allTokensAreMinted() private view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }

    function incrementMintedAmountForWhitelist(uint256 quantity) private {
        uint256 newMintedAmount = whitelistMinted[msg.sender] + quantity;
        require(newMintedAmount <= MAX_MINT_AMOUNT_PER_WHITELIST, "Reached the mint limit for whitelist");
        whitelistMinted[msg.sender] = newMintedAmount;
    }

    function mintCheckConditions(uint256 quantity) private {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        if (msg.sender != owner()) {
            require(quantity <= MAX_MINT_AMOUNT_PER_TRANSACTION, "Too many tokens requested in a single transaction");
            require(msg.value == MINT_PRICE * quantity, "Wrong ether amount");
        }
        _safeMint(msg.sender, quantity);
    }

    function checkSaleDatesOrder() private view {
        require(preSaleStartDate < publicSaleStartDate, "Presale should start before the public sale");
    }

    // ONLY OWNER FUNCTIONS BELOW

    function renounceOwnership() public override onlyOwner {
        require(allTokensAreMinted(), "Mint is not finished yet");
        require(address(this).balance == 0, "Ownership can be renounced only if the contract balance is 0");
        super.renounceOwnership();
    }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreSaleStartDate(uint256 _preSaleStartDate) external onlyOwner {
        preSaleStartDate = _preSaleStartDate;
        checkSaleDatesOrder();
    }

    function setPublicSaleStartDate(uint256 _publicSaleStartDate) external onlyOwner {
        publicSaleStartDate = _publicSaleStartDate;
        checkSaleDatesOrder();
    }
}

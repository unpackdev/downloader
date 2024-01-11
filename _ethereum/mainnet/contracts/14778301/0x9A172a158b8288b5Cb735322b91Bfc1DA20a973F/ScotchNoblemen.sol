// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract ScotchNoblemen is ERC721A, Ownable, ReentrancyGuard {
    // Immutable Values
    uint256 public immutable MAX_SUPPLY = 10001;
    uint256 public OWNER_MINT_MAX_SUPPLY = 200; // If not minted can be utilized by public mint
    uint256 public WHITELIST_MAX_SUPPLY = 3000; // If not minted can be utilized by public mint

    string internal baseUri;
    uint256 public mintRate;
    uint256 public maxMintLimit = 10;
    bool public publicMintPaused = true;

    // Reveal NFT Variables
    bool public revealed;
    string public hiddenBaseUri;

    // Whitelist Variables
    using MerkleProof for bytes32[];
    bool public whitelistMintPaused;
    uint256 public whitelistMintRate;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxItemsPerWhiteListedWallet = 3;
    mapping(address => uint256) public whitelistMintedAmount;

    struct BatchMint {
        address to;
        uint256 amount;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _hiddenBaseUri,
        uint256 _mintRate,
        uint256 _whitelistMintRate,
        bytes32 _whitelistMerkleRoot
    ) ERC721A(_name, _symbol) {
        mintRate = _mintRate;
        hiddenBaseUri = _hiddenBaseUri;
        whitelistMintRate = _whitelistMintRate;
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // ===== Owner mint =====
    function ownerMint(address to, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(
            amount <= OWNER_MINT_MAX_SUPPLY,
            "Minting amount exceeds reserved supply"
        );
        require((totalSupply() + amount) <= MAX_SUPPLY, "Sold out!");
        _safeMint(to, amount);
        OWNER_MINT_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - amount;
    }

    // ===== Owner mint in batches =====
    function ownerMintInBatch(BatchMint[] memory batchMint)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < batchMint.length; i++) {
            require(
                batchMint[i].amount <= OWNER_MINT_MAX_SUPPLY,
                "Minting amount exceeds reserved supply"
            );
            require(
                (totalSupply() + batchMint[i].amount) <= MAX_SUPPLY,
                "Sold out!"
            );
            _safeMint(batchMint[i].to, batchMint[i].amount);
            OWNER_MINT_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - batchMint[i].amount;
        }
    }

    // ===== Public mint =====
    function mint() external payable {
        require(!publicMintPaused, "Public mint is paused");
        uint256 quantity = _getMintQuantity(msg.value, true);
        require(
            quantity <= maxMintLimit,
            "The number of quantity is not between the allowed nft mint range."
        );
        _safeMint(msg.sender, quantity);
    }

    // ===== Whitelist mint =====
    function whitelistMint(bytes32[] memory proof)
        external
        payable
        nonReentrant
    {
        require(!whitelistMintPaused, "Whitelist mint is paused");
        require(
            isAddressWhitelisted(proof, msg.sender),
            "You are not eligible for a whitelist mint"
        );

        uint256 amount = _getMintQuantity(msg.value, false);

        require(WHITELIST_MAX_SUPPLY >= amount, "Whitelist mint is sold out");

        require(
            whitelistMintedAmount[msg.sender] + amount <=
                maxItemsPerWhiteListedWallet,
            "Minting amount exceeds allowance per wallet"
        );
        _safeMint(msg.sender, amount);

        whitelistMintedAmount[msg.sender] += amount;

        WHITELIST_MAX_SUPPLY = WHITELIST_MAX_SUPPLY - amount;
    }

    function isAddressWhitelisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function _getMintQuantity(uint256 value, bool _publicMint)
        internal
        view
        returns (uint256)
    {
        uint256 tempRate = _publicMint == true ? mintRate : whitelistMintRate;
        uint256 remainder = value % tempRate;
        require(remainder == 0, "Send a divisible amount of eth");
        uint256 quantity = value / tempRate;
        require(quantity > 0, "quantity to mint is 0");
        require(
            (totalSupply() + quantity) <= MAX_SUPPLY,
            "Not enough NFTs left!"
        );
        return quantity;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Used to get the maximum supply of tokens.
     * @return uint256 for max supply of tokens.
     */
    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Only Owner Functions
    function updateMintRate(uint256 _mintRate) public onlyOwner {
        require(_mintRate > 0, "Invalid mint rate value.");
        mintRate = _mintRate;
    }

    function updateWhitelistMintRate(uint256 _whitelistMintRate)
        public
        onlyOwner
    {
        whitelistMintRate = _whitelistMintRate;
    }

    function updateMaxMintLimit(uint256 _maxMintLimit) public onlyOwner {
        require(_maxMintLimit > 0, "Invalid max mint limit.");
        maxMintLimit = _maxMintLimit;
    }

    function updatePublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function updateWhitelistMintPaused(bool _whitelistMintPaused)
        external
        onlyOwner
    {
        whitelistMintPaused = _whitelistMintPaused;
    }

    function updateBaseTokenURI(string memory _baseTokenURI)
        external
        onlyOwner
    {
        baseUri = _baseTokenURI;
    }

    function updateHiddenBaseTokenURI(string memory _hiddenBaseTokenURI)
        external
        onlyOwner
    {
        hiddenBaseUri = _hiddenBaseTokenURI;
    }

    function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function updatemaxItemsPerWhiteListedWallet(
        uint256 _maxItemsPerWhiteListedWallet
    ) external onlyOwner {
        maxItemsPerWhiteListedWallet = _maxItemsPerWhiteListedWallet;
    }

    function updateRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return hiddenBaseUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev withdraw all eth from contract and transfer to owner.
     */
    function withdraw() public onlyOwner nonReentrant {

        uint256 contractBalance = address(this).balance; 

        (bool aa, ) = payable(0xf7CA0f33502980331065169E58f07FB5377f23Fd).call{
            value: (contractBalance * 3250) / 10000
        }("");
        require(aa);

        (bool ab, ) = payable(0x2ba983d1a3F4463B351B0B385FA65eFCA977A4BC).call{
            value: (contractBalance * 3250) / 10000
        }("");
        require(ab);

        (bool ac, ) = payable(0x6Ce62D72d9539E188493FA01314F5A5143Ad1D09).call{
            value: (contractBalance * 1500) / 10000
        }("");
        require(ac);

        (bool ad, ) = payable(0x65933182441F7786D4CdA1FC3D311921c53d7EAa).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ad);

        (bool ae, ) = payable(0xECf52bee7879b5AE0d1CFb954023D40A339C5f4B).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ae);

        (bool af, ) = payable(0x2aBa590725247c8066EaDaA5c204dD6cfde5FEc8).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(af);

        (bool ag, ) = payable(0x205763544D93E70D53956CEe75C023231A2BC9c9).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ag);

        (bool ah, ) = payable(0x3891bF5094a0ECd4157eb7729E1Da35BDAa52741).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ah);

        (bool ai, ) = payable(0xB9E95651a78907fD5Bb8Bc37Fc5138669314ED93).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ai);

        (bool aj, ) = payable(0xE0ecA13fccD3118EB99E04F644b65AF825458cA7).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(aj);

        (bool ak, ) = payable(0x432fBa58Fe37ea125600077EB0e758C4BCdAdB3c).call{
            value: (contractBalance * 200) / 10000
        }("");
        require(ak);

        (bool al, ) = payable(0x53aaf2078B08B9CFED09e812FB9c0175fbbe2217).call{
            value: (contractBalance * 400) / 10000
        }("");
        require(al);
    }
}

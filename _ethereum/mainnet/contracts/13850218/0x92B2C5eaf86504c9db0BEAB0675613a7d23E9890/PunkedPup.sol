// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.10;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IPunkedPup.sol";
import "./IShelter.sol";
import "./BONE.sol";
import "./ReentrancyGuard.sol";

contract PunkedPup is
    IPunkedPup,
    ReentrancyGuard,
    ERC721Enumerable,
    Ownable,
    Pausable
{
    struct Whitelist {
        bool isWhitelisted;
        uint16 numMinted;
    }

    // mint price
    uint256 public constant MINT_PRICE = .055 ether;
    uint256 public constant WHITELIST_PRICE = .025 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 10000 of MAX_TOKENS
    uint256 public PAID_TOKENS = 10000;
    // number of tokens for pre sale
    uint256 public PRE_SALE_TOKENS = 1500;
    // number of tokens have been minted so far
    uint16 public minted;
    // keep track of minted NFT, user can mint up to 10 NFT tokens.
    mapping(address => uint256) public _count;

    // reference to the Shelter for choosing random pup thieves
    IShelter public shelter;
    // reference to $BONE for burning on mint
    BONE public bone;
    // base uri
    string public baseUri = "https://api.punkedpups.com/nftMetadata/";
    // contract uri
    string public contractUri =
        "https://api.punkedpups.com/nftCollectionMetadata/";

    mapping(uint256 => string) private _tokenURIs;

    // mint limit
    uint256 mintLimit = 10;
    // mint limit for whitelist addresses
    uint256 whitelistMintLimit = 20;
    // mapping for whitelist addresses
    mapping(address => Whitelist) private _whitelistAddresses;

    // event for minting
    event Mint(
        address indexed _to,
        uint256 indexed tokenId,
        uint8 indexed alphaIndex
    );

    /**
     * instantiates contract and rarity tables
     */
    constructor(
        address _bone,
        uint256 _maxTokens,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        bone = BONE(_bone);
        MAX_TOKENS = _maxTokens;
        _pause();
    }

    /** EXTERNAL */

    /**
     * mint a token - 90% Pup, 7.5% cat, 2.5% dog catcher
     * The first 20% are free to claim, the remaining cost $BONE
     */
    function mint(uint256 amount) external payable whenNotPaused nonReentrant {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        if (_msgSender() != owner()) {
            require(amount > 0 && amount <= 10, "Invalid mint amount");
            if (_whitelistAddresses[_msgSender()].isWhitelisted) {
                require(
                    _count[_msgSender()] + amount <= whitelistMintLimit,
                    "Exceeds mint limit"
                );
            } else {
                require(
                    _count[_msgSender()] + amount <= mintLimit,
                    "Exceeds mint limit"
                );
            }
            if (minted < PRE_SALE_TOKENS) {
                require(
                    minted + amount <= PRE_SALE_TOKENS,
                    "All tokens on-pre-sale already sold"
                );
                if (
                    _whitelistAddresses[_msgSender()].isWhitelisted &&
                    _whitelistAddresses[_msgSender()].numMinted + amount <= 10
                ) {
                    require(
                        amount * WHITELIST_PRICE == msg.value,
                        "Invalid payment amount"
                    );
                    _whitelistAddresses[_msgSender()].numMinted += uint16(
                        amount
                    );
                } else {
                    require(
                        amount * MINT_PRICE == msg.value,
                        "Invalid payment amount"
                    );
                }
            } else if (minted < PAID_TOKENS) {
                require(
                    minted + amount <= PAID_TOKENS,
                    "All tokens on-sale already sold"
                );
                require(
                    amount * MINT_PRICE == msg.value,
                    "Invalid payment amount"
                );
            } else {
                require(msg.value == 0);
            }
        }

        uint256 totalBoneCost = 0;
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            uint8 alphaIndex = uint8(randomWithRange(seed, 5)) + 1;
            _safeMint(address(shelter), minted);
            _count[_msgSender()]++;
            emit Mint(address(shelter), minted, alphaIndex);
            tokenIds[i] = minted;
            totalBoneCost += mintCost(minted);
        }

        if (totalBoneCost > 0) bone.burn(_msgSender(), totalBoneCost);
        shelter.addManyToShelterAndPack(_msgSender(), tokenIds);
    }

    /**
     * the first 10000 are paid in ETH
     * the next 10000 are 20000 $BONE
     * the final 10000 are 40000 $BONE
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= 20000) return 20000 ether;
        return 40000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Shelter's approval so that users don't have to waste gas approving
        if (_msgSender() != address(shelter))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _msgSender(),
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number with range
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function randomWithRange(uint256 seed, uint256 mod)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _msgSender(),
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            ) % mod;
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random pup thieves
     * @param _shelter the address of the Shelter
     */
    function setShelter(address _shelter) external onlyOwner {
        shelter = IShelter(_shelter);
    }

    /**
     * called after deployment so that the contract whitelist addresses can mint in low price
     * @param addressesToAdd the address of the Shelter
     */
    function addToWhitelist(address[] calldata addressesToAdd)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            _whitelistAddresses[addressesToAdd[i]] = Whitelist(true, 0);
        }
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * updates the number of tokens for pre sale
     */
    function setPreSaleTokens(uint256 _preSaleToken) external onlyOwner {
        PRE_SALE_TOKENS = _preSaleToken;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function baseTokenURI() public view returns (string memory) {
        return baseUri;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractUri = uri;
    }

    function setMintLimit(uint256 newLimit) public onlyOwner {
        mintLimit = newLimit;
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        if (
            keccak256(abi.encodePacked(_tokenURIs[tokenId])) ==
            keccak256(abi.encodePacked(""))
        ) {
            return
                string(
                    abi.encodePacked(baseTokenURI(), Strings.toString(tokenId))
                );
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
}

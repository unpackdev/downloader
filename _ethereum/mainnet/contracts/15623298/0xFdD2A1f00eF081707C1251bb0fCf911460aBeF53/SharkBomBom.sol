// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract SharkBomBom is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // Event
    event merge(
        address minter,
        uint256 firstTokenId,
        uint256 secondTokenId,
        uint256 thirdTokenId,
        Level level
    );

    // Modifier
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "No contracts please");
        _;
    }

    modifier onlyBackendVerified(bytes memory _signature) {
        bytes32 msgHash = keccak256(
            abi.encodePacked(name(), msg.sender, currentPhaseName)
        );
        require(isValidSignature(msgHash, _signature), "Not authorized");
        _;
    }

    modifier mintCompliance(Level level, uint256 quantity) {
        CardSpec memory card = cardSpecs[level];
        require(initialized, "Not initialized");
        require(currentPhaseMaxMintPerAddress > 0, "Not allow to mint");
        require(quantity <= maxMintPerTx, "Over transaction limit");
        require(
            msg.value >= currentPhasePrice * quantity,
            "Not enough ether sent"
        );
        require(
            addressClaimedCountForCurrentPhase[currentPhaseName][msg.sender] +
                quantity <=
                currentPhaseMaxMintPerAddress,
            "Over address limit"
        );
        require(
            totalClaimedCountForCurrentPhase[currentPhaseName] + quantity <=
                currentPhaseMaxSupply,
            "Over phase supply"
        );
        require(
            totalSupplyByLevel(level) + quantity <= card.maxSupply,
            "Over supply"
        );
        _;
    }

    // Constants
    address private rootSigner; // Root signer
    string private unrevealedURI;
    Counters.Counter private _tokenIdCounterTeamCard;
    Counters.Counter private _tokenIdCounterSSCard;
    Counters.Counter private _tokenIdCounterSCard;
    Counters.Counter private _tokenIdCounterACard;
    Counters.Counter private _tokenIdCounterNCard;
    Counters.Counter private _tokenIdCounterNPCard;
    Counters.Counter private _tokenIdCounterReserveCard;

    struct CardSpec {
        uint256 maxSupply;
        uint256 startingTokenId;
    }

    enum Level {
        TeamCard, // 0
        SSCard, // 1
        SCard, // 2
        ACard, // 3
        NCard, // 4
        NPCard, // 5
        ReserveCard // 6
    }

    mapping(Level => CardSpec) cardSpecs;
    mapping(string => mapping(address => uint256))
        public addressClaimedCountForCurrentPhase;
    mapping(string => uint256) public totalClaimedCountForCurrentPhase;

    bool public initialized;
    bool public isRevealed;

    string public baseURI;
    string public currentPhaseName = "Preparing";

    uint256 public maxMintPerTx = 5;
    uint256 public currentPhasePrice;
    uint256 public currentPhaseMaxMintPerAddress;
    uint256 public currentPhaseMaxSupply;

    constructor() ERC721("Shark Bom Bom", "SHARK") {
        cardSpecs[Level.TeamCard] = CardSpec(20, 1);
        cardSpecs[Level.SSCard] = CardSpec(10, 21);
        cardSpecs[Level.SCard] = CardSpec(25, 31);
        cardSpecs[Level.ACard] = CardSpec(45, 56);
        cardSpecs[Level.NCard] = CardSpec(1000, 101);
        cardSpecs[Level.NPCard] = CardSpec(50, 1101);
        cardSpecs[Level.ReserveCard] = CardSpec(50, 1151);
    }

    function setRootSigner(address _newRootSigner) external onlyOwner {
        rootSigner = _newRootSigner;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUnrevealURI(string memory _newUnrevealedURI)
        external
        onlyOwner
    {
        unrevealedURI = _newUnrevealedURI;
    }

    function setPhase(
        string calldata _newPhaseName,
        uint256 _newPhasePrice,
        uint256 _newPhaseMaxMintPerAddress,
        uint256 _newPhaseMaxSupply
    ) external onlyOwner {
        currentPhaseName = _newPhaseName;
        currentPhasePrice = _newPhasePrice;
        currentPhaseMaxMintPerAddress = _newPhaseMaxMintPerAddress;
        currentPhaseMaxSupply = _newPhaseMaxSupply;
    }

    function setMaxMintPerTx(uint256 _maxMint) external onlyOwner {
        maxMintPerTx = _maxMint;
    }

    function setPhasePrice(uint256 _newPhasePrice) external onlyOwner {
        currentPhasePrice = _newPhasePrice;
    }

    function setPhaseMaxMintPerAddress(uint256 _newPhaseMaxMintPerAddress)
        external
        onlyOwner
    {
        currentPhaseMaxMintPerAddress = _newPhaseMaxMintPerAddress;
    }

    function getSpec(Level level) private view returns (CardSpec memory) {
        return cardSpecs[level];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function initialize(
        address _rootSigner,
        string calldata _initBaseURI,
        string calldata _initUnrevealedURI,
        string calldata _initPhaseName,
        uint256 _initPhasePrice,
        uint256 _initPhaseMaxMintPerAddress,
        uint256 _initPhaseMaxSupply
    ) external onlyOwner {
        require(!initialized, "Initialization can only be done once");

        initialized = true;

        // Root Signer
        rootSigner = _rootSigner;
        // Base URI
        baseURI = _initBaseURI;
        // Unrevealed URI
        unrevealedURI = _initUnrevealedURI;
        // Phase Name
        currentPhaseName = _initPhaseName;
        // Phase Price
        currentPhasePrice = _initPhasePrice;
        // Phase Max Mint Limitation
        currentPhaseMaxMintPerAddress = _initPhaseMaxMintPerAddress;
        // Phase Max Supply
        currentPhaseMaxSupply = _initPhaseMaxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        string memory currentBaseURI = _baseURI();

        if (isRevealed) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        }

        return unrevealedURI;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool isValid)
    {
        return hash.recover(signature) == rootSigner;
    }

    function mintCards(bytes memory signature, uint256 quantity)
        external
        payable
        onlyBackendVerified(signature)
    {
        _mint(Level.NCard, quantity);
    }

    function mergeCards(
        bytes memory signature,
        uint256 firstCardId,
        uint256 secondCardId,
        uint256 thirdCardId,
        Level level
    ) external payable {
        CardSpec memory card = cardSpecs[level];
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                msg.sender,
                firstCardId,
                secondCardId,
                thirdCardId,
                level
            )
        );

        require(isValidSignature(msgHash, signature), "Not authorized");
        require(totalSupplyByLevel(level) + 1 <= card.maxSupply, "Over supply");
        require(
            ownerOf(firstCardId) == msg.sender &&
                ownerOf(secondCardId) == msg.sender &&
                ownerOf(thirdCardId) == msg.sender,
            "Not owner"
        );

        _burn(firstCardId);
        _burn(secondCardId);
        _burn(thirdCardId);

        _safeMintLoop(level, 1, msg.sender);

        emit merge(msg.sender, firstCardId, secondCardId, thirdCardId, level);
    }

    function mintCardsForAddress(
        Level level,
        address receiver,
        uint256 quantity
    ) external onlyOwner {
        CardSpec memory card = cardSpecs[level];
        require(
            totalClaimedCountForCurrentPhase[currentPhaseName] + quantity <=
                currentPhaseMaxSupply,
            "Over phase supply"
        );
        require(
            totalSupplyByLevel(level) + quantity <= card.maxSupply,
            "Over supply"
        );
        addressClaimedCountForCurrentPhase[currentPhaseName][
            receiver
        ] += quantity;
        totalClaimedCountForCurrentPhase[currentPhaseName] += quantity;
        _safeMintLoop(level, quantity, receiver);
    }

    function _mint(Level level, uint256 quantity)
        internal
        onlyEOA
        mintCompliance(level, quantity)
    {
        addressClaimedCountForCurrentPhase[currentPhaseName][
            msg.sender
        ] += quantity;
        totalClaimedCountForCurrentPhase[currentPhaseName] += quantity;
        _safeMintLoop(level, quantity, msg.sender);
    }

    function _safeMintLoop(
        Level level,
        uint256 quantity,
        address to
    ) internal {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupplyByLevel(level) +
                getSpec(level).startingTokenId;
            increaseSupplyByLevel(level);
            _safeMint(to, tokenId);
        }
    }

    function getCounter(Level level)
        private
        view
        returns (Counters.Counter storage)
    {
        if (level == Level.TeamCard) {
            return _tokenIdCounterTeamCard;
        }
        if (level == Level.SSCard) {
            return _tokenIdCounterSSCard;
        }
        if (level == Level.SCard) {
            return _tokenIdCounterSCard;
        }
        if (level == Level.ACard) {
            return _tokenIdCounterACard;
        }
        if (level == Level.NCard) {
            return _tokenIdCounterNCard;
        }
        if (level == Level.NPCard) {
            return _tokenIdCounterNPCard;
        }
        if (level == Level.ReserveCard) {
            return _tokenIdCounterReserveCard;
        }
        revert("Invalid level");
    }

    function totalSupplyByLevel(Level level) public view returns (uint256) {
        return getCounter(level).current();
    }

    function increaseSupplyByLevel(Level level) internal {
        getCounter(level).increment();
    }

    function maxSupplyByLevel(Level level) public view returns (uint256) {
        return getSpec(level).maxSupply;
    }

    function startingTokenIdByLevel(Level level) public view returns (uint256) {
        return getSpec(level).startingTokenId;
    }

    function withdraw(address receiver) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }

    fallback() external payable {}

    receive() external payable {}
}

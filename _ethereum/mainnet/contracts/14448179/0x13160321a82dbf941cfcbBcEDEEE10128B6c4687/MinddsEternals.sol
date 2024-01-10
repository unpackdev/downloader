// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract MinddsEternals is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2
{
    using Address for address;

    string public constant PROVENANCE_HASH = "a881120431347c13d8c6c41c0f527c54a7abfcdde2531aaafe48d718fb7a257e";
    uint256 public constant MAX_SUPPLY = 333;

    uint256 public tokenOffset;

    uint256 public earlyPrice = 0.333 ether;
    uint256 public salePrice = 0.5 ether;

    uint256 public publicTxLimit = 2;

    bytes32 public gasLaneKeyHash;

    VRFCoordinatorV2Interface VRFCoordinator;
    LinkTokenInterface LINK;

    string public baseURI;
    bool public revealed;

    address public developer;

    bytes32 public earlySaleMerkleRoot;
    bytes32 public presaleMerkleRoot;

    mapping(address => uint256) public minted;
    address[] public premintAddresses = [
        0xcB0c66913aa173C8923524D73C7cd173a674D41d,
        0xa2e300817Ce9dE52F2724edf56032F015e9B6A1A,
        0xdE28454eA52d9abC62eAE7aa8DDce328485cf029,
        0xF531c7A28a3492390D4C47dBa6775FA76349DcFF,
        0xF531c7A28a3492390D4C47dBa6775FA76349DcFF, // two for this person
        0xbee683d39F969f13Ec44D7Da12aF108842CA7cb7
    ];
    bool public preminted;

    enum SaleState {
        CLOSED,
        EARLY,
        PRESALE,
        PUBLIC
    }
    SaleState public saleState;

    uint64 private linkSubscriptionId;
    uint256 private randomRequestId;

    constructor(
        address _owner,
        address _VRFCoordinatorAddress,
        address _LINKTokenAddress,
        bytes32 _gasLaneKeyHash
    )
        ERC721A("MINDDS 2.0 Eternals", "MNDS2")
        Ownable()
        ReentrancyGuard()
        VRFConsumerBaseV2(_VRFCoordinatorAddress)
    {
        require(_owner != address(0));
        require(_VRFCoordinatorAddress != address(0));
        require(_LINKTokenAddress != address(0));
        require(_gasLaneKeyHash != 0);
        developer = _msgSender();
        _transferOwnership(_owner);
        VRFCoordinator = VRFCoordinatorV2Interface(_VRFCoordinatorAddress);
        LINK = LinkTokenInterface(_LINKTokenAddress);
        gasLaneKeyHash = _gasLaneKeyHash;
    }

    // Metadata Functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata __baseURI) public onlyAuthorized {
        require(!revealed, "Already revealed");
        baseURI = __baseURI;
    }

    function reveal(string calldata __baseURI) public onlyAuthorized {
        require(tokenOffset != 0, "Token offset must be set");
        require(!revealed, "Already revealed");
        baseURI = __baseURI;
        revealed = true;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Randomness

    function generateTokenOffset() public onlyAuthorized {
        require(tokenOffset == 0, "Token offset already set");

        uint32 callbackGasLimit = 100000;
        uint16 requestConfirmations = 10;
        randomRequestId = VRFCoordinator.requestRandomWords(
            gasLaneKeyHash,
            linkSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            2
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(randomRequestId == requestId, "Unmatched RequestId");
        require(!revealed, "Already revealed");

        tokenOffset = randomWords[0];
        if (tokenOffset == 0) {
            tokenOffset = randomWords[1];
        }
    }

    function setLinkSubscriptionId(uint64 subscriptionId)
        public
        onlyAuthorized
    {
        linkSubscriptionId = subscriptionId;
    }

    function setGasLaneKeyHash(bytes32 _gasLaneKeyHash) public onlyAuthorized {
        gasLaneKeyHash = _gasLaneKeyHash;
    }

    function setVRFCoordinator(address _VRFCoordinatorAddress)
        public
        onlyAuthorized
    {
        VRFCoordinator = VRFCoordinatorV2Interface(_VRFCoordinatorAddress);
    }

    function setLinkToken(address _LINKTokenAddress) public onlyAuthorized {
        LINK = LinkTokenInterface(_LINKTokenAddress);
    }

    // Minting Functions

    function premint() public onlyAuthorized {
        require(!preminted);
        for (uint256 i = 0; i < premintAddresses.length; i++) {
            _mintMindds(premintAddresses[i], 1);
        }
        preminted = true;
    }

    function presaleMint(
        address _to,
        uint256 amount,
        uint256 totalReserved,
        bytes32[] calldata _merkleProof
    ) public payable isNotContract {
        require(
            saleState == SaleState.EARLY || saleState == SaleState.PRESALE,
            "Presale not active"
        );
        bytes32 _merkleRoot = saleState == SaleState.EARLY
            ? earlySaleMerkleRoot
            : presaleMerkleRoot;
        uint256 price = saleState == SaleState.EARLY
            ? earlyPrice
            : salePrice;

        require(
            verify(_merkleRoot, _merkleProof, _to, totalReserved),
            "Invalid proof"
        );
        require(msg.value == price * amount, "Invalid Payment");
        require(totalReserved > 0, "None reserved");

        require(minted[_to] + amount <= totalReserved, "Invalid amount");

        _mintMindds(_to, amount);
        minted[_to] += amount;
    }

    function publicMint(address _to, uint256 amount)
        public
        payable
        isNotContract
    {
        require(saleState == SaleState.PUBLIC, "Public sale not active");
        require(msg.value == salePrice * amount, "Invalid Payment");
        require(amount <= publicTxLimit, "Only 2 per tx");
        _mintMindds(_to, amount);
    }

    function setSaleState(SaleState _saleState) public onlyAuthorized {
        require(preminted);
        saleState = _saleState;
    }
 
    function presaleMinted(address _address) public view returns (uint256) {
        return minted[_address];
    }

    function _mintMindds(address _to, uint256 amount) private {
        require(_to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "Amount cannot be 0");
        require(amount + totalSupply() <= MAX_SUPPLY, "Sold out");
        _safeMint(_to, amount);
    }

    // Merkle Functions

    function verify(
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof,
        address _to,
        uint256 totalReserved
    ) public pure returns (bool) {
        bytes32 leaf = getLeaf(_to, totalReserved);
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    function getLeaf(address _to, uint256 totalReserved)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, totalReserved));
    }

    function setEarlySaleMerkleRoot(bytes32 _merkleRoot) public onlyAuthorized {
        earlySaleMerkleRoot = _merkleRoot;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) public onlyAuthorized {
        presaleMerkleRoot = _merkleRoot;
    }

    function withdrawTo(address to, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        if (to == address(0)) {
            to = _msgSender();
        }
        if (amount == 0) {
            amount = address(this).balance;
        }
        Address.sendValue(payable(to), amount);
    }

    function setSalePrice(uint256 _salePrice) public onlyAuthorized {
        salePrice = _salePrice;
    }

    function setEarlyPrice(uint256 _earlyPrice) public onlyAuthorized {
        earlyPrice = _earlyPrice;
    }

    function setPublicTxLimit(uint256 _publicTxLimit) public onlyAuthorized {
        publicTxLimit = _publicTxLimit;
    }

    function setDeveloper(address _developer) public onlyAuthorized {
        developer = _developer;
    }

    // Modifiers

    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(
            _msgSender() == owner() || _msgSender() == developer,
            "Unauthorized"
        );
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "Contracts cannot mint");
        _;
    }
}

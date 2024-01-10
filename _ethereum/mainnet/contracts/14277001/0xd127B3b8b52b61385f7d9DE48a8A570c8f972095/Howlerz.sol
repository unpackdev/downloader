pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./VRFConsumerBase.sol";

interface ENS_Registrar {
    function setName(string calldata name) external returns (bytes32);
}

contract Howlerz is
    ERC721A,
    PaymentSplitter,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase
{
    using Strings for uint256;

    uint256 public constant MAXTOKENS = 5000;
    uint256 public constant TOKENPRICE = 0.13 ether;
    uint256 public constant WALLETLIMIT = 5;

    uint256 public startingBlock = 999999999;
    uint256 public tokenOffset;
    
    bool public revealed;
    string public baseURI;
    string public provenance;
    bytes32 internal keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint256 private fee = 0.1 ether;
    address public VRF_coordinatorAddress =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address public linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory unrevealedURI
    )
        public
        ERC721A("HOWLERZ NFT", "HOWLERZ", WALLETLIMIT)
        PaymentSplitter(payees, shares)
        VRFConsumerBase(VRF_coordinatorAddress, linkAddress)
    {
        baseURI = unrevealedURI;
    }


    //Returns token URI
    //Note that TokenIDs are shifted against the underlying metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return _baseURI();
        uint256 shiftedTokenId = (tokenId + tokenOffset) % MAXTOKENS;
        return string(abi.encodePacked(_baseURI(), shiftedTokenId.toString()));
    }

    //Returns base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //Minting
    function mint(uint256 quantity) external payable nonReentrant {
        require(
            block.number >= startingBlock || 
            msg.sender==owner(), "Sale hasn't started yet!"  //allow owner to test mint immediately after deployment to confirm website functionality prior to activating the sale
        ); 
        require(
            totalSupply() + quantity <= MAXTOKENS,
            "Minting this many would exceed supply!"
        );
        require(
            _numberMinted(msg.sender) + quantity <= WALLETLIMIT,
            "There is a per-wallet limit!"
        );
        require(msg.value == TOKENPRICE * quantity, "Wrong ether sent!");
        require(msg.sender == tx.origin, "No contracts!");

        _safeMint(msg.sender, quantity);
    }

    function setStartingBlock(uint256 _startingBlock) external onlyOwner {
        startingBlock = _startingBlock;
    }

    //Provenance may only be set once, irreversibly
    function setProvenance(string memory _provenance) external onlyOwner {
        require(bytes(provenance).length == 0, "Provenance already set!");
        provenance = _provenance;
    }

    //Modifies the Chainlink configuration if needed
    function changeLinkConfig(
        uint256 _fee,
        bytes32 _keyhash
    ) external onlyOwner {
        fee = _fee;
        keyHash = _keyhash;
    }

    //To be called prior to reveal in order to set a token ID shift
    function requestOffset() public onlyOwner returns (bytes32 requestId) {
        LINK.transferFrom(owner(), address(this), fee);
        require(tokenOffset == 0, "Random offset already established");
        return requestRandomness(keyHash, fee);
    }

    //Chainlink callback
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(!revealed);
        tokenOffset = randomness % MAXTOKENS;
    }

    //Set Base URI
    function updateBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    //Reveals the tokens by updating to a new URI 
    //To be called after receiving a random token offset
    function reveal(string memory newURI) external onlyOwner {
        require(!revealed, "Already revealed");
        baseURI = newURI;
        revealed = true;
    }

    //To allow the contract to set a reverse ENS record
    function setReverseRecord(string calldata _name, address registrar_address)
        external
        onlyOwner
    {
        ENS_Registrar(registrar_address).setName(_name);
    }
}
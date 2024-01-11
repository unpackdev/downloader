//SPDX-License-Identifier: MIT
//contracts/MCNFT.sol
pragma solidity 0.8.12;

import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./LinkTokenInterface.sol";
import "./ERC721Psi.sol";
import "./EIP712Whitelisting.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract MCNFT is ERC721Psi, VRFConsumerBaseV2, ReentrancyGuard, EIP712Whitelisting, ERC2981ContractWideRoyalties {
    using Address for address;
    using SafeMath for uint256;

    event RandomseedRequested(uint256 timestamp);
    event RandomseedFulfilmentSuccess(
        uint256 timestamp,
        uint256 requestId,
        uint256 seed
    );
    event RandomseedFulfilmentManually(uint256 timestamp);
    event SaleStart(uint256 indexed _saleStartTime);
    event PublicSaleStart(uint256 indexed _saleStartTime);
    event SalePaused(uint256 indexed _salePausedTime);

    mapping(address => uint256) private addressMintCount;

    enum SalePhase {
        None,
        Private,
        Public
    }

    SalePhase public salePhase = SalePhase.None;

    uint256 public revealBlock = 0;
    uint256 public seed = 0;
    uint256 public maxSupply = 1200;

    uint256 public privatePrice = 0.08 ether; // 0.08 ether
    uint256 public publicPrice = 0.098 ether; // 0.098 ether
    uint256 public airdropAmount = 200;
    uint256 public airdropMinted = 0;
    uint private maxMintPerAddress = 2; // 2
    bool public randomseedRequested = false;
    bool public hasSaleStarted = false;

    address public vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 public s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 public callbackGasLimit = 300000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords =  1;

    uint64 public s_subscriptionId;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINKTOKEN;

    address public treasury;
    address public reserve;
    string public baseURI;
    string public unrevealedURI;

    string public MCNFT_PROVENANCE = "";

    // https://mirror.xyz/clemlaflemme.eth/v3O2NPRW75U5s5NG5CgsFlvNNw-TEFXB3LNjwaGqTI0
    constructor(string memory _baseURI, string memory _unrevealedURI, uint256 _maxSupply, address _treasury, uint64 _subscriptionId)
        ERC721Psi("Monday Club NFT", "MCNFT")
        VRFConsumerBaseV2(vrfCoordinator) 
    {
        s_subscriptionId = _subscriptionId;
        unrevealedURI = _unrevealedURI;
        baseURI = _baseURI;
        maxSupply = _maxSupply;
        treasury = _treasury;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

  // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner 
    {
        require(!randomseedRequested, "Chainlink VRF already requested");
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        randomseedRequested = true;
        emit RandomseedRequested(block.timestamp);
    }
  
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords) internal override 
    {
        s_randomWords = randomWords;
        seed = (randomWords[0] % 1000) + 1;
        emit RandomseedFulfilmentSuccess(block.timestamp, requestId, seed);
    }

    function isRevealed() public view returns (bool) 
    {
        return seed > 0 && revealBlock > 0 && block.number > revealBlock;
    }

    function setRevealBlock(uint256 blockNumber) external onlyOwner 
    {
        revealBlock = blockNumber;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) 
    {
        if (_msgSender() != owner()) {
            require(tokenId < totalSupply(), "Token not exists.");
        }

        if (!isRevealed()) return "default";

        uint256[] memory metadata = new uint256[](maxSupply);

        for (uint256 i = 0; i < maxSupply; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 0; i < maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) % (maxSupply));

            if(j >= 0 && j < maxSupply) {
                (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
            }
        }

        return Strings.toString(metadata[tokenId]);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");

        return
            isRevealed()
                ? string(
                    abi.encodePacked(
                        baseURI,
                        getMetadata(tokenId),
                        ".json"
                    )
                )
                : unrevealedURI;
    }

    function retrieveFunds() external onlyOwner 
    {
        payable(treasury).transfer(address(this).balance);
    }

    function setReserve(address _reserve) external onlyOwner
    {
        reserve = _reserve;
    }

    function reserveAirdrop(uint256 amount) external onlyOwner nonReentrant
    {
        require(airdropMinted <= airdropAmount, "Exceeded limit");
        
        _safeMint(reserve, amount);
        
        airdropMinted = airdropMinted + amount;
    }

    function mint(uint256 amount, bytes calldata signature) 
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(!msg.sender.isContract(), "Contract is not allowed.");
        require(hasSaleStarted, "Sales currently not active");
        require(totalSupply() + amount <= maxSupply, "Limit reached");

        if(salePhase == SalePhase.Private) {
            require(privatePrice.mul(amount) <= msg.value, "Amount received is not correct");
            require(isEIP712WhiteListed(signature), "Not whitelisted.");
            require(addressMintCount[_msgSender()] < maxMintPerAddress, "You cannot mint more"); // whitelist phase then public phase

            _safeMint(msg.sender, amount);

            addressMintCount[_msgSender()] = addressMintCount[_msgSender()] + amount;
        }

        if(salePhase == SalePhase.Public) {
            require(publicPrice.mul(amount) <= msg.value, "Amount received is not correct");

            _safeMint(msg.sender, amount);
        }
        
        return true;
    }

    function startSale() external onlyOwner 
    {
        require(!hasSaleStarted, "Sale has already begun");
        hasSaleStarted = true;
        salePhase = SalePhase.Private;

        emit SaleStart(block.timestamp);
    }

    function startPublicSale() external onlyOwner
    {
        salePhase = SalePhase.Public;

        emit PublicSaleStart(block.timestamp);
    }

    function pauseSale() external onlyOwner 
    {
        hasSaleStarted = false;
        emit SalePaused(block.timestamp);
    }

    function setRoyalties(address _recipient, uint256 _value) external onlyOwner 
    {
        _setRoyalties(_recipient, _value);
    }

    function setProvenanceHash(string memory _hash) external onlyOwner
    {
        MCNFT_PROVENANCE = _hash;
    }

    function setTreasury(address _treasury) external onlyOwner
    {
        treasury = _treasury;
    }

    function setbaseURI(string memory _uri) external onlyOwner
    {
        baseURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, ERC2981Base)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
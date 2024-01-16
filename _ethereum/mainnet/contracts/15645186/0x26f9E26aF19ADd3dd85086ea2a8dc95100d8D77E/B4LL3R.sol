// SPDX-License-Identifier: MIT
         


pragma solidity ^0.8.16;

import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract B4LL3R is Ownable, ReentrancyGuard, VRFConsumerBaseV2, ERC721AQueryable, IERC721ABurnable {
    event PermanentURI(string _value, uint256 indexed _id);

    VRFCoordinatorV2Interface private VRF_COORDINATOR;
    uint64 private _chainlinkSubscriptionId; //Set this with the setChainlinkSubscriptionID function
    bytes32 private _vrfKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //Gaslane for network - controls gas limits - https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/
    address private constant VRF_COORDINATOR_ADDR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; // Depends on chain being used - in this case : Ethereum
    uint32 private constant CHAINLINK_CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant CHAINLINK_REQ_CONFIRMATIONS = 3;

    uint256 public constant MAX_SUPPLY = 250;
    
    // Holds the # of remaining tokens for each DNA
    mapping(uint256 => uint256) public dnaToRemainingSupply;


    // Holds the # of remaining tokens available for migration
    uint256 public remainingSupply = 250;

    mapping(uint256 => uint256) private _randomnessRequestIdToTokenId;

    // 0: Migration still in progress or token not minted
    // 1: Human
    // 2: Robot
    // 3: Demon
    // 4: Angel
    // 5: Reptile
    // 6: Undead
    // 7: Alien
    mapping(uint256 => uint256) public tokenIdToDna;

    bool public openBoxPaused;
    bool public contractPaused;

    string private _baseTokenURI;
    bool public baseURILocked;

    BoxContract private BOX;
    address private _burnAuthorizedContract;
    
    address private _admin;

    constructor(
        string memory baseTokenURI,
        address admin,
        address boxContract,
        uint64 chainlinkSubscriptionId)
    VRFConsumerBaseV2(VRF_COORDINATOR_ADDR)
    ERC721A("Jersey", "Jersey") {
        _chainlinkSubscriptionId = chainlinkSubscriptionId;
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        openBoxPaused = false;

        VRF_COORDINATOR = VRFCoordinatorV2Interface(VRF_COORDINATOR_ADDR);
        BOX = BoxContract(boxContract);

        
        _initializeSupplies();

        _safeMint(msg.sender, 1);
        _setTokenMetadata(0, 1); // Human 
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function _initializeSupplies() private {
        dnaToRemainingSupply[1] = 64;

        dnaToRemainingSupply[2] = 50;

        dnaToRemainingSupply[3] = 40;

        dnaToRemainingSupply[4] = 40;

        dnaToRemainingSupply[5] = 28;

        dnaToRemainingSupply[6] = 18;

        dnaToRemainingSupply[7] = 10;
    }

    // Starts the migration process of given B4//3R Box.
    // Note that migration is asynchronous; the B4//3R Jersey will be minted but its metadata
    //will be assigned later (see `fulfillRandomWords`) when the on-chain randomness is produced.
    function startopenBox(uint256[] memory boxIds)
        external
        nonReentrant
        callerIsUser
    {
        require(!openBoxPaused && !contractPaused, "Box opening is paused");


        uint256 i;
        for (i = 0; i < boxIds.length;) {
            uint256 boxId = boxIds[i];
            // check if the msg sender is the owner
            require(BOX.ownerOf(boxId) == msg.sender, "You don't own the given Box");

            // burn Box
            BOX.burn(boxId);

            unchecked { i++; }
        }

        // mint Jersey
        uint256 firstJerseyId = _nextTokenId();
        _safeMint(msg.sender, boxIds.length);

        // request random metadata for Jersey
         i = firstJerseyId;
        unchecked {
            while (true) {
                if (i >= firstJerseyId + boxIds.length) { break; }
                
                _requestRandomMetadata(i);

                i++;
            }
        }

    }

    function _requestRandomMetadata(uint256 tokenId) private {
        // request a random number from Chainlink to give a random metadata to the token
        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            _vrfKeyHash,
            _chainlinkSubscriptionId,
            CHAINLINK_REQ_CONFIRMATIONS,
            CHAINLINK_CALLBACK_GAS_LIMIT,
            1);
        _randomnessRequestIdToTokenId[requestId] = tokenId;
    }

    // Will be used by an admin, only if Chainlink VRF request fails and needs a retry
    function retryopenBox(uint256 tokenId) external onlyOwnerOrAdmin {
        // request a random number from Chainlink to give a random DNA to the minted Jersey
        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            _vrfKeyHash,
            _chainlinkSubscriptionId,
            CHAINLINK_REQ_CONFIRMATIONS,
            CHAINLINK_CALLBACK_GAS_LIMIT,
            1);
        _randomnessRequestIdToTokenId[requestId] = tokenId;
    }

    // Called by Chainlink when requested randomness is ready
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 tokenId = _randomnessRequestIdToTokenId[requestId];
        require(tokenId > 0, "Invalid request id");
 
        unchecked {
            uint256 rand = randomWords[0];
            uint256 randForDna = rand % remainingSupply;

            uint256 j = 0;
            for (uint256 dna = 1; dna < 8; dna++) {
                uint256 remDnaSupply = dnaToRemainingSupply[dna];
                if (remDnaSupply <= 0) {
                    // DNA is completely minted
                    continue;
                }

                j += remDnaSupply;
                if (randForDna < j) {

                    // assign the metadata
                    _setTokenMetadata(tokenId, dna);
                    break;
                }
            }
        }
    }

    function _setTokenMetadata(uint256 tokenId, uint256 dna) private {
        require(tokenIdToDna[tokenId] == 0, "Token already has a DNA");

        tokenIdToDna[tokenId] = dna;

        unchecked {
            if (dna > 0 && dna < 8) {
                // regular DNA, adjust supplies

                dnaToRemainingSupply[dna]--;

                remainingSupply--;
            }
        }
    }

    // Will be used by an admin, only if Chainlink VRF totally fails and we need to assign a metadata manually
    function setTokenMetadata(uint256 tokenId, uint256 dna) external onlyOwnerOrAdmin {
        _setTokenMetadata(tokenId, dna);
    }
    
    function getDna(uint256 tokenId) external view returns (uint256) {
        return tokenIdToDna[tokenId];
    }


    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _burnAuthorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function pauseopenBox(bool paused) external onlyOwnerOrAdmin {
        openBoxPaused = paused;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function _beforeTokenTransfers(
        address /* from */,
        address /* to */,
        uint256 /* startTokenId */,
        uint256 /* quantity */
    ) internal virtual override {
        require(!contractPaused, "Contract is paused");
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        baseURILocked = true;
        for (uint256 i = 0; i < _nextTokenId(); i++) {
            if (_exists(i)) {
                emit PermanentURI(tokenURI(i), i);
            }
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Quantity exceeds supply");

        uint256 firstJerseyId = _nextTokenId();
        _safeMint(to, quantity);
        
        for (uint256 i = firstJerseyId; i < firstJerseyId + quantity; i++) {
            _requestRandomMetadata(i);
        }
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setBoxContract(address addr) external onlyOwnerOrAdmin {
        BOX = BoxContract(addr);
    }

    function setBurnAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _burnAuthorizedContract = authorizedContract;
    }
    
    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Sets the Chainlink subscription id
    function setChainlinkSubscriptionId(uint64 id) external onlyOwnerOrAdmin {
        _chainlinkSubscriptionId = id;
    }

    // Marketplace blocklist functions
    mapping(address => bool) private _marketplaceBlocklist;

    function approve(address to, uint256 tokenId) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[to] == false, "Marketplace is blocked");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[operator] == false, "Marketplace is blocked");
        super.setApprovalForAll(operator, approved);
    }

    function blockMarketplace(address addr, bool blocked) public onlyOwnerOrAdmin {
        _marketplaceBlocklist[addr] = blocked;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://exhale.mypinata.cloud/ipfs/QmZwZyWCpJtueASnJEqJ2dPynL9NemQoCtmiCGtUtjBVyJ";
    }
}

interface BoxContract {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
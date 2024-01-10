// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Poppables is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    AccessControl,
    VRFConsumerBaseV2
{
    using SafeMath for uint256;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    bool public poppablesActive = false;
    uint256 public price;
    bytes32 public giftRoot;
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    address private account1;
    address private account2;
    address private account3;
    address private account4;

    uint256 private maxMintableSupply;
    uint256 private maxSupply;
    uint256 private _seed = 0;
    string private _contractURI;
    string private _tokenBaseURI;

    uint64 private s_subscriptionId;

    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 1;
    uint256 public s_requestId;

    event NFTMinted(bool state, uint256 quantity);
    event GiftNFTMinted(bool state);
    event NFTAirdropped(bool state);
    event NFTRandomnessRequest(uint256 timestamp);
    event NFTRandomnessFullfill(uint256 timestamp);
    event NFTChainlinkError(uint256 timestamp, uint256 requestId);

    constructor(
        address _account1,
        address _account2,
        address _account3,
        address _account4,
        address devRoleAdress,
        uint64 subscriptionId
    ) ERC721A("Poppables", "POP") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;

        price = 50000000000000000; //0.05 ETH
        maxMintableSupply = 1600;
        maxSupply = 9599;

        account1 = _account1;
        account2 = _account2;
        account3 = _account3;
        account4 = _account4;

        _contractURI = "https://www.poppables.io/opensea.json";
        _tokenBaseURI = "https://poppables.mypinata.cloud/ipfs/QmbQfWj7y6QeAAU4ibzAG94JFYThaH9NR2ktSEAjmMAnCU/";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, devRoleAdress);
    }

    function mintNFTs(uint256 quantity) external payable nonReentrant {
        require(poppablesActive, "Not active");
        require(quantity >= 1 && quantity < 23, "Wrong quantity");

        require(
            totalSupply() + quantity <= maxMintableSupply,
            "Cannot mint more"
        );

        require(msg.value >= price.mul(quantity), "Not enough ETH");

        _safeMint(msg.sender, quantity);

        emit NFTMinted(true, quantity);
    }

    function mintGiftNFTs(address minter, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(poppablesActive, "Not active");
        require(totalSupply() + 1 <= maxMintableSupply, "Cannot mint more");

        bytes32 leaf = keccak256(abi.encodePacked(minter));
        bool inTheList = MerkleProof.verify(proof, giftRoot, leaf);
        require(inTheList, "Not in the git list");

        _safeMint(msg.sender, 1);

        emit GiftNFTMinted(true);
    }

    function airdrop(address receiver)
        external
        nonReentrant
        onlyRole(DEV_ROLE)
    {
        require(poppablesActive, "Not active");
        require(totalSupply() + 1 <= maxMintableSupply, "Cannot mint more");

        _safeMint(receiver, 1);

        emit NFTAirdropped(true);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(
                abi.encodePacked(_tokenBaseURI, metadataOf(tokenId), ".json")
            );
    }

    function metadataOf(uint256 tokenId) internal view returns (string memory) {
        uint256[] memory metaIds = new uint256[](maxSupply);
        uint256 ss = _seed;

        for (uint256 i = 0; i < maxSupply; i += 1) {
            metaIds[i] = i;
        }

        for (uint256 i = 0; i < maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(ss, i))) % (maxSupply));
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }
        return Strings.toString(metaIds[tokenId]);
    }

    function toggleActive() external onlyRole(DEV_ROLE) {
        poppablesActive = !poppablesActive;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractUri)
        external
        onlyRole(DEV_ROLE)
    {
        _contractURI = contractUri;
    }

    function setBaseURI(string memory baseURI) external onlyRole(DEV_ROLE) {
        _tokenBaseURI = baseURI;
    }

    function setSeed(uint256 randomNumber) public onlyRole(DEV_ROLE) {
        _seed = randomNumber;
    }

    function updateGiftRoot(bytes32 _merkleGiftRoot)
        external
        onlyRole(DEV_ROLE)
    {
        giftRoot = _merkleGiftRoot;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        payable(account1).transfer(balance.mul(15).div(100));
        payable(account2).transfer(balance.mul(15).div(100));
        payable(account3).transfer(balance.mul(20).div(100));
        payable(account4).transfer(balance.mul(50).div(100));
    }

    function updateKeyHash(bytes32 _keyHash) external onlyRole(DEV_ROLE) {
        keyHash = _keyHash;
    }

    function requestRandomWords() external onlyRole(DEV_ROLE) {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit NFTRandomnessRequest(block.timestamp);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomNumber = randomWords[0];
        if (randomNumber > 0) {
            _seed = randomNumber;
            emit NFTRandomnessFullfill(block.timestamp);
        } else {
            emit NFTChainlinkError(block.timestamp, requestId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./IFaithToken.sol";

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract EtherGoddess is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI =
        "https://ethergoddessnft.s3.amazonaws.com/metadata/";

    uint256 public supply = 5000;
    uint256 public publicMintPrice = 0.08 ether;
    uint256 public wlMintPrice = 0.065 ether; 

    // used to validate lists
    bytes32 public druidMerkleRoot;
    bytes32 public acolyteMerkleRoot;
    bytes32 public adeptMerkleRoot;

    // free minting allowance
    mapping(address => uint256) public freeAllocated;

    // keep track of those on lists who have claimed their NFT
    mapping(address => uint256) public druidClaimed;
    mapping(address => uint256) public acolyteClaimed;
    mapping(address => uint256) public adeptClaimed;

    bool public isWLMintingOpen = false;
    bool public isAdeptMintingOpen = false;
    bool public isPublicMintingOpen = false;

    constructor() ERC721A("Ether Goddess", "EG") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ============ Modifiers ============
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens <= msg.value,
            "Insufficient ETH value sent"
        );
        _;
    }

    modifier withinSupplyLimit(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <= supply,
            "Not enough supply left"
        );
        _;
    }

    modifier whitelistMintingOpen() {
        require(isWLMintingOpen, "WL Minting is not open");
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintFree(uint256 mintAmount)
        external
        nonReentrant
        withinSupplyLimit(mintAmount)
        whitelistMintingOpen
    {
        require(
            (freeAllocated[msg.sender] - mintAmount) >= 0,
            "Maxed out allocation"
        );
        _safeMint(msg.sender, mintAmount);
        freeAllocated[msg.sender] -= mintAmount;
    }

    function mintDruid(bytes32[] calldata merkleProof, uint256 mintAmount)
        external
        payable
        isValidMerkleProof(merkleProof, druidMerkleRoot)
        isCorrectPayment(wlMintPrice, mintAmount)
        withinSupplyLimit(mintAmount)
        whitelistMintingOpen
        nonReentrant
    {
        require(
            druidClaimed[msg.sender] + mintAmount <= 4,
            "Maxed out allocation"
        );
        _safeMint(msg.sender, mintAmount);
        druidClaimed[msg.sender] += mintAmount;
    }

    function mintAcolyte(bytes32[] calldata merkleProof, uint256 mintAmount)
        external
        payable
        isValidMerkleProof(merkleProof, acolyteMerkleRoot)
        isCorrectPayment(wlMintPrice, mintAmount)
        withinSupplyLimit(mintAmount)
        whitelistMintingOpen
        nonReentrant
    {
        require(
            acolyteClaimed[msg.sender] + mintAmount <= 2,
            "Maxed out allocation"
        );
        _safeMint(msg.sender, mintAmount);
        acolyteClaimed[msg.sender] += mintAmount;
    }

    function mintAdept(bytes32[] calldata merkleProof, uint256 mintAmount)
        external
        payable
        isValidMerkleProof(merkleProof, adeptMerkleRoot)
        isCorrectPayment(wlMintPrice, mintAmount)
        withinSupplyLimit(mintAmount)
        nonReentrant
    {
        require(isAdeptMintingOpen, "Adept Minting is not open");
        require(
            adeptClaimed[msg.sender] + mintAmount <= 2,
            "Maxed out allocation"
        );
        _safeMint(msg.sender, mintAmount);
        adeptClaimed[msg.sender] += mintAmount;
    }

    // Public mint with Crossmint compatibility
    function mintTo(address to, uint256 _count)
        external
        payable
        isCorrectPayment(publicMintPrice, _count)
        withinSupplyLimit(_count)
        nonReentrant
    {
        require(isPublicMintingOpen, "Public Minting is not open");
        require(_count <= 10, "Max 10 per transaction");
        _safeMint(to, _count);
    }

    // ============ PUBLIC VIEW FUNCTION ============
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setFreeAllocation(
        address[] calldata addresses,
        uint256[] calldata allocation
    ) public onlyOwner {
        require(
            (addresses.length == allocation.length),
            "addresses and allocation must be the same length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            freeAllocated[addresses[i]] = allocation[i];
        }
    }

    function setDruidMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        druidMerkleRoot = merkleRoot;
    }

    function setAcolyteMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        acolyteMerkleRoot = merkleRoot;
    }

    function setAdeptMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        adeptMerkleRoot = merkleRoot;
    }

    function toggleWhiteListMinting() external onlyOwner {
        isWLMintingOpen = !isWLMintingOpen;
    }

    function toggleAdeptMinting() external onlyOwner {
        isAdeptMintingOpen = !isAdeptMintingOpen;
    }

    function togglePublicMinting() external onlyOwner {
        isPublicMintingOpen = !isPublicMintingOpen;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        supply = _supply;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setWLMintPrice(uint256 _wlMintPrice) external onlyOwner {
        wlMintPrice = _wlMintPrice;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // ============ WITHDRAWAL FUNCTIONS ============
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ============ STAKING FUNCTIONS ============

    IFaithToken public faithTokenContract;
    // Token reward rate per day per staked NFT
    uint256 public baseRewardRate = 10;

    mapping(uint256 => bool) public tokenStakedStatus;
    mapping(address => uint256) public tokenStakedBalance;

    mapping(address => uint256) private rewards;
    mapping(address => uint256) private lastUpdateTimestamp;

    // ============ PUBLIC FUNCTIONS ============
    function stake(uint256[] calldata tokenIds) public {
        updateRewards(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
    }

    function unstake(uint256[] calldata tokenIds) public {
        updateRewards(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(tokenIds[i]);
        }
    }

    function claimRewards() public {
        updateRewards(msg.sender);
        faithTokenContract.mint(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function getRewardBalance(address holder) external view returns (uint256) {
        if (lastUpdateTimestamp[holder] > 0)
            return (rewards[holder] + calculateAccumulatedReward(holder));
        else return 0;
    }

    function getTotalStakedNFTCount() external view returns (uint256) {
        uint256 stakedCount = 0;

        for (uint256 i = 0; i < 5000; i++) {
            if (tokenStakedStatus[i]) stakedCount++;
        }
        return stakedCount;
    }

    // ============ STAKING INTERNAL FUNCTIONS ============

    function _stake(uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == msg.sender, "Token not owned by sender");
        require(tokenStakedStatus[_tokenId] == false, "Token already staked");
        tokenStakedStatus[_tokenId] = true;
        tokenStakedBalance[msg.sender]++;
    }

    function _unstake(uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == msg.sender, "Token not owned by sender");
        require(tokenStakedStatus[_tokenId] == true, "Token not staked");
        tokenStakedStatus[_tokenId] = false;
        tokenStakedBalance[msg.sender]--;
    }

    function updateRewards(address _user) internal {
        if (lastUpdateTimestamp[_user] > 0) {
            rewards[_user] += calculateAccumulatedReward(_user);
        }
        lastUpdateTimestamp[_user] = block.timestamp;
    }

    function calculateAccumulatedReward(address _user)
        internal
        view
        returns (uint256)
    {
        uint256 stakedBalance = tokenStakedBalance[_user];
        uint256 rewardRate = baseRewardRate + (stakedBalance / 5); // stake 5, bonus 10%. stake 10, bonus 20%, etc
        uint256 timeDelta = (block.timestamp - lastUpdateTimestamp[_user]) /
            86400; // seconds in a day

        return stakedBalance * rewardRate * timeDelta;
    }

    // ============ STAKING ADMIN FUNCTIONS ============
    function setRewardRate(uint256 _baseRewardRate) public onlyOwner {
        baseRewardRate = _baseRewardRate;
    }

    function setFaithTokenContract(IFaithToken _faithTokenContract)
        public
        onlyOwner
    {
        faithTokenContract = _faithTokenContract;
    }

    // ============ STAKING OVERIDE FUNCTIONS ============
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            tokenStakedStatus[tokenId] == false,
            "You can not transfer a staked token"
        );

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            tokenStakedStatus[tokenId] == false,
            "You can not transfer a staked token"
        );
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            tokenStakedStatus[tokenId] == false,
            "You can not transfer a staked token"
        );

        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            tokenStakedStatus[tokenId] == false,
            "You can not burn a staked token"
        );
        _burn(tokenId, true);
    }
}

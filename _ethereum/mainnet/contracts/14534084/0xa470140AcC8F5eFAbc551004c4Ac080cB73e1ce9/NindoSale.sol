// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

abstract contract NindoContract {
    function mintTransfer(address to, uint256 n) public virtual;

    function totalSupply() public view virtual returns (uint256);
}

contract NindoSale is Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public immutable maxWhitelistAmount = 3000;
    uint256 public immutable maxWhitelistPerAmount = 2;
    uint256 public immutable maxPublicSalePerAmount = 30;
    uint256 public constant whitelistSalePrice = 0.0777 ether;
    uint256 public constant publicSalePrice = 0.0888 ether;

    uint256 public constant rewardPercent = 5;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // set time
    uint64 public immutable whitelistStartTime = 1649394780;
    uint64 public immutable whitelistEndTime = 1649481180;
    uint64 public immutable publicSaleStartTime = 1649481180;
    uint64 public immutable publicSaleEndTime = 1650085980;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    uint256 public whitelistMintedAmount;
    uint256 public refAddrCount;
    bool refRewardWithdrawLocked = false;
    address nindoTokenAddress;

    mapping(address => string) public refName;
    mapping(uint256 => address) public refAddrList;
    mapping(string => bool) public refNameRegistered;
    mapping(string => uint256) public refRewardUnclaimed;
    mapping(string => uint256) public refRewardClaimed;

    address withdrawAddress;

    event MintWhitelistWithRef(address buyer, string ref);
    event MintPublicWithRef(address buyer, string ref);
    event WithdrawReward(address user, uint256 amount);

    constructor() {
        refNameRegistered["none"] = true;
        nindoTokenAddress = address(0xaBAd3A3Ea761960093aF10DeD751bE8D94A564f4);
        whitelistMerkleRoot = 0x0;
    }

    // ============ MODIFIER FUNCTIONS ============
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
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canWhitelistMint(uint256 numberOfTokens) {
        uint256 ts = whitelistMintedAmount;
        require(
            ts + numberOfTokens <= maxWhitelistAmount,
            "Purchase would exceed max whitelist round tokens"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        NindoContract tokenAttribution = NindoContract(nindoTokenAddress);
        uint256 ts = tokenAttribution.totalSupply();
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _;
    }

    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "Outside whitelist round hours"
        );
        _;
    }
    modifier checkPublicSaleTime() {
        require(
            block.timestamp >= uint256(publicSaleStartTime) &&
                block.timestamp <= uint256(publicSaleEndTime),
            "Outside public sale hours"
        );
        _;
    }

    function isContainSpace(string memory _name) internal pure returns (bool) {
        bytes memory _nameBytes = bytes(_name);
        bytes memory _spaceBytes = bytes(" ");
        for (uint256 i = 0; i < _nameBytes.length; i++) {
            if (_nameBytes[i] == _spaceBytes[0]) {
                return true;
            }
        }
        return false;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintWhitelist(
        uint256 n,
        bytes32[] calldata merkleProof,
        string memory ref
    )
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whitelistSalePrice, n)
        canWhitelistMint(n)
        checkWhitelistTime
        nonReentrant
    {
        require(
            whitelistMinted[msg.sender] + n <= maxWhitelistPerAmount,
            "NFT is already exceed max mint amount by this wallet"
        );
        if (
            keccak256(abi.encodePacked(ref)) ==
            keccak256(abi.encodePacked("none"))
        ) {} else {
            require(refNameRegistered[ref] == true, "Ref name does not exist");
            require(
                keccak256(abi.encodePacked(refName[msg.sender])) !=
                    keccak256(abi.encodePacked(ref)),
                "Invalid Ref Name"
            );
            uint256 reward = (msg.value * rewardPercent) / 100;
            refRewardUnclaimed[ref] += reward;
            emit MintWhitelistWithRef(msg.sender, ref);
        }
        NindoContract tokenAttribution = NindoContract(nindoTokenAddress);
        tokenAttribution.mintTransfer(msg.sender, n);
        whitelistMinted[msg.sender] += n;
        whitelistMintedAmount += n;
    }

    function publicMint(uint256 n, string memory ref)
        public
        payable
        isCorrectPayment(publicSalePrice, n)
        canMint(n)
        checkPublicSaleTime
        nonReentrant
    {
        require(
            publicMinted[msg.sender] + n <= maxPublicSalePerAmount,
            "NFT is already exceed max mint amount by this wallet"
        );

        if (
            keccak256(abi.encodePacked(ref)) ==
            keccak256(abi.encodePacked("none"))
        ) {} else {
            require(refNameRegistered[ref] == true, "Ref name does not exist");
            require(
                keccak256(abi.encodePacked(refName[msg.sender])) !=
                    keccak256(abi.encodePacked(ref)),
                "Invalid Ref Name"
            );
            uint256 reward = (msg.value * rewardPercent) / 100;
            refRewardUnclaimed[ref] += reward;
            emit MintPublicWithRef(msg.sender, ref);
        }
        NindoContract tokenAttribution = NindoContract(nindoTokenAddress);
        tokenAttribution.mintTransfer(msg.sender, n);
        publicMinted[msg.sender] += n;
    }

    // ============ PUBLIC FUNCTIONS FOR REFERRAL ============
    function register(string memory name) public {
        require(refNameRegistered[name] == false, "This name already exists");
        bytes memory tempName = bytes(name);
        bytes memory tempRefName = bytes(refName[msg.sender]);
        bool containSpace = isContainSpace(name);
        require(
            tempName.length > 0 && tempRefName.length == 0,
            "This address already has name OR name you enter is empty"
        );
        require(containSpace == false, "Ref name can not include space");
        refAddrList[refAddrCount] = msg.sender;
        refName[msg.sender] = name;
        refNameRegistered[name] = true;
        ++refAddrCount;
    }

    function withdrawRefReward() public {
        string memory name = refName[msg.sender];
        require(refNameRegistered[name] == true, "This name does not exists");
        require(
            refRewardWithdrawLocked == false,
            "refRewardWithdraw is locked"
        );
        uint256 claim = refRewardUnclaimed[name];
        require(claim > 0, "Nothing to claim");
        payable(msg.sender).transfer(claim);
        refRewardClaimed[name] += claim;
        refRewardUnclaimed[name] = 0;
        emit WithdrawReward(msg.sender, claim);
    }

    function getRefNameByAddress(address addr)
        external
        view
        returns (string memory)
    {
        return refName[addr];
    }

    function getRefNameAlreadyRegistered(string memory name)
        external
        view
        returns (bool)
    {
        return refNameRegistered[name];
    }

    function getRefRewardClaimed(address addr) external view returns (uint256) {
        string memory name = this.getRefNameByAddress(addr);
        return refRewardClaimed[name];
    }

    function getRefRewardUnclaimed(address addr)
        external
        view
        returns (uint256)
    {
        string memory name = this.getRefNameByAddress(addr);
        return refRewardUnclaimed[name];
    }

    function getRefAddrByIndex(uint256 index) public view returns (address) {
        return refAddrList[index];
    }

    function getRefAddrList() external view returns (address[] memory) {
        address[] memory addrList = new address[](refAddrCount);
        for (uint256 i = 0; i < refAddrCount; i++) {
            addrList[i] = refAddrList[i];
        }
        return addrList;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function withdraw() public {
        require(
            refRewardWithdrawLocked == true,
            "refReward withdraw must be true"
        );
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setNindoTokenAddress(address newAddress) public onlyOwner {
        nindoTokenAddress = newAddress;
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }

    function toggleRefRewardLock() public onlyOwner {
        refRewardWithdrawLocked = !refRewardWithdrawLocked;
    }
}

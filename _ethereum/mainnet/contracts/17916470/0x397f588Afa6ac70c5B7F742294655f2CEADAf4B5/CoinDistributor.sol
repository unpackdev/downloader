pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";

contract CoinDistributor is Ownable {
    event Claimed(address indexed account, uint256 amount);
    event DistributionCreated(uint256 indexed version, uint256 amount);

    mapping(address => uint256) public TOTAL_CLAIMED;
    bytes32 public merkleRoot;

    // Added versioning
    uint256 public currentVersion;
    mapping(address => uint256) public lastClaimedVersion;

    address erc20token; //EXAMPLE ADDRESS - CHANGE

    // Admins enumerable set
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    constructor(address _token) {
        erc20token = _token;
        admins.add(msg.sender);
    }

    // Modifier to check if the caller is an admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    function isAdmin(address _account) public view returns (bool) {
        return admins.contains(_account);
    }

    function addAdmin(address[] memory _account) external onlyOwner {
        for (uint i = 0; i < _account.length; i++) {
            admins.add(_account[i]);
        }
    }

    function removeAdmin(address[] memory _account) external onlyOwner {
        for (uint i = 0; i < _account.length; i++) {
            admins.remove(_account[i]);
        }
    }

    function claimRewards(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        // Ensure the user is claiming for the current version
        require(
            lastClaimedVersion[msg.sender] < currentVersion,
            "Already claimed for this version."
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof."
        );

        TOTAL_CLAIMED[msg.sender] += _amount;
        lastClaimedVersion[msg.sender] = currentVersion; // Update their claimed version
        IERC20(erc20token).transfer(msg.sender, _amount);

        emit Claimed(msg.sender, _amount);
    }

    function createDistribution(
        bytes32 _merkleRoot,
        uint256 _amount
    ) external onlyAdmin {
        merkleRoot = _merkleRoot;
        currentVersion++;
        IERC20(erc20token).transferFrom(msg.sender, address(this), _amount);

        emit DistributionCreated(currentVersion, _amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        IERC20(erc20token).transfer(msg.sender, amount);
    }

    function setTokenAddress(address _token) external onlyOwner {
        erc20token = _token;
    }
}

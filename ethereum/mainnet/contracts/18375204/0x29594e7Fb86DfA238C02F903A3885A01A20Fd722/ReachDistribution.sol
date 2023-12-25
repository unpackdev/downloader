// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.19;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract ReachDistribution is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Claimed(
        address indexed account,
        uint256 amount,
        uint256 indexed version
    );

    event DistributionCreated(uint256 indexed version, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event MissionCreated(string  missionId, uint256 amount);

    struct Mission {
        uint256 amount;
        address creator;
    }

    mapping(string => Mission) public missions;
    mapping(address => uint256) public totalClaimed;
    bytes32 public merkleRoot;
    uint256 public currentVersion;
    mapping(address => uint256) public lastClaimedVersion;
    address public erc20token;
    bool public tokenDistribution;
    bool public paused;

    // Admins enumerable set
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    constructor() {
        admins.add(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    /*
     * @notice Pauses the contract
     */
    function toggleClaiming() external onlyAdmin {
        paused = !paused;
    }

    /*
     * @notice Checks if an address is an admin
     * @param _account The address to check
     * @return bool indicating whether the address is an admin
     */
    function isAdmin(address _account) public view returns (bool) {
        return admins.contains(_account);
    }

    /*
     * @notice Adds new admins
     * @param _account The addresses to be added as admins
     */
    function addAdmin(address[] memory _account) external onlyOwner {
        require(_account.length <= 10, "Too many admins");
        for (uint i = 0; i < _account.length; i++) {
            admins.add(_account[i]);
        }
    }

    /*
     * @notice Removes admins
     * @param _account The addresses to be removed from admins
     */
    function removeAdmin(address[] memory _account) external onlyOwner {
        require(_account.length <= 10, "Too many admins");
        for (uint i = 0; i < _account.length; i++) {
            admins.remove(_account[i]);
        }
    }

    /*
     * @notice Allows users to claim rewards
     * @param _amount The amount to be claimed
     * @param _merkleProof The merkle proof required for claiming
     */
    function claimRewards(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        require(!paused, "Claiming is paused.");
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

        totalClaimed[msg.sender] += _amount;
        lastClaimedVersion[msg.sender] = currentVersion;

        if (tokenDistribution) {
            IERC20(erc20token).safeTransfer(msg.sender, _amount);
        } else {
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "Transfer failed.");
        }

        emit Claimed(msg.sender, _amount, currentVersion);
    }

    /*
     * @notice Creates a new distribution
     * @param _merkleRoot The merkle root for the new distribution
     * @param _amount The total amount for the new distribution
     */
    function createDistribution(
        bytes32 _merkleRoot,
        uint256 _amount
    ) external onlyAdmin {
        merkleRoot = _merkleRoot;
        currentVersion++;

        emit DistributionCreated(currentVersion, _amount);
    }

    /*
     * @notice Sets the address of the ERC20 token for distributions
     * @param _token The address of the ERC20 token
     */
    function setTokenAddress(address _token) external onlyOwner {
        erc20token = _token;
    }

    /*
     * @notice Creates a new mission
     * @param _missionId The ID of the new mission
     * @param _amount The amount allocated to the new mission
     */
    function createMission(
        string memory _missionId,
        uint256 _amount
    ) external payable {
        require(_amount > 0, "Amount must be greater than 0.");
        require(_amount == msg.value, "Incorrect amount sent.");

        emit MissionCreated(_missionId, _amount);
    }

    // Fallback function to receive Ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

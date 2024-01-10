import "./MerkleProof.sol";
import "./IERC20.sol";

contract MerkleDistributor {

    address public immutable token;
    address public immutable sweeper;
    bytes32 public immutable merkleRoot;

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

     /// @notice Thrown if address has already claimed
    error AlreadyClaimed();

    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// @notice Emitted after all the tokens in the contract have been sweeped
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Sweeped(address indexed to, uint256 amount);

    constructor(
        address token_, 
        bytes32 merkleRoot_,
        address sweeper_
    ) public {
        token = token_;
        merkleRoot = merkleRoot_;
        sweeper = sweeper_;
    }

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[to]) revert AlreadyClaimed();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        // Set address to claimed
        hasClaimed[to] = true;

        require(IERC20(token).transfer(to, amount), 'MerkleDistributor: Transfer failed.');

        // Emit claim event
        emit Claim(to, amount);
    }

    /// @notice Allows all the tokens in the contrac to be sweeped for unclaimed tokens
    function sweep() external {
        // Ensure that only the sweeper can call the contract!
        require(
            msg.sender == sweeper,
            "Sweep can only be called by the sweeper"
        );

        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(sweeper, balance);

        // Emit the sweep event
        emit Sweeped(sweeper, balance);
    }
}
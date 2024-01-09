pragma solidity 0.8.6;


import "MerkleProofIndex.sol";
import "IJellyAccessControls.sol";
import "IJellyContract.sol";
import "EnumerableSet.sol";

/**
 * @notice MerkleListV2 - Merkle List with proofs of a `token` balance.
 */
contract MerkleListV2 is IJellyContract  {
 
     using EnumerableSet for EnumerableSet.Bytes32Set;

    IJellyAccessControls public accessControls;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant override TEMPLATE_TYPE = 6;
    bytes32 public constant override TEMPLATE_ID = keccak256("MERKLE_LIST_V2");

    struct Proof {
        string merkleURI;
    }

    EnumerableSet.Bytes32Set private roots;
    mapping(bytes32 => Proof) public proofs;
    
    /// @notice Whether initialised or not.
    bool private initialised;

    constructor() {
    }

    /**
     * @notice Initializes token point list with reference token.
     * @param _merkleRoot Merkle Root
     */

    function initMerkleList(address _accessControls, bytes32 _merkleRoot, string memory _merkleURI) public {
        require(!initialised, "Already initialised");

        proofs[_merkleRoot] = Proof(_merkleURI);
        roots.add(_merkleRoot);

        accessControls = IJellyAccessControls(_accessControls);
        initialised = true;
    }

    /**
     * @notice Adds merkle proof to the list
     * @param _merkleRoot Merkle Root
     */
    function addProof(bytes32 _merkleRoot, string memory _merkleURI) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "addProof: Sender must be admin"
        );
        roots.add(_merkleRoot);
        proofs[_merkleRoot].merkleURI = _merkleURI;
    }

    /**
     * @notice Deletes merkle proof.
     * @param _merkleRoot Merkle Root
     */
    function deleteProof(bytes32 _merkleRoot) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "deleteProof: Sender must be admin"
        );
        roots.remove(_merkleRoot);
    }

    /**
     * @notice Updates Merkle Root.
     * @param _merkleRoot Merkle Root
     */
    function updateMerkleURI(bytes32 _merkleRoot, string memory _merkleURI) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "updateMerkle: Sender must be admin"
        );
        require(roots.contains(_merkleRoot), "Incorrect Merkle URI");
        proofs[_merkleRoot].merkleURI = _merkleURI;

    }

    function currentMerkleRoot() public view returns (bytes32) {
        uint256 index = roots.length() - 1;
        return roots.at(index);
    }

    function currentMerkleURI() public view returns (string memory) {
        return proofs[currentMerkleRoot()].merkleURI;
    }

    /**
     * @notice Checks if account address is in the list (has any tokens).
     * @param _account Account address.
     * @return bool True or False.
     */
    function tokensClaimable(bytes32 _merkleRoot, uint _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) public view returns (uint256) {
        require(roots.contains(_merkleRoot));
        bytes32 leaf = keccak256(abi.encodePacked(_index, _account, _amount));
        (bool valid, uint256 index) = MerkleProofIndex.verify(_merkleProof, _merkleRoot, leaf);
        if (!valid) {
            return 0;
        }
        return _amount;
    }


    /* ========== Factory Functions ========== */

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) public override {
        (
        address _accessControls,
        bytes32 _merkleRoot, 
        string memory _merkleURI
        ) = abi.decode(_data, (address, bytes32, string));

        initMerkleList(
                       _accessControls,
                       _merkleRoot,
                       _merkleURI
                    );
    }

   /** 
     * @dev Generates init data for Farm Factory
  */
    function getInitData(
        address _accessControls,
        bytes32 _merkleRoot,
        string memory _merkleURI
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(
                        _accessControls,
                        _merkleRoot,
                        _merkleURI
                        );
    }


}

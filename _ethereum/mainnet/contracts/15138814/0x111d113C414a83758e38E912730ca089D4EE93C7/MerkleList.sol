pragma solidity 0.8.6;


import "MerkleProofIndex.sol";
import "IJellyAccessControls.sol";
import "IJellyContract.sol";

/**
 * @notice TokenAllowList - Allow List that references a given `token` balance to return approvals.
 */
contract MerkleList is IJellyContract  {
 
    bytes32 private merkleRoot;
    string private merkleURI; 
    IJellyAccessControls public accessControls;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant override TEMPLATE_TYPE = 6;
    bytes32 public constant override TEMPLATE_ID = keccak256("MERKLE_LIST");


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
        merkleRoot = _merkleRoot;
        merkleURI = _merkleURI;
        accessControls = IJellyAccessControls(_accessControls);
        initialised = true;
    }

    /**
     * @notice Updates Merkle Root.
     * @param _merkleRoot Merkle Root
     */
    function updateProof(bytes32 _merkleRoot, string memory _merkleURI) public {
        require(
            accessControls.hasAdminRole(msg.sender) ||  accessControls.hasOperatorRole(msg.sender),
            "updateProof: Sender must be admin"
        );
        merkleRoot = _merkleRoot;
        merkleURI = _merkleURI;
    }

    function currentMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function currentMerkleURI() public view returns (string memory) {
        return merkleURI;
    }


    /**
     * @notice Checks if account address is in the list (has any tokens).
     * @param _account Account address.
     * @return bool True or False.
     */
    function tokensClaimable(bytes32 _merkleRoot, uint _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) public view returns (uint256) {
        require(merkleRoot == _merkleRoot);
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

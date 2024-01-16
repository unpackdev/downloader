// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./MerkleProofUpgradeable.sol";

contract NodeV2 is Initializable, ERC1155Upgradeable, OwnableUpgradeable {
    mapping(uint256 => bytes32) public roots;
    mapping(uint256 => uint256) public expirations;
    mapping(uint256 => mapping(address => bool)) private _claimed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init(
            "https://ipfs.io/ipfs/QmZQEPPGL9sNDekzjFeiAzCQNQHf6nBwGfxe7SrerXKLhq/{id}.json"
        );
        __Ownable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setWhitelist(
        uint256 id,
        bytes32 root,
        uint256 expiration
    ) public onlyOwner {
        roots[id] = root;
        expirations[id] = expiration;
    }

    function verify(
        uint256 id,
        address owner,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return _verify(roots[id], _leaf(owner, id), proof);
    }

    function claim(uint256 id, bytes32[] calldata proof) public {
        require(verify(id, msg.sender, proof), "Node: Invalid proof");
        require(expirations[id] >= block.timestamp, "Node: expired");
        require(!_claimed[id][msg.sender], "Node: already claimed");
        _claimed[id][msg.sender] = true;
        _mint(msg.sender, id, 1, "");
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override {
        require(false, "Node: can't transfer");
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override {
        require(false, "Node: can't transfer");
    }

    function _leaf(address account, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, tokenId));
    }

    function _verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./MerkleProof.sol";

/// @notice Struct containing infos about airdrop
/// @param root Root hash of the merkle tree
/// @param expiry Max date to claim the airdrop
/// @param price Price in wei to pay per token
struct DropData {
    bytes32 root;
    uint256 expiry;
    uint256 price;
}

/// @title LongDefiSushiAirdrop
/// @author HHK-ETH
/// @notice Airdrop any erc1155 token to selected addresses using merkle tree
contract LongDefiSushiAirdrop is ERC1155TokenReceiver {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_NotOwner();
    error Error_DateExpired();
    error Error_InvalidAmount();
    error Error_InvalidPayment();
    error Error_InvalidProof();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event SetDrop(uint256 indexed id, bytes32 root, uint256 maxClaimDate, ERC1155 token, uint256 price);
    event Claimed(uint256 indexed id, address indexed to, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Mutable variables & constructor
    /// -----------------------------------------------------------------------

    /// @notice owner of the contract
    address internal owner;
    /// @notice drop id => data
    mapping(uint256 => DropData) internal drop;
    /// @notice drop id => address => amount claimed
    mapping(uint256 => mapping(address => uint256)) public claimed;
    /// @notice token address
    ERC1155 internal token;

    constructor(ERC1155 tokenAddress) {
        owner = msg.sender;
        token = tokenAddress;
    }

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Modifier to make functions callable by owner only
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert Error_NotOwner();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    /// @notice Edit or add new token Id and airdrop merkle root
    /// @param id Id of the token to edit/add
    /// @param root Merkle root of the airdrop
    /// @param expiry Max date the token can be claimed
    /// @param price Price in wei to pay per token
    function setDrop(uint256 id, bytes32 root, uint256 expiry, uint256 price) external onlyOwner {
        drop[id] = DropData(root, expiry, price);

        emit SetDrop(id, root, expiry, token, price);
    }

    /// @notice Claim airdrop using merkle proofs
    /// @param id Id of the token to claim, used to compute the leaf
    /// @param to Address to receive the airdrop, used to compute the leaf
    /// @param amount Amount to claim, user can decide to claim less than deserved amount
    /// @param maxAmount Total amount deserved to the user, used to compute the leaf
    /// @param proof Array of ordered merkle proofs to compute the root
    function claim(uint256 id, address to, uint256 amount, uint256 maxAmount, bytes32[] calldata proof) external payable {
        DropData memory data = drop[id];
        if (data.expiry < block.timestamp) {
            revert Error_DateExpired();
        }

        if (msg.value < data.price * amount) {
            revert Error_InvalidPayment();
        }
        
        uint256 totalClaimed = claimed[id][to] + amount;
        if (totalClaimed > maxAmount) {
            revert Error_InvalidAmount();
        }

        bytes32 leaf = keccak256(abi.encodePacked(id, to, maxAmount));
        if (!MerkleProof.verify(proof, data.root, leaf)) {
            revert Error_InvalidProof();
        }

        claimed[id][to] = totalClaimed;
        token.safeTransferFrom(address(this), to, id, amount, "");

        emit Claimed(id, to, amount);
    }

    /// @notice Transfer ownership of the contract to a new address
    /// @param newOwner New owner of the contract
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    /// @notice Edit the ERC1155 to interact with
    /// @param newToken New token
    function setToken(ERC1155 newToken) external onlyOwner {
        token = newToken;
    }

    /// @notice Withdraw ETH from the contract
    function withdraw() external onlyOwner {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        require(success);
    }

    /// -----------------------------------------------------------------------
    /// No state change functions
    /// -----------------------------------------------------------------------

    /// @notice View function to get token dropData
    /// @param id Id of the token/airdrop
    /// @return data Returns the DropData struct
    function dropData(uint id) external view returns (DropData memory data) {
        return drop[id];
    }

    /// @notice View function to get the admin infos
    /// @return _owner Return owner of the contract
    /// @return _token Return ERC1155 token used by the contract
    function adminInfos() external view returns (address _owner, ERC1155 _token) {
        return (owner, token);
    }

    /// @dev ERC1155 compliance
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev ERC1155 compliance
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}
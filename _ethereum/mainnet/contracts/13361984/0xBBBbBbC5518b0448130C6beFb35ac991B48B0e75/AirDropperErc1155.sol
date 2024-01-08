// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.9;


import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Receiver.sol";

contract AirDropperErc1155 is Ownable, ERC1155Receiver {

    uint256 public constant DEFAULT_AIRDROP_EXPIRATION = 90 * 24 * 60 * 60;
    uint256 public constant DEFAULT_ADMIN_WITHDRAWAL  = 30 * 24 * 60 * 60;

    struct AirDrop {
        ERC1155 token;              // 20 bytes
        uint256 tokenId;
        uint64 expirationTimestamp; // 8 bytes
        bytes32 merkleRoot;
        uint256 amount;
        address creator;
        mapping(uint256 => uint256) claimedBitMap;
    }

    mapping(uint256 => AirDrop) public airDrops;
    mapping(uint256 => bool) public isPaused;

    function addErc1155Airdrop(
        uint256 airdropId,
        ERC1155 token,
        uint256 tokenId,
        uint256 amount,
        bytes32 merkleRoot,
        uint256 expirationSeconds
    )
    external
    {
        require(!isPaused[0], "Paused");

        AirDrop storage airDrop = airDrops[airdropId];
        require(address(airDrop.token) == address(0), "Airdrop already exists");
        // require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Can't transfer tokens from msg.sender");
        token.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        airDrop.token = token;
        airDrop.tokenId = tokenId;
        airDrop.merkleRoot = merkleRoot;
        airDrop.amount = amount;
        airDrop.creator = msg.sender;
        if (expirationSeconds > 0) {
            airDrop.expirationTimestamp = uint64(block.timestamp + expirationSeconds);
        } else {
            airDrop.expirationTimestamp = uint64(block.timestamp + DEFAULT_AIRDROP_EXPIRATION);
        }
        emit AddedAirdrop(airdropId, token, tokenId, amount);
    }

    function isClaimed(uint256 airdropId, uint256 index) public view returns (bool) {
        // to save the gas, whether user claim the token is stored in bitmap
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        AirDrop storage airDrop = airDrops[airdropId];
        uint256 claimedWord = airDrop.claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 airdropId, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        AirDrop storage airDrop = airDrops[airdropId];
        airDrop.claimedBitMap[claimedWordIndex] = airDrop.claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 airdropId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    )
    external
    {
        require(!isPaused[1], "Paused");
        AirDrop storage airDrop = airDrops[airdropId];

        require(address(airDrop.token) != address(0), "Airdrop with given Id doesn't exists");
        require(!isClaimed(airdropId, index), "Account already claimed tokens");
        require(block.timestamp <= airDrop.expirationTimestamp, "Airdrop expired");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, airDrop.merkleRoot, node), "Invalid Merkle-proof");

        airDrop.amount = airDrop.amount - amount;
        // Mark it claimed and send the token.
        _setClaimed(airdropId, index);
        airDrop.token.safeTransferFrom(address(this), account, airDrop.tokenId, amount, "");

        emit Claimed(airdropId, index, account, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawFee() external onlyOwner  {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Airdrop creator is able to withdraw unclaimed tokens after expiration date is over
     */
    function withdrawTokensFromExpiredAirdrop(uint256 airdropId) external {
        require(!isPaused[2], "Paused");
        AirDrop storage airDrop = airDrops[airdropId];
        require(address(airDrop.token) != address(0), "Airdrop with given Id doesn't exists");
        require(airDrop.creator == msg.sender, "Only airdrop creator can withdraw");
        require(airDrop.expirationTimestamp < block.timestamp, "Airdrop isn't expired yet");
        require(airDrop.amount > 0, "Airdrop balance is empty");
        uint256 amount = airDrop.amount;
        airDrop.amount = 0;
        airDrop.token.safeTransferFrom(address(this), msg.sender, airDrop.tokenId, amount, "");
    }

    /**
     * @notice Admin is able to withdraw tokens unclaimed by creators 1 month after expiration date is over
     */
    function adminWithdrawTokensFromExpiredAirdrop(uint256 airdropId) external onlyOwner {
        AirDrop storage airDrop = airDrops[airdropId];
        require(address(airDrop.token) != address(0), "Airdrop with given Id doesn't exists");
        require(airDrop.expirationTimestamp + DEFAULT_ADMIN_WITHDRAWAL < block.timestamp,
            "need to wait creator withdrawal expiration");
        require(airDrop.amount > 0, "Airdrop balance is empty");
        uint256 amount = airDrop.amount;
        airDrop.amount = 0;
        airDrop.token.safeTransferFrom(address(this), msg.sender, airDrop.tokenId, amount, "");
    }

    function setPause(uint256 i, bool _isPaused) onlyOwner external {
        isPaused[i] = _isPaused;
    }

    event AddedAirdrop(uint256 airdropId, ERC1155 token, uint256 tokenId, uint256 amount);
    event Claimed(uint256 airdropId, uint256 index, address account, uint256 amount);
    event Received(address, uint);

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    override
    returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    override
    returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}

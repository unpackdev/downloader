// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./IMerkleDistributor.sol";


contract MetakeyDistributor is IMerkleDistributor, Ownable, ReentrancyGuard{

    
//  __       __             __                __                                  _______   __              __                __  __                    __                         
// |  \     /  \           |  \              |  \                                |       \ |  \            |  \              |  \|  \                  |  \                        
// | $$\   /  $$  ______  _| $$_     ______  | $$   __   ______   __    __       | $$$$$$$\ \$$  _______  _| $$_     ______   \$$| $$____   __    __  _| $$_     ______    ______  
// | $$$\ /  $$$ /      \|   $$ \   |      \ | $$  /  \ /      \ |  \  |  \      | $$  | $$|  \ /       \|   $$ \   /      \ |  \| $$    \ |  \  |  \|   $$ \   /      \  /      \ 
// | $$$$\  $$$$|  $$$$$$\\$$$$$$    \$$$$$$\| $$_/  $$|  $$$$$$\| $$  | $$      | $$  | $$| $$|  $$$$$$$ \$$$$$$  |  $$$$$$\| $$| $$$$$$$\| $$  | $$ \$$$$$$  |  $$$$$$\|  $$$$$$\
// | $$\$$ $$ $$| $$    $$ | $$ __  /      $$| $$   $$ | $$    $$| $$  | $$      | $$  | $$| $$ \$$    \   | $$ __ | $$   \$$| $$| $$  | $$| $$  | $$  | $$ __ | $$  | $$| $$   \$$
// | $$ \$$$| $$| $$$$$$$$ | $$|  \|  $$$$$$$| $$$$$$\ | $$$$$$$$| $$__/ $$      | $$__/ $$| $$ _\$$$$$$\  | $$|  \| $$      | $$| $$__/ $$| $$__/ $$  | $$|  \| $$__/ $$| $$      
// | $$  \$ | $$ \$$     \  \$$  $$ \$$    $$| $$  \$$\ \$$     \ \$$    $$      | $$    $$| $$|       $$   \$$  $$| $$      | $$| $$    $$ \$$    $$   \$$  $$ \$$    $$| $$      
//  \$$      \$$  \$$$$$$$   \$$$$   \$$$$$$$ \$$   \$$  \$$$$$$$ _\$$$$$$$       \$$$$$$$  \$$ \$$$$$$$     \$$$$  \$$       \$$ \$$$$$$$   \$$$$$$     \$$$$   \$$$$$$  \$$      
//                                                               |  \__| $$                                                                                                        
//                                                                \$$    $$                                                                                                        
//                                                                 \$$$$$$                                                                                                         


    //token address
    address public override token;
    bytes32 public override merkleRoot;

    //This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    uint256 public currentDropIndex = 0;
    uint256 public deadline;

    uint256 public tokenIdToTransfer;
    address public addressToTransferFrom;

    event TokenIdSet(uint id, address from, uint time);
    event MerkleRootAndTokenSet(bytes32 root, address token);

     constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Sets the token id to transfer, claim deadline and address to transfer from
     */
    function setTransferIdAndAccount(uint _tokenIdToTransfer, uint _deadline, address _addressToTransferFrom) private {
        require(IERC1155(token).isApprovedForAll(_addressToTransferFrom, address(this)), 'Metakey Distributor not approved to spend NFT');

        tokenIdToTransfer = _tokenIdToTransfer;
        deadline = block.timestamp + _deadline;
        addressToTransferFrom = _addressToTransferFrom;

        emit TokenIdSet(_tokenIdToTransfer, addressToTransferFrom, deadline);
    }

    function setDeadline(uint _deadline) external onlyOwner {
        deadline = block.timestamp + _deadline;
    }

    function getSetTokenId() external view returns(uint){
        return tokenIdToTransfer;
    }

    /**
     * @dev Sets the new merkle root
     */
    function setClaimConfig (address token_, bytes32 merkleRoot_, uint _tokenIdToTransfer, uint _deadline, address _addressToTransferFrom) external onlyOwner {
        token = token_;
        merkleRoot = merkleRoot_;
        currentDropIndex += 1;
        emit MerkleRootAndTokenSet(merkleRoot, token);
        setTransferIdAndAccount(_tokenIdToTransfer, _deadline, _addressToTransferFrom);

    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[currentDropIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[currentDropIndex][claimedWordIndex] = claimedBitMap[currentDropIndex][claimedWordIndex] | (1 << claimedBitIndex);
        
    }


    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override nonReentrant{
        require(block.timestamp <= deadline, "The claiming time has passed.");
        require(IERC1155(token).balanceOf(addressToTransferFrom, tokenIdToTransfer) >= amount, 'No NFTs left');
        require(!isClaimed(index), 'Metakey Distributor: NFT already claimed.');
        require(account != address(0), "Cannot mint to 0x0.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Metakey Distributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);  
        IERC1155(token).safeTransferFrom(addressToTransferFrom, account, tokenIdToTransfer, amount, '');

        emit Claimed(index, account, amount);
    }
}
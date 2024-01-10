// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract WinDaoToken is ERC20, Ownable{
    using SafeMath for uint256;

    bytes32 public   merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

     // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);


    constructor() ERC20("WinDao", "WIN") {
        _mint(msg.sender,7900000000 * 10**18);
    }

    // The functions below are overrides required by Solidity.
    function isClaimed(uint256 index) public view  returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external  {
        require(!isClaimed(index), 'Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender , amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(this).transfer(msg.sender , amount), 'Transfer failed.');

        emit Claimed(index, msg.sender , amount);
    }

    function setMerkleRoot (bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset,address to) onlyOwner external { 
        IERC20(asset).transfer(to, IERC20(asset).balanceOf(address(this)));
    }
    
}
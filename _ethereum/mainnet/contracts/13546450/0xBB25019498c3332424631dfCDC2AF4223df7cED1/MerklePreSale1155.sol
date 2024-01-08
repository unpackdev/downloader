// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IMerklePreSale.sol";
import "./ISuper1155.sol";

contract MerklePreSale1155 is IMerklePreSale, Ownable {
    using SafeMath for uint256;

    address public immutable override token;

    address payable public receiver;

    uint256 public price;

    uint256 public purchaseLimit;

    //bytes32 public immutable override merkleRoot;
    mapping ( uint256 => bytes32 ) public merkleRoots;

    // This is a packed array of booleans.
    mapping( uint256 => mapping( uint256 => uint256) ) private purchasedBitMap;

    constructor( address _token, address payable _receiver, uint256 _price, uint256 _purchaseLimit) {
        token = _token;
        receiver = _receiver;
        price = _price;
        purchaseLimit = _purchaseLimit;
     }

    function setRoundRoot(uint256 groupId, bytes32 merkleRoot) external onlyOwner {
      merkleRoots[groupId] = merkleRoot;
    }

    function updateReceiver(address payable _receiver) external onlyOwner {
      receiver = _receiver;
    }

    function updatePrice(uint256 _price) external onlyOwner {
      price = _price;
    }

    function updatePurchaseLimit(uint256 _purchaseLimit) external onlyOwner {
      purchaseLimit = _purchaseLimit;
    }

    function isPurchased( uint256 groupId, uint256 index ) public view override returns ( bool ) {
        uint256 purchasedWordIndex = index / 256;
        uint256 purchasedBitIndex = index % 256;
        uint256 purchasedWord = purchasedBitMap[groupId][purchasedWordIndex];
        uint256 mask = ( 1 << purchasedBitIndex );
        return purchasedWord & mask == mask;
    }

    function _setPurchased( uint256 groupId, uint256 index ) private {
        uint256 purchasedWordIndex = index / 256;
        uint256 purchasedBitIndex = index % 256;
        purchasedBitMap[groupId][purchasedWordIndex] = purchasedBitMap[groupId][purchasedWordIndex] | ( 1 << purchasedBitIndex );
    }

    function purchase( uint256 groupId, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof ) public payable override {
        require( !isPurchased( groupId, index ), 'MerklePreSale: Drop already purchased.' );
        require( amount <= purchaseLimit, 'MerklePreSale: Buy fewer items');
        uint256 totalCost = amount.mul(price);
        require( msg.value >= totalCost, 'MerklePreSale: Send more eth');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, uint(1)));
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(merkleProof[i], node));
            } else {
                node = keccak256(abi.encodePacked(node, merkleProof[i]));
            }
            path /= 2;
        }

        // Check the merkle proof
        require(node == merkleRoots[groupId], 'MerklePreSale: Invalid proof.' );
        // Mark it purchased and send the token.
        _setPurchased(  groupId, index );

        uint256 newTokenIdBase = groupId << 128;
        uint256 currentMintCount = ISuper1155( token ).groupMintCount(groupId);

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint[](amount);
        for(uint256 i = 0; i < amount; i++) {
          ids[i] = newTokenIdBase.add(currentMintCount).add(i).add(1);
          amounts[i] = uint256(1);
        }
        (bool paymentSuccess, ) = receiver.call{ value: msg.value }("");
        require( paymentSuccess, 'MerklePreSale: payment failure');

        ISuper1155( token ).mintBatch( account, ids, amounts, "" );
        emit Purchased( index, account, amount );
    }
}

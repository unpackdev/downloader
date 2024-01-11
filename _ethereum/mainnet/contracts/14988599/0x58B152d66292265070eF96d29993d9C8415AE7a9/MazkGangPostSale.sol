// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MazkGang.sol";
import "./ERC721Holder.sol";

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProof.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProof2 {
  function verify(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool isValid) {
    assembly {
      let computedHash := leaf

      // Initialize `data` to the offset of `proof` in the calldata.
      let data := proof.offset

      // Iterate over proof elements to compute root hash.
      for {
        // Left shift by 5 is equivalent to multiplying by 0x20.
        let end := add(data, shl(5, proof.length))
      } lt(data, end) {
        data := add(data, 0x20)
      } {
        let loadedData := calldataload(data)
        // Slot of `computedHash` in scratch space.
        // If the condition is true: 0x20, otherwise: 0x00.
        let scratch := shl(5, gt(computedHash, loadedData))

        // Store elements to hash contiguously in scratch space.
        // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
        mstore(scratch, computedHash)
        mstore(xor(scratch, 0x20), loadedData)
        computedHash := keccak256(0x00, 0x40)
      }
      isValid := eq(computedHash, root)
    }
  }
}

contract MazkGangPostSale is Ownable, ReentrancyGuard, ERC721Holder {
    MazkGang public immutable mazk;

    bytes32 root;

    // Presale is free mint
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;

    // Public sale has variable price
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;

    uint256 public publicSalePrice = 0.05 ether;

    mapping(address => uint256) public numberMinted;

    constructor(
        MazkGang _mazk,
        uint256 _preSaleStartTime,
        uint256 _publicSaleStartTime,
        uint256 _preSaleEndTime,
        uint256 _publicSaleEndTime,
        bytes32 _root
    ) {
        mazk = _mazk;

        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
        
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;

        root = _root;
    }

    //for merkle tree
    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function _mint(uint256 amount) internal {
        require(amount <= 100, "Hacker");

        unchecked {
            uint256 supply = mazk.totalSupply();

            if (amount <= 5) {
                mazk.lastDevMint(amount);

                for (uint256 j = 0; j < amount; ++j) {
                    mazk.transferFrom(address(this), msg.sender, supply++);
                }
            } else {
                for (uint256 i = 0; i < amount; i += 5) {
                    if (amount - i < 5) {
                        mazk.lastDevMint(amount - i);

                        for (uint256 j = 0; j < amount - i; ++j) {
                            mazk.transferFrom(address(this), msg.sender, supply++);
                        }
                    } else {
                        mazk.lastDevMint(5);

                        // Loop unrolling
                        mazk.transferFrom(address(this), msg.sender, supply++);
                        mazk.transferFrom(address(this), msg.sender, supply++);
                        mazk.transferFrom(address(this), msg.sender, supply++);
                        mazk.transferFrom(address(this), msg.sender, supply++);
                        mazk.transferFrom(address(this), msg.sender, supply++);
                    }
                }
            }
        }
    }

    function airdropMint(uint256 maxAmount, uint256 amount, bytes32[] calldata proof) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAmount));
        require(MerkleProof2.verify(proof, root, leaf), "Incorrect proof");

        require(isPreSaleOn(), "Airdrop not active");

        require(
            numberMinted[msg.sender] + amount <= maxAmount,
            "Limited"
        );

        _mint(amount);
        numberMinted[msg.sender] += amount;
    }

    function publicSaleMint(uint256 amount) external payable nonReentrant {
        require(msg.sender == tx.origin, "Not EOA");
        require(amount <= 5, "Limit 5");
        require(
            isPublicSaleOn(),
            "public sale has not begun yet"
        );

        refundIfOver(publicSalePrice * amount);
        _mint(amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isPreSaleOn() 
    public view returns (bool) {
        return block.timestamp >= preSaleStartTime &&
        block.timestamp < preSaleEndTime;
    }

    function isPublicSaleOn() 
    public view returns (bool) {
        return block.timestamp >= publicSaleStartTime &&
        block.timestamp < publicSaleEndTime;
    }

    //Just in case, we have to change.
    function setPreSaleTime(uint256 _start, uint256 _end) external onlyOwner {
        preSaleStartTime = _start;
        preSaleEndTime = _end;
    }

    //Just in case, we have to change.
    function setPublicSaleTime(uint256 _start, uint256 _end) external onlyOwner {
        publicSaleStartTime = _start;
        publicSaleEndTime = _end;
    }

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function restoreOwnership() external onlyOwner {
        mazk.transferOwnership(owner());
    }

    function withdrawMoney(address to) external onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
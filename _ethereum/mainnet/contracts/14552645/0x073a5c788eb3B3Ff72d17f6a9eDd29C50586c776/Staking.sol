// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Context.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

contract Staking is Ownable, ERC1155Holder {
    IERC721 private landContract;
    IERC721 private avatarContract = IERC721(0x31eAa2E93D7AFd237F87F30c0Dbd3aDEB9934f1B);
    IERC1155 private furnitureContract = IERC1155(0xb644476e44A797Db3B8a6A16f2e63e8D5a541b67);

    mapping (bytes32 => bool) public proofs;
    mapping (address => uint256) public tickets;
    uint256 public totalTickets;
    bool public stakingEnabled = true;
    bool public unstakingEnabled = false;

    event Stake(address indexed userAddress, uint256[] landIds, uint256[] avatarIds, uint256[] furnitureIds, uint256[] furnitureAmounts, uint256 blockNumber);
    event Unstake(address indexed userAddress, uint256[] landIds, uint256[] avatarIds, uint256[] furnitureIds, uint256[] furnitureAmounts, uint256 blockNumber);
    
    constructor() {}

    function transferERC721(IERC721 contractERC721, address from, address to, uint256[] calldata ids) internal {
        uint256 length = ids.length;
        for(uint256 i = 0; i < length;) {
            contractERC721.transferFrom(from, to, ids[i]);

            unchecked {
                ++i;
            }
        }
    }
    
    function stake(uint256[] calldata landIds, uint256[] calldata avatarIds, uint256[] calldata furnitureIds, uint256[] calldata furnitureAmounts) external {
        require(stakingEnabled, "Staking is disabled");

        bytes32 proof = keccak256(abi.encode(_msgSender(), landIds, avatarIds, furnitureIds, furnitureAmounts, block.number));
        require(!proofs[proof], "Proof already exists");
        proofs[proof] = true;

        transferERC721(landContract, _msgSender(), address(this), landIds);
        transferERC721(avatarContract, _msgSender(), address(this), avatarIds);

        uint256 earnedTickets;
        unchecked {
            earnedTickets = landIds.length + avatarIds.length;
        }

        uint256 furnitureLength = furnitureIds.length;
        if(furnitureLength > 0){
            furnitureContract.safeBatchTransferFrom(_msgSender(), address(this), furnitureIds, furnitureAmounts, "");

            for(uint256 i = 0; i < furnitureLength;) {
                require(furnitureIds[i] < 4, "Only mega-rare furnitures");

                unchecked {
                    earnedTickets += furnitureAmounts[i++];
                }
            }
        }

        require(earnedTickets > 0, "No NFTs selected to stake");

        unchecked {
            tickets[_msgSender()] += earnedTickets;
            totalTickets += earnedTickets;
        }

        emit Stake(_msgSender(), landIds, avatarIds, furnitureIds, furnitureAmounts, block.number);
    }

    function unstake(uint256[] calldata landIds, uint256[] calldata avatarIds, uint256[] calldata furnitureIds, uint256[] calldata furnitureAmounts, uint256 blockNumber) external {
        require(unstakingEnabled, "Unstaking is disabled");

        bytes32 proof = keccak256(abi.encode(_msgSender(), landIds, avatarIds, furnitureIds, furnitureAmounts, blockNumber));
        require(proofs[proof], "Proof does not exist");
        delete proofs[proof];

        transferERC721(landContract, address(this), _msgSender(), landIds);
        transferERC721(avatarContract, address(this), _msgSender(), avatarIds);

        uint256 earnedTickets;
        unchecked {
            earnedTickets = landIds.length + avatarIds.length;
        }

        uint256 furnitureLength = furnitureIds.length;
        if(furnitureLength > 0){
            furnitureContract.safeBatchTransferFrom(address(this), _msgSender(), furnitureIds, furnitureAmounts, "");

            for(uint256 i = 0; i < furnitureLength;) {
                unchecked {
                    earnedTickets += furnitureAmounts[i++];
                }
            }
        }

        unchecked {
            tickets[_msgSender()] -= earnedTickets;
            totalTickets -= earnedTickets;
        }

        emit Unstake(_msgSender(), landIds, avatarIds, furnitureIds, furnitureAmounts, blockNumber);
    }

    function enableStaking() external onlyOwner {
        require(!unstakingEnabled, "First disable unstaking");
        stakingEnabled = true;
    }

    function disableStaking() external onlyOwner {
        stakingEnabled = false;
    }

    function enableUnstaking() external onlyOwner {
        require(!stakingEnabled, "First disable staking");
        unstakingEnabled = true;
    }

    function disableUnstaking() external onlyOwner {
        unstakingEnabled = false;
    }

    function setLandAddress(address landAddress) external onlyOwner {
        landContract = IERC721(landAddress);
    }
}
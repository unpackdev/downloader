//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

contract Referral is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event MintOwner(address indexed collection, address indexed owner, address indexed referrer, uint256[] tokens, uint256 gained, uint256 spent, uint256 reward);

    struct MintRequest {
        uint256 nonce;
        uint256 price;
        uint256[] tokenIds;
        address referralAddress;
        address collectionAddress;
        address tokensOwnerAddress;
        uint256 systemRewardPercent;
        uint256 referralRewardPercent;
    }

    address public signer;
    uint256 public interval = 5 minutes;
    uint256 private minPrice = 0.001 ether;

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setSigner(address signerAddress) external onlyOwner {
        signer = signerAddress;
    }

    function verify(MintRequest memory mintRequest, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            keccak256(
                abi.encodePacked(
                    mintRequest.nonce,
                    mintRequest.price,
                    mintRequest.tokenIds,
                    mintRequest.referralAddress,
                    mintRequest.collectionAddress,
                    mintRequest.tokensOwnerAddress,
                    mintRequest.systemRewardPercent,
                    mintRequest.referralRewardPercent
                )
            ).toEthSignedMessageHash().recover(signature) == signer;
    }

    function mint(MintRequest calldata mintRequest, bytes calldata signature)
        external
        payable
    {
        uint256 totalPrice = mintRequest.price.mul(mintRequest.tokenIds.length);
        require(block.timestamp.sub(mintRequest.nonce) <= interval, "Signature is stale");
        require(totalPrice != 0, "Total price cannot be zero");
        require(msg.value >= totalPrice, "Not enough ETH");
        require(msg.value >= minPrice, "Not enough Ether sent");
        require(verify(mintRequest, signature), "Invalid request");

        for (uint256 i; i < mintRequest.tokenIds.length; i++) {
            IERC721(mintRequest.collectionAddress).safeTransferFrom(
                mintRequest.tokensOwnerAddress,
                msg.sender,
                mintRequest.tokenIds[i]
            );
        }

        uint256 percent = msg.value.div(10000);
        uint256 systemReward = percent.mul(mintRequest.systemRewardPercent);
        uint256 referralReward = percent.mul(mintRequest.referralRewardPercent);
        uint256 spent = systemReward.add(referralReward);
        uint256 ownerReward = msg.value.sub(spent);

        if (referralReward != 0) {
            (bool referralPaymentSuccess, ) = mintRequest.referralAddress.call{ value: referralReward}("");
            require(referralPaymentSuccess, "Failed to send Ether to referral");
        }

        if (ownerReward != 0) {
            (bool ownerPaymentSuccess, ) = mintRequest.tokensOwnerAddress.call{value: ownerReward}("");
            require(ownerPaymentSuccess, "Failed to send Ether to owner");
        }

        emit MintOwner(mintRequest.collectionAddress, mintRequest.tokensOwnerAddress, mintRequest.referralAddress, mintRequest.tokenIds, ownerReward, spent, referralReward);
    }
}

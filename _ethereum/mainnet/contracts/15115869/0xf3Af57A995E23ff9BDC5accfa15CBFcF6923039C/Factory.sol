// SPDX-License-Identifier: MIT
// @author Eggshill.me

pragma solidity ^0.8.4;

import "./NFT.sol";
import "./Clones.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./VRFCoordinatorV2Interface.sol";

error ZeroAddress();
error WrongRate();

contract Factory is Ownable, ReentrancyGuard {
    VRFCoordinatorV2Interface public constant VRF_COORDINATOR =
        VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);

    address public erc721AImplementation;
    address public platform;

    uint256 public platformRate;
    uint256 public commission;

    uint64 public subscriptionId;

    event CreateNFT(address indexed nftAddress);

    constructor(
        address platform_,
        uint256 platformRate_,
        uint256 commission_
    ) {
        erc721AImplementation = address(new NFT());

        platform = platform_;
        platformRate = platformRate_;
        commission = commission_;

        subscriptionId = VRF_COORDINATOR.createSubscription();
    }

    function requestSubscriptionOwnerTransfer(address newOwner) public onlyOwner {
        VRF_COORDINATOR.requestSubscriptionOwnerTransfer(subscriptionId, newOwner);
    }

    function createSubscription() public onlyOwner {
        subscriptionId = VRF_COORDINATOR.createSubscription();
    }

    function createNFT(
        string memory name_,
        string memory symbol_,
        string memory notRevealedURI_,
        uint256 maxPerAddressDuringMint_,
        uint256 collectionSize_,
        uint256 amountForDevsAndPlatform_,
        address signer_
    ) public payable {
        if (msg.value < commission) revert EtherNotEnough();

        address clonedNFT = Clones.clone(erc721AImplementation);
        
        VRF_COORDINATOR.addConsumer(subscriptionId, clonedNFT);

        NFT(clonedNFT).initialize(
            name_,
            symbol_,
            notRevealedURI_,
            maxPerAddressDuringMint_,
            collectionSize_,
            amountForDevsAndPlatform_,
            subscriptionId,
            platformRate,
            platform,
            signer_
        );
        NFT(clonedNFT).transferOwnership(msg.sender);

        emit CreateNFT(clonedNFT);
    }

    function setPlatformParms(
        address payable platform_,
        uint256 platformRate_,
        uint256 commission_
    ) public onlyOwner {
        if (platform_ == address(0)) revert ZeroAddress();
        if (platformRate_ >= 100) revert WrongRate();

        platform = platform_;
        platformRate = platformRate_;
        commission = commission_;
    }

    function changeImplementation(address newImplementationAddress) public onlyOwner {
        erc721AImplementation = newImplementationAddress;
    }

    function withdrawEth(address destination_, uint256 amount_) external onlyOwner nonReentrant {
        if (destination_ == address(0)) revert ZeroAddress();

        (bool success, ) = destination_.call{value: amount_}("");

        if (!success) revert SendEtherFailed();
    }
}

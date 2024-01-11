// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Justin Maller
/// @title: Facets

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                    &&&     &&&#                                                    //
//                                              .&&&&&&&&     &&&&&&&&%                                               //
//                                         ,&&&&&&&&&&&&&     &&&&&&&&&&&&&#                                          //
//                                    .&&&&&&&&&&&&&&&&&&     &&&&&&&&&&&&&&&&&&%                                     //
//                               ,&&&&&&&&&&&&(                         ,&&&&&&&&&&&&&                                //
//                          *&&/                                                       ,&&%                           //
//                                            %&&&&&&&           &&&&&&&&,                                            //
//                            .%&&&&&&&&&&&&&&&&&&&&%      &%      &&&&&&&&&&&&&&&&&&&&&.                             //
//              #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,              //
//             .&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&              //
//              (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&               //
//               %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&.     ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                //
//                &&&&&&&&&&&&&&&&&&&&&&&&&&&      #&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&                 //
//                 &&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&      /&&&&&&&&&&&&&&&&&&&&&&&&                  //
//            ,     &&&&&&&&&&&&&&&&&&&&&&      ,&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&     &             //
//             &     &&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&      %&&&&&&&&&&&&&&&&&&&     %&             //
//             &&     &&&&&&&&&&&&&&&&&,      &&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&     /&#             //
//             &&&     &&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&     .&&,             //
//             &&&&     &&&&&&&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#      &&&&&&&&&&&&,     &&&              //
//             &&&&#     &&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&(     &&&&              //
//             &&&&&/     &&&&&&&%      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.      &&&&&&&%     &&&&&              //
//             &&&&&&.     &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&     &&&&&&              //
//             &&&&&&&     .&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&     &&&&&&&              //
//             ,&&&&&&&     /      *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &     &&&&&&&&              //
//              &&&&&&&&          &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&          &&&&&&&&&              //
//              &&&&&&&&&                                                                     &&&&&&&&&&              //
//              &&&&&&%                                                                          &&&&&&,              //
//              &&&        *       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &        &&&               //
//                      &&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&                       //
//                  ,&&&&&&&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&                   //
//                 ,&&&&&&&&&&&&&&       %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&&&%                  //
//                      &&&&&&&&&&&&,      /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&*                      //
//                          &&&&&&&&&&/      .&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&                           //
//                              %&&&&&&&#       &&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&                               //
//                                  *&&&&&&       &&&&&&&&&&&&&&&&&&&%       &&&&&&                                   //
//                                       &&&&       &&&&&&&&&&&&&&&(      ,&&&#                                       //
//                                           &&       &&&&&&&&&&&*      (&.                                           //
//                                                      &&&&&&&.                                                      //
//                                                        &&&                                                         //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./AdminControl.sol";
import "./ERC165Checker.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

import "./ERC721BurnRedeem.sol";
import "./ERC721CreatorCollectionBase.sol";
import "./DutchAuction.sol";

contract Facets is ERC721CreatorCollectionBase, IERC721CreatorExtensionApproveTransfer, DutchAuction, ReentrancyGuard, AdminControl {

    event SenderRefunded(
        uint256 received,
        uint256 returned
    );

    constructor(address creatorAddress, address signingAddress) {
        _initialize(
            creatorAddress,
            365, // purchaseMax_
            3650000000000000000, // purchasePrice_
            365, // purchaseLimit_
            365, // transactionLimit_ 
            0, // presalePurchasePrice_
            0, // presalePurchaseLimit_ 
            signingAddress, 
            false // useDynamicPresalePurchaseLimit_
        );
        minimumPrice = 500000000000000000;
        priceDropInterval = 300;
        priceDropMagnitude = 50000000000000000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCollectionBase, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId || ERC721CreatorCollectionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {ERC721CreatorCollectionBase-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public override payable nonReentrant {
        ERC721CreatorCollectionBase.purchase(amount, message, signature, nonce);
        uint256 totalPrice = amount * getCurrentPrice(presalePurchasePrice, purchasePrice);
        if (msg.value > totalPrice) {
            Address.sendValue(payable(msg.sender), msg.value - totalPrice);
            emit SenderRefunded(msg.value, msg.value - totalPrice);
        }
    }

    /**
     * Validate price
     */
    function _validatePrice(uint16 amount) internal override {
        require(msg.value >= amount * getCurrentPrice(presalePurchasePrice, purchasePrice), "Invalid purchase amount sent");
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }
    
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "Creator must implement IERC721CreatorCore");
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-approveTransfer}.
     */
    function approveTransfer(address from, address, uint256) external view override returns (bool) {
        return _validateTokenTransferability(from);
    }
}
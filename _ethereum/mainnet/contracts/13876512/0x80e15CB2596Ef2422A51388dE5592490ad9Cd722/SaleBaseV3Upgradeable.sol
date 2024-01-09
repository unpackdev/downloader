// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./FarbeArtV3Upgradeable.sol";

contract SaleBaseV3Upgradeable is Initializable, IERC721ReceiverUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address payable;

    // reference to the NFT contract
    FarbeArtSaleV3Upgradeable public NFTContract;
    // struct for secondary sale
    struct saleDetail {
        bool isSecondarySale;
    }

    // mappings of tokenId against saleDetails struct
    mapping(uint256 => saleDetail) public tokenIdToSaleDetails;
    
    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    // address of the platform wallet to which the platform cut will be sent
    address internal platformWalletAddress;

    /**
     * @dev Implementation of ERC721Receiver
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override virtual returns (bytes4) {
        // This will fail if the received token is not a FarbeArt token
        // _owns calls NFTContract
        require(_owns(address(this), _tokenId), "owner is not the sender");

        return this.onERC721Received.selector;
    }

    /**
     * @dev Internal function to check if address owns a token
     * @param _claimant The address to check
     * @param _tokenId ID of the token to check for ownership
     * @return bool Weather the _claimant owns the _tokenId
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (NFTContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev Internal function to transfer the NFT from this contract to another address
     * @param _receiver The address to send the NFT to
     * @param _tokenId ID of the token to transfer
     */
    function _transfer(address _receiver, uint256 _tokenId) internal {
        NFTContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @dev Internal function that calculates the cuts of all parties and distributes the payment among them
     * @param _seller Address of the seller
     * @param _creator Address of the original creator
     * @param _gallery Address of the gallery, 0 address if gallery is not involved
     * @param _creatorCut The cut of the original creator
     * @param _platformCut The cut that goes to the Farbe platform
     * @param _galleryCut The cut that goes to the gallery
     * @param _amount The total amount to be split
     * @param _tokenId The ID of the token that was sold
     */
    function _payout(
        address payable _seller,
        address payable _creator,
        address payable _gallery,
        uint16 _creatorCut,
        uint16 _platformCut,
        uint16 _galleryCut,
        uint256 _amount,
        uint256 _tokenId
    ) internal {
        // if this is a secondary sale
        if (getSecondarySale(_tokenId)) {
            // initialize amount to send to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale, wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)){
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // platform gets 2.5% on secondary sales (hard-coded)
            uint256 platformAmount = (25 * _amount) / 1000;
            // calculate amount to send to creator
            uint256 creatorAmount = (_creatorCut * _amount) / 1000;
            // calculate amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + creatorAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            payable(platformWalletAddress).sendValue(platformAmount);
            _creator.sendValue(creatorAmount);
            _seller.sendValue(sellerAmount);
        }
        // if this is a primary sale
        else {
            require(_seller == _creator, "Seller is not the creator");

            // dividing by 1000 because percentages are multiplied by 10 for values < 1%
            uint256 platformAmount = (_platformCut * _amount) / 1000;
            // initialize amount to be sent to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)) {
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // calculate the amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            _seller.sendValue(sellerAmount);
            payable(platformWalletAddress).sendValue(platformAmount);

            // set secondary sale to true
            setSecondarySale(_tokenId);
        }
    }

    /**
     * @dev External function to allow admin to change the address of the platform wallet
     * @param _address Address of the new wallet
    */
    function setPlatformWalletAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformWalletAddress = _address;
    }
    /**
     * @dev Internal function to update sale struct if sale is secondary sale
     * @param _tokenId ID of the token to check
    */
    function setSecondarySale(uint256 _tokenId) internal {
        require(msg.sender != address(0));
        tokenIdToSaleDetails[_tokenId].isSecondarySale = true;
    }

    /**
     * @dev Checks from the mapping if the token has been sold before
     * @param _tokenId ID of the token to check
     * @return bool Weather this is a secondary sale (token has been sold before)
    */
    function getSecondarySale(uint256 _tokenId) public view returns (bool) {
        return tokenIdToSaleDetails[_tokenId].isSecondarySale;
    }
    uint256[1000] private __gap;
}
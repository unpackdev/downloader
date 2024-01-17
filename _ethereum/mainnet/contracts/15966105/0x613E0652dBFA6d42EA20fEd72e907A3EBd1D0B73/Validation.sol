// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./ERC721.sol";
// import "./ERC721URIStorage.sol";
import "./Ownable.sol";
// import "./Counters.sol";
import "./LuckyBears.sol";

contract Validation is Ownable {
    uint256 public personalNFTLimit = 8;
    uint256 public companyNFTLimit = 9;
    address public nftContract;

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    struct ValidationData {
        address user; // Holder of the NFT
        uint256 purchaseLimit;
        bool used; //True if NFT has been used
    }

    error InvalidAddress();
    error NotTheOwnerOfNFT();
    error NFTHasBeenUsed();
    error ExceedingPurchaseLimitOfPersonalNFT();
    error ExceedingPurchaseLimitOfCompanyNFT();

    event UserAllowanceSet(
        address nftContract,
        address user,
        uint256 tokenId,
        uint256 purchaseLimit,
        bool permission
    );

    event NFTUsed(
        address nftContract,
        address user,
        uint256 productQuantity,
        uint256 tokenId
    );

    mapping(address => mapping(uint256 => ValidationData))
        public validationRecord;

    // mapping is contract address to NFT token Id to struct

    function setPersonalNFTLimit(uint256 _newLimit) external onlyOwner {
        personalNFTLimit = _newLimit;
    }

    function setCompanyNFTLimit(uint256 _newLimit) external onlyOwner {
        companyNFTLimit = _newLimit;
    }

    function getNFTIdentity(uint256 _id) public pure returns (string memory) {
        if (_id >= 38 && _id <= 721) {
            return "Personal NFT";
        } else if (_id >= 722 && _id <= 1000) {
            return "Company NFT";
        }
    }
    // calls when owner is setting allowance
    function setAllowance(
        address _nftHolder,
        uint256 _tokenId,
        bool _permission
    ) external onlyOwner {
        if (_nftHolder == address(0) || nftContract == address(0)) {
            revert InvalidAddress();
        }

        LuckyBears nft = LuckyBears(nftContract);
        address NFTHolder = nft.ownerOf(_tokenId);
        if (NFTHolder != _nftHolder) {
            revert NotTheOwnerOfNFT();
        }

        if (_tokenId >= 38 && _tokenId <= 721) {
            validationRecord[nftContract][_tokenId] = ValidationData(
                _nftHolder,
                personalNFTLimit,
                _permission
            );

            emit UserAllowanceSet(
                nftContract,
                _nftHolder,
                _tokenId,
                personalNFTLimit,
                _permission
            );
        } else if (_tokenId >= 722 && _tokenId <= 1000) {
            validationRecord[nftContract][_tokenId] = ValidationData(
                _nftHolder,
                companyNFTLimit,
                _permission
            );

            emit UserAllowanceSet(
                nftContract,
                _nftHolder,
                _tokenId,
                companyNFTLimit,
                _permission
            );
        }
    }
    // calls when verifying
    function validateBuyerAddress(uint256 _tokenId) public view returns (bool) {
        LuckyBears nft = LuckyBears(nftContract);
        address NFTHolder = nft.ownerOf(_tokenId);
        if (NFTHolder == msg.sender) {
            return true;
        }
        return false;
    }
    // calls when checking if NFT has been used
    function validateNFTUsage(uint256 _tokenId) public view returns (bool) {
        return validationRecord[nftContract][_tokenId].used;
    }
    // calls after the purchase to set the NFT as used
    function setNftUsed(
        uint256 _tokenId,
        uint256 _productQuantity // uint _productAllowance
    ) external {
        if (!validateBuyerAddress(_tokenId)) {
            revert NotTheOwnerOfNFT();
        }

        if (validateNFTUsage(_tokenId)) {
            revert NFTHasBeenUsed();
        }

        if (
            _tokenId >= 38 &&
            _tokenId <= 721 &&
            _productQuantity > personalNFTLimit
        ) {
            revert ExceedingPurchaseLimitOfPersonalNFT();
        }

        if (
            _tokenId >= 722 &&
            _tokenId <= 1000 &&
            _productQuantity > companyNFTLimit
        ) {
            revert ExceedingPurchaseLimitOfCompanyNFT();
        }

        // add another internal function to check allowance of products

        validationRecord[nftContract][_tokenId].used = true;

        emit NFTUsed(nftContract, msg.sender, _productQuantity, _tokenId);
    }

}

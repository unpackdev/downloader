// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @author: SWMS.de

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./GoldeneIngeStructs.sol";

contract DieGoldeneInge is AdminControl {
    address private _creator;
    address[] private nftImageHolders;


    bool isActive;
    Collection private collectionData;
    NFTDataAttributes[] private nftData;
    ContractData private contractData;

    mapping(uint256 => string) public _tokens;

    NFTDataAttributes[] private tokensData;

    constructor(
        address creator,
        string memory _title,
        uint256 _price,
        uint16 _editions,
        address payable _beneficiary,
        string[] memory hashes
    ) {
        _creator = creator;
        contractData.beneficiary = _beneficiary;
        contractData.isActive = true;
        contractData.APIEndpoint = "https://arweave.net/";
        setCollectionData(
            Collection({title: _title, price: _price, editions: _editions})
        );
        setNftData(hashes, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    modifier collectableIsActive() {
        require(contractData.isActive == true);
        _;
    }

    function containsOwner(address to, string memory hashString)
        public
        view
        returns (bool isInArray)
    {
        for (uint256 i = 0; i < tokensData.length; i++) {
            if (
                keccak256(bytes(hashString)) ==
                keccak256(bytes(tokensData[i].hashString))
            ) {
                for (uint256 j = 0; j < tokensData[i].owners.length; j++) {
                    if (tokensData[i].owners[j] == to) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function getImageMetaByHash(string memory hashString)
        public
        view
        returns (NFTDataAttributes memory data, uint256 index)
    {
        bytes memory tempEmptyStringTest = bytes(hashString); 
        require(tempEmptyStringTest.length > 5);
        for (uint256 i = 0; i < tokensData.length; i++) {
            if (
                keccak256(bytes(hashString)) ==
                keccak256(bytes(tokensData[i].hashString))
            ) {
                return (tokensData[i], i);
            }
        }
    }

    function mint(string memory imageId)
        public
        payable
        collectableIsActive
        returns (uint256 tokenId)
    {
        bytes memory testIfEmpty = bytes(imageId); 
        require(testIfEmpty.length > 5,"invalid hash");

        (
            NFTDataAttributes memory tokenData,
            uint256 index
        ) = getImageMetaByHash(imageId);

        uint256 price = collectionData.price;
        uint256 sold = tokenData.sold;
        testIfEmpty = bytes(tokenData.hashString); 
    
        require(testIfEmpty.length > 5, "Hash not valid");
        require(msg.value >= price, "Not enough ether to purchase NFTs.");
        require(sold < collectionData.editions, "Edition sold out");
        require(
            !containsOwner(msg.sender, imageId),
            "You already own this image"
        );

        uint256 newItemId = IERC721CreatorCore(_creator).mintExtension(
            msg.sender
        );
        IERC721CreatorCore(_creator).setTokenURIExtension(
            newItemId,
            string(abi.encodePacked(contractData.APIEndpoint , tokensData[index].hashString))
        );
        tokensData[index].tokens.push(newItemId);
        tokensData[index].owners.push(msg.sender);
        tokensData[index].sold = tokensData[index].sold + 1;
        _tokens[newItemId] = imageId;
        return newItemId;
    }

    function setApiEndpoint(string memory _apiEndpoint) public adminRequired {
        contractData.APIEndpoint  = _apiEndpoint;
    }

    function setCollectionData(Collection memory _data) public adminRequired {
        collectionData = _data;
    }

    function setNftData(string[] memory _tokensData, bool reset) public adminRequired {
        uint256[] memory placeholder;
        if(reset) {
               delete tokensData;
        }
        for (uint256 i = 0; i < _tokensData.length; i += 1) {
            tokensData.push(
                NFTDataAttributes({
                    hashString: _tokensData[i],
                    sold: 0,
                    owners: new address[](0),
                    tokens: placeholder
                })
            );
        }
    }

    function setBeneficiaryAddress(address payable _beneficiary)
        public
        adminRequired
    {
        contractData.beneficiary = _beneficiary;
    }

    function setIsActive(bool _isActive) public adminRequired {
        contractData.isActive = _isActive;
    }

    function withdraw() public adminRequired {
        contractData.beneficiary.transfer(address(this).balance);
    }
}

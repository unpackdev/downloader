// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract InkersHKCollection is ERC1155, Ownable, Pausable  {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => address payable) originalOwners;
    mapping(uint256 => bool) public orderedOriginalPrints;
    mapping(uint256 => address payable[]) copiesOwner;
    mapping(uint256 => uint256) copyCountForOriginal;

    uint earlyAccessOriginalsCount = 40;
    uint256 firstOriginalPrice = 0.1 ether;
    uint256 firstCopyPrice = 0.05 ether;
    uint maximumMintableOriginals = 100;
    uint copyNumberPriceFactor = 150;
    uint originalNumberPriceFactor = 110;
    
    constructor() public ERC1155("https://nft.inkers.app/api/metadatas/{id}-metadatas.json") {
    }



//      8888888b.      d8888 Y88b   d88P     d8888 888888b.   888      8888888888  .d8888b.  
//      888   Y88b    d88888  Y88b d88P     d88888 888  "88b  888      888        d88P  Y88b 
//      888    888   d88P888   Y88o88P     d88P888 888  .88P  888      888        Y88b.      
//      888   d88P  d88P 888    Y888P     d88P 888 8888888K.  888      8888888     "Y888b.   
//      8888888P"  d88P  888     888     d88P  888 888  "Y88b 888      888            "Y88b. 
//      888       d88P   888     888    d88P   888 888    888 888      888              "888 
//      888      d8888888888     888   d8888888888 888   d88P 888      888        Y88b  d88P 
//      888     d88P     888     888  d88P     888 8888888P"  88888888 8888888888  "Y8888P"  


    function generateNewOriginal() payable public whenNotPaused returns (uint256) {
        uint256 nextOriginalPrice = this.getNextOriginalPrice();
        require(
            msg.value == nextOriginalPrice,
            append("Must pay enought to mint a new original: ", uint2str(nextOriginalPrice))
        );
        require(
            _tokenIds.current() / 3 < maximumMintableOriginals,
            "No more original available"
        );
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        // reserve the next two slots for copies and printed copies
        _tokenIds.increment();
        _tokenIds.increment();

        _mint(msg.sender, newTokenId, 1, "");
        originalOwners[newTokenId] = msg.sender;
        emit OriginalCreated(msg.sender, newTokenId);
        return newTokenId;
    }
    
    function generateNewCopy(uint256 id) payable public whenNotPaused returns (uint256) {
        
        require(isOriginal(id), "Can only copy originals");

        uint256 nextCopyPrice = this.getCopyPrice(id);
        
        require(
            msg.value == nextCopyPrice,
            append("Must pay at least nextCopyPrice to mint a new copy: ", uint2str(nextCopyPrice))
        );

        uint256 copiesId = id+1;

        // pay commission
        uint256 originalOwnerCommission = msg.value.mul(30).div(100);
        address owner = originalOwners[id];
        (bool success, ) = owner.call{value: originalOwnerCommission}("");
        require(success, "Payment to owner failed");
        
        // if a copies owner exist, we have to pay their commissions too
        if (copiesOwner[copiesId].length > 0) {
            uint256 copiesOwnersCommission = msg.value.mul(30).div(100).div(copiesOwner[copiesId].length);
            for (uint256 i = 0; i < copiesOwner[copiesId].length; i++) {
                address copyOwner = copiesOwner[copiesId][i];
                (bool copyOwnerSuccess, ) = copyOwner.call{value: copiesOwnersCommission}("");
                require(copyOwnerSuccess, "Payment to copy owner failed");
            }
        }
        copyCountForOriginal[id]++;

        _mint(msg.sender, copiesId, 1, "");
        copiesOwner[copiesId].push(msg.sender);
        emit CopyCreated(msg.sender, id);

        return copiesId;
    }

    function orderPrint(uint256 id) whenNotPaused public {
        require(
            !isPrintedCopy(id),
            "Cannot print an already printed copy"
        );
        // if it's a copy, we'll have to change it to a printed copy
        // so it cannot be printed twice
        if (isCopy(id)) {
            require(
                balanceOf(msg.sender, id) > 0,
                append("Must own an unprinted copy for this id: ", uint2str(id))
            );
            // exchange a copy with a printed copy
            _mint(msg.sender, id+1, 1, "");
            _burn(msg.sender, id, 1);
        } else if (isOriginal(id)) {
            require(
                balanceOf(msg.sender, id) > 0,
                append("Must own an unprinted original for this id: ", uint2str(id))
            );
            require(
                orderedOriginalPrints[id] != true,
                "This print has already been ordered"
            );
            orderedOriginalPrints[id] = true;
        }
        emit PrintOrdered(msg.sender, id);
    }




//     8888888b.  888     888 8888888b.  8888888888  .d8888b.  
//     888   Y88b 888     888 888   Y88b 888        d88P  Y88b 
//     888    888 888     888 888    888 888        Y88b.      
//     888   d88P 888     888 888   d88P 8888888     "Y888b.   
//     8888888P"  888     888 8888888P"  888            "Y88b. 
//     888        888     888 888 T88b   888              "888 
//     888        Y88b. .d88P 888  T88b  888        Y88b  d88P 
//     888         "Y88888P"  888   T88b 8888888888  "Y8888P"  


    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function isOriginal(uint id) public pure returns (bool) {
        return id % 3 == 1;
    }
    function isCopy(uint id) public pure returns (bool) {
        return id % 3 == 2;
    }
    function isPrintedCopy(uint id) public pure returns (bool) {
        return id % 3 == 0;
    }




//      888     888 8888888 8888888888 888       888  .d8888b.  
//      888     888   888   888        888   o   888 d88P  Y88b 
//      888     888   888   888        888  d8b  888 Y88b.      
//      Y88b   d88P   888   8888888    888 d888b 888  "Y888b.   
//       Y88b d88P    888   888        888d88888b888     "Y88b. 
//        Y88o88P     888   888        88888P Y88888       "888 
//         Y888P      888   888        8888P   Y8888 Y88b  d88P 
//          Y8P     8888888 8888888888 888P     Y888  "Y8888P"  


    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 index;
        
        // first count all tokens
        uint256 tokenCount=0;
        for (index = 0; index < _tokenIds.current(); index++) {
            tokenCount += balanceOf(_owner, index+1);
        }
        
        // then iterate over all tokens to find the ones owned 
        // by the requested owners
        uint256[] memory result = new uint256[](tokenCount);
        uint256 insertingIndex = 0;
        for (index = 0; index < _tokenIds.current(); index++) {
            uint balance = balanceOf(_owner, index+1);
            uint256 index2;
            for (index2 = 0; index2 < balance; index2++) {
                result[insertingIndex++] = index+1;
            }
        }
        return result;
    }        
    function getCopyPrice(uint256 id) external view returns (uint256) {
        uint256 nextCopyCount = copyCountForOriginal[id];
        uint index;
        uint256 nextCopyPrice = firstCopyPrice;
        for (index = 0; index < nextCopyCount; index++) {
            nextCopyPrice = nextCopyPrice * copyNumberPriceFactor / 100;
        }
        return nextCopyPrice;
    }
    function getNextOriginalPrice() external view returns (uint256) {
        uint256 currentToken = _tokenIds.current()/3;
        if (currentToken <= earlyAccessOriginalsCount) {
            currentToken = 0;
        } else {
            currentToken -= earlyAccessOriginalsCount;
        }
        uint256 current = currentToken/5;
        uint index;
        uint256 nextOriginalPrice = firstOriginalPrice;
        for (index = 0; index < current; index++) {
            nextOriginalPrice = nextOriginalPrice * originalNumberPriceFactor / 100;
        }
        return nextOriginalPrice;
    }
    function getCopyCount(uint256 id) external view returns (uint256) {
        return copyCountForOriginal[id];
    }
    function getCopyOwners(uint256 id) external view returns (address payable[] memory) {
        return copiesOwner[id];
    }


//          888    888  .d88888b.   .d88888b.  888    d8P   .d8888b.  
//          888    888 d88P" "Y88b d88P" "Y88b 888   d8P   d88P  Y88b 
//          888    888 888     888 888     888 888  d8P    Y88b.      
//          8888888888 888     888 888     888 888d88K      "Y888b.   
//          888    888 888     888 888     888 8888888b        "Y88b. 
//          888    888 888     888 888     888 888  Y88b         "888 
//          888    888 Y88b. .d88P Y88b. .d88P 888   Y88b  Y88b  d88P 
//          888    888  "Y88888P"   "Y88888P"  888    Y88b  "Y8888P"  
           

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            // transfer originals
            if (originalOwners[id] == from) {
                originalOwners[id] = payable(to);
            }
            // transfer copies and printed copies
            if (id % 3 == 0) {
                id--; // use copiesId for printedCopiesId
            }
            for (uint j = 0; j < copiesOwner[id].length; j++) {
                if (copiesOwner[id][j] == from && 
                    to != address(0x0) /* ignore burning of copies for printed copies */) {
                    copiesOwner[id][j] = payable(to);
                }
            }
        }
    }


//        
//               d8888 8888888b.  888b     d888 8888888 888b    888 
//              d88888 888  "Y88b 8888b   d8888   888   8888b   888 
//             d88P888 888    888 88888b.d88888   888   88888b  888 
//            d88P 888 888    888 888Y88888P888   888   888Y88b 888 
//           d88P  888 888    888 888 Y888P 888   888   888 Y88b888 
//          d88P   888 888    888 888  Y8P  888   888   888  Y88888 
//         d8888888888 888  .d88P 888   "   888   888   888   Y8888 
//        d88P     888 8888888P"  888       888 8888888 888    Y888 

    function cancelPrintRequest(address requester, uint256 tokenId) public onlyOwner {
        require(
            isPrintedCopy(tokenId) || 
            (isOriginal(tokenId) && orderedOriginalPrints[tokenId] == true),
            "TokenID must be a printed copy or a printed original"
        );
        require(
            balanceOf(requester, tokenId) > 0,
            "Requester must own at leasts one token of requested type"
        );
        if (isPrintedCopy(tokenId)) {
            _mint(requester, tokenId-1, 1, "");
            _burn(requester, tokenId, 1);
        } else if (isOriginal(tokenId)) {
            orderedOriginalPrints[tokenId] = false;
        }
    }

    function changeFirstOriginalPrice(uint256 newPrice) public onlyOwner {
        firstOriginalPrice = newPrice;
    }
    function changeCopyNumberPriceFactor(uint256 newFactor) public onlyOwner {
        copyNumberPriceFactor = newFactor;
    }
    function changeOriginalNumberPriceFactor(uint256 newFactor) public onlyOwner {
        originalNumberPriceFactor = newFactor;
    }
    function changeFirstCopyPrice(uint256 newPrice) public onlyOwner {
        firstCopyPrice = newPrice;
    }

    function changeMaximumMintableOriginals(uint256 newMaximum) public onlyOwner {
        maximumMintableOriginals = newMaximum;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(string memory newuri) internal virtual onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        uint256 withdrawableFunds = address(this).balance;
        msg.sender.transfer(withdrawableFunds);
    }



//        8888888888 888     888 8888888888 888b    888 88888888888  .d8888b.  
//        888        888     888 888        8888b   888     888     d88P  Y88b 
//        888        888     888 888        88888b  888     888     Y88b.      
//        8888888    Y88b   d88P 8888888    888Y88b 888     888      "Y888b.   
//        888         Y88b d88P  888        888 Y88b888     888         "Y88b. 
//        888          Y88o88P   888        888  Y88888     888           "888 
//        888           Y888P    888        888   Y8888     888     Y88b  d88P 
//        8888888888     Y8P     8888888888 888    Y888     888      "Y8888P"  

    event OriginalCreated(address indexed to, uint256 id);
    event PrintOrdered(address indexed to, uint256 id);
    event CopyCreated(address indexed to, uint256 originalId);

}
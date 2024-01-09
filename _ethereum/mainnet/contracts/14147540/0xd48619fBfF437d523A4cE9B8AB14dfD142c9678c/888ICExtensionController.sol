// SPDX-License-Identifier: MIT
/*
     888888888           888888888           888888888     
   8888888888888       8888888888888       8888888888888   
 88888888888888888   88888888888888888   88888888888888888 
8888888888888888888 8888888888888888888 8888888888888888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
 88888888888888888   88888888888888888   88888888888888888 
  888888888888888     888888888888888     888888888888888  
 88888888888888888   88888888888888888   88888888888888888 
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888888888888888 8888888888888888888 8888888888888888888
 88888888888888888   88888888888888888   88888888888888888 
   8888888888888       8888888888888       8888888888888   
     888888888           888888888           888888888
 */
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./I888ICExtensionSale.sol";

contract ICExtensionController is Ownable {
    I888ICExtensionSale[] private _saleContracts;

    function addContract(address[] memory _contracts) external onlyOwner {
        for (uint i = 0; i < _contracts.length; i++) {
            _saleContracts.push(I888ICExtensionSale(_contracts[i]));
        }
    }

    function removeContract(uint256[] memory indexes) external onlyOwner {
        for (uint i = 0; i < indexes.length; i++) {
            _saleContracts[indexes[i]] = _saleContracts[_saleContracts.length - 1];
            _saleContracts.pop();
        }
    }

    function toggleSale() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleSale();
        }
    }

    function toggleClaimCode() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleClaimCode();
        }
    }

    function toggleInnerCircle() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleInnerCircle();
        }
    }

    function toggleAllowList() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleAllowList();
        }
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].setSignerAddress(newSigner);
        }
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].updatePrice(newPrice);
        }
    }

    function withdraw() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].withdraw();
        }
    }
}
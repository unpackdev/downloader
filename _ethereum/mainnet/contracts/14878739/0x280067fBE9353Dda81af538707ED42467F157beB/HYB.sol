// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ContractFactory.sol";
import "./HYBCards.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract HYB is ContractFactory, HYBCards {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    
    string public mycontractURI;
    bool public isSalePaused = false;

    //royalty
    uint256 public royaltyBasis = 500;

    address private signerAddress = 0x95076037D76B6dF18422388c7424dc82d9c9c243;
    address private vaultAddress = 0xc0DCDbc10a9841540Da4251F99299358B6235e6e;
    address private developerAddress = 0x40996Aedb1F630940DF5959accF99B621325b1EF;
    uint256 private developerFee = 500;   

    constructor() ERC1155("ipfs://") {     
        name_ = "Hide Your Bags";
        symbol_ = "HYB";   
        mycontractURI = "https://mint.goodmorning-games.com/api/contract";
    }

    function mint(bytes memory signature, uint256[] memory ids, uint256[] memory amounts) external payable {
        bytes memory message = abi.encodePacked(msg.sender, ids, amounts);
        bytes32 messagehash =  keccak256(message);

        require(signerAddress == messagehash.recover(signature), "INVALID MINT SIGNATURE!");
        require(!isSalePaused, "SALE IS PAUSED");
        
        uint256 calculatedPrice = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(cards[i].isCardForSale, "CARD NOT FOR SALE!");
            require(totalSupply(i) + amounts[i]  <= cards[i].maxSupply, "MAX SUPPLY FOR CARD REACHED!");
            calculatedPrice += amounts[i] * cards[i].mintPrice;
        }
            require(msg.value == calculatedPrice, "INVALID PAYMENT!"); 

        _mintBatch(msg.sender, ids, amounts, "");
    }

    //ERC-2981
    function royaltyInfo(uint256, uint256 _salePrice) external view 
        returns (address receiver, uint256 royaltyAmount){          
            return (vaultAddress, _salePrice.mul(royaltyBasis).div(10000));
    }

    // OWNER FUNCTIONS
    function reserveMint(uint256 cardID, uint256 amount, address to) external onlyOwner {
        _mint(to, cardID, amount, "");
    }

    function pause(bool _state) external onlyOwner {
        isSalePaused = _state;
    } 

    function setRoyalty(uint256 _royaltyBasis) external onlyOwner {
        royaltyBasis = _royaltyBasis;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0);

        // Developer
        payable(developerAddress).transfer(address(this).balance.mul(developerFee).div(10000));

        // Owner
        payable(vaultAddress).transfer(address(this).balance);
    }
    
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }  
    
    function setDeveloperAddress(address _developerAddress) external onlyOwner {
        developerAddress = _developerAddress;
    }  

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        mycontractURI = _contractURI; //Contract Metadata format based on:  https://docs.opensea.io/docs/contract-level-metadata    
    }

    function uri(uint256 id) public view override returns (string memory) {            
        return string(abi.encodePacked(super.uri(id), cards[id].ipfsMetadataHash));
    }  
}
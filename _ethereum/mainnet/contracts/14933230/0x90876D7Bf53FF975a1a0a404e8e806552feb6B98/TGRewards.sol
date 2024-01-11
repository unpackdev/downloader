// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RewardLogic.sol";
import "./SafeMath.sol";
import "./ERC1155Supply.sol";

contract TGRewards is ERC1155Supply, Reward {
    using SafeMath for uint256;
    
    string public mycontractURI;
    bool public isSalePaused = false;

    string public name_;
    string public symbol_;  

    //royalty
    uint256 public royaltyBasis = 500;

    address private vaultAddress = 0x924017Eb78A0B2229F1F3b34E1383573F994E4Be;

    constructor() ERC1155("ipfs://") {     
        name_ = "Taco Gatos Rewards";
        symbol_ = "TGR";   
        mycontractURI = "https://api.tacogatosnft.com/api/contract_tgrewards";
    }

    //ERC-2981
    function royaltyInfo(uint256, uint256 _salePrice) external view 
        returns (address receiver, uint256 royaltyAmount){          
            return (vaultAddress, _salePrice.mul(royaltyBasis).div(10000));
    }

    // OWNER FUNCTIONS
    function sendReward(uint256 cardID, uint256 amount, address to) external onlyOwner {
        _mint(to, cardID, amount, "");
    }


    function setRoyalty(uint256 _royaltyBasis) external onlyOwner {
        royaltyBasis = _royaltyBasis;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0);

        // Owner
        payable(vaultAddress).transfer(address(this).balance);
    }
    
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }  
    
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        mycontractURI = _contractURI; //Contract Metadata format based on:  https://docs.opensea.io/docs/contract-level-metadata    
    }

    function uri(uint256 id) public view override returns (string memory) {            
        return string(abi.encodePacked(super.uri(id), rewards[id].ipfsMetadataHash));
    }      
    
    function name() external view returns (string memory) {
        return name_;
    }

    function symbol() external view returns (string memory) {
        return symbol_;
    }          

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./IERC721AQueryable.sol";
import "./ERC165.sol";
import "./Base64.sol";
import "./Ownable.sol";


interface OcOpepen{
    function transferOwnership (address newOwner) external;
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external;
}

interface classique{
    function balanceOf(address owner) external view returns (uint256);
}

contract OcOclassq is ERC721A, ERC721AQueryable, Ownable{

    uint256 public price = 0 ether; 
    uint256 public maxSupply = 429;
    uint256 public maxPerTransaction = 3;
    uint256 public maxPerWallet = 3;
    uint256 public totalAirdroppedTokens;
    bool public saleActive;
    address classq_addr;
    address OcO_addr;
    mapping(address => uint256) public claimsByWallet;

    // OcOpepen oco;
    // classique clQ;

    constructor () ERC721A("OcOclassq", "OcOclQ") {
        }

    function _setOcoAddr(address _OcO_addr) public onlyOwner  {  
            OcO_addr = _OcO_addr;
        }

    function _setClassQAddr(address _classq_addr) public onlyOwner  {  
            classq_addr = _classq_addr;
        }

    function transferOcOOwnership(address newOwner) external onlyOwner {
            OcOpepen(OcO_addr).transferOwnership(newOwner);
        }

    function Claim(uint256 amount) external payable {
        
        require(saleActive);
        require(amount <= maxPerTransaction);
        require(totalAirdroppedTokens + amount <= maxSupply);
        require(classique(classq_addr).balanceOf(msg.sender) > 0, "You must own classique for free mint. aye?");
        require(claimsByWallet[msg.sender] + amount <= maxPerWallet, "Exceeds the maximum claims per wallet.");


        require(msg.value >= price);
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        
        OcOpepen(OcO_addr).airdropTokens(recipients, amounts);
        totalAirdroppedTokens += amount;

        claimsByWallet[msg.sender] += amount;
    }

    function startSale() external onlyOwner {
        require(saleActive == false);
        saleActive = true;
    }

    function stopSale() external onlyOwner {
        require(saleActive == true);
        saleActive = false;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxPerWallet(uint256 newmaxPerWallet) public onlyOwner {
    maxPerWallet = newmaxPerWallet;
    }

    function setMaxPerTransaction(uint256 newmaxPerTrxn) public onlyOwner {
    maxPerTransaction = newmaxPerTrxn;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    }
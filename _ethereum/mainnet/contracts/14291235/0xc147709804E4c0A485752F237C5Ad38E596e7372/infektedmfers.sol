// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*

           ╔═╗    ╔╗   ╔╗       ╔╗         ╔═╗           
           ║╔╝    ║║  ╔╝╚╗      ║║         ║╔╝           
    ╔╗╔═╗ ╔╝╚╗╔══╗║║╔╗╚╗╔╝╔══╗╔═╝║    ╔╗╔╗╔╝╚╗╔══╗╔═╗╔══╗
    ╠╣║╔╗╗╚╗╔╝║╔╗║║╚╝╝ ║║ ║╔╗║║╔╗║    ║╚╝║╚╗╔╝║╔╗║║╔╝║══╣
    ║║║║║║ ║║ ║║═╣║╔╗╗ ║╚╗║║═╣║╚╝║    ║║║║ ║║ ║║═╣║║ ╠══║
    ╚╝╚╝╚╝ ╚╝ ╚══╝╚╝╚╝ ╚═╝╚══╝╚══╝    ╚╩╩╝ ╚╝ ╚══╝╚╝ ╚══╝
                                         @donkey_brained                                                
                                                     
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract InfektedMfers is ERC721A, Ownable, Pausable {
    uint256 public mintPrice = .0269 ether;
    uint256 public maxInfektedMfers = 10000;
    uint256 public maxMint = 10;
    string public baseURI;

    address public vmAddress = 0x04c469b60980b50c395175Cc34b133678D018456; // Viral Mfers contract
    address public mferAddress = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f; // Mfer contract

    constructor() ERC721A("Infekted Mfers", "IM") {
        setBaseURI("");
        _pause();
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 amount) external payable whenNotPaused {
        /**
        * @notice If you hold Viral Mfers or Mfers, you are eligible for up to 10 FREE mints.
        * MINT THOSE FIRST as the freeMint function checks your Infekted Mfer balance and will not 
        * allow more than 10 NFTs in your wallet whether you minted them free or not.
        * No refunds will be given for messing this up.
        */
        require(msg.value >= mintPrice * amount, "Not enough ETH for purchase.");
        require(amount <= maxMint, "Save some for the rest of us.");
        require(totalSupply() + amount <= maxInfektedMfers, "Not enough Infekted Mfers remaining.");
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint256 amount) external payable whenNotPaused {
        /**
        * @notice If you hold Viral Mfers or Mfers, you are eligible for up to 10 FREE mints.
        * MINT THESE FIRST as the freeMint function checks your Infekted Mfer balance and will not 
        * allow more than 10 NFTs in your wallet whether you minted them free or not.
        * No refunds will be given for messing this up.
        * @param amount The total of your Viral Mfer and Mfer counts up to 10. Use checkTokenCounts 
        * to confirm before minting.
        */       
        
        // check Viral Mfer balance
        ERC721A vmToken = ERC721A(vmAddress);
        uint256 vmOwnedAmount = vmToken.balanceOf(msg.sender);
        // check Mfer balance
        ERC721A mferToken = ERC721A(mferAddress);
        uint256 mferOwnedAmount = mferToken.balanceOf(msg.sender);
        // check Infekted Mfer balance
        uint256 imOwnedAmount = balanceOf(msg.sender);
        require(vmOwnedAmount + mferOwnedAmount >= 1, "You don't own Viral Mfers or Mfers.");
        require(amount + imOwnedAmount <= vmOwnedAmount + mferOwnedAmount, "Not enough Viral Mfers and Mfers in wallet.");
        require(imOwnedAmount + amount <= maxMint, "Max 10 Free.");
        require(totalSupply() + amount <= maxInfektedMfers, "Not enough Infekted Mfers remaining.");
        _safeMint(msg.sender, amount);
    } 

    function devMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxInfektedMfers, "Not enough Infekted Mfers remaining.");
        _safeMint(to, amount);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function lowerMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply < maxInfektedMfers, "New supply must be less than current."); 
        maxInfektedMfers = _newMaxSupply;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkTokenCounts(address owner) public view returns (uint256 viralMfersCount, uint256 mfersCount, uint256 infektedMfersCount) {
        /**
        * @notice Enter your wallet address to see how many free mints you can claim (up to 10).
        * FREE MINT FIRST as the freeMint function checks your Infekted Mfer balance and will not
        * allow more than 10 Infekted Mfers NFTs in your wallet whether you minted them free or not.
        * No refunds will be given for messing this up.
        */       
        
        ERC721A vmToken = ERC721A(vmAddress);
        uint256 vmOwnedAmount = vmToken.balanceOf(owner);
        ERC721A mferToken = ERC721A(mferAddress);
        uint256 mferOwnedAmount = mferToken.balanceOf(owner);
        uint256 imOwnedAmount = balanceOf(owner);
        return (vmOwnedAmount, mferOwnedAmount, imOwnedAmount);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}
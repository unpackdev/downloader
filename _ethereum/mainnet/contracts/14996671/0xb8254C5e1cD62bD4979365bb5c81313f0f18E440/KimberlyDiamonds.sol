// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error DiamondsDepleted();
error NoGiftingYet();
error NotEnoughEther();
error UndefinedError();

contract Burner {
    constructor(){

    }
}
contract KimberlyDiamonds is ERC721, Pausable, Ownable, ReentrancyGuard {

    uint16         public                     totalSupply; 
    uint16         public                     totalBurned; 
    uint16         public constant            TOTAL_DIAMONDS = 3024;
    uint           internal constant          LEVEL1_MINT_FEE = 0.01 ether;
    uint           internal constant          LEVEL2_MINT_FEE = 0.03 ether;
    uint           internal constant          LEVEL3_MINT_FEE = 0.05 ether;
    uint           internal constant          LEVEL4_MINT_FEE = 0.07 ether;
    uint           internal constant          LEVEL5_MINT_FEE = 0.09 ether;

    Burner                                    blank_burner_contract  = new Burner();
    address        public                     burner_address_;
    string         private                    _base_uri;

    constructor() ERC721("Kimberly Diamonds", "DIAMONDS") {
        burner_address_ = address(blank_burner_contract);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function discover_() external payable nonReentrant {
        uint undiscovered = TOTAL_DIAMONDS - totalSupply - totalBurned;
        if (undiscovered <= 0){
            revert DiamondsDepleted();
        }

        uint new_token = totalSupply + 1;
        if (new_token <= 200){
            _safeMint(_msgSender(), new_token);            
        }else if (new_token > 200 && new_token <= 500){
            if (msg.value >= LEVEL1_MINT_FEE)
                _safeMint(_msgSender(), new_token);
            else
                revert NotEnoughEther();
        }else if (new_token > 500 && new_token <= 1000){
            if (msg.value >= LEVEL2_MINT_FEE)
                _safeMint(_msgSender(), new_token);
            else
                revert NotEnoughEther();                
        }else if (new_token > 1000 && new_token <= 1500){
            if (msg.value >= LEVEL3_MINT_FEE)
                _safeMint(_msgSender(), new_token);
            else
                revert NotEnoughEther();                
        }else if (new_token > 1500 && new_token <= 2000){
            if (msg.value >= LEVEL4_MINT_FEE)
                _safeMint(_msgSender(), new_token);
            else
                revert NotEnoughEther();                
        }else if (new_token > 2000){
            if (msg.value >= LEVEL5_MINT_FEE)
                _safeMint(_msgSender(), new_token);
            else
                revert NotEnoughEther();                
        }else{
            revert UndefinedError();  
        }

        if (msg.value>0){
            (bool sent,) = payable(owner()).call{value:msg.value}("");
            require(sent==true,"UNPAID");
        }

        //Burn diamond
        if (totalBurned < 200){
            uint tail = TOTAL_DIAMONDS - totalSupply;
           _mint(burner_address_, tail);  //Mints(burns) to Blank Burner contract address: Can never be transfered
           totalBurned += 1;
        }

        totalSupply += 1;

    }

    function gift(address to) external onlyOwner {
        uint undiscovered = TOTAL_DIAMONDS - totalSupply - totalBurned;
        if (undiscovered <= 0){
            revert DiamondsDepleted();
        }

        uint new_token = totalSupply + 1;
        if (new_token > 200){
            _safeMint(to, new_token);
            totalSupply += 1;
        }else{
            revert NoGiftingYet();
        }
        
    }    

    function setBaseURI(string calldata uri) external onlyOwner{
        _base_uri = uri;
    }


    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721) {
        ERC721._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _base_uri;
    }

    function tokenURI(uint256 tokenId) public view  override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }


}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**

 */
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract LuckyPanda is ERC721, ERC721Burnable, Ownable {

    bool public isActive = true;
    uint private totalSupply_ = 0;
    uint private nbBurnt_ = 0;
    uint private nbFreeMint = 888;
    uint private price = 0.025 ether;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    

    constructor(address payable shareholderAddress_) ERC721("LuckyPanda", "LUCKYPANDA") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        _baseURIextended = "ipfs://QmdvD4Yp2bvgKVmDHZReJ9Sd3mx2LVUDLumaX6UtEZfnBe/";
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_ - nbBurnt_;
    }

    function setNbFree(uint nbFree) external onlyOwner {
        nbFreeMint = nbFree;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function unluckyPandaBurn() public onlyOwner {
        // Get all id finishing by a 4
        // 
        // burn all function
        for (uint256 i = 4; i<=totalSupply_; i+=10) {
            if (_exists(i)) {
                nbBurnt_++;
                _burn(i);
            }
        }
    }

    function create888genesisPandas() public onlyOwner {
        // Get all id finishing by a 4
        // create genesis before bunring them
        for (uint256 i = 4; i<=totalSupply_; i+=10) {
            _mint(ownerOf(i), i); // This one is genesis ! The magic is in a secret contract ;)
        }
    }

    function freeMint(uint256 numberOfTokens) public {
        require(isActive, "Sale must be active to mint a panda");
        require(numberOfTokens <= 5, "Exceeded max token purchase (max 3)");
        require(totalSupply_ + numberOfTokens <= nbFreeMint, "Only the first apes were free. Please use mint function now ;)");
        require(totalSupply_ + numberOfTokens <= 8888, "Purchase would exceed max supply of tokens");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < nbFreeMint) {
                _safeMint(msg.sender, mintIndex);
                totalSupply_ = totalSupply_ + 1;
            }
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(isActive, "Sale must be active to mint a panda");
        require(numberOfTokens <= 8, "Exceeded max token purchase");
        require(totalSupply_ + numberOfTokens <= 8888, "Purchase would exceed max supply of tokens");
        require(price * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < 8888) {
                _safeMint(msg.sender, mintIndex);
                totalSupply_ = totalSupply_ + 1;
            }
        }
    }

    function withdraw() public onlyOwner {
        Address.sendValue(shareholderAddress, address(this).balance);
    }
}

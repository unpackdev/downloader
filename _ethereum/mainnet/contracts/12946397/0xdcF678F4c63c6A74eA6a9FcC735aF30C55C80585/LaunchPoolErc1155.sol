pragma solidity 0.8.0;

import "./ERC1155Supply.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract LaunchPoolErc1155 is ERC1155Supply, Ownable {

    uint256 public constant TYPE_GOLD = 0;
    uint256 public constant TYPE_SILVER = 1;
    uint256 public constant TYPE_BRONZE = 2;
    uint256 public constant TYPE_DIAMOND = 3;

    constructor(string memory uri) public ERC1155(uri) {}

    function mint(address _to, uint256 _id, uint256 _amount) public onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }
    
    function mintGold(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, TYPE_GOLD, _amount, "");
    }
    
    function mintSilver(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, TYPE_SILVER, _amount, "");
    }
    
    function mintBronze(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, TYPE_BRONZE, _amount, "");
    }
    
    function mintDiamond(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, TYPE_DIAMOND, _amount, "");
    }
   
    function burn(address _account, uint256 _id, uint256 _amount) public onlyOwner {
        _burn(_account, _id, _amount);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}
//              _..._                         .        .--.   _..._              
//            .'     '..-.          .-      .'|        |__| .'     '.   .--./)   
//           .   .-.   .\ \        / /  .| <  |        .--..   .-.   . /.''\\    
//     __    |  '   '  | \ \      / / .' |_ | |        |  ||  '   '  || |  | |   
//  .:--.'.  |  |   |  |  \ \    / /.'     || | .'''-. |  ||  |   |  | \`-' /    
// / |   \ | |  |   |  |   \ \  / /'--.  .-'| |/.'''. \|  ||  |   |  | /("'`     
// `" __ | | |  |   |  |    \ `  /    |  |  |  /    | ||  ||  |   |  | \ '---.   
//  .'.''| | |  |   |  |     \  /     |  |  | |     | ||__||  |   |  |  /'""'.\  
// / /   | |_|  |   |  |     / /      |  '.'| |     | |    |  |   |  | ||     || 
// \ \._,\ '/|  |   |  | |`-' /       |   / | '.    | '.   |  |   |  | \'. __//  
//  `--'  `" '--'   '--'  '..'        `'-'  '---'   '---'  '--'   '--'  `'---'       
//                                                                                                   
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";

contract Anything is Ownable, ERC2981, ERC721 {
  using Strings for uint256;

    // public variables
    uint256 public totalSupply = 0;
    uint256 constant public MAX_SUPPLY = 5000;
    uint256 constant MAX_MINT = 1;
    bool public saleOpen;
    string public baseURI;

    mapping(address => uint256) public claimedAmount;

    function mint() public {
      if(!saleOpen) revert("Sale not open");
      require(totalSupply < MAX_SUPPLY, "Max supply reached");
      require(claimedAmount[msg.sender] < MAX_MINT, "Exceeds your mint quota");
      
      claimedAmount[msg.sender] = 1;
      uint256 curr = totalSupply+1;
      totalSupply += 1;

      _mint(msg.sender, curr);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory _baseURI = getBaseURI();
      return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
    }

    function getBaseURI() public view returns(string memory){
      return baseURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
      baseURI = _baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function toggleSale() external onlyOwner{
    saleOpen = true;
  }

  constructor(string memory _baseURI) ERC721("Anything", "ANY"){
      _setRoyalties(0x985167ca3294Ca212512B5726D375d88F8a5c5B6, 700);
      baseURI= _baseURI;
  }

}

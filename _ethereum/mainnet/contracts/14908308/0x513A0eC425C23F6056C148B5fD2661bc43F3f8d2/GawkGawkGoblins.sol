//                                                                                                                       .-'''-.                                              
//                                                                                                                      '   _    \            .---.                           
//                                  .                                                    .                            /   /` '.   \ /|        |   |.--.   _..._               
//   .--./)              _     _  .'|                     .--./)              _     _  .'|                     .--./).   |     \  ' ||        |   ||__| .'     '.             
//  /.''\\         /\    \\   //.'  |                    /.''\\         /\    \\   //.'  |                    /.''\\ |   '      |  '||        |   |.--..   .-.   .            
// | |  | |      __`\\  //\\ //<    |                   | |  | |      __`\\  //\\ //<    |                   | |  | |\    \     / / ||  __    |   ||  ||  '   '  |            
//  \`-' /    .:--.'.\`//  \'/  |   | ____               \`-' /    .:--.'.\`//  \'/  |   | ____               \`-' /  `.   ` ..' /  ||/'__ '. |   ||  ||  |   |  |       _    
//  /("'`    / |   \ |\|   |/   |   | \ .'               /("'`    / |   \ |\|   |/   |   | \ .'               /("'`      '-...-'`   |:/`  '. '|   ||  ||  |   |  |     .' |   
//  \ '---.  `" __ | | '        |   |/  .                \ '---.  `" __ | | '        |   |/  .                \ '---.               ||     | ||   ||  ||  |   |  |    .   | / 
//   /'""'.\  .'.''| |          |    /\  \                /'""'.\  .'.''| |          |    /\  \                /'""'.\              ||\    / '|   ||__||  |   |  |  .'.'| |// 
//  ||     ||/ /   | |_         |   |  \  \              ||     ||/ /   | |_         |   |  \  \              ||     ||             |/\'..' / '---'    |  |   |  |.'.'.-'  /  
//  \'. __// \ \._,\ '/         '    \  \  \             \'. __// \ \._,\ '/         '    \  \  \             \'. __//              '  `'-'`           |  |   |  |.'   \_.'   
//   `'---'   `--'  `"         '------'  '---'            `'---'   `--'  `"         '------'  '---'            `'---'                                  '--'   '--'            
//
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";

contract GawkGawkGoblins is Ownable, ERC2981, ERC721 {
  using Strings for uint256;

    // public variables
    uint256 public totalSupply = 0;
    uint256 constant public MAX_SUPPLY = 6969;
    uint256 constant MAX_MINT = 1;
    bool public saleOpen;
    string public baseURI;

    mapping(address => uint256) public claimedAmount;

    // Free mint, maximum limit = 1 per wallet
    function mint() public {
      if(!saleOpen) revert("Sale not open");
        require(totalSupply < MAX_SUPPLY, "Max gawk gawk supply reached");
        require(claimedAmount[msg.sender] < MAX_MINT, "You have already received your gawk gawk goblin");
        
        claimedAmount[msg.sender] = 1;

        totalSupply += 1;

        _mint(msg.sender, totalSupply);
    
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

  constructor() ERC721("GawkGawkGoblins", "GOBGAWKGOB"){
      _setRoyalties(0x985167ca3294Ca212512B5726D375d88F8a5c5B6, 690);
  }

}

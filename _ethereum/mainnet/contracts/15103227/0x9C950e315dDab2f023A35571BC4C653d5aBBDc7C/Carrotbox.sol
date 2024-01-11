// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
#     # ####### ####### #     # ######  #     # #     # #     # #     # 
##   ## #     # #     # ##    # #     # #     # ##    # ##    #  #   #  
# # # # #     # #     # # #   # #     # #     # # #   # # #   #   # #   
#  #  # #     # #     # #  #  # ######  #     # #  #  # #  #  #    #    
#     # #     # #     # #   # # #     # #     # #   # # #   # #    #    
#     # #     # #     # #    ## #     # #     # #    ## #    ##    #    
#     # ####### ####### #     # ######   #####  #     # #     #    #  


 #####     #    ######  ######  ####### #######    ######  ####### #     # 
#     #   # #   #     # #     # #     #    #       #     # #     #  #   #  
#        #   #  #     # #     # #     #    #       #     # #     #   # #   
#       #     # ######  ######  #     #    #       ######  #     #    #    
#       ####### #   #   #   #   #     #    #       #     # #     #   # #   
#     # #     # #    #  #    #  #     #    #       #     # #     #  #   #  
 #####  #     # #     # #     # #######    #       ######  ####### #     # 
                                                                                                    
                                                                                                    
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXX0kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkkkkxkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXXXXXX
XXXXXXXXXXXKkl'.............''''''''''''''''''''''''''''''''''''''............'...........................ckKXKXXXXXXXXX
XXXXXXXXXKXk,.''''';;,,;::;::ccccccccccccccccccccccccccccccccccc::;;;,''''''';c'...''''',,,,;;,;::;;;;,....,kXKXXXXXXXXX
XXXXXXXXXKXk'.'''',;:;;::::::;;::::::::::::::::::::::::::::::::::;;::;;,''''';c;'....',,;:;::;::::::;,'.',.'kXKXXXXXXXXX
XXXXXXXXXKXk'.,,,;::;;::::::::::::::::::::::::::::::::::::::::::::;;;,;;;,,,':c;''''..':::;::;::::;,,,;::;.'kXXXXXXXXXXX
XXXXXXXXXXXk'.,;;::;::;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;::;;;::::;';c;',;:;',,;:::::;:;;,,;;:::;.'kXXXXXXXXXXX
XXXXXXXXXXXk'.',;::;::;,lOOO00000000OOOO0000000000000000000OOOOOkl::;::::::;;:c;,;:;::;;,,;::;;;,,;;:::;:;.'kXKXXXXXXXXX
XXXXXXXXXXXk'.,;;:::::;'dWKONMMMMWXX0oo0NWMMMMMMMMMMMMMMMMMWWKOXXdc:;::::::;,:c:;;:::;::;;,,;;,,;;:::;;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:::::;'dWWNWMMNKd:,,ll,l0NMMMMMMMMMMMMMMMMMMWNWXdc:;::;;;:;;cl:::::;::::;;;,,;::::::;:::;.'kXKXXXXXXXXX
XXXXXXXXXXXk'.;:;:;:::;'dWMMMN0o':o:'::,',l0NMMMMMMMMMMMMMMMMMMMXdc:;::::::::cl::::::::::::;';cc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWMW0d:;;;::::ccll;,lONMMMMMMMMMMMMMMMMMXdc:;::::::::cl:;::::::::::;';cc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWMNxcc::;;:oOKkxdol,,lONMMMMMMMMMMMMMMMXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:::;:::;'dWMMMXx;.,lox0XX0kxdl:.;KMMMWkxXMMMMMMMMXdc:;::::::::cl:;::::::::::;';cc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:::;:::;'dWMMMMMx.'lodxOKXXOdl:,;ckWOccccxNMMMMMMXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWMMMMMXkc'cdddxOKOdl::'.cXl.:l'':cclOWWXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWMMMMMMWd.;cclodddo:,'..';'.;clolc;;:lKXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:::;:::;'dWMMMMMMMNO:.';cc:,,:cclolc::clool:,,ckXXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:::;:::;'dWMMMMMMMNO:..';:cloxxkO00kkxc;lolc:;:lKXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:::::::;'dWMWKOOOOl,:llodxkkO0KK0xdddo:'..::cckNWXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWKd;'''';lodxkkO0kdddddooolc:;.;KWWWMMMXdc:;::::::::cl:;::::::::::;';lc::::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;:;:::;'dWkc;'',;cooooddddooololcc::;'':xNMMMMMMXdc:;::::::::cl:;::::::::::;';lc::;:::;;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.;:;;::;:;'dWMNkoo:..',:lllllc;;;:;'....:xXMMMMMMMMXdc:;::::;:::cl:;::::::::::;',::;:::::;;:;.'kXKXXXXXXXXX
XXXXXXXXXXXk'.;:;::;;:;'dWKONMMXxdd;..'''......,oxxdxXMMMMMWWKONXdc::::::;:::cl::::::;::;;,,,,,;;:::;;:;:;.'kXKXXXXXXXXX
XXXXXXXXXXXk'.;:::::::;'dNXKNWWWWWW0kkkkkkkkkkk0NWWWWWWWWWWWNXKNKdc:::;::;:::cl::::::::;,,,;;;;,,;;:;;;::;.'kXKXXXXXXXXX
XXXXXXXXXXXk'.';;:;:::;;cdxxxdddddddxxxxxddxdxxxxddxxdddddddddxxoc::;;:::;;;;cl:;::::;;,,;;:;;:;;,,;;;:;:;.'kXKXXXXXXXXX
XXXXXXXXXKXk'.,;;;;;;::::::::::::::::::::::::::::::::::::::::::::::::;;;;::;,:l:;;;,,,;;;::::::::;;,,;;;;'.'kXKXXXXXXXXX
XXXXXXXXXXXk'.',;;,;:::::::::::::::::::::::::::::;::;;::::;:::;::::;:;,,;;;,';c;'...';:;;;;:::::::;;;,,,,,.'kXXXXXXXXXXX
XXXXXXXXXXXk'.',;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,''''';c,....,;;;;::;;;;;;;;;;;,... 'kXXXXXXXXXXX
XXXXXXXXXXX0l,..'...................................'........................',. ....'...''..........'....,l0XXXXXXXXXXX
XXXXK00KK0000x:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:x0000KK00KXXXX
XXXXK00KK000000OkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkO000000KKK0KXXXX
XXXXXXXXXXXXXXXK0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000KXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXXXXXXXXXXXXX 
*/

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";


interface MoonbunnyInterface{
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
}

contract Carrotbox is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;
    mapping (uint256 => bool) _isClaimed;
    mapping (uint256 => bool) _goldenCarrots;
    bool private _saleStatus = false;
 
    string private _baseTokenURI;
    string private _goldenCarrotTokenURI;

    uint256 public MAX_SUPPLY = 8888;
    address public MOONBUNNY_CONTRACT = 0xF40B0395a45b82044178b6F9cF308A052d20088A;
    MoonbunnyInterface MoonbunnyContract = MoonbunnyInterface(MOONBUNNY_CONTRACT);
    
    function checkClaimed(uint256 tokenId) public view returns (bool) {
        return _isClaimed[tokenId];
    }

    constructor() ERC721A("Carrot Box", "Carrot Box") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setGoldenCarrotURI(string calldata newGoldenCarrotURI) external onlyOwner {
        _goldenCarrotTokenURI = newGoldenCarrotURI;
    }


    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (_goldenCarrots[tokenId]) {
             return string(abi.encodePacked(_goldenCarrotTokenURI));
        }

        return string(abi.encodePacked(_baseTokenURI));
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function adminClaim(uint256 _tokenId)
        external
        payable
        onlyOwner
    {
        require(MoonbunnyContract.ownerOf(_tokenId) == msg.sender, "Moonbunny: You do not own this Moonbunny.");
        require(_isClaimed[_tokenId] == false, "Moonbunny: The token you're trying to claim has already been claimed.");
        _safeMint(msg.sender, 1);        

        if (_tokenId == 3348 || _tokenId == 5303 || _tokenId == 8744 || _tokenId == 8855 || _tokenId == 1575 || _tokenId == 1968 || _tokenId == 2507
         || _tokenId == 6564 || _tokenId == 360 || _tokenId == 1842 || _tokenId == 5045 || _tokenId == 8495 || _tokenId == 3025 || _tokenId == 4672 
         || _tokenId == 5813 || _tokenId == 6161) {
             _goldenCarrots[totalSupply()] = true;
         }          
        _isClaimed[_tokenId] = true;

    }    

    function claim(uint256 _tokenId)
        external
        payable
        callerIsUser
    {
        require(MoonbunnyContract.ownerOf(_tokenId) == msg.sender, "Moonbunny: You do not own this Moonbunny.");
        require(_isClaimed[_tokenId] == false, "Moonbunny: The token you're trying to claim has already been claimed.");
        require(isClaimActive(), "Moonbunny: Claim window is closed.");
        _safeMint(msg.sender, 1);

        
        if (_tokenId == 3348 || _tokenId == 5303 || _tokenId == 8744 || _tokenId == 8855 || _tokenId == 1575 || _tokenId == 1968 || _tokenId == 2507
         || _tokenId == 6564 || _tokenId == 360 || _tokenId == 1842 || _tokenId == 5045 || _tokenId == 8495 || _tokenId == 3025 || _tokenId == 4672 
         || _tokenId == 5813 || _tokenId == 6161) {
             _goldenCarrots[totalSupply()] = true;
         }   
        _isClaimed[_tokenId] = true;
    }

    function isClaimActive() public view returns (bool) {
        return _saleStatus;
    }    
}
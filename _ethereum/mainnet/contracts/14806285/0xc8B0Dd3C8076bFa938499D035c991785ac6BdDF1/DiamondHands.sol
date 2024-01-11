 
pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

 /*                                                .                                                                
                                                                                  .':cc;.                                                             
                                                                                .;:::::c:;'.                                                          
                                                                  .';cc:;,...  .clllllcccll:'                                                         
                                                                .;cclccclollc;..clllloloolll:.                                                        
                                                     .........  'ooloodolloooo;':lllllloooool.                                                        
                                                   '::;;;;:clc,..lddoodoooooodl;:lllllllooddo;                                                        
                                             .... .:lccc::clooo;.cdddooooodddol::olllllloddooc.                                                       
                                           .,:cc:..:lllolllooodo;;oddoollodddooccoooollodddol:.                                                       
                                          .;ccllc;':loooooooodddc;cddollllllllllcloooolllolc:;,,,..                                                   
                                         .:cclcccc;,:oooooooddddo:;odoll:,;;;;::;;::::::clooooocclc'                                                  
                                         .:cccccccc;,:oooloodddddc;ldddo;,loooooooolc:;cooddddolclol,                                                 
                                         .,:clllllllc;:loooddddddl;:odooc';clolccoolc:cloooddddollloc'                                                
                                          .;lodoollool::lodxdddddo:;looool;',:cllodooodddoooooooollll:.                                               
                                           .;loollloodo:coodoodddoc,:oodxxdol;,;codddxxxolllooooooolllc.                                              
                                             'cloooodxdccdddooddooc..lodddddddoc:;'';:c:;;,,;lodddollooc.                                             
                                         .::'..,cllclodccdxxddxxdo:..:odddolllodd;    .....'lddddddoooooc.                                            
                                         'odol:;;cllloo:;lddddddxd:. ,oddddddoc:;'',:looooc,:oooodddddddd;                                            
                                         ;dddoooc:clc;'..'codddddl'..',;:c:;;::cldxxkkxddooc:;;;,;coddddd:.                                           
                                        .cxxddoooolcc:,,,'';::::;,;colc:;..,cdkkkkkkxxxdddodddolccodddddd:.                                           
                                        .lxxxdooddddxxoooollccccldxxddxdc:oxxkkkOkkkxddddooddxxxxxxxxxxxx:.                                           
                                        .lxdddoodddxxxdxxxdddoodxxxxxdoccoxkkkkkkxxxdddddxxxxxxkkkkkxxxxx:.                                           
                                        .ldddxxdddxkxxxxxxxxxxoloxxdool:oxkkkkxxxkxxxdddxxkkxxxkkkkkkxddo'                                            
                                        .cxxdddddxkkkkxddxxdxxkdloxddo:cddxxxxxxxkkxxxxxddxxxxxxkkxxxkxl.                                             
                                         ;dxxdddxxkkkxxxxxxxxxkkxdxxxllxxxxxxxxxxkOkkxxxxxxxxxxxxxxxxx:.                                              
                                         .lxxxxddxxkkk       DIAMOND HANDS NFT          kxkkxxkkkkkxdc.                                                
                                          ,oxxxxkkkkkkkkkkkxxkkkkkxdooxxxxkOkxxxxkkxxkkkkkkkOOOOkxo,                                                  
                                           ,oxxkkOOOkkkkkkkxxkkkkkkkkkkkkkOOOkxkOOkkkxkkxxxkkOkkxc.                                                   
                                            .cdkkxxxxxkkkkkkkkkOO00OkkkkOOkkkkkO0Okxkkkxxxxxxkxo;.                                                    
                                              .,coxxxxxxkkkkkkOOOOOxooxkkkkxxxkOOOkkOOOkkxxxxd:.                                                      
                                                .,cdkxxdxkkkkkOOkkkOkkkkkkkkkkkOOOOOOOOOOOOxc.                                                        
                                                .loodxdddxkkkkOOkxxkOkkxxxxxkkO00000OOOO0kl'                                                          
                                                .lOOkxdddxxkkxkkkkxxOkxddxxxkkkO0KK00Okdc.                                                            
                                                 :kOOkxddxxxxdxxkOdokOdcoxkkkkkkO00Oxol:;.                                                            
                                                 'xOOkxdddxxxxxkkkdoxOdldkOOOOkkkOkxddxkx,                                                            
                                                 .lkkkxddxxxxkkkkkxdk0Oxk00000OkkkO00Okxd;                                                            
                                                 .lOkkkxxxkkkkkOkkkkO00O000K00Okxxk00OkOk;                                                            
                                                 .cOOkOOOOkkkOOOOOOOkkkO00OOOOOOkkkO000KO,                                                            
*/

import "./ERC721A.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract DiamondHands is ERC721A, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public immutable maxSupply;
    uint256 public constant maxPerAddressDuringMint = 5;
    uint256 public constant mintPrice = .01 ether;

    uint256 public  airdropSupplyRemaining = 20;
    uint256 public freeSupplyRemaining  = 100;

    bool public canMint = false;

    string private _baseTokenURI;

    modifier mintOpen() {
        require(canMint, "The mint is not live yet");
        _;
    }

    constructor(uint256 _maxSupply) ERC721A('DiamondHands', 'DMD') {
        maxSupply = _maxSupply;
    }

    function publicMint(uint256 quantity) external payable mintOpen {
        require(quantity <= 5, "You can only mint 5 at a time");
        require(numberMinted(msg.sender) + quantity <= 5, "You can only claim 5 mints");
        require(totalSupply() + quantity + 20 <= maxSupply, "reached max supply");

        _mint(msg.sender, quantity);
        refundOverPayment(quantity * mintPrice);
    }

    function freeMint(uint256 quantity) external mintOpen {
        require(numberMinted(msg.sender) + quantity <= 5, "You can only claim 5 mints");
        require(freeSupplyRemaining > 0 , "There are no free mints left :(");

        freeSupplyRemaining = freeSupplyRemaining.sub(quantity);
        _mint(msg.sender, quantity);
    }

    function refundOverPayment(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
        Reward early founders of the project:)
    */
    function airdrop(address[] calldata receivers) external onlyOwner {
        require(airdropSupplyRemaining > receivers.length, "Not enough airdrop allocations left");

        for (uint256 i; i < receivers.length; ++i) {
            _mint(receivers[i], 1);
            airdropSupplyRemaining --;
        }
    }

    function ownerClaim() external onlyOwner {
        _mint(msg.sender, airdropSupplyRemaining);
        airdropSupplyRemaining = 0;
    }

    function setMintState(bool state) external onlyOwner {
        canMint = state;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address tknOwner) public view returns (uint256) {
        return _numberMinted(tknOwner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}

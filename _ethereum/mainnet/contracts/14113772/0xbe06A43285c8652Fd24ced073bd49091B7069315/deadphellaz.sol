// SPDX-License-Identifier: MIT

/*                                                
                                            .........                           
                                 ...'.....',,'''''''''....                      
                              .',::;.';::;''',;;:c:;,,,,;;;'.                   
                            .,;,;c:;;::'..':cccc:;''',,'''';:'.                 
                           .;;.';;',:;.',:lllccc,.,:ccccc;..::.                 
                        ...;;.':;.':;.':clolccc:..:ccc:::;.'::'                 
                     ..,:ccc:;::,'::'.:clllccll:'.;:c:;''''::,.                 
                    .:lllcc::;'.'';:::ccllccllcc:,.',;;;;;;,'.                  
                   'cllccc:'..,',:cooollllllllllllc;,''''''..,'.                
                  .:lcccc:,',:loooooooooooooooooooooolllcclc'.;'                
                  ,:;::::ccloolc;,,,,;:looooooooooool:;,,,,;,..,.               
                  ,;.,;.,looo:'',;;;;,''':ooooooool:'',;;;;,'..'.               
                  .'.';.;looo:;;,;::;,;;,:loooooool:;;,;::,,;,...               
             ..',,,'..,:cloool;,lOKK0o,,:coooooooooc,,o0KKOl,,. ...             
            .;c::::::,':cloooc':0NNNNXl';cooooooooo:'lXNNNN0:'..,c:.            
           .;cc;..';cccccloool,,dKNNXx;,:coooooooooc,;xXNNKo,,'.:cc:.           
           .;cc;'.':ccccclooool;,;cc:,;cloooc,,,,;loc;,:cc;,;c'.;cc:.           
            .;:::c:c:;:ccloooooollccclooooooc,''';looollcclloc'.:c;.            
             ..'',''',:cclooooooooooooooooolcc:;:clloooooooooc'....             
                   .;ccccloooooooooooooc;,,,,,,,,,,,,;looooooc.                 
                   .;c;;:cloooooooooool;';cloollllol:,:ooooooc.                 
                    ':;'.,:llooooooooooooooooollllooooooooool;.                 
                  .'';:'...':llooooooooooooooooooooooooooool;.                  
                  ;0x,..''....,:cloooooooooooooooooooooolc:'.                   
                ..lWWOc'...,. ..'',;;:::cccccccc:cc::;;,...                     
            .  ...;KMMW0dc;'..',,,,,''.......,clo:...                           
        ..... .....:KMMMMWO;,'....;:,,,';lxk0XWMXl........                      
      ....... ..... ,kWMMMxcOc.'..;,:kolkXMMMMMKc..'....'......                 
      ...... ...... ..ckNWdlKl...;';Odc0WWMMWXk;..''...'....'''..               
      ....... ..... ....;o;cOc.;:';kd:d0Okdl:'...''........'''''.               
     .',........... .....odol'';',ldllc'.......'''........''''''.               
    .,c;...... .... .....:KWd'''oXX0xl,..................''......               
    .:;....... ...........cO:.'oXO:'.......... .....''.''........               
   ............ ..........;c'.cKx'.''..............''''....'.....               
     .....................',.,xo..'....... ......''''... .........              
  .'............... ....'''..dKd;'....'.........''......  ... .....             
  .....................lKKl.;KMMNd...''......''''.. ............''..            
 ................. ....oWNc.oWMM0,..''.. ...'''''..............''''.            
*/

pragma solidity ^0.8.2;
import "./Ownable.sol";
import "./ERC721.sol";
 
contract Deadphellaz is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant Max_token_supply = 10000;
    
    //uint256 public current_mint_cost = dynamic_cost(totalSupply);

    uint256 public totalSupply = 0;


    string public baseUri = "https://deadphellaz.com/api/metadata?id=";

    constructor() ERC721("DeadPhellaz", "DEADPHELLAZ") {}

    function dynamic_cost(uint256 _supply) internal pure returns (uint256 _cost){
        //Tiered pricing

        //TODO need to add 1 to make it work (1001, etc)
        if(_supply<1001){ //i.e. 1001 or 2001
            return 0.03 ether;
        }
        else if(_supply<2001){
            return 0.04 ether;
        }
        else if(_supply<3001){
            return 0.05 ether;
        }else{
            return 0.069 ether;
        }
    }


    // PUBLIC FUNCTIONS
    function mint(uint256 _numTokens) external payable {
        
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= Max_token_supply, "Minting has finished, maximum supply has been reached.");

        if(_numTokens>1){
            uint256 cumulative_cost = 0;
            for (uint256 n = 1; n <= _numTokens; n++) {
                cumulative_cost += dynamic_cost(curTotalSupply+n);
            }
            require(cumulative_cost <= msg.value, "You didn't send enough ETH to mint.");
        }else{
            require(dynamic_cost(curTotalSupply+1) <= msg.value, "You didn't send enough ETH to mint.");
        }
        
        
        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }

        totalSupply += _numTokens;
    }

    // OWNER ONLY FUNCTIONS
    /* function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    } */

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 100 / 100;
        (bool transferOne, ) = payable(0xBe24BA1e5175F968A266A43F9A30Cdf5Fa4af4D8).call{value: balanceOne}(""); //SHOULD BE MY ADDRESS
        require(transferOne, "Transfer failed.");
    }

    // INTERNAL FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
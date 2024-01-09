// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                                                                           
//                                       .. ....  .*...*.,...,...   .                                  
//                  *(#((##((((((.*,,,,*,,,/**/*.,,,*******,/,*.,,.,.*,/(/((((/*/*(#*.                 
//                  #(&%%%&#%%(//*/*/////(/**////*/,,*(/(%**/***/,,**,,*#%&@@@@@@@&&%&                 
//                  .%&%%%#((//,***///*//*//*/*/*/(/(///*/((/(((//*/,,,*(&&&@@@@&&&&%                  
//                   (%&%(//*/,,**/**//*,*,**/*(/(*(((#((%//(//&(/,///***#@@&@@@@&&&%                  
//                    (&&%#//*,,,,,*,**,**/*/**/((/(*%#(#&##(((/*/////*,*(&&@@@@@@@%                   
//                     %#%(**,,,,,**(%(*%%(,*((*(((##/(&&&%(/(*/##/*&(/(*.//*,/*/@&                    
//                      ,/,,,,,,,***/##(#%#(%((/((//(/(%(%%%#/(%(#%&%#%%/*,,,,...                      
//                    ..,*,,*,,*/*/(((/@@@%%%((///(/((##(#%%%#&%@@@@&&&@&#&#*,...                      
//                   ..,,*///**///((%%(&(%##(((////*//**/&#%&@@@@@%@&@&@@&&%%%#//*,...                 
//                  .*,*//*/*/*/(/((%(#/(((/(/***,,,,/*,/(/(&@@&&%&#&&&#%%#%&##(//**... .  ..          
//                 ..**///((////(((((//////*/*,,,*//(///(/*(%&@&&%%%#%%&&&&&%#%###//*,,.. .            
//           .  .....*/*/*////(((((//(////*/,,**%&%((&@&#. (/(&@@@&&&#&&&@@&&%&%#(((/,,...    .        
//             .,.,***///(//(//(((///*////*,,**(%&&#&&&@@@&&(((%#&@@@@&@&&&@&&&&%%#//,,,.   .          
//              .,,,/*///**///**(//((///*(,,****/%&&@@@@@@@&#%#(%%@*&@@@@@@@&&&%##/*,,,.... .          
//             ..,*//////(#(///((((((/*//*,,**/*(//#%&##%%%&&%((###@@@@@%&&&&&%#(#/,,,, ..             
//           .,,*,///**/((#***/(((/#///*.//,,*//####(%(##&%%&#(#%&&&&@&*&@%@%%#((,.,, ..               
//             . .  .,,//*///(((/*//##%(//((#&@&////#%@&@%@@@&&&&&&&@@&%%%%&%#/**,...                  
//                . ., .., ,*/(###(*#*/#%#/((/*##., %@@@@@@@%&%@@@&&#&%#(#%#/, ,.                      
//                        .    ,/(####((#(((#%&%##########%%&&&%%#%%%%%#*/*.                           
//                       ...      . (#%%%%#%%######%%#%%%#&%%%#%&%%%#//.                               
//                                  (###&%%%%#######%%%%%%%%%&&&@@@&%/.                                
//                                 *((((#%%((##((#/((%&&&&&&&&@&@@@%%#,                                
//                                ,//(/(####(((#((#(%#%&&&&&@@@@@&&&#//                                
//                               ,,*/*//#%(((/((/((###%&%&&&@%@@@@%&&#(*.                              
//                            ..,*//*(/(#((((/((((/(/((#&&%%%&%%&&%//((*/..                            
//                         ,*,,,*//#**//###((((///(#(##(##&&%%%###%#((//#///,.,. .                     
//                  .,,..,,,**/////**/*((#(((//(((/(##%%(#%@%%%%%#%#%%##*(#((*/(.,**.,                 
//            ,/*.,,,,**,/*#*/(s/(****/((####/%//((((###(##%%&#@%%#(##(%%(#(&(/(/((//*,,,..,           
//         ,,,,***//*/(///////((///*/*/((##((/k/((/#(((##(#%%%%&%&&%#%%%%%%%###(##/(**((//*,,.,        
//      .,,***///*////*#/////***//**///#((#(((#(%((#(%(#####(%&(&&&&/#%&(&%###%*(#(###/#*#(/*/,,,.,    
//   .,,,//////*//////*(/**//*////*//*/(##(/(((((#(((####%###(%%&%%%%&(##((&#((%((////(/(/(//*(/*/,..  
// .,,*(***/***/*///******(/**/((*(*/(####(/(((/(#(#((##(@#%#&#%%&&%#%(##w/#*///(/#/////*(#/(#/*(*,/*,.
// ,*///*///*/*/*//////////(//*(*((/(###(((((((((##(####((##%#%%#%%%%%%((##((/((/((/(//a#(#(##(#((#(#/*
// ,/(/***//*//*/((////*((/##/(#((#((#(##/(/((((###((#(###%%((#%#%%##%%&/#&%#((((#/#(/#/((/*/(##%%#(##/
// */**//****/*/////((//((((#(#%((/#%##((#((#(((#((#(#((#####(%####%#%&%%%&%%###%##((((##(((((((((####(
// */***/****/////*/((/##%#&%#/#(/#%#(%#/(((((((#(#((%((#((((&((##/(%(&%&&&@&&%(#%##&#/(((%*((%w((%###@
// */*/(///(//////(/((((####%###/%###(((#((((#((##(((#(#(//(#((%(#((#%##%%%&&&%&%%%%%%(#%/#(#((#%((%(##
// **/#**/////(/((*((//#(##%%%(((((##((((#(#/(#((((#(#((#(#(%####&(#(#@#(&#%%%%%%%%###%##/%#(/##%%((#(&
// *(/(///*//////*(/////(%###%#((((((((###((#%#((#(####((%((#(##%%%(%(%###%%%&&&#@&%%######(%%#(%#%(/(#


import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract MightyRaccoons is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    string  baseUrl;

    uint256 public constant MINT_PRICE = 0.099 ether;
    uint256 immutable public maxSupply = 9999;

    uint256 public constant ALLOWED_PER_TX = 4;
    uint256 public allowedwhitePerAddress = 4;
    uint256 public allowedPerAddress = 8;

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public mintCount;

    address racoon1 = 0x25BC9Da80bE03682ca671349e58274E5FF81469C;
    address racoon2 = 0x344789A5Ef3118B8eDAb4fFCF06455EB226A645F;
    address racoon3 = 0xFFBEA927699c88C299E28dA765A77d3d2D4455dE;
    address racoon4 = 0x06C32a292fFb76a70d7Ec6b8Ef3E510Df33047bD;

    constructor() ERC721("mightyraccoons", "MRAS") {
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

   
    function mintWhitelist(uint numberOfTokens , bytes32[] calldata merkleProof)

        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        
        
    {
        require(presaleIsActive, "Presale must be active to mint");
        require(numberOfTokens <= ALLOWED_PER_TX, "Too many requested");
        require(msg.value >= numberOfTokens * MINT_PRICE,"Not enough ethers sent");

        uint256 current = _tokenSupply.current();

        require(current + numberOfTokens < maxSupply, "Exceeds total supply");
        require(mintCount[msg.sender] + numberOfTokens < allowedwhitePerAddress,"Exceeds allowance");

        mintCount[msg.sender] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintIndex();
        }
    }

   
    function publicSaleMint(uint numberOfTokens) 
    public 
    payable
    {
        require(saleIsActive, "Sale haven't started");
        require(numberOfTokens <= ALLOWED_PER_TX, "Too many requested");
        require(
            msg.value >= numberOfTokens * MINT_PRICE,
            "Not enough ethers sent"
        );

        uint256 current = _tokenSupply.current();

        require(current + numberOfTokens < maxSupply, "Exceeds total supply");
        require(mintCount[msg.sender] + numberOfTokens < allowedPerAddress,"Exceeds allowance");

        mintCount[msg.sender] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintIndex();
        }
    }

    function adminMint(uint256 numberOfTokens) external  onlyOwner {
        
        uint current = _tokenSupply.current();
        require(current + numberOfTokens <= maxSupply, "Exceeds total supply");

         mintCount[msg.sender] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintIndex();
        }
    }
    
    function mintIndex() internal {
        uint256 tokenId = _tokenSupply.current();
        _tokenSupply.increment();
        _mint(msg.sender, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        baseUrl = newUri;
    }

   function getCurrentmintCount(address _account) public view returns (uint) {
        return mintCount[_account];
    }


    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }
    
    function togglePreSale() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
  
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }


   function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(racoon1, (balance * 50) / 1000);
        _withdraw(racoon2, (balance * 10) / 1000);
        _withdraw(racoon3, (balance * 25) / 1000);
        _withdraw(racoon4, (balance * 15) / 1000);

        
        _withdraw(owner(), address(this).balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
}
/*
                                                                                                                  
                                                        -@@%#+:                                                   
                                                        .@@#*%@@#-                                                
                                                        -@@=..:+#@@*:                                             
                                     -*#*.            .*@@=.:::..:*@@#:                                           
                                    #@@%@%           +@@*:...:::::.:*@@+                                          
                                  :%@%+#@@.         :@@+---=--:.::::.:%@%.                                        
                                 +@@#++#@@.       .-*@@@@@@@@@%:.::::..#@@.                                       
                               :%@@*++++@@+   .=#@@@%*##%%##*+-.:::::..:%@#                                       
                             :#@@#++++++*@@*-#@@#=::..........:::..::-==%@%                                       
                          .=%@@#++++++++++%@@@@%*+=-:.:::::...::--==+#%@@@%*=.                                    
                       .=#@@%*++++++++++++++*##%%%@@@#=::::--==+*#%@@@@@#=+#@@%+                                  
                     -%@@%#+++++*++++++++++++++++++*#@@@#**#%%@@@@@%#=-..:..:+%@@:                                
                     %@@*****++++++++++*+++++++++++++++%@@@@@@%#+-:..:::..::-==%@#                                
                     :*%@@@@@@@%#+++++++++++++++++++++++*@@%::...::..:::-=====*@@=                                
                            .:-#@@#+++++++++++++++++++++++@@+.::::--=====+*#@@@@@*-.                              
                                -@@*++++++++++++++++++++++#@@=======++#%@@@@@#+-=#@@#:                            
                                 %@%+++++++++++++++++*++++*@@*+*##%@@@@@@#+-:..::.:+@@*                           
                                 +@@+++++**++++++++++++++++@@@@@@@@%#+=::..::::::::.-@@+                          
                                :+@@%++++++++++++++++++++++@@%*+-::...:::::::::::::.:%@*                          
                            .=%@@%#@@%+++++++++++*++++++++*@@-..::::::::::::::::::.:*@@:                          
                           *@@#=:..-%@@*+++++++++++++++***@@@***-.:::::::::::...::=#@@-                           
                          #@@-.::::..=%@@#**##%%%@@@@@%##*+++=+=:.:::...:::::--=+#@@@@%*-                         
                         -@@+-.::::.:-+@@@%#*+==--:::..........:::::---=====+*#@@@@%=-+%@%=                       
                         =@@+==::...=#*=::.....:::::::::----===========+*#%@@@@@#+:..:..-%@%.                     
                         .@@%=====--------====================++**#%%@@@@@@@#*-:..::::::.:%@#                     
                          -@@@%*+++++++++++++++++***###%%%@@@@@@@@@@@%#*+-:...::::::::::..*@%                     
                       :=+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#*+=-::...............:::-=#@@-                     
                    :*@@%#**#%@@@@@@@@@@@@@@@@@%-#@@@@@@@@@@@@%%##**++++===-----===+**#%@@@*                      
         .-+#%%#*= +@@*:      .=@@@@@@@@@@@@@@@= =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##*+=----:         
       :#@@%*=+*%@@@@-   =**+.  -@@@%###%@@@@@@- =@@@@@@@@@@@@@@@@@@@@@-+@@@@@@@@@@@@@@@@%=:--=+**#%@@@@@@*       
      +@@*. :=+. %@@%   %@@@@@*  +@@-.-:. =@@@@- -@@@@@@@@@@@@@%@@@@@@+  #@@@@@@@@@@@@@@@%+--::..       =@@-      
     -@@- :%@@@: =@@:  %@@@@@@@%  %@+ .@@= +@@@= :@@@@@*.:==-:. -@@@@= . -@@@@@@%  *@@@% *@@@@@@@@@%%: -@@@%      
     *@@. :@@@=   @@. -@@@#:%@@@# =@@  -@= *@@@- :@@@@@+  ==+*#@@@@@= .#  *##%@@. . #@@- %@@@@@@@*-.  *@@@@:      
     @@@*.  . -=  #@= :@@@   *@@= :@@.  . .*@@@: -@@@@@: .%%@@%#@..   :::  ::-#+  *= %%  @@@@#=:  .-#@@@@@-       
     #@@@@@%%@@*  %@#  +@@*+%@@#  *@@  .+=.  *@. :@@@@@:       :%%: :@@@@- -@@@   @@.-#  @@+. .-*@@@@@@@#.        
     .%@@@@@@@@- .@@@+  .+*#+=.  +@@*  *@@@* =@-  ##*++:  +%%%@@+   @@@@@%  .@@  *@@% - :@*  +@@@@@@@@@@##=-      
     #@@@@@@@@%  +@@@@%+:.   .-*@@@@:  @@@@+ %@*    .::-:  -+***-..#@@@@@@%=+@@ -@@@@+  %@-        .:::-=*%@%.    
    #@@..@@@@%: .@@@@@@@@@@@@@@@@@@@#-*#*=..*@@@%#%@@@@@@#=::..:+@@@@@#*@@@@@@@%@@@@@@#%@@+-+**##%%##**==+#@@=    
   :@@@  -@@*  :@@@@*%@@@@@@@@@@@@@@#. .:=#@@@@@@@@@@@@@@@@@@@@@@@@@@%. *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#    
   :@@@#.    .*@@@@#  .-+*#%##+-.-@@@@@@@@@@@@%%@@@%*++*@@@@@@@@@@@*:     ::-*%@%*::#@@@@@@@@@@@@@@@@@@@@@@@*.    
    #@@@@#**%@@@@@*               %@@@@@@@@@#-           :=*****+-                    . -**+-::      .:--:.       
     #@@@@@@@@@@%:                 -+*##*=:                                                                       
      -*%@@@@%*:                                                                                                  
                                                                                                                  
                                                                                                                  
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./ECDSA.sol";

contract Gobleanz is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 constant MAX_SUPPLY = 2222;
    uint256 constant MAX_MINTS = 3;

    string public baseURI = "";
    bool public isActive = false;

    address public signerAddress = 0x5A1cb8Ae36A0af27e90c9CC48D7f4f2065296F25;

    constructor() ERC721A("Gobleanz", "GOBLEANZ") {}

    function getzOne(
        bytes32 hash,
        bytes memory signature,
        uint256 quantity,
        uint256 nonce
    ) external nonReentrant {    
        require(isActive, "Sorry Gobleanz: Mint is not active");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Sorry Gobleanz: You exceeded the limit.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Sorry Gobleanz are out.");
        require(noBotz(hash, signature), "Sorry Gobleanz: Direct mint not allowed.");
        require(secretzStuff(msg.sender, quantity, nonce) == hash, "Sorry Gobleanz: Something didn't add up.");    
        _safeMint(msg.sender, quantity);
    }

    function getzSome(address makers, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Sorry Gobleanz are out.");
        _safeMint(makers, quantity);
    }

    function secretzStuff(
        address sender,
        uint256 qty,
        uint256 nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce))
            )
        );
        return hash;
    }

    function noBotz(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setIsActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    // Start tokenid at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        payable(signerAddress).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/*

            .-+*%@@@@@@%#+-.            
  =**=:  :+%@@#*=--::--=*#@@%+.  .=**+  
 %#:+@@%#@@*:              :+@@%#@@+:*@.
*%=*=-@@@=                    =%@@=-*+#*
@+* :@@*                        +@@: +=@
@=#*@@+                          =@@*#=@
+@+#@%                            #@%=@*
 =#@@-                            -@@#= 
  .@@:                            .@@:  
  .@@-          *%#-   +##=       :@@:  
   %@*          :%@@.-::#@@:      +@@   
   -@@-    :+*%++*+:=+-=**+#%*=: :@@=   
    =@@-:*@*-.      +-:+     :=#@@@+    
     -@@@*             .      .*@@=     
       +@@*:        -**+    :*@@*.      
        .+@@@*=:    -gm=:-*%@@+.        
           :=#%@@@@%%@@@@@#+:           
 d'b 8                                 8      .oo               
 8   8                                 8     .P 8               
o8P  8 .oPYo. .oPYo. oPYo. .oPYo. .oPYo8    .P  8 .oPYo. .oPYo. 
 8   8 8    8 8    8 8  `' 8oooo8 8    8   oPooo8 8    8 8oooo8 
 8   8 8    8 8    8 8     8.     8    8  .P    8 8    8 8.     
 8   8 `Ygmi' `Wgmi' 8     `Wagmi `YooP' .P     8 8YooP' `Yooo' 
:..::..:.....::.....:..:::::.....::.....:..:::::..8 ....::.....:
::::::::::::::::::::::::::::::::::::::::::::::::::8 ::::::::::::
*/

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract flooredApe is ERC721, ERC721URIStorage, ReentrancyGuard, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OG_ROLE = keccak256("OG_ROLE");
    bool public publicBool = false;
    bool public whiteListBool = false;
    bool public adminBool = true;
    string private uriValue = "https://flooredape.mypinata.cloud/ipfs/QmdnpoFHDeVJcBbGyUZDXrNisKynYj2EgpNszuAnGmdRhp";
    string private degenURI = "https://flooredape.mypinata.cloud/ipfs/QmeaN8mGCyRTEr74jAFjnVYoJ8WjBxSyxtSrb2V3FyiUcg";
    string private ogURI = "https://flooredape.mypinata.cloud/ipfs/QmYs6cZwDQ3r9SLzzowfRNhHNMphDgn3pevPtgKkFEWoTq";

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _ogTokenIdCounter;

    uint256 public MINT_RATE = 0.02 ether;

    constructor() ERC721("flooredApe", "fA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(OG_ROLE, msg.sender);
        _tokenIdCounter.setCounter();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function batchFreeMint(
        address[] memory whiteList,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(publicBool, "Function not currently accessible");
        require(_tokenIdCounter.current() < 50001, "Tokens are sold out.");
        for (uint256 j = 0; j < whiteList.length; j++) {
            address to = whiteList[j];
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(to, _tokenIdCounter.current());
                _setTokenURI(_tokenIdCounter.current(), degenURI);
                _tokenIdCounter.increment();
            }
        }
    }

    function degenMint(
        uint256 amount
    ) public payable nonReentrant {
        require(amount < 11, "amount exceeds limit (10)");
        require(publicBool, "Function not currently accessible");
        require(_tokenIdCounter.current() < 50001, "Tokens are sold out.");
        require(msg.value >= amount * MINT_RATE, "Not enough ether.");

        address to = msg.sender;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _setTokenURI(_tokenIdCounter.current(), degenURI);
            _tokenIdCounter.increment();
        }
    }

    function whiteListMint(
        uint256 amount
    ) public payable onlyRole(MINTER_ROLE) nonReentrant {
        address to = msg.sender;
        require(amount < 11, "amount exceeds limit (10)");
        require(whiteListBool, "Function not currently accessible");
        require(_tokenIdCounter.current() < 50001, "Tokens are sold out.");
        require(msg.value >= amount * MINT_RATE, "Not enough ether.");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _setTokenURI(_tokenIdCounter.current(), degenURI);
            _tokenIdCounter.increment();
        }
    }

    function batchOwnMint (
        address[] memory whiteList,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(adminBool, "Function not currently accessible");
        require(_ogTokenIdCounter.current() < 1001, "OG Tokens are sold out");

        for (uint256 j = 0; j < whiteList.length; j++) {
            address to = whiteList[j];
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(to, _ogTokenIdCounter.current());
                _setTokenURI(_ogTokenIdCounter.current(), ogURI);
                _ogTokenIdCounter.increment();
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return
            uriValue;
    }

    function setContractURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE){
        uriValue = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function batchRole(bytes32 role, address[] memory arr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            grantRole(role, arr[i]);
        }
    }

    function batchRevoke(bytes32 role, address[] memory arr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            revokeRole(role, arr[i]);
        }
    }

    function currentPublic() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function currentOg() public view returns (uint256) {
        return _ogTokenIdCounter.current();
    }

    function flipPublic() public onlyRole(DEFAULT_ADMIN_ROLE) {
        publicBool = !publicBool;
    }

    function flipWhiteList() public onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteListBool = !whiteListBool;
    }

    function flipOwner() public onlyRole(DEFAULT_ADMIN_ROLE) {
        adminBool = !adminBool;
    }

    function withdrawFees() public onlyRole(DEFAULT_ADMIN_ROLE){
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}

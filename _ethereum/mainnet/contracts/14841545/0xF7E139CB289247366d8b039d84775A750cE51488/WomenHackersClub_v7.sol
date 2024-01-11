// SPDX-License-Identifier: MIT
/*

                  .-'''-.                                                          
                 '   _    \                                                        
               /   /` '.   \  __  __   ___         __.....__        _..._          
       _     _.   |     \  ' |  |/  `.'   `.   .-''         '.    .'     '.        
 /\    \\   //|   '      |  '|   .-.  .-.   ' /     .-''"'-.  `. .   .-.   .       
 `\\  //\\ // \    \     / / |  |  |  |  |  |/     /________\   \|  '   '  |       
   \`//  \'/   `.   ` ..' /  |  |  |  |  |  ||                  ||  |   |  |       
    \|   |/       '-...-'`   |  |  |  |  |  |\    .-------------'|  |   |  |       
     '                       |  |  |  |  |  | \    '-.____...---.|  |   |  |       
                             |__|  |__|  |__|  `.             .' |  |   |  |       
                             _..._               `''-...... -'   |  |   |  |       
                          .-'_..._''.                            |  |   |  |       
   .                    .' .'      '.\    .           __.....__  '--'   '--'       
 .'|                   / .'             .'|       .-''         '.                  
<  |                  . '             .'  |      /     .-''"'-.  `. .-,.--.        
 | |             __   | |            <    |     /     /________\   \|  .-. |       
 | | .'''-.   .:--.'. | |             |   | ____|                  || |  | |  _    
 | |/.'''. \ / |   \ |. '             |   | \ .'\    .-------------'| |  | |.' |   
 |  /    | | `" __ | | \ '.          .|   |/  .  \    '-.____...---.| |  '-.   | / 
 | |     | |  .'.''| |  '. `._____.-'/|    /\  \  `.             .' | |  .'.'| |// 
 | |     | | / /   | |_   `-.______ / |   |  \  \   `''-...... -'   | |.'.'.-'  /  
 | '.    | '.\ \._,\ '/            `  '    \  \  \                  |_|.'   \_.'   
 '---'   '---'`--'  `"               '------'  '---'                               
       _..._                                                                       
    .-'_..._''. .---.                                                              
  .' .'      '.\|   |           /|                                                 
 / .'           |   |           ||                                                 
. '             |   |           ||                                                 
| |             |   |           ||  __                                             
| |             |   |   _    _  ||/'__ '.                                          
. '             |   |  | '  / | |:/`  '. '                                         
 \ '.          .|   | .' | .' | ||     | |                                         
  '. `._____.-'/|   | /  | /  | ||\    / '                                         
    `-.______ / '---'|   `'.  | |/\'..' /                                          
             `       '   .'|  '/'  `'-'`                                           
                      `-'  `--'                                                    



*/

pragma solidity ^0.8.13;

import "./ONFT721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract WomenHackersClub is Ownable, ONFT721 {
    using Counters for Counters.Counter;
    Counters.Counter private nextMintId;
    string public baseTokenURI;
    uint256 public maxMintId;
    uint256 price = 82000000000000000; // 0.082 ether
    uint256 mintpassprice = 64000000000000000; // 0.064  ether
    uint256 allowlistprice = 76000000000000000; // 0.076 ether
    uint256 public walletLimit = 100; 
    uint256 public perTxLimit = 3;
    bool public saleIsActive = false; 
    bool public PresaleIsActive = true; 
    mapping(address => uint256) public addressMintedBalance;
    address private a1 = 0xd6B20f7AB159Faf338093d51e1Eb78DEdB2a00B2;
    address public signingAddress = 0x1048Ded3a542e064C82161Ab8840152393E0477E;

    constructor(address _layerZeroEndpoint, uint startMintId, uint endMintId) ONFT721("Women Hackers Club", "WHC", _layerZeroEndpoint) {
        nextMintId = Counters.Counter(startMintId);
        maxMintId = endMintId;

    }

    function allowlistMint(uint256 mintCount,uint8 v, bytes32 r,bytes32 s,uint256 mint_allowed,uint256 free) external payable {
        require(PresaleIsActive, "Presale not active");
        require(msg.value >= allowlistprice * mintCount, "Not enought eth");
        require(verifySignature(v,r,s,mint_allowed,free), "Invalid signature");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= mint_allowed, "Individual mint limit exceeded!");
        mint(msg.sender,mintCount);
    }

    function mintpassMint(uint256 mintCount,uint8 v, bytes32 r,bytes32 s,uint256 mint_allowed,uint256 free) external payable {
        require(PresaleIsActive, "Presale not active");
        require(msg.value >= mintpassprice * mintCount, "Not enought eth");
        require(verifySignature(v,r,s,mint_allowed,free), "Invalid signature");
        require(free == 2, "No mintpass");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= mint_allowed, "Exceeds Individual mint limit!");
        mint(msg.sender,mintCount);
    }
    
    function claim(uint256 mintCount,uint8 v, bytes32 r,bytes32 s,uint256 mint_allowed,uint256 free) external payable {
        require(PresaleIsActive, "Presale not active");
        require(verifySignature(v,r,s,mint_allowed,free), "Invalid signature");
        require(free == 1, "Not allowed to claim");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= mint_allowed, "Exceeds allowed free claims");

        mint(msg.sender,mintCount);
    }

    function publicMint(uint256 mintCount) external payable {
        require(saleIsActive, "Sale not active");
        require(msg.value >= price * mintCount, "not enought eth");
        require(mintCount <= perTxLimit, "tx_limit exceeded");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= walletLimit, "wallet_limit exceeded");
 
        mint(msg.sender,mintCount);
    }

   function mintOwner(address addr, uint256 mintCount) external onlyOwner {
        mint(addr,mintCount);
    }

    function mint(address addr, uint256 mintCount) private {
        require((nextMintId.current() + mintCount) < maxMintId, "Sold out! No more WHCs are available");
        for(uint i = 0;i<mintCount;i++)
        {
            _safeMint(addr, nextMintId.current());
            nextMintId.increment();
            addressMintedBalance[msg.sender]++;
        }
    }

    function setMaxMintId(uint256 _maxMintId) external onlyOwner {
        maxMintId = _maxMintId;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMintpassPrice(uint256 _mintpassprice) external onlyOwner {
        mintpassprice = _mintpassprice;
    }

    function setAllowlistPrice(uint256 _allowlistprice) external onlyOwner {
        allowlistprice = _allowlistprice;
    }

    function setPerTxLimit(uint256 _perTxLimit) external onlyOwner {
        perTxLimit = _perTxLimit;
    }

    function setWalletLimit(uint256 _perWalletLimit) external onlyOwner {
        walletLimit = _perWalletLimit;
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return maxMintId;
    }
     function getCurrentId() external view returns (uint256) {
        return nextMintId.current();
    }

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresale() public onlyOwner {
        PresaleIsActive = !PresaleIsActive;
    }

    function setSigningAddress(address _signingAddress) external onlyOwner {
        signingAddress = _signingAddress;
    }
    
    function withdraw() external onlyOwner {
        payable(a1).transfer(address(this).balance);
    }

     /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }

    function verifySignature(uint8 v, bytes32 r,bytes32 s,uint256 amountAllowed,uint256 free) public view returns (bool) {
    bytes32 messageHashed = keccak256(abi.encodePacked( msg.sender, amountAllowed,free));
    bytes32 hash = toEthSignedMessageHash(messageHashed);
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "invalid signature");
    if(signer == signingAddress){
        return true;
    } else{
        return false;
    }
    }
}
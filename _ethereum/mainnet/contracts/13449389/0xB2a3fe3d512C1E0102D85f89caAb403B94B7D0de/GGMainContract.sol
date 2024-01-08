// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
//man thats a lot of imports...
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

import "./Context.sol";
import "./Counters.sol";

import "./ECDSA.sol";
import "./Ownable.sol";
/*

   _________ __       __       _______      __    
  / ____/ (_) /______/ /_     / ____(_)____/ /____
 / / __/ / / __/ ___/ __ \   / / __/ / ___/ / ___/
/ /_/ / / / /_/ /__/ / / /  / /_/ / / /  / (__  ) 
\____/_/_/\__/\___/_/ /_/   \____/_/_/  /_/____/  
                                                 

v0.2
*/

contract GlitchGirls is Context, ERC721Enumerable, ERC721Burnable, Ownable {   
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdTracker;
    
    string private _tokenBaseURI;

    uint256 public constant GG_PRICE = 0.1 ether;

    

    uint256 public constant GG_WHITELIST = 1743;
    uint256 public constant GG_REGISTER = GG_WHITELIST + 3000;
    uint256 public constant DEV_HOLDBACK = 69;
    uint256 public constant GG_PUBLIC = (GG_REGISTER + 2226) - DEV_HOLDBACK;
    uint256 public constant GG_MAX = GG_PUBLIC + DEV_HOLDBACK; //6969

    bool public whitelistLive;
    bool public publicLive;
    bool public registerLive;

    address private _signerAddress;

    constructor(string memory startingBaseToken, address startingSignerAddress) ERC721("Glitch Girls", "GG") {
        _tokenBaseURI = startingBaseToken;
        _signerAddress = startingSignerAddress;
    }

    function currentSupply() public view returns(uint256) {
        return _tokenIdTracker.current()+1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    mapping(address => uint256) public whiteListAmountLeft;

    function addToWhiteList(address[] calldata entries, uint256[] calldata amountAllowed) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            whiteListAmountLeft[entry] = amountAllowed[i];
        }   
    }

    function removeFromWhiteList(address[] calldata entries) external onlyOwner {
        
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            
            whiteListAmountLeft[entry] = 0;
        }
    }

    function mintGGWhiteList(uint256 tokenQuantity) external payable {

        require(whitelistLive, "11");

        int256 AmountOfWhiteLists = int256(whiteListAmountLeft[msg.sender]);

        require(!(AmountOfWhiteLists == 0), "10");
        require((AmountOfWhiteLists - int256(tokenQuantity)) >= 0, "12");
        require(_tokenIdTracker.current() <= GG_WHITELIST, "13");
        require((_tokenIdTracker.current() + tokenQuantity) <= GG_WHITELIST, "12");
        require((GG_PRICE * tokenQuantity) <= msg.value, "2");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
        }
        whiteListAmountLeft[msg.sender] = whiteListAmountLeft[msg.sender] - tokenQuantity;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(_tokenIdTracker.current() <= GG_MAX, "13");
        require((_tokenIdTracker.current() + receivers.length) <= GG_MAX, "12");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            _tokenIdTracker.increment();
            _safeMint(receivers[i], _tokenIdTracker.current());
        }
    }

    function verifyAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(address sender, string memory transactionID, uint256 tokenQuantity) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(sender, transactionID, tokenQuantity));
          return hash;
    }

    mapping(string => bool) public usedTransactions;

    function mintGG(bytes32 hash, bytes memory signature, uint256 tokenQuantity, string memory transactionID) external payable {
        require(publicLive || registerLive, "31");
        uint256 supplyForMint;
        if (registerLive) {
            supplyForMint = GG_REGISTER;
        }
        if (publicLive) {
            supplyForMint = GG_PUBLIC;
        }

        require(verifyAddressSigner(hash, signature), "68");
        
        require(!usedTransactions[transactionID], "3");

        require(hashTransaction(msg.sender, transactionID, tokenQuantity) == hash, "5");

        require(_tokenIdTracker.current() <= supplyForMint, "32");
        require((_tokenIdTracker.current()+ tokenQuantity) <= supplyForMint, "33");
        require((GG_PRICE * tokenQuantity) <= msg.value, "2");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
        }

        usedTransactions[transactionID] = true;
    }

    address private withdrawAccount = 0x3586218D139C2fd5eC9445E13FFC466D5bB5aa8c;
    
    modifier withdrawAddressCheck() {
        require(msg.sender == withdrawAccount, "99");
        _;
    }

    function totalBalance() external view returns(uint) {
        return payable(address(this)).balance;
    }

    function withdrawFunds() external withdrawAddressCheck() {
        payable(msg.sender).transfer(this.totalBalance());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function toggleWhiteList(uint256 typeToActivate) external onlyOwner {
        if (typeToActivate == 1) {
            whitelistLive = !whitelistLive;
        } else if (typeToActivate == 2) {
            registerLive = !registerLive;
        } else if (typeToActivate == 3) {
            publicLive = !publicLive;
        }
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "1");
        
        return string(abi.encodePacked(_tokenBaseURI, (tokenId).toString(), string(".json")));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
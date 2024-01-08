// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SixClocks is ERC721Enumerable, Ownable {

    using Strings for uint256;

    mapping(uint256 => string) _tokenURIs;
    uint256 public cost = 0.08 ether;
    uint256 public maxSupply= 500;                                    // how much total are we allowed to mint?
    uint256 public maxMintAmount = 20;                               // for a mass mint, what's the maximum at one time someone can mint?
    bool public paused = false;
    string public baseURI;
    string public baseExtension = ".json";
    mapping(address => bool) public whitelisted;

    struct RenderToken {
        uint256 id;
        string uri;
        address mintOwner;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {

         setBaseURI(_initBaseURI);

         // original chain mints!
         /*
         _safeMint(address(0xF525382b952383E5bcc693bcD21467A7Fd284913), 0);
         _safeMint(address(0x910760eF0fa3C77507bA94f3F0FC221A1de6078B), 1);
         _safeMint(address(0x910760eF0fa3C77507bA94f3F0FC221A1de6078B), 2);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 3);
         _safeMint(address(0xF525382b952383E5bcc693bcD21467A7Fd284913), 4);
         _safeMint(address(0xF525382b952383E5bcc693bcD21467A7Fd284913), 5);
         _safeMint(address(0x910760eF0fa3C77507bA94f3F0FC221A1de6078B), 6);
         _safeMint(address(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274), 7);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 8);
         _safeMint(address(0xF525382b952383E5bcc693bcD21467A7Fd284913), 9);
         _safeMint(address(0x4DbE965AbCb9eBc4c6E9d95aEb631e5B58E70d5b), 10);
         _safeMint(address(0x4DbE965AbCb9eBc4c6E9d95aEb631e5B58E70d5b), 11);
         _safeMint(address(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274), 12);
         _safeMint(address(0x0bCadc4588622BCA284d5d04F1C76af6eAb4a6Ac), 13);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 14);
         _safeMint(address(0x548efCE69bb82a16f3911a86a65384327c99c3Ab), 15);
         _safeMint(address(0x4917d55E6b1dA5a0BFC616DE6233256C1c75107D), 16);
         _safeMint(address(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274), 17);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 18);
         _safeMint(address(0x910760eF0fa3C77507bA94f3F0FC221A1de6078B), 19);
         _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 20);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 21);
         _safeMint(address(0xF525382b952383E5bcc693bcD21467A7Fd284913), 22);
         _safeMint(address(0x84747165e0100cD7f9BdeB37d771E8d139f49e14), 23);
         _safeMint(address(0xAa8ec1691D4A1FFbCd6241840F075D6685531fD6), 24);
         _safeMint(address(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274), 25);
         _safeMint(address(0x9c9190635D46c36452Da89C1603216e0377e0e57), 26);
         _safeMint(address(0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274), 27);
         _safeMint(address(0x27F8602E403B6EA18f8711A7858fa4a94ef3269b), 28);
         _safeMint(address(0x1407C9d09d1603A9A5b806A0C00f4D3734df15E0), 29);
         _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 30);
         _safeMint(address(0x1407C9d09d1603A9A5b806A0C00f4D3734df15E0), 31);
         _safeMint(address(0x4D17c6eF27356254B929Adc124184bB34E5c5A1C), 32);
         _safeMint(address(0x4B018431ecfB9d6fd73ddc23CDafFfdba8d672Dd), 33);
         _safeMint(address(0x48a6ceaBf9998f11d97c304a4d38e7743DA4C9D4), 34);
        
         _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 35);
         _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 36);
         _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 37);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 38);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 39);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 40);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 41);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 42);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 43);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 44);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 45);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 46);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 47);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 48);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 49);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 50);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 51);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 52);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 53);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 54);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 55);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 56);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 57);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 58);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 59);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 60);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 61);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 62);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 63);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 64);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 65);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 66);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 67);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 68);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 69);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 70);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 71);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 72);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 73);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 74);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 75);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 76);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 77);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 78);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 79);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 80);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 81);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 82);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 83);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 84);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 85);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 86);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 87);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 88);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 89);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 90);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 91);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 92);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 93);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 94);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 95);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 96);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 97);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 98);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 99);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 100);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 101);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 102);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 103);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 104);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 105);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 106);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 107);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 108);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 109);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 110);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 111);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 112);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 113);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 114);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 115);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 116);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 117);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 118);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 119);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 120);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 121);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 122);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 123);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 124);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 125);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 126);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 127);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 128);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 129);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 130);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 131);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 132);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 133);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 134);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 135);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 136);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 137);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 138);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 139);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 140);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 141);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 142);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 143);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 144);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 145);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 146);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 147);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 148);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 149);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 150);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 151);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 152);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 153);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 154);
        _safeMint(address(0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA), 155);

        _safeMint(address(0x22E45117634162E88946B5121242b22c0dD69338), 156);
        */
    }
    
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, (tokenId + 1).toString(), baseExtension))
            : "";
    }

    function getAllTokens() public view returns(RenderToken[] memory) {
       uint256 latestId = totalSupply();
     //  uint256 counter = 1; // totalSupply starts at 0, but we want to return something starting at 1
       RenderToken[] memory res = new RenderToken[](latestId);
       for(uint256 i = 0; i < latestId; i++) {
           if(_exists(i)) {
               string memory uri = tokenURI(i);
               address mintOwner = ownerOf(i);
               res[i] = RenderToken(i, uri, mintOwner);
           }
          // counter++; 
       }
       return res;
    }
    
    function getMaxMint() public view returns(uint256) {
        return maxSupply;
    }

    function getAlreadyMinted() public view returns(uint256) {
        return totalSupply();
    }

    function mint(address recipient) public payable {
        // only allow initial creating wallet (mine) to mint.
        // (might change this later)
        uint256 supply = totalSupply();
        require(!paused);
        require(supply <= maxSupply, "Cannot mint over the limit.");
        
        if (msg.sender != owner()) {
            if(whitelisted[msg.sender] != true) {
                require(msg.value >= cost);
            }
        }
        _safeMint(recipient, supply);
    }

    function getPaused() public view returns(bool) {
       return paused;
    }
    
    //----------------------------------------------------------
    // only owner functions below
    //----------------------------------------------------------

    function massMint(address _to, uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }
    
    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }

    function setmaxSupply(uint256 _newmaxSupply) public onlyOwner() {
        maxSupply = _newmaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    // if we need to blatantly update metadata
    function setTokenURI(uint256 _tokenId, string memory _uri) public onlyOwner {
        require(_exists(_tokenId));
        _tokenURIs[_tokenId] = _uri;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Kareqn_contract is ERC721A, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0;
    uint256 public maxSupply = 1000;
    uint256 public preSaleSupply = 1000;
    uint256 public maxMintAmount = 5;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    mapping(address => uint256) public whitelistUserAmount;
    mapping(address => uint256) public whitelistMintedAmount;
    

    constructor(
    ) ERC721A('KareQN', 'KQN') {
        setBaseURI('ipfs://QmPwSLwEbjjUK9kYW7aVMTcEUMn5vBicSRh7MzFLbBLea6/');
        _safeMint(0xE99D2CA74de6190449F1A856D922a4099CB2a770,50);
        _safeMint(0xE35b8c32be71c55726e2ed1d6247d367B407aEb9,50);
        _safeMint(0xC8710C9ca16c5804BB49Bf2999645AAf9E97D862,5);
        _safeMint(0x6542684e6c00bE02362B4b5Fc954e72BF566AE66,5);
        _safeMint(0x1D9B4E8CdDaDBA7323533D4495ed27CFf8ae8831,10);
        _safeMint(0xFfc5df85CBAa6928601866E7dc983816C648F858,5);
        _safeMint(0x9EA0Bb5B9c43854d8cE2c045069BE095766ae4e7,5);
        _safeMint(0xdEcf4B112d4120B6998e5020a6B4819E490F7db6,5);
        _safeMint(0x6c5a094304cBA401578b0cf5Bd361f9582f8E31b,5);
        _safeMint(0x225B7354B2c6160868280CC524175D8b1f9b3b98,5);
        _safeMint(0x2E581428eD71F291a64ac76A03Dbe85Bad847441,5);
        _safeMint(0xAa4dD68dC9D319717e6Eb8b3D08EABF6677cAFDb,5);
        _safeMint(0x4eA84A06F011495B99Aa7202fDca60443107042F,5);
        _safeMint(0x8427EDea80FbF90fF9B7830c00243DE6A4899505,5);
        _safeMint(0x2E879093CbC63F55e8160178FF26A18cFB06d27f,5);
        _safeMint(0x88aB1910F099c7DA7083FB8bc7c85eb7a7d41397,5);
        _safeMint(0xAc04daD074B83dC497aF021865655079429809a3,10);
        _safeMint(0x06BAc69D925002B5B1e5553b8C20f997144905c0,5);
        _safeMint(0x12745885d75983d52853219cA36B17292a98B65f,5);
        _safeMint(0xd89d6Dad49Bbc704708F1c51A3c9107FAF70DC88,5);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
        
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(supply + _mintAmount <= preSaleSupply, "pre Sale NFT limit exceeded");

        // Owner also can mint.
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
            if(onlyWhitelisted == true) {
                require(whitelistUserAmount[msg.sender] != 0, "user is not whitelisted");
                require(whitelistMintedAmount[msg.sender] + _mintAmount <= whitelistUserAmount[msg.sender], "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }

        _safeMint(msg.sender, _mintAmount);
    }


    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUserAmount[addresses[i]] = saleSupplies[i];
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    //only owner  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }    

    function setpreSaleSupply(uint256 _newpreSaleSupply) public onlyOwner {
        preSaleSupply = _newpreSaleSupply;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    
}
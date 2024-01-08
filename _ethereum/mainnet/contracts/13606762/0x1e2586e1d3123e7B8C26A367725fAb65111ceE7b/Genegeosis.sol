//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//          `-+gggggggggg/-                                                                                           -ggG/                   //
//        .gGGGgg/---:+gGGg                                                                                           :Ggg/                   //
//       +gGGG:         :gG                                                                                            `.`                    //
//      /GGGG-           :g                                                                                                                   //
//      GGGGg                 `ggggggGg:.gggGGGgGGGGg/   :gG930GGg` :gGGggGGGgGG+ :gGgggGGg`  /gGggggGGg+   :gGgggGG ggGGGg   :GGgggG:        //
//      GGGGg                .gGg:--gGGg./GGGGg:-gGGGg  gGGg---gGGg-GGGg  -GGGG-`gGGg---gGGg gGGG-   gGGGg /GGg.  gg -gGGGg  gGGg  /g-        //
//      gGGGg      .SiggiEggertssonggggg` gGGG/  :GGGG .Genegeosis+:GGGg  `GGGg .GGGggggggg+:GGGg     gGGG:-GGGGgg:   /GGGg  GGGGgg/`         //
//      -GGGGg        GGGGg  gGGg         gGGG/  :GGGG :GGG+        +gGGg+gGGg. :GGG+       +GGGg     gGGG/ -ggGGGGg` /GGGg  `gGGGGGg/        //
//       :gGGGg`      gGGGg  gGGGg-  `:g. gGGG/  :GGGG `gGGg+.  .+g +GGgggg+-.  `gGGg+.  .+g`gGGg`    gGGG`-g.`:gGGG+ /GGGg  g/ .+gGGg        //
//        `ggGGgg+/::/CLIPg` `gGGVQganGg.+GGGGg//gGGGg+.-GGGGggggg: GGGGgggggggg`-GGGGggggg: .gGGg/-:gGGg` /Gg:-/GGG.:gGGGg:`gg+-:gGG+        //
//          `./gggggggggg/-    -ggggg+. .ggggggg+gggggg- `/ggggg:`  :GGgGgggGGGGg `/ggggg:`    -gggggg+.   `gggggg/` ggggggg`/g2021g.         //
//                                                                 /gGg.`````gGG:                                                             //
//                                                                 /gGG/--:/ggg/                                                              //
//                                                                   .+gggggg+-`                                   By Siggi Eggertsson        //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Genegeosis is ERC721Tradable {

    address public artistWallet;
    address public devWallet;

    uint256 public MAX_ITEMS = 930;
    uint256 public price = 0.1 ether;
    uint256 public devSplit = 10; // percent
    string public baseUri;
    bool public locked = true;

    constructor (string memory _baseUri, address _artistWallet, address _devWallet, address _proxyRegistryAddress) ERC721Tradable("Genegeosis", "GEOS", _proxyRegistryAddress) {
        baseUri = _baseUri;
        artistWallet = _artistWallet;
        devWallet = _devWallet;
    }

    ///////////////////////////////////////////////////////////////////////////
    // External functions
    ///////////////////////////////////////////////////////////////////////////

    function mint() external payable {
        uint256 supply = totalSupply();
        require(!locked, 'Not unlocked yet.');
        require(supply + 1 <= MAX_ITEMS, 'Sold out!');
        require(price == msg.value, 'Price must be equal to the price.');
        require(balanceOf(msg.sender) + 1 <= 93, 'There is a minting limit of 93 per wallet.');

        _safeMint(msg.sender, supply + 1);
        
        paymentForward();
    }

    function mintMany(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require(!locked, 'Not unlocked yet.');
        require(supply + _amount <= MAX_ITEMS, 'Sold out!');
        require(price * _amount == msg.value, 'Price must be equal to the price.');
        require(_amount <= 20, 'You cannot mint more than 20 tokens at once.');
        require(balanceOf(msg.sender) + _amount <= 93, 'There is a minting limit of 93 per wallet.');

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
                
        paymentForward();
    }

    function ownerMintTo(address _to) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_ITEMS, 'Sold out!');
        _mint(_to, supply + 1);
    }

    function ownerMintManyTo(address _to, uint256 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _amount <= MAX_ITEMS, 'Sold out!');
        require(_amount <= 20, 'You cannot mint more than 20 tokens at once.');

        for (uint256 i = 1; i <= _amount; i++) {
            _mint(_to, supply + i);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Public functions
    ///////////////////////////////////////////////////////////////////////////

    function setLocked() public onlyOwner {
        require(!locked, 'Contract is already locked');
        locked = true;
    }

    function setUnlocked() public onlyOwner {
        require(locked, 'Contract is already unlocked');
        locked = false;
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function baseTokenURI() override public view returns (string memory) {
        return baseUri;
    }

    function setArtistWallet(address _artistWallet) public onlyOwner {
        artistWallet = _artistWallet;
    }

    function setDevWallet(address _devWallet) public onlyOwner {
        devWallet = _devWallet;
    }

    function setDevSplit(uint256 newDevSplit) public onlyOwner {
        devSplit = newDevSplit;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), "contract"));
    }

    ///////////////////////////////////////////////////////////////////////////
    // Internal functions
    ///////////////////////////////////////////////////////////////////////////

    function paymentForward() internal {
        uint256 _splitDev = msg.value * devSplit / 100;
        uint256 _splitArtist = msg.value - _splitDev;
        sendViaCall(payable(devWallet), _splitDev);
        sendViaCall(payable(artistWallet), _splitArtist);
    }
    
    
    function sendViaCall(address payable _to, uint256 _value) internal {
        (bool sent, bytes memory data) = _to.call{value: _value}("");
        require(sent, "Failed to send ETH");
    }
}


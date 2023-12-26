// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";


contract NFTv1 is ERC721,ERC721Burnable, ERC721Enumerable, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply;
    bool public isSale = false;
    uint256 public cost = 200000000000000000;
    uint256 public maxMintPerTx = 10;
    string public tokenName = unicode'The Laughing Man Original';
    string public description = unicode"StorySyncNFT（Original）\\nDive into the world of Japanese cyberpunk.\\n\\nCopycat or ghost, which will you choose? \\n\\nOfficial Project of Ghost in the Shell STAND ALONE COMPLEX\\n©Shirow Masamune・Production I.G/KODANSHA All Rights Reserved.";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    function mint(uint256 _amount) public payable  {
        
        require(isSale, 'NFTV1Error: Sale unavailable');
        require(_amount > 0, 'NFTV1Error: Mint amount invalid');
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + _amount <= maxSupply,'NFTV1Error: Mint amount overloaded');
        require(_amount <= maxMintPerTx,'NFTV1Error: Mint per Tx overloaded');
        if (msg.sender != owner()) {
             require(msg.value >= cost * _amount,'NFTV1Error: Insufficient fund');
        }
        for (uint256 i = 1; i <= _amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function getCurrentTokenId() view public returns (uint256){
        return _tokenIdCounter.current();
    }

    function setSaleOpen() public onlyOwner {
        isSale = true;
    }

    function setSaleClose() public  onlyOwner {
        isSale = false;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory svg = getSVG();
        bytes memory json = abi.encodePacked(
            '{"name": "',
            tokenName,
            '", "description": "',
            description,
            '", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
    

    function getSVG() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    unicode'<svg id="master-artboard" viewBox="0 0 1400 980" version="1.1" xmlns="http://www.w3.org/2000/svg" x="0" y="0" style="enable-background:new 0 0 1400 980" width="1400" height="980" xmlns:xlink="http://www.w3.org/1999/xlink"><path id="ee-background" style="fill:#fff;fill-opacity:0;pointer-events:none" d="M0 0h1400v980H0z"/><defs><style id="ee-google-fonts">.filler{fill:#002C59}.stroker{stroke:#002C59}@import url(https://fonts.googleapis.com/css?family=Fjalla+One:400|Roboto:100,100italic,300,300italic,400,400italic,500,500italic,700,700italic,900,900italic);</style></defs><g/><g transform="matrix(1.96 0 0 1.96 214.164 .558)"><path d="M0 0h500v500H0V0Z" class="cls-4" transform="rotate(90 250.12 250.12)" style="fill:#FFFFFF;fill-opacity:1" id="background"/><path class="stroker" d="M50 250C50 96.04 216.667-.185 350 76.795 411.88 112.52 450 178.547 450 250c0 153.96-166.667 250.185-300 173.205C88.12 387.48 50 321.453 50 250" stroke-width="10" fill="#FFF" style="fill-opacity:1;stroke-width:12" transform="matrix(.98619 0 0 .98085 3.454 4.788)"/><path id="tlms" d="M85 250c0-127.017 137.5-206.403 247.5-142.894C383.551 136.58 415 191.05 415 250c0 127.017-137.5 206.403-247.5 142.894C116.449 363.42 85 308.95 85 250" stroke="transparent" fill="#FFF" style="fill-opacity:1"/><animateTransform attributeName="transform" type="rotate" from="0 250 250" to="-360 250 250" dur="10s" repeatCount="indefinite" xlink:href="#tlms"/><path class="stroker" d="M110 250c0-107.772 116.667-175.13 210-121.244 43.316 25.009 70 71.227 70 121.244 0 107.772-116.667 175.13-210 121.244-43.316-25.009-70-71.227-70-121.244" stroke-width="20" fill="#FFF" style="stroke-width:23;fill-opacity:1" transform="translate(4.7 5.21) scale(.98038)"/><path class="filler" d="M147 279a104.907 104.907 0 0 0 49.17 71.33c15.76 9.52 34.2 14.98 53.85 14.98s38.08-5.46 53.85-14.98c25.44-15.45 43.7-41.05 49.17-71.33H138.91 147Zm156.86 44.48c-14.52 12.49-33.25 20-53.85 20s-39.33-7.49-53.85-20c-7.49-6.24-13.74-13.89-18.42-22.48h144.53c-4.68 8.58-11.08 16.23-18.42 22.48h.01Z" style="fill-opacity:1" transform="translate(-5.067 -16.232) scale(1.01855)"/><text class="filler" font-size="30" font-weight="bold" font-family="Impact" style="font-size:30px;font-weight:700;font-family:Impact;white-space:pre;fill-opacity:1" transform="matrix(.957 0 0 .957 9.58 8.932)"><textPath style="fill-opacity:1" xlink:href="#tlms">Or should I?　　　Or should I?　　　　Or should I?　　　Or should I?</textPath></text></g><g transform="matrix(6.78306 0 0 .44565 38.907 388.43)"><g id="g-9"><path class="filler" d="M58 49h100v100H58V49z"  id="g-10"/></g></g><g transform="translate(56.168 335.413) scale(1.60923)"><g id="g-3" transform="translate(-3.497)"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z"  id="g-4"/></g></g><g transform="matrix(1.65263 0 0 .71434 838.123 419.821)"><g id="g-1"><path class="st0" d="M58 49h100v100H58V49z" style="fill:#fff" transform="translate(2.614)" id="g-2"/></g></g><g transform="matrix(.37601 0 0 .42555 960.479 506.376)"><g id="g-15"><path class="filler" d="M58 49h100v100H58V49z" style="stroke:#000;stroke-width:0" transform="matrix(3.41126 0 0 1.02518 -139.853 -3.705)" id="g-16"/></g></g><path d="M99 240h22v10H99v-10Z" stroke="transparent" fill="#FFF" transform="matrix(2.28176 0 0 1.65915 184.97 56.594)" style="fill-opacity:1"/><path class="filler stroker" d="M541.605 513.229s3.957-49.543 52.256-50.157c48.3-.614 52.89 50.973 52.89 50.973s-17.017-22.225-52.425-22.728c-29.803-.423-52.846 21.86-52.72 21.912Z" style="fill-opacity:1;stroke-opacity:0;stroke-width:20;paint-order:fill" transform="translate(214.56 1.517)"/><path class="filler stroker" d="M541.605 513.229s3.957-49.543 52.256-50.157c48.3-.614 52.89 50.973 52.89 50.973s-17.017-22.225-52.425-22.728c-29.803-.423-52.846 21.86-52.72 21.912Z" style="fill-opacity:1;stroke-opacity:0;stroke-width:20;paint-order:fill" transform="translate(.636 1.517)"/><g transform="translate(627.316 183.456) scale(.13313)"><g id="g-5"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z"  id="g-6"/></g></g><g transform="translate(604.46 183.456) scale(.13313)"><g id="g-11"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z" id="g-12"/></g></g><g transform="matrix(.24113 0 0 .13447 676.94 182.992)"><g id="Layer_2_4_"><path class="filler" d="M58 49h100v100H58V49z" id="Layer_1-2_4_"/></g></g><g transform="matrix(.36113 0 0 .13387 663.66 189.562)"><g id="g-17"><path class="filler" d="M58 49h100v100H58V49z" id="g-18"/></g></g><g transform="translate(635.188 422.09) scale(.7138)"><g id="g-19" transform="translate(3.034 -.268)"><path class="st0" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z" style="fill:#fff" id="g-20"/></g></g></svg>'
                )
        );
    }
}
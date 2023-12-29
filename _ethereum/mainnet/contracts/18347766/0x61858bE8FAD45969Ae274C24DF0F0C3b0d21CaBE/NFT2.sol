// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./NFT1.sol";

contract NFTv2 is ERC721, ERC721Enumerable, Ownable{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct TokenMetadata {
        uint256 colorId;
        uint256 textId;
        uint256 backgroundColorId;
        uint256 textType;
    }

    bool public isSale = true;
    
    string[17] public colorList;
    string[16] public backgroundColorList;
    string[10] public textListNormal;
    string[10] public textListJapanese;
    string[10] public textListNormalForAttributes;
    string[10] public textListJapaneseForAttributes;
    
    string public textBug;
    string public textBugForAttributes;

    mapping(uint256=> TokenMetadata) public tokenIdToTokenMetadata;
    mapping(uint256=> string) public textTypeToTextTypeName;
    mapping(uint256=> string) public colorIdToColorName;
    mapping(uint256=> string) public backgroundColorIdTobackgroundColorName;

    NFTv1 public nftv1;
    string public tokenName = unicode'The Laughing Man Copycat';
    string public description = unicode'StorySyncNFT（Copycat）\\nDive into the world of Japanese cyberpunk.\\n\\nOfficial Project of Ghost in the Shell STAND ALONE COMPLEX\\n©Shirow Masamune・Production I.G/KODANSHA All Rights Reserved.';
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _contractAddress
    ) ERC721(_name, _symbol) {
        nftv1 = NFTv1(_contractAddress);
        setTextNormal();
        setTextJapanese();
        setBugText();
        setColorList();
        setBackgroundColorList();
        setTextTypeName();
        setBackgroundColorName();
        setColorName();
        setTextNormalForAttributes();
        setTextJapaneseForAttributes();
        setBugTextForAttributes();
    }

    function mint(uint256 _tokenIdToBurnt,  uint256 _textId) public {
        require(isSale, 'NFTV2Error: Sale unavailable');
        require(nftv1.ownerOf(_tokenIdToBurnt) == msg.sender ,'NFTV2Error: You are not the token owner'); 
        require(_textId < textListNormal.length, 'NFTV2Error: invalid textId');
        
        _tokenIdCounter.increment();
        
        uint256 tokenId = _tokenIdCounter.current();
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId,_tokenIdToBurnt)));
        uint256 colorId =  seed % colorList.length;
        uint256 backgroundColorId =  seed % backgroundColorList.length;
        uint256 textType = getMetaDataTextType(seed);

        tokenIdToTokenMetadata[tokenId] = TokenMetadata(colorId,_textId,backgroundColorId,textType);

        nftv1.burn(_tokenIdToBurnt);
        _safeMint(msg.sender, tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    
    function getMetaDataTextType(uint256 _randomSeed)  private  pure returns (uint256){
        uint256 langSeed = _randomSeed % 10;
        if (langSeed < 5){
            return 0;
        }else if (langSeed < 9) {
            return 1;
        }else{
            return 2;
        }
    }

    function setSaleOpen() public onlyOwner {
        isSale = true;
    }

    function setSaleClose() public  onlyOwner {
        isSale = false;
    }


    function setTextNormal() private onlyOwner {
        textListNormal[0] =  unicode"He must be a super-class-A hacker.　　He must be a super-class-A hacker.";
        textListNormal[1] =  unicode"...as he suddenly vanished into the shadows of the Net.";
        textListNormal[2] =  unicode"We don't have convenient excuses like team plays here at Section 9.";
        textListNormal[3] =  unicode"Now I'll go down in the history books as the Laughing Man.";
        textListNormal[4] =  unicode"Who the hell was peeking around inside this guy's brain?";
        textListNormal[5] =  unicode"I'm the real one! The one and only!　　　I'm the real one! The one and only!";
        textListNormal[6] =  unicode"In a play, even the audience is simply a part of the performance.";
        textListNormal[7] =  unicode"Everything's being stained the same color.";
        textListNormal[8] =  unicode"I'll leave my memories with you.　　　　I'll leave my memories with you.";
        textListNormal[9] =  unicode"Oh God... How powerless we are...my brothers and I...";
    }

    function setTextJapanese() private onlyOwner {
        textListJapanese[0] =  unicode'本当にそれを一人でやってのけたとしたら、超特A級のハッカーね';
        textListJapanese[1] =  unicode'笑い男はネットの闇に忽然と姿を消した';
        textListJapanese[2] =  unicode'我々の間にはチームプレイなどという都合のいい言い訳は存在せん';
        textListJapanese[3] =  unicode'これで俺も晴れて笑い男として歴史に名を残すわけだ';
        textListJapanese[4] =  unicode'誰なんだ、こいつの脳を覗いていたやつは？';
        textListJapanese[5] =  unicode'俺だけが本物なの！　　俺だけが本物なの！　　俺だけが本物なの！';
        textListJapanese[6] =  unicode'劇とは観客自体もその演出の一部に過ぎない。';
        textListJapanese[7] =  unicode'全てが同じ色に染まっている。　　　全てが同じ色に染まっている。';
        textListJapanese[8] =  unicode'僕の記憶おいて行きます。　　　　　僕の記憶おいて行きます。';
        textListJapanese[9] =  unicode'神様...僕たちはなんて無力なんだ。　　神様...僕たちはなんて無力なんだ。';
    }

    function setBugText() private onlyOwner {
        textBug = unicode'縺昴≧縺励ｍ縺｣縺ｦ蝗√￥縺ｮ繧医?∫ｧ√?繧ｴ繝ｼ繧ｹ繝医′縲';
    }

    function setTextNormalForAttributes() private onlyOwner {
        textListNormalForAttributes[0] =  unicode"He must be a super-class-A hacker.";
        textListNormalForAttributes[1] =  unicode"...as he suddenly vanished into the shadows of the Net.";
        textListNormalForAttributes[2] =  unicode"We don't have convenient excuses like team plays here at Section 9.";
        textListNormalForAttributes[3] =  unicode"Now I'll go down in the history books as the Laughing Man.";
        textListNormalForAttributes[4] =  unicode"Who the hell was peeking around inside this guy's brain?";
        textListNormalForAttributes[5] =  unicode"I'm the real one! The one and only!";
        textListNormalForAttributes[6] =  unicode"In a play, even the audience is simply a part of the performance.";
        textListNormalForAttributes[7] =  unicode"Everything's being stained the same color.";
        textListNormalForAttributes[8] =  unicode"I'll leave my memories with you.";
        textListNormalForAttributes[9] =  unicode"Oh God... How powerless we are...my brothers and I...";
    }

    function setTextJapaneseForAttributes() private onlyOwner {
        textListJapaneseForAttributes[0] =  unicode'本当にそれを一人でやってのけたとしたら、超特A級のハッカーね';
        textListJapaneseForAttributes[1] =  unicode'笑い男はネットの闇に忽然と姿を消した';
        textListJapaneseForAttributes[2] =  unicode'我々の間にはチームプレイなどという都合のいい言い訳は存在せん';
        textListJapaneseForAttributes[3] =  unicode'これで俺も晴れて笑い男として歴史に名を残すわけだ';
        textListJapaneseForAttributes[4] =  unicode'誰なんだ、こいつの脳を覗いていたやつは？';
        textListJapaneseForAttributes[5] =  unicode'俺だけが本物なの！';
        textListJapaneseForAttributes[6] =  unicode'劇とは観客自体もその演出の一部に過ぎない。';
        textListJapaneseForAttributes[7] =  unicode'全てが同じ色に染まっている。';
        textListJapaneseForAttributes[8] =  unicode'僕の記憶おいて行きます。';
        textListJapaneseForAttributes[9] =  unicode'神様...僕たちはなんて無力なんだ。';
    }

    function setBugTextForAttributes() private onlyOwner {
        textBugForAttributes = unicode'縺昴≧縺励ｍ縺｣縺ｦ蝗√￥縺ｮ繧医?∫ｧ√?繧ｴ繝ｼ繧ｹ繝医′縲';
    }


    function setColorList() private onlyOwner {
        colorList[0] =  '7E3B7E';
        colorList[1] =  'DD8080';
        colorList[2] =  '93876C';
        colorList[3] =  '6B5E47';
        colorList[4] =  'A8803E';
        colorList[5] =  '691C10';
        colorList[6] =  'FF6F7A';
        colorList[7] =  '80002F';
        colorList[8] =  '554030';
        colorList[9] =  '351C09';
        colorList[10] =  '9B4623';
        colorList[11] =  '2C302E';
        colorList[12] =  '7A4D3D';
        colorList[13] =  '004EC9';
        colorList[14] =  'FF8B00';
        colorList[15] =  'BE004C';
        colorList[16] =  '2E2737';
    }


    function setColorName() private onlyOwner {
        colorIdToColorName[0] =  'Motoko-1';
        colorIdToColorName[1] =  'Motoko-3';
        colorIdToColorName[2] =  'Batou-1';
        colorIdToColorName[3] =  'Batou-3';
        colorIdToColorName[4] =  'Togusa-1';
        colorIdToColorName[5] =  'Togusa-3';
        colorIdToColorName[6] =  'Miki';
        colorIdToColorName[7] =  'Aramaki-1';
        colorIdToColorName[8] =  'Ishikawa-1';
        colorIdToColorName[9] =  'Ishikawa-3';
        colorIdToColorName[10] =  'Borma-1';
        colorIdToColorName[11] =  'Saito-1';
        colorIdToColorName[12] =  'Paz-1';
        colorIdToColorName[13] =  'Book-1';
        colorIdToColorName[14] =  'Sunflower Society';
        colorIdToColorName[15] =  'Crime Lab';
        colorIdToColorName[16] =  'Section9-1';
    }

    function setBackgroundColorList() private onlyOwner {
        backgroundColorList[0] =  'C8A1C6';
        backgroundColorList[1] =  'CEB98F';
        backgroundColorList[2] =  'C43540';
        backgroundColorList[3] =  'EBCD00';
        backgroundColorList[4] =  '008091';
        backgroundColorList[5] =  '0071AD';
        backgroundColorList[6] =  'DFDED7';
        backgroundColorList[7] =  'BCBCBC';
        backgroundColorList[8] =  'B89E87';
        backgroundColorList[9] =  'DC8B67';
        backgroundColorList[10] =  '6F7180';
        backgroundColorList[11] =  '00CA96';
        backgroundColorList[12] =  'C8B5AF';
        backgroundColorList[13] =  'EAE799';
        backgroundColorList[14] =  '02BC67';
        backgroundColorList[15] =  '6E6A76';
    }


    function setBackgroundColorName() private onlyOwner {
        backgroundColorIdTobackgroundColorName[0] =  'Motoko-2';
        backgroundColorIdTobackgroundColorName[1] =  'Motoko-4';
        backgroundColorIdTobackgroundColorName[2] =  'Motoko-5';
        backgroundColorIdTobackgroundColorName[3] =  'Batou-2';
        backgroundColorIdTobackgroundColorName[4] =  'Togusa-2';
        backgroundColorIdTobackgroundColorName[5] =  'Tachikoma-1';
        backgroundColorIdTobackgroundColorName[6] =  'Tachikoma-2';
        backgroundColorIdTobackgroundColorName[7] =  'Aramaki-2';
        backgroundColorIdTobackgroundColorName[8] =  'Ishikawa-2';
        backgroundColorIdTobackgroundColorName[9] =  'Borma-2';
        backgroundColorIdTobackgroundColorName[10] =  'Saito-2';
        backgroundColorIdTobackgroundColorName[11] =  'Saito-3';
        backgroundColorIdTobackgroundColorName[12] =  'Paz-2';
        backgroundColorIdTobackgroundColorName[13] =  'Book-2';
        backgroundColorIdTobackgroundColorName[14] =  'DiveRoom';
        backgroundColorIdTobackgroundColorName[15] =  'Section9-2';
    }

    

    function setTextTypeName() private onlyOwner {
        textTypeToTextTypeName[0] = 'English';
        textTypeToTextTypeName[1] = 'Japanese';
        textTypeToTextTypeName[2] = 'MojiBug';
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


     function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory svgText;
        string memory attributesText;

        uint256 textType = tokenIdToTokenMetadata[_tokenId].textType;
        uint256 textId = tokenIdToTokenMetadata[_tokenId].textId;
        uint256 colorId = tokenIdToTokenMetadata[_tokenId].colorId;
        uint256 backgroundColorId = tokenIdToTokenMetadata[_tokenId].backgroundColorId;
        if (textType==0){
            svgText = textListNormal[textId];
            attributesText = textListNormalForAttributes[textId];
        }else if(textType==1){
            svgText = textListJapanese[textId];
            attributesText = textListJapaneseForAttributes[textId];
        }else{
            svgText = textBug;
            attributesText = textBugForAttributes;
        }
        string memory svg = getSVG(svgText, colorList[colorId],backgroundColorList[backgroundColorId]);
        bytes memory json = abi.encodePacked(abi.encodePacked(
            '{"name": "',
            tokenName,
            '", "description": "',
            description,
            '",', 
            '"attributes":[{"trait_type":"LAUGHINGMAN", "value": "',
            colorIdToColorName[colorId],
            '"},{"trait_type":"BACKGROUND", "value":"',
            backgroundColorIdTobackgroundColorName[backgroundColorId],
            '"},{"trait_type":"FAMOUSQUOTE", "value":"'
            
        ),abi.encodePacked(attributesText,
            '"},{"trait_type":"LANGUAGE", "value":"',
            textTypeToTextTypeName[textType],
            '"},{"trait_type":"TRANSLATION", "value":"',
            textListNormalForAttributes[textId],
            '"}],',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}')
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
    function getSVG(string memory _text,string memory _colorText,string memory _backgroundTextColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg id="master-artboard" viewBox="0 0 1400 980" version="1.1" xmlns="http://www.w3.org/2000/svg" x="0" y="0" style="enable-background:new 0 0 1400 980" width="1400" height="980" xmlns:xlink="http://www.w3.org/1999/xlink"><path id="ee-background" style="fill:#fff;fill-opacity:0;pointer-events:none" d="M0 0h1400v980H0z"/><defs><style id="ee-google-fonts">.filler{fill:#',
                    _colorText,
                    '}.stroker{stroke:#',
                    _colorText,
                    '}@import url(https://fonts.googleapis.com/css?family=Fjalla+One:400|Roboto:100,100italic,300,300italic,400,400italic,500,500italic,700,700italic,900,900italic);</style></defs><g/><g transform="matrix(1.96 0 0 1.96 214.164 .558)"><path d="M0 0h500v500H0V0Z" class="cls-4" transform="rotate(90 250.12 250.12)" style="fill:#',
                    _backgroundTextColor,
                    ';fill-opacity:1" id="background"/><path class="stroker" d="M50 250C50 96.04 216.667-.185 350 76.795 411.88 112.52 450 178.547 450 250c0 153.96-166.667 250.185-300 173.205C88.12 387.48 50 321.453 50 250" stroke-width="10" fill="#FFF" style="fill-opacity:1;stroke-width:12" transform="matrix(.98619 0 0 .98085 3.454 4.788)"/><path id="tlms" d="M85 250c0-127.017 137.5-206.403 247.5-142.894C383.551 136.58 415 191.05 415 250c0 127.017-137.5 206.403-247.5 142.894C116.449 363.42 85 308.95 85 250" stroke="transparent" fill="#FFF" style="fill-opacity:1"/><animateTransform attributeName="transform" type="rotate" from="0 250 250" to="-360 250 250" dur="10s" repeatCount="indefinite" xlink:href="#tlms"/><path class="stroker" d="M110 250c0-107.772 116.667-175.13 210-121.244 43.316 25.009 70 71.227 70 121.244 0 107.772-116.667 175.13-210 121.244-43.316-25.009-70-71.227-70-121.244" stroke-width="20" fill="#FFF" style="stroke-width:23;fill-opacity:1" transform="translate(4.7 5.21) scale(.98038)"/><path class="filler" d="M147 279a104.907 104.907 0 0 0 49.17 71.33c15.76 9.52 34.2 14.98 53.85 14.98s38.08-5.46 53.85-14.98c25.44-15.45 43.7-41.05 49.17-71.33H138.91 147Zm156.86 44.48c-14.52 12.49-33.25 20-53.85 20s-39.33-7.49-53.85-20c-7.49-6.24-13.74-13.89-18.42-22.48h144.53c-4.68 8.58-11.08 16.23-18.42 22.48h.01Z" style="fill-opacity:1" transform="translate(-5.067 -16.232) scale(1.01855)"/><text class="filler" font-size="30" font-weight="bold" font-family="Impact" style="font-size:30px;font-weight:700;font-family:Impact;white-space:pre;fill-opacity:1" transform="matrix(.957 0 0 .957 9.58 8.932)"><textPath style="fill-opacity:1" xlink:href="#tlms">',
                    _text,
                    ' </textPath></text></g><g transform="matrix(6.78306 0 0 .44565 38.907 388.43)"><g id="g-9"><path class="filler" d="M58 49h100v100H58V49z"  id="g-10"/></g></g><g transform="translate(56.168 335.413) scale(1.60923)"><g id="g-3" transform="translate(-3.497)"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z"  id="g-4"/></g></g><g transform="matrix(1.65263 0 0 .71434 838.123 419.821)"><g id="g-1"><path class="st0" d="M58 49h100v100H58V49z" style="fill:#fff" transform="translate(2.614)" id="g-2"/></g></g><g transform="matrix(.37601 0 0 .42555 960.479 506.376)"><g id="g-15"><path class="filler" d="M58 49h100v100H58V49z" style="stroke:#000;stroke-width:0" transform="matrix(3.41126 0 0 1.02518 -139.853 -3.705)" id="g-16"/></g></g><path d="M99 240h22v10H99v-10Z" stroke="transparent" fill="#FFF" transform="matrix(2.28176 0 0 1.65915 184.97 56.594)" style="fill-opacity:1"/><path class="filler stroker" d="M541.605 513.229s3.957-49.543 52.256-50.157c48.3-.614 52.89 50.973 52.89 50.973s-17.017-22.225-52.425-22.728c-29.803-.423-52.846 21.86-52.72 21.912Z" style="fill-opacity:1;stroke-opacity:0;stroke-width:20;paint-order:fill" transform="translate(214.56 1.517)"/><path class="filler stroker" d="M541.605 513.229s3.957-49.543 52.256-50.157c48.3-.614 52.89 50.973 52.89 50.973s-17.017-22.225-52.425-22.728c-29.803-.423-52.846 21.86-52.72 21.912Z" style="fill-opacity:1;stroke-opacity:0;stroke-width:20;paint-order:fill" transform="translate(.636 1.517)"/><g transform="translate(627.316 183.456) scale(.13313)"><g id="g-5"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z"  id="g-6"/></g></g><g transform="translate(604.46 183.456) scale(.13313)"><g id="g-11"><path class="filler" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z" id="g-12"/></g></g><g transform="matrix(.24113 0 0 .13447 676.94 182.992)"><g id="Layer_2_4_"><path class="filler" d="M58 49h100v100H58V49z" id="Layer_1-2_4_"/></g></g><g transform="matrix(.36113 0 0 .13387 663.66 189.562)"><g id="g-17"><path class="filler" d="M58 49h100v100H58V49z" id="g-18"/></g></g><g transform="translate(635.188 422.09) scale(.7138)"><g id="g-19" transform="translate(3.034 -.268)"><path class="st0" d="M652 46c27.6 0 50 22.4 50 50s-22.4 50-50 50-50-22.4-50-50 22.4-50 50-50z" style="fill:#fff" id="g-20"/></g></g></svg>'
                )
            );
        
    }
}

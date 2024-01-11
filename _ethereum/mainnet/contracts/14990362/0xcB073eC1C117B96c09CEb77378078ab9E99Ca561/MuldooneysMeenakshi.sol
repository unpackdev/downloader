// SPDX-License-Identifier: MIT  

//       ___           ___                        _____          ___           ___           ___           ___                       ___     
//      /__/\         /__/\                      /  /::\        /  /\         /  /\         /__/\         /  /\          ___        /  /\    
//     |  |::\        \  \:\                    /  /:/\:\      /  /::\       /  /::\        \  \:\       /  /:/_        /__/|      /  /:/_   
//     |  |:|:\        \  \:\    ___     ___   /  /:/  \:\    /  /:/\:\     /  /:/\:\        \  \:\     /  /:/ /\      |  |:|     /  /:/ /\  
//   __|__|:|\:\   ___  \  \:\  /__/\   /  /\ /__/:/ \__\:|  /  /:/  \:\   /  /:/  \:\   _____\__\:\   /  /:/ /:/_     |  |:|    /  /:/ /::\ 
//  /__/::::| \:\ /__/\  \__\:\ \  \:\ /  /:/ \  \:\ /  /:/ /__/:/ \__\:\ /__/:/ \__\:\ /__/::::::::\ /__/:/ /:/ /\  __|__|:|   /__/:/ /:/\:\
//  \  \:\~~\__\/ \  \:\ /  /:/  \  \:\  /:/   \  \:\  /:/  \  \:\ /  /:/ \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\/:/ /:/ /__/::::\   \  \:\/:/~/:/
//   \  \:\        \  \:\  /:/    \  \:\/:/     \  \:\/:/    \  \:\  /:/   \  \:\  /:/   \  \:\  ~~~   \  \::/ /:/     ~\~~\:\   \  \::/ /:/ 
//    \  \:\        \  \:\/:/      \  \::/       \  \::/      \  \:\/:/     \  \:\/:/     \  \:\        \  \:\/:/        \  \:\   \__\/ /:/  
//     \  \:\        \  \::/        \__\/         \__\/        \  \::/       \  \::/       \  \:\        \  \::/          \__\/     /__/:/   
//      \__\/         \__\/                                     \__\/         \__\/         \__\/         \__\/                     \__\/    

// RIGHTS OF USE: Permission to resell Muldooneys NFT. However no rights applied for reproduction, adaption of the NFT or usage of the Muldooneys IP

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";

contract MuldooneysMeenakshi is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Data) public DatasToTokenId;
    uint256 public maxSupply = 600;

    struct Data {
        string name;
        string description;
        string image;
        string animationUrl;
        string externalUrl;
        string variant;
        string dates;
    }

    constructor() ERC721("Muldooneys - Meenakshi", "M01") {}

    function mint(string memory variant, string memory imageUrl, string memory animationUrl, string memory dates) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();

        require(
            tokenId + 1 <= maxSupply, 
            "Season sold out"
        );
        require(
            keccak256(bytes(variant)) == keccak256(bytes("Paparadscha")) || keccak256(bytes(variant)) == keccak256(bytes("Canard")) || keccak256(bytes(variant)) == keccak256(bytes("Indian Tan")),
            "Variant needs to be one of: 'Paparadscha, Canard, Indian Tan'"
        );

        Data memory newData = Data(
            string(abi.encodePacked("Muldooneys - Meenakshi #", uint256(tokenId + 1).toString())),
            "**DESIGNING THE LUXURY OF TOMORROW. We are raising the bar in being the first luxury leathergoods brand in our category, to marry physical designs with its minted NFT twin.**\\n\\nThe goal to showcase not only provenance, but also to eulogise the prestige of French savoir-faire, with its precious **Made in France** label, whilst importantly gifting our six hundred customers with a rare, precious and unique NFT collectible, with high resale investment value.\\n\\nOur exquisite haut de gamme, designs are made to order at our atelier Maison Hamon in Paris. Every design, using precious raw materials, which have been meticulously sourced for nearly 90% on French soil whilst honouring the rich craft of knowledge, skill and human ingenuity of French savoir-faire craftmanship. Breaking through luxury convention, our consumers are at the heart and soul of our avant-garde supply chain. In real time, they have private access to our atelier, validating provenance, whilst witnessing the supreme artistry of French craftsmanship, and the human hands which craft each luxurious element of a Muldooneys design.\\n\\n**Muldooneys (2005)**\\n\\nLuxury Leathergoods brand Muldooneys was founded in 2005 by Marlene P. Naicker (1975). A brand synonymous with taking an indifferent approach to luxury, and now after a near decade long hiatus, relaunching in Paris, France, marrying technology and French savoir-faire. Each high-tech Muldooneys design has its own unique digital footprint with an embedded serialized hologram key, which is activated when paired with its digital NFT, thus securely preserving Muldooneys iconic individuality. Headed by founder and CEO Marlene, managing partner and CTO Tim; Katherine and David.\\n\\n**Maison Hamon (1919)**\\n\\nWorking with Maison Hamon, as part of special projects managed by Alice Doremus and Patrick Faure, they have left no stone unturned in finding the best suppliers of raw materials in France and turning the Meenakshi into a sublime rare collectible item, for posterity.\\n\\n**Pledge**\\n\\nPart of the royalties derived from the Meenakshi series will be given to the Meenakshi Amman Temple, and the arts and culture centre of the Thirumalai Nayakkar Palace in Madurai, India.\\n\\n**MULDOONEYS MEENAKSHI POTLI BAG**\\n\\nProvenance: Paris, France June 2022",
            imageUrl,
            animationUrl,
            "https://www.muldooneys.com",
            variant,
            dates
        );

        _tokenIdCounter.increment();
        DatasToTokenId[tokenId + 1] = newData;
        _safeMint(msg.sender, tokenId + 1);
    }

    function getStrassGemstones(string memory variant) internal pure virtual returns (string memory) {
        if(keccak256(bytes(variant)) == keccak256(bytes("Paparadscha"))) {
            return  string("Paparadscha, Ruby, Fuscia, Blush, Rose Pink");   
        }
        if(keccak256(bytes(variant)) == keccak256(bytes("Canard"))) {
            return  string("Montana, Capri Blue, Indicolite");   
        }
        if(keccak256(bytes(variant)) == keccak256(bytes("Indian Tan"))) {
            return  string("Topaz, Smoke Topaz, Light Rose Gold Quartz");          
        }
        return string('');
    }

    function buildMetadata(uint256 _tokenId) private view returns (string memory) {
        Data memory currentData = DatasToTokenId[_tokenId];
        string[9] memory details;
        string[13] memory suppliers;

        details[0] = '{"trait_type": "Series","display_type": "number","value":"1", "max_value": "8"},';
        details[1] = string(abi.encodePacked('{"trait_type": "01 ORDER COMPLETE","display_type": "date","value": "', getSlice(1,10,currentData.dates), '"},'));
        details[2] = string(abi.encodePacked('{"trait_type": "02 APPROVISIONNEMENT/MEENAKSHI RAW MATERIALS","display_type": "date","value": "', getSlice(11,20,currentData.dates), '"},'));
        details[3] = string(abi.encodePacked('{"trait_type": "03 LA COUPE/CUTTING","display_type": "date","value": "', getSlice(21,30,currentData.dates), '"},'));
        details[4] = string(abi.encodePacked('{"trait_type": "04 LA PREPARATION/PREPARATION","display_type": "date","value": "', getSlice(31,40,currentData.dates), '"},'));
        details[5] = string(abi.encodePacked('{"trait_type": "05 LA COUTURE/ASSEMBLAGE","display_type": "date","value": "', getSlice(41,50,currentData.dates), '"},'));
        details[6] = string(abi.encodePacked('{"trait_type": "06 FINITON/FINISHINGS","display_type": "date","value": "', getSlice(51,60,currentData.dates), '"},'));
        details[7] = string(abi.encodePacked('{"trait_type": "07 CONTROLE/QUALITY CONTROL","display_type": "date","value": "', getSlice(61,70,currentData.dates), '"},'));
        details[8] = string(abi.encodePacked('{"trait_type": "08 PACKAGING/EXPEDITION","display_type": "date","value": "', getSlice(71,80,currentData.dates), '"},'));

        suppliers[0] = string(abi.encodePacked('{"trait_type": "LEATHER", "value": "TANNERIE HAAS (1842) / Alsace, France / Color - ', currentData.variant, ' / Awards EPV - L\x27excellence des savoir-faire francais"},'));
        suppliers[1] = string(abi.encodePacked('{"trait_type": "CUSTOMISED HARDWARE", "value": "FIRST / Yonne, France / Goldplated Muldooneys nameplate, handle dee-rings, holo-plate & zipper puller"},'));
        suppliers[2] = string(abi.encodePacked('{"trait_type": "SUN & MOON BIJOU", "value": "MAISON HAMON (1919) / Paris, France /  Awards EPV - L\x27excellence des savoir-faire francais"},'));
        suppliers[3] = string(abi.encodePacked('{"trait_type": "HOLOGRAM", "value": "3D AG (1989) / Baar, Switzerland / Customised serial digital keys"},'));
        suppliers[4] = string(abi.encodePacked('{"trait_type": "FABRIC LINING #1", "value": "BERTO (1887) / Veneto, Italy / Cotton"},'));
        suppliers[5] = string(abi.encodePacked('{"trait_type": "FABRIC LINING #2", "value": "DENIS & FILS (1956) / Paris, France / Grosgrain Cotton 100%"},'));
        suppliers[6] = string(abi.encodePacked('{"trait_type": "FABRIC TINT", "value": "BLEU OCEANE (1973) / Beauvoir-sur-Mer, France / GOTS Certification"},'));
        suppliers[7] = string(abi.encodePacked('{"trait_type": "HAND-EMBROIDERED FABRIC / TISSU FLOWERS", "value": "TESSITURA ATTILIO IMPERIALI (1900) / Como, Italy / Duchess Satin Cellulose Acetate"},'));
        suppliers[8] = string(abi.encodePacked('{"trait_type": "COTTON", "value": "SERAFIL AMANN (1854) / La Chapelle d\x27Armentieres, France / Silk Thread ', currentData.variant, '"},'));
        suppliers[9] = string(abi.encodePacked('{"trait_type": "STRASS GEMSTONES", "value": "SWAROVSKI (1883) / Wattens, Austria / Hotfix Rhinestones ', getStrassGemstones(currentData.variant), '"},'));
        suppliers[10] = string(abi.encodePacked('{"trait_type": "ROSE PINS/GRIFFES", "value": "SWAROVSKI (1883) / Wattens, Austria"},'));
        suppliers[11] = string(abi.encodePacked('{"trait_type": "ATELIER MAROQUNERIE", "value": "MAISON HAMON (1919) / Paris, France / Awards EPV - L\x27excellence des savoir-faire francais"},'));
        suppliers[12] = string(abi.encodePacked('{"trait_type": "PACKAGING", "value": "GAINERIE 91 (1967) / Montgeron, France / Branded Muldooneys Packaging"}'));

        string memory output = string(abi.encodePacked(details[0], details[1], details[2], details[3], details[4], details[5], details[6], details[7], details[8]));
        string memory output2 = string(abi.encodePacked(output, suppliers[0], suppliers[1], suppliers[2], suppliers[3], suppliers[4], suppliers[5], suppliers[6]));
        string memory output3 = string(abi.encodePacked(output2, suppliers[7], suppliers[8], suppliers[9], suppliers[10], suppliers[11], suppliers[12]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"', currentData.name,'","external_url":"', currentData.externalUrl,'","description":"', currentData.description,'","image":"', currentData.image,'","animation_url":"', currentData.animationUrl,'", "attributes": [', output3, ']}'))));

        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure virtual returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }
}
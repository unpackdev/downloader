// contracts/NuCLK-G.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

contract NuclkGenesis is ERC721Enumerable, Ownable {
    uint public MAX_CLK = 250;
    bool public PAUSED = true;

    uint256 private _price = 0.07 ether;
    mapping(uint256 => bool) private _logo;
    mapping(uint256 => uint256) private _jewel;

    constructor() ERC721(unicode"NüCLK Génesis", "NUCLK001") {}

    function mint() public payable {
        require(!PAUSED,                 "Sale paused");
        require(totalSupply() < MAX_CLK, "Sale has already ended");
        require(msg.value >= _price,     "Ether sent is not correct");

        uint256 id = totalSupply();

        _logo[id] = prng(block.difficulty) % 3 == 2;
        _jewel[id] = prng(block.timestamp) % 6;

        _safeMint(msg.sender, id);
    }

    function pause() public onlyOwner {
        PAUSED = !PAUSED;
    }

    function withdraw() public payable onlyOwner {
        require(payable(0xed8D89B01cB469B75a9a18bd4680f0b4c4224a4d).send(address(this).balance));
    }

    function CLK(uint256 tokenId) private view returns (bytes memory) {

        bytes memory r = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"');
        
        if (_jewel[tokenId] != 5) {
            r = abi.encodePacked(r, ' style="background-color:#EFCEA3"');
        }

        if (_jewel[tokenId] == 1) {
            r = abi.encodePacked(r, '><style><![CDATA[.B{stroke:#eff3f9}.C{stroke-linecap:round}.D{stroke-width:2}.E{fill:#1FDBCC');
        } else if (_jewel[tokenId] == 2 || _jewel[tokenId] == 3) {
            r = abi.encodePacked(r, '><style><![CDATA[.B{stroke:#eff3f9}.C{stroke-linecap:round}.D{stroke-width:2}.E{fill:#1A90FF');
        } else {
            r = abi.encodePacked(r, '><style><![CDATA[.B{stroke:#eff3f9}.C{stroke-linecap:round}.D{stroke-width:2}.E{fill:#E94E77');
        }

        r = abi.encodePacked(r, '}]]></style><defs><linearGradient id="A" gradientTransform="rotate(90)"><stop offset="50%" stop-color="#171f25"/><stop offset="50%" stop-color="#efcea3"/></linearGradient></defs><circle r="146" cx="150" cy="150" fill="');
        
        if (_jewel[tokenId] == 5) {
            r = abi.encodePacked(r, '#171f25');
        } else {
            r = abi.encodePacked(r, '#c9a87f');
        }
        
        r = abi.encodePacked(r, '"/><circle r="137" cx="150" cy="150" fill="#c49362"/><g fill="#0f253a"><circle r="136" cx="150" cy="150"/><g class="B"><circle r="133" cx="150" cy="150" stroke-dasharray="6.964" stroke-dashoffset="3.482" class="D"/><circle r="118" cx="150" cy="150" stroke-width="22" stroke-dasharray="30.892" stroke-dashoffset="15.446"/></g></g><g fill="#171f25" stroke-width="1.5" class="B"><circle r="26" cx="150" cy="210" stroke-dasharray="1.361" stroke-dashoffset="0.681"/><circle r="26" cx="150" cy="90" stroke-dasharray="0.817" stroke-dashoffset="0.408"/></g><g><path id="milli" d="M150 84v29" class="B C D"/><animateTransform attributeName="transform" type="rotate" from="0 150 90" to="360 150 90" dur="1s" repeatCount="indefinite"/></g><g><path id="sec" d="M150 216v-29" class="B C D"/><animateTransform attributeName="transform" type="rotate" from="0 150 210" to="360 150 210" dur="60s" repeatCount="indefinite"/></g><circle r="2.5" cx="150" cy="90" fill="#eff3f9"/><circle r="2.5" cx="150" cy="210" fill="#eff3f9"/><circle r="1" cx="150" cy="90" class="E"/><circle r="1" cx="150" cy="210" class="E"/><g stroke-width=".4"');

        if (_logo[tokenId]) {
            r = abi.encodePacked(r, ' transform="scale(-1,1) translate(-300, 0)"');
        }

        return abi.encodePacked(r, '><rect x="55" y="137" width="190" height="26" fill="url(#A)" rx="5"/><path fill="#efcea3" stroke="#efcea3" d="M64.85 141.4h0q.07 0 .11.04.04.05.04.11h0v5.27q0 .09-.05.14-.05.04-.12.04h0q-.03 0-.07-.02-.03-.01-.06-.04h0l-3.71-5.08.11-.05v5.05q0 .06-.04.1-.04.04-.11.04h0q-.07 0-.11-.04-.04-.04-.04-.1h0v-5.3q0-.09.05-.12.05-.04.09-.04h0q.04 0 .07.01.03.01.05.05h0l3.7 5.04-.06.16v-5.11q0-.06.04-.11.05-.04.11-.04zm4.63 1.61h0q.07 0 .12.05.04.04.04.11h0v2.33q0 .77-.44 1.16-.43.39-1.15.39h0q-.71 0-1.15-.39-.44-.39-.44-1.16h0v-2.33q0-.07.05-.11.05-.05.11-.05h0q.08 0 .12.05.04.04.04.11h0v2.33q0 .6.34.92.34.32.93.32h0q.59 0 .93-.32.34-.32.34-.92h0v-2.33q0-.07.04-.11.05-.05.12-.05zm-.77-.8h0q-.13 0-.2-.08-.08-.08-.08-.21h0v-.06q0-.13.08-.21.08-.08.21-.08h0q.11 0 .19.08.07.08.07.21h0v.06q0 .13-.07.21-.08.08-.2.08zm-1.3 0h0q-.13 0-.21-.08-.07-.08-.07-.21h0v-.06q0-.13.08-.21.08-.08.21-.08h0q.11 0 .18.08.08.08.08.21h0v.06q0 .13-.08.21-.07.08-.19.08z"/><path fill="#171f25" stroke="#171f25" d="M235.06 153.86h0q-.07.05-.08.11 0 .06.04.13h0q.04.05.1.06.06 0 .11-.03h0q.34-.23.73-.37.4-.14.85-.14h0q.51 0 .95.19.45.19.78.53.34.35.53.82.19.47.19 1.04h0q0 .57-.19 1.04-.19.47-.53.82-.33.34-.78.53-.44.19-.95.19h0q-.45 0-.84-.14-.39-.14-.73-.36h0q-.06-.04-.12-.03-.06.01-.1.06h0q-.04.06-.04.12.01.07.07.11h0q.19.13.48.26.29.13.62.2.33.08.66.08h0q.57 0 1.08-.22.5-.21.89-.6.38-.39.6-.91.22-.53.22-1.15h0q0-.62-.22-1.15-.22-.52-.6-.91-.39-.39-.89-.6-.51-.22-1.08-.22h0q-.49 0-.94.14-.45.15-.81.4zm-1.38-.62v5.6q0 .06.05.11.05.05.11.05h0q.07 0 .12-.05.04-.05.04-.11h0v-5.6q0-.06-.05-.11-.05-.05-.11-.05h0q-.07 0-.12.05-.04.05-.04.11h0zm-1.57 5.76h0q.07 0 .12-.05.04-.05.04-.11h0v-5.6q0-.06-.04-.11-.05-.05-.12-.05h0q-.07 0-.11.05-.05.05-.05.11h0v5.6q0 .06.05.11.04.05.11.05zm-2.77-4.04h0q-.07 0-.12.05-.04.05-.04.12h0q0 .07.05.12h0l2.78 2.31.01-.38-2.58-2.17q-.05-.05-.1-.05zm-.05 4.04h0q.06 0 .12-.06h0l1.93-2.06-.24-.21-1.92 2.05q-.05.05-.05.12h0q0 .08.06.12.07.04.1.04z"/></g><g><path id="min" stroke="#fff" stroke-width="3" d="M150 164V21" class="C"/><animateTransform attributeName="transform" type="rotate" from="0 150 150" to="360 150 150" dur="1h" repeatCount="indefinite"/></g><g><path id="hr" stroke="#fff" stroke-width="5" d="M150 167V52" class="C"/><animateTransform attributeName="transform" type="rotate" from="0 150 150" to="360 150 150" dur="12h" repeatCount="indefinite"/></g><circle r="10" cx="150" cy="150" fill="#fff"/><circle r="7" cx="150" cy="150" class="E"/><script type="text/javascript"><![CDATA[const e=new Date();var n=e.getMilliseconds(),o=e.getSeconds()+n/1e3,r=e.getMinutes()+o/60,s=e.getHours()+r/60;document.getElementById("milli").setAttribute("transform","rotate("+n/1e3*360+" 150 90)"),document.getElementById("sec").setAttribute("transform","rotate("+o/60*360+" 150 210)"),document.getElementById("min").setAttribute("transform","rotate("+r/60*360+" 150 150)"),document.getElementById("hr").setAttribute("transform","rotate("+s/12*360+" 150 150)");]]></script></svg>');
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");


        bytes memory json = abi.encodePacked(
            unicode'{"name":"NüCLK Génesis #', Strings.toString(tokenId),
            unicode'","description":"Clocks for the Metaverse","image":"data:image/svg+xml;base64,',
            Base64.encode(CLK(tokenId)), '", "attributes":[{"trait_type":"Logo","value":"');

        if (_logo[tokenId]) {
            json = abi.encodePacked(json, 'Invertido"}, {"trait_type":"Jewels","value":"');
        } else {
            json = abi.encodePacked(json, 'Normal"}, {"trait_type":"Jewels","value":"');
        }

        if (_jewel[tokenId] == 1) {
            json = abi.encodePacked(json, 'Diamante"}]}');
        } else if (_jewel[tokenId] == 2 || _jewel[tokenId] == 3) {
            json = abi.encodePacked(json, 'Zafiro"}]}');
        } else if (_jewel[tokenId] == 5) {
            json = abi.encodePacked(json, unicode'Rubí"}, {"trait_type": "Background", "value": "Transparente"}]}');
        } else {
            json = abi.encodePacked(json, unicode'Rubí"}]}');
        }

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }

    // LuckySeven - @matiasbn_eth
    function prng(uint mu) internal pure returns (uint O) {
        assembly {
            let L := exp(10, 250) // 10^p
            let U := mul(L, 1) // 10^p * b
            let C := exp(10, 10) // 10^n
            let K := sub(C, mu) // 10^n - mu
            let Y := div(U, K) // (10^p * b)/(10^n - mu)
            let S := exp(10, add(2, 3)) // 10^(i+j)
            let E := exp(10, 2) // 10^i
            let V := mod(Y, S) // Y % 10^(i+j)
            let N := mod(Y, E) // Y % 10^i
            let I := sub(V, N) // (Y % 10^(i+j)) / (Y % 10^i)
            O := div(I, E)
        }
    }
}

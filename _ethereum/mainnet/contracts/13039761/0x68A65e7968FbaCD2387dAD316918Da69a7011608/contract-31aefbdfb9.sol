// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";

contract DVDLogo is ERC721 {
    constructor() ERC721("DVDLogo", "DVD") {
        _mint(msg.sender, 1);
    }

    string constant imgx = "data:application/json;charset=UTF-8,%7B%22name%22%3A%20%22DVD%20Logo%22%2C%22description%22%3A%20%22Bouncing%20DVD%20logo.%20A%20new%20frame%20is%20rendered%20per%20block%2C%20and%20every%20250%20blocks%20a%20new%20animation%20starts%20at%20a%20random%20position.%22%2C%22image%22%3A%20%22data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%20width%3D'800px'%20height%3D'600px'%20viewBox%3D'0%200%2040%2030'%20style%3D'background-color%3Ablack'%3E%3Csvg%20id%3D'dvd'%20width%3D'9'%20height%3D'6'%20viewBox%3D'0%200%20210%20107'%20x%3D'";
    string constant imgy = "'%20y%3D'";
    string constant imgc = "'%20fill%3D'%23";
    string constant imgend = "'%3E%3Cpath%20d%3D'M118.895%2C20.346c0%2C0-13.743%2C16.922-13.04%2C18.001c0.975-1.079-4.934-18.186-4.934-18.186s-1.233-3.597-5.102-15.387H81.81H47.812H22.175l-2.56%2C11.068h19.299h4.579c12.415%2C0%2C19.995%2C5.132%2C17.878%2C14.225c-2.287%2C9.901-13.123%2C14.128-24.665%2C14.128H32.39l5.552-24.208H18.647l-8.192%2C35.368h27.398c20.612%2C0%2C40.166-11.067%2C43.692-25.288c0.617-2.614%2C0.53-9.185-1.054-13.053c0-0.093-0.091-0.271-0.178-0.537c-0.087-0.093-0.178-0.722%2C0.178-0.814c0.172-0.092%2C0.525%2C0.271%2C0.525%2C0.358c0%2C0%2C0.179%2C0.456%2C0.351%2C0.813l17.44%2C50.315l44.404-51.216l18.761-0.092h4.579c12.424%2C0%2C20.09%2C5.132%2C17.969%2C14.225c-2.29%2C9.901-13.205%2C14.128-24.75%2C14.128h-4.405L161%2C19.987h-19.287l-8.198%2C35.368h27.398c20.611%2C0%2C40.343-11.067%2C43.604-25.288c3.347-14.225-11.101-25.293-31.89-25.293h-18.143h-22.727C120.923%2C17.823%2C118.895%2C20.346%2C118.895%2C20.346L118.895%2C20.346z'%2F%3E%3Cpath%20d%3D'M99.424%2C67.329C47.281%2C67.329%2C5%2C73.449%2C5%2C81.012c0%2C7.558%2C42.281%2C13.678%2C94.424%2C13.678c52.239%2C0%2C94.524-6.12%2C94.524-13.678C193.949%2C73.449%2C151.664%2C67.329%2C99.424%2C67.329z%20M96.078%2C85.873c-11.98%2C0-21.58-2.072-21.58-4.595c0-2.523%2C9.599-4.59%2C21.58-4.59c11.888%2C0%2C21.498%2C2.066%2C21.498%2C4.59C117.576%2C83.801%2C107.966%2C85.873%2C96.078%2C85.873z'%2F%3E%3Cpolygon%20points%3D'182.843%2C94.635%20182.843%2C93.653%20177.098%2C93.653%20176.859%2C94.635%20179.251%2C94.635%20178.286%2C102.226%20179.49%2C102.226%20180.445%2C94.635%20182.843%2C94.635'%2F%3E%3Cpolygon%20points%3D'191.453%2C102.226%20191.453%2C93.653%20190.504%2C93.653%20187.384%2C99.534%20185.968%2C93.653%20185.013%2C93.653%20182.36%2C102.226%20183.337%2C102.226%20185.475%2C95.617%20186.917%2C102.226%20190.276%2C95.617%20190.504%2C102.226%20191.453%2C102.226'%2F%3E%3C%2Fsvg%3E%3C%2Fsvg%3E%22%7D";

    uint constant cc = 8;
    uint constant ww = 40-9;
    uint constant hh = 30-6;
    uint constant loop = 250;
    
    function tokenURI(uint256)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        (uint x, uint y, uint ci) = getVals();
        
        string[8] memory colors = ['be00ff','00feff','ff8300','0026ff','fffa01','ff2600','ff008b','25ff01'];
        string memory color = colors[ci];
        return string(abi.encodePacked(imgx, itoa(x), imgy, itoa(y), imgc, color, imgend));
    }
    
    function getVals() public view returns (uint x, uint y, uint ci) {
      uint b = block.number % loop;
      uint r = uint(blockhash(block.number - (block.number % loop) - 1));
      uint x0 = r % ww;
      uint y0 = r % hh;
      
      x = (x0 + b) % (2 * ww);
      x = x > ww ? (2*ww) - x : x;
      
      y = (y0 + b) % (2*hh);
      y = y > hh ? (2*hh) - y : y;
      
      uint cx = (x0 + b) / ww;
      uint cy = (y0 + b) / hh;
      ci = (cx + cy) % cc;
    }

    function itoa(uint n) internal pure returns (string memory) {
        if (n == 0) {
            return "0";
        }
        bytes memory reversed = new bytes(100);
        uint len = 0;
        while (n != 0) {
            uint r = n % 10;
            n = n / 10;
            reversed[len++] = bytes1(uint8(48 + r));
        }
        bytes memory buf = new bytes(len);
        for (uint i= 0; i < len; i++) {
            buf[i] = reversed[len - i - 1];
        }
        return string(buf);
    }
}

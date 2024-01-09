// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
  _____                                    ______ _______ _    _ 
 |  __ \                                  |  ____|__   __| |  | |
 | |__) |___  ___  ___ _ ____   _____ _ __| |__     | |  | |__| |
 |  _  // _ \/ __|/ _ \ '__\ \ / / _ \ '__|  __|    | |  |  __  |
 | | \ \  __/\__ \  __/ |   \ V /  __/ |_ | |____   | |  | |  | |
 |_|  \_\___||___/\___|_|    \_/ \___|_(_)|______|  |_|  |_|  |_|

    https://reserver.eth
    https://discord.gg/reservereth

    Disclaimer:
    By interacting with this smart contract, you represent and 
    warrant that your use does not violate any law, rule or regulation 
    in your jurisdiction of residence.

*/

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

library Art {

    function gen2(uint256 _tokenId) public pure returns (string[11] memory) {
        string[11] memory p;
        p[0] = '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1908 2546.9" style="enable-background:new 0 0 1908 2546.9;" xml:space="preserve"><style type="text/css">.wave-1{opacity:0.65;fill:';
        p[1] = liquid(_tokenId);
        p[2] = ';fill-opacity:0.65;enable-background:new;}</style>';
        p[3] = 'd="M964.1,0l-16.8,57v1652.7l16.8,16.7l767.2-453.5L964.1,0z"/>';
        p[4] = 'd="M964.1,0L196.9,1272.9l767.2,453.5V0z"/>';
        p[5] = 'd="M964.1,1871.6l-9.4,11.5v588.7l9.4,27.6l767.6-1081L964.1,1871.6z"/>';
        p[6] = 'd="M964.1,2499.4v-627.8l-767.2-453.2L964.1,2499.4z"/>';
        p[7] = 'd="M964.1,1726.4l767.1-453.5L964.1,924.2V1726.4z"/>';
        p[8] = 'd="M196.9,1272.9l767.2,453.5V924.2L196.9,1272.9z"/>';
        p[9] = '<g><defs><path id="SVGID_1_" d="M196.9,1272.9L964.1,0l0,0l0,0l0,0v0l767.1,1272.9l0,0l0,0l0,0l-767.2,453.5l-0.1-0.1L196.9,1272.9z M964.1,2499.4l767.6-1081l-767.6,453.2v0l-767.2-453.2L964.1,2499.4L964.1,2499.4L964.1,2499.4L964.1,2499.4L964.1,2499.4z"/></defs><clipPath id="SVGID_00000105410603237165858250000008469157625393990569_"><use xlink:href="#SVGID_1_"  style="overflow:visible;"/></clipPath><g style="clip-path:url(#SVGID_00000105410603237165858250000008469157625393990569_);"><g transform="translate(-36 ';
        p[10] = ')"><path class="wave-1" d="M11142,1199.9c-216.4,0-438.3-18.6-642.4-17.7c-401.3,0-843.7,59.1-960.2,59.1 c-357.5,0-821.8-100.4-1108.1-100.4c-161.6,0-336.9,65-515,65c-216.4,0-438.3-59.1-642.4-59.1c-401.3,0-519.1,59.1-786.2,59.1 c-267.1,0-453.4-65-739.6-65c-161.6,0-336.9,65-515,65c-216.4,0-438.3-59.1-642.4-59.1c-401.3,0-843.7,100.4-960.2,100.4 c-357.5,0-821.8-70.9-1108.1-70.9c-161.6,0-336.9,70.9-515,70.9c-141.1,0-360.2-53.2-642.4-53.2c-126,0-247.9,11.8-356.1,11.8 c-234.2,0-416.4,0-495.8,0c-357.5,0-452,0-452,0v3101l12399.9-35.4V1205.8C12445.9,1205.8,11320,1199.9,11142,1199.9z"/><animateMotion xmlns="http://www.w3.org/2000/svg" path="M 0 0 L -8050 40 Z" dur="70s" repeatCount="indefinite"/></g></g></g></svg>';
        return p;
    }

    function colors(uint256 _n) public pure returns (string memory) {
        string[10] memory _colors;
        _colors[0] = '<path fill="#33FFE3" ';
        _colors[1] = '<path fill="#33A8FF" ';
        _colors[2] = '<path fill="#337AFF" ';
        _colors[3] = '<path fill="#3352FF" ';
        _colors[4] = '<path fill="#4633FF" ';
        _colors[5] = '<path fill="#9633FF" ';
        _colors[6] = '<path fill="#C433FF" ';
        _colors[7] = '<path fill="#E033FF" ';
        _colors[8] = '<path fill="#FF33FC" ';
        _colors[9] = '<path fill="#FF33BE" ';
        return _colors[_n];
    }

    function height(uint256 _tokenId) public pure returns (string memory) {
        string[11] memory h;
        h[0] = "-1000";
        h[1] = "-800";
        h[2] = "-600";
        h[3] = "-400";
        h[4] = "-200";
        h[5] = "0";
        h[6] = "200";
        h[7] = "400";
        h[8] = "600";
        h[9] = "800";
        h[10]= "1000";
        uint256 n = 10 - (_tokenId / 304);
        return h[n];
    }

    function liquid(uint256 _tokenId) public pure returns (string memory color) {
        if(_tokenId <= 450) { return "black"; }
        else if(_tokenId > 450 && _tokenId <= 1100) { return "purple"; }
        else if(_tokenId > 1100 && _tokenId <= 2050) { return "yellow"; }
        else { return "white"; }
    }

    function generation(uint256 _tokenId) public pure returns (string memory) {
        if(_tokenId <= 833) { return "Primus"; }
        else if(_tokenId > 833 && _tokenId <= 1666) { return "Secundus"; }
        else { return "Tertius"; }
    }

    // found this online cost <700 gas suppose. Also should work with our formula.
    // When all else fails google is king
    // https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity
    function log2(uint x) public pure returns (uint y) { //Function rounds up after input of 4. 
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }

}

contract ReserverETH is ReentrancyGuard, ERC721, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Address for address; 

    Counters.Counter private _tokenIdCounter;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public reserve;
    uint256 public minted;
    uint256 internal nonce;
    uint256 internal index;
    address internal dev;
    mapping (uint256 => Piece) public pieces;
    
    modifier isMinting() {
        require(_tokenIdCounter.current() <= maxSupply, "Max Supply has been reached.");
        require(!Address.isContract(msg.sender), "Sorry, contracts cannot mint.");
        _;
    }

    struct Piece {
        string[6] colors;
        uint256 value;
        uint256 reroll;
        uint32 time;
    }

    receive() external payable {}

    constructor(uint256 _maxSupply, uint256 _cost) ERC721("ReserverETH", "RSVR") {
        cost = _cost;
        maxSupply = _maxSupply; 
        _tokenIdCounter.increment();
        dev = msg.sender;
    }

    function multiPurchase(uint256 _amount) public payable isMinting nonReentrant {        
        require(msg.value == cost * _amount, "Please send exact amount of ETH!");
        require(_amount <= 10, "You can multi mint up to 10 at a time.");
        require(minted + _amount <= maxSupply, "Mint exceeds total supply.");
        for(uint256 i = 0; i < _amount; i++) {
            spawn();
        }
    }

    function spawn() internal {
        Piece memory piece;
        for(uint i = 0; i < 6; i++) {
            piece.colors[i] = Art.colors(random());
        }

        uint256 id = _tokenIdCounter.current();
        uint256 value = reserveAmount(id);
        piece.value = value;
        piece.reroll = 0.01 ether; 
        piece.time = uint32(block.timestamp); 
        pieces[id] = piece;
        reserve += value;
        Address.sendValue(payable(dev), cost - value);

        _tokenIdCounter.increment();
        _safeMint(msg.sender, id);

        minted++; // for UI & maxSupply mint cap require 
    }

    function hodlTime(uint256 _piece) public view returns (uint32) {
        return uint32(block.timestamp) - pieces[_piece].time;
    }

    function resetTime(uint256 _tokenId) internal {
        Piece storage piece = pieces[_tokenId];
        piece.time = uint32(block.timestamp);
    }

    function reRoll(uint256 _tokenId) external payable nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token.");
        Piece storage piece = pieces[_tokenId];
        uint256 rerollPrice = piece.reroll;
        require(msg.value == rerollPrice, "Please send exact amount of ETH for reroll!");

        piece.reroll = piece.reroll * 2;
        resetTime(_tokenId);
        Address.sendValue(payable(dev), rerollPrice / 10);

        for(uint i = 0; i < 6; i++) {
            piece.colors[i] = Art.colors(random());
        }
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        resetTime(tokenId);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        resetTime(tokenId);
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        resetTime(tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    function gen(uint256 _piece) public view returns (string memory) {
        string[11] memory art = Art.gen2(_piece);
        string memory a = string(abi.encodePacked(art[0], art[1], art[2], pieces[_piece].colors[0], art[3], pieces[_piece].colors[1], art[4], pieces[_piece].colors[2], art[5], pieces[_piece].colors[3], art[6]));
        string memory b = string(abi.encodePacked(pieces[_piece].colors[4], art[7], pieces[_piece].colors[5], art[8], art[9], Art.height(_piece), art[10]));
        return string(abi.encodePacked(a, b));
    }

    function tokenURI(uint256 _piece) public view override(ERC721) returns (string memory) {
        string[11] memory attr;
        attr[0] = '[{ "trait_type": "Backing ETH", "value": "';
        attr[1] = Strings.toString(ETHToRecieve(_piece)); 
        attr[2] = '" }, { "trait_type": "Reroll fee", "value": "';
        attr[3] = Strings.toString(pieces[_piece].reroll); 
        attr[4] = '" }, { "trait_type": "Time", "value": "';
        attr[5] = Strings.toString(pieces[_piece].time); 
        attr[6] = '" }, { "trait_type": "Level", "value": "';
        attr[7] = Strings.toString(whatLevelAmI(_piece));
        attr[8] = '" }, { "trait_type": "Dignitas", "value": "';
        attr[9] = Art.generation(_piece);
        attr[10] = '" }]';
        string memory attributes = string(abi.encodePacked(attr[0], attr[1], attr[2], attr[3], attr[4], attr[5], attr[6], attr[7], attr[8], attr[9], attr[10]));
        string memory name = string(abi.encodePacked('"', Art.generation(_piece), ' ', Art.liquid(_piece), '"'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": ', name, ', "description": "On-chain generative art backed by Ethereum", "attributes": ', attributes, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(gen(_piece))), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function random() internal returns (uint256) {
        nonce++;
        nonce = uint256(keccak256(abi.encodePacked(block.coinbase, msg.sender, nonce)));
        
        return nonce % 10;
    }

    function reserveAmount(uint _tokenID) public view returns (uint256) {
        if(_tokenID > 0) {
            return (cost * (100000 + (differenceMultiplier() * (_tokenID-1)))) / 1000000; // (cost * (10% + change in %))/100%
        }

        return 0;
    }

    function differenceMultiplier() public view returns (uint256) {
        return 800000 / (maxSupply - 1); // (90% - 10%) / (n - 1) = 80% / (n - 1) 
    }

    function burn(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(!Address.isContract(msg.sender), "Contracts cannot burn.");

        Piece memory burner = pieces[tokenId];
        uint value = burner.value;
        uint256 amount = ETHToRecieve(tokenId);

        _burn(tokenId);
        reserve -= value;
        Address.sendValue(payable(msg.sender), amount);
    }

    function whatLevelAmI(uint256 _tokenID) public view returns (uint256) {
        uint32 xp = hodlTime(_tokenID);
        return Art.log2(((1000*xp)/795534)+1) + 1;
    }

    // @dev function to calculate the amount eth on burn
    function ETHToRecieve(uint256 _tokenID) public view returns (uint256) {
        Piece memory token = pieces[_tokenID];
        uint256 amount = token.value;
        uint256 level = whatLevelAmI(_tokenID);
        uint256 priorFee = amount + (amount * (address(this).balance - reserve)) / reserve; // Finds the ratio of itself to the royalities on the contract
        uint256 afterFee = priorFee - ( priorFee/ (19 + level)); // subtracting fee level 1 is 5% then each new level reduces the fee to subtract level 10 is 3.45% fee

        return afterFee;
    }

    // Overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
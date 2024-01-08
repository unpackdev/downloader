// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Abramo
/// @author: FractalSoft
//  https://mandelbrot.fractalnft.art
//  https://julia.fractalnft.art
/* ....................................................'''''''',,''''''''''................
   ................................................''''''''''',;c:;,,'''''''''.............
   ..........................................''''''''''''''',,,;col:;:;,'''''''''..........
   .......................................''''''''''''''''',,,,;:cdxol:;,''''''''''........
   .....................................''''''''''''''''',,,,;::coxkxc;;,,,'''''''''''.....
   ...............................'''''''''''''''''''',,,,,,:lxxxd;;xxdo:,,,'''''''''''....
   ...........................'''''''''''''''''''',,,,,,,,;;:oOo.   .cOx:;,,,,,,'''''''''..
   ........................''''''''''''''''''',,,,,,;;;;;;;::lkc     'xo:;;;;,,,,,,,'''''''
   ....................''''''''''''''''''''',,,,,:ldxxl::oddddxd,   .lxdooodl;;;;:lc,,'''''
   ..................''''''''''''''''''''',,,,,;;:oOOlldxdc;,....   ....,::oxlldddkxc,,''''
   ...............'''''''''''''''''''',,,,,,,,;;;:cxd..,,.                 .'cl,.ckx:,,''''
   ............'''''''''''',,,,,,,,,,,,,,,,,;;coddxxo'                          'odc;,,''''
   ..........''''''''''',,;:;;,,,,,,,,;,,;;;;:dOOd:'                            'loc;;;,'''
   .........''''''''''',,,:oo:::;;coc;;;;;;::lxxx:                               .:loxc,,''
   ......''''''''''''',,,;;lodkkdlxOxddoc:::cxxl'                                 .;oo:,,''
   ....''''''''''''',,,,,;;:cxOccol:,:lldxoldx;                                    :dl;,'''
   .''''''''''''',,,,,;;;;coxko.        .,okOl.                                    ,dl;,'''
   '''''''',,,,,,,,,;;loclokk;             ck,                                    .lo;,,'''
   '''',,,;;;,,;;;;;::lOkoox:               '.                                   .:l;,,,'''
   ,,;;;;:llc:cllccoxxOx,  ..                   Mandelbrot Trilogy Collection   ,c:;;,,,'''
   ',,,;;;:::;:::::clodko,,:'                                                   .,c:;,,,'''
   '''''',,,,,,,,,;;;:lxxxxOo.             .l'                                    'lc;,,'''
   ''''''''''',,,,,,,;::::cxko,.          ,x0:                                     :d:,,'''
   ..''''''''''''',,,,,,;;:clkk,.,.. ..':oxdkd.                                    ,do;,,''
   ....''''''''''''',,,,,;;:lkOddxkxodkkdlcclxo,.                                  cdc;,,''
   ......'''''''''''''',,,;odollc:lkdccc:;:::dkkl.                                .:dkc,,''
   .........'''''''''''',,;lc;;;;;;::;;;;;;;:cdOOc.                              ,ddll:,'''
   ............''''''''''',,,,,,,,,,,,,,,,;;;:okkdol,                           ;dd:;,,,'''
   .............'''''''''''''''''',,,,,,,,,,,;;:cclxx,                       .'..:xl;,,''''
   ................''''''''''''''''''''',,,,,,;;;:lkd,;oo;.              ..'lddlcokkc;,''''
   ....................'''''''''''''''''''',,,,,,:dOOkxookxoocc:,   .:cclooxd::cccdo:,'''''
   ......................''''''''''''''''''',,,,,;cccl:;:clccokd.   .ckdc:cc:;;,,;:;,''''''
   .........................'''''''''''''''''''',,,,,,,,;;;;:lkc     'xd:;;,,,,,,,''''''''.
   .............................'''''''''''''''''''',,,,,,,;:okkl;..:dkx:;,,,,''''''''''...
   .................................''''''''''''''''''',,,,,;coodkddkocc;,,,'''''''''''....
   ......................................''''''''''''''''',,,,;;:cxOdc:;,,''''''''''.......
   ..........................................''''''''''''''',,,;:odlll:,,'''''''''.........
   ..............................................'''''''''''',,;ll:;,,,'''''''''...........
   .................................................'''''''''',,;;,,''''''''''.............
   ....................................................'''''''''''''''''''.................

   1978 unique pieces available
*/


import "./ERC721TradableTrilogy.sol";

contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
}

contract ITrilogyFinder {
    function get_trilogy_id(uint256 token_id) public view returns(uint16) {}
}

/**
 * @title Trilogy
 * Trilogy - a contract for non-fungible Mandelbrot Trilogies
 */
contract Trilogy is ERC721TradableTrilogy {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721TradableTrilogy("Mandelbrot Trilogy Collection", "TRI", _proxyRegistryAddress) {}

    bool    private _active;
    uint256 private claimed = 0;

    mapping (uint256 => uint256) token_to_trilogy;
    mapping (uint256 => uint256) brot_to_trilogy;

    // LIVE
    address public  MANDELBROT_ADDRESS = 0x6E96Fb1f6D8cb1463E018A2Cc6E09C64eD474deA;
    address public  JULIA_ADDRESS      = 0x6e845bE4ea601B4Dbe98ED1f52b371dca1Dbb2b6;
    address private FINDER_1_ADDRESS   = 0xac69bbAC27a85F3d762aC0d083183D646452c9Df;
    address private FINDER_2_ADDRESS   = 0xE74CcB76b1453F5B6b5B43aC99E8E89b352545dC;
    address private FINDER_3_ADDRESS   = 0xc8cAC2F64850F705a7d1AA90aA73eebCb383c002;
    address private FINDER_4_ADDRESS   = 0x251A6cA8350c70D8A66abce678428a6EEB2d3683;


    function find_id(uint256 owned) internal view returns(uint256 _trilogy_id) {
        uint256 owned_reduced;
        if (owned%(250*5)>0) owned_reduced = owned%(250*5);
        else owned_reduced = 250*5;
        if      (owned<=250*5*1 ) return uint256(ITrilogyFinder(FINDER_1_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*2 ) return uint256(ITrilogyFinder(FINDER_2_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*3 ) return uint256(ITrilogyFinder(FINDER_3_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*4 ) return uint256(ITrilogyFinder(FINDER_4_ADDRESS).get_trilogy_id(owned_reduced));
    }

    
    function claim_trilogy(uint256 trilogy_id) public {

        require(trilogy_id>0 && trilogy_id<=1978, "Please enter a valid Mandelbrot id");
        require(_active);
        uint256 verified_brot = 0;
        uint256 verified_julias = 0;
        uint256 owned;
        uint256 j = 0;
        while (verified_brot < 1) {
            owned = IERC721Enumerable(MANDELBROT_ADDRESS).tokenOfOwnerByIndex(msg.sender, j);
            if (owned==trilogy_id) verified_brot++;
            j++;
        }
        j = 0;
        while (verified_julias < 2) {
            owned = IERC721Enumerable(JULIA_ADDRESS).tokenOfOwnerByIndex(msg.sender, j);
            if (find_id(owned)==trilogy_id) verified_julias++;
            j++;
        }
        if (verified_brot+verified_julias==3) {
            mintTo(msg.sender);
            token_to_trilogy[_currentTokenId] = trilogy_id;
            brot_to_trilogy[trilogy_id] = _currentTokenId;
            claimed++;
        }
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://trilogy.fractalnft.art/item?token_id=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://trilogy.fractalnft.art/collection";
    }


    // Views

    function active() external view returns(bool) {
        return _active;
    }


    function get_trilogy_id(uint256 token_id) external view returns(uint256 _trilogy_id) {
        return token_to_trilogy[token_id];
    }

    function was_trilogy_claimed(uint256 trilogy_id) external view returns(bool) {
        require(_active, "Inactive");
        if (brot_to_trilogy[trilogy_id]>0) return true;
        return false;
    }

    function claimable_trilogies() external view returns(uint256) {
        require(_active, "Inactive");
        return 1978 - claimed;
    }



    // Owner's functions

    function activate() external onlyOwner {
        require(!_active, "Already active");
        _active = true;
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() external onlyOwner {
        _active = false;
    }

    function resume() external onlyOwner {
        _active = true;
    }

    function test_finder(uint256 owned) external onlyOwner view returns(uint256 _trilogy_id) {
        return find_id(owned);
    }

}

// SPDX-License-Identifier: MIT
/// @artist: Pi_CarD_CollarD
/// @author: Root LaunchPad
//  https://root.fractalnft.art/metabrot
//  https://root.fractalnft.art/
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
   ,,;;;;:llc:cllccoxxOx,  ..                        MetaBrot Collection        ,c:;;,,,'''
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

   4000 unique NFTs, 0.05 ETH each
*/

pragma solidity ^0.8.0;
import "./ERC721TradableMetaBrot.sol";
 
contract MetaBrot is ERC721TradableMetaBrot {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721TradableMetaBrot("MetaBrot Collection", "MBC", _proxyRegistryAddress) {}

    bool public  _unveiled = false;
    uint256 public  _sale = 0; // 0 --> Inactive, 1 --> Pre-sale, 2 --> Public Sale
    string  private _theBaseURI = "ipfs://QmWFMKU59tqZuBUMM9THcBQmZPjSSEGMjWwadCPNPnwmnU/";
    uint256 constant private PRICE = 50000000000000000;    // 0.05 ETH
    uint256 constant private MAX_QUANTITY = 20;           // Maximum allowed quantity to purchase in one transaction
    uint256 constant public  COMMUNITY_QUOTA = 15;       // 15% of the sale proceeds stays in the community
    address constant public  COMMUNITY_WALLET = 0xBd152865C7DeCb5aeE2EF515B23843Dfad2DEeb2;

    mapping (address => uint256) WL_spots;
    mapping (address => uint256) FM_spots;

    function baseTokenURI() override public view returns (string memory) {
        if (bytes(_theBaseURI).length == 0){
            return "";
        } else {
            return strConcat(_theBaseURI,"metabrot_");
        }
    }


    // Views
    function contractURI() public pure returns (string memory) {
        return "ipfs://Qmewt5F4NE5fYWEghvoSFZLAb8T9StEoAr4RKW4Cap9mi3";
    }

    function sale_status() external view returns(string memory) {
        if (_sale==0) { return "Paused"; }
        if (_sale==1) { return "Pre Sale"; }
        else  { return "Public Sale"; }
    }

    function WL_spots_for(address _address) external view returns (uint256) {
        return WL_spots[_address];
    }

    function FM_spots_for(address _address) external view returns (uint256) {
        return FM_spots[_address];
    }



    // Sale
    function give_to_community(uint256 nfts) internal {
        uint256 amount = (nfts*PRICE*COMMUNITY_QUOTA).div(100);
        payable(COMMUNITY_WALLET).transfer(amount);
    }

    function purchase(uint256 nfts) external payable {
        require(_sale>=1, "Sale Paused");
        require(nfts <= remaining() && nfts <= MAX_QUANTITY, "Too many nfts requested");
        require(msg.value == nfts*PRICE, "Invalid purchase amount sent");
        if (_sale==1){ //Presale
            require(WL_spots[msg.sender]>=nfts);
            require(nfts <= remaining() - 200);
            WL_spots[msg.sender] -= nfts;
        }
        for (uint i = 0; i < nfts; i++) {
            mintTo(msg.sender);
        }
        give_to_community(nfts);
    }


    function free_mint(uint256 nfts) external {
        require(_sale>0, "Sale Paused");
        require(nfts <= remaining() && nfts <= MAX_QUANTITY, "Too many nfts requested");
        require(FM_spots[msg.sender]>=nfts);
        FM_spots[msg.sender] -= nfts;
        for (uint i = 0; i < nfts; i++) {
            mintTo(msg.sender);
        }
    }



    // Owner's functions
    function setBaseMetadataURI( string memory _newBaseMetadataURI) public onlyDeployer {
        if (!_unveiled) {
            _theBaseURI = _newBaseMetadataURI;
            _unveiled   = true; // Cannot modify again after unveil
        }
    }

    function start_pre_sale() external onlyDeployer {
        require(_sale!=1, "Pre-sale already started");
        _sale = 1;
    }

    function start_public_sale() external onlyDeployer {
        require(_sale!=2, "Public sale already started");
        _sale = 2;
    }

    function pause_sale() external onlyDeployer {
        require(_sale!=0, "Already paused");
        _sale = 0;
    }

    function premine(uint256 nfts) external onlyDeployer {
        require(_sale>1, "Public sale already started");
        for (uint i = 0; i < nfts; i++) {
            mintTo(msg.sender);
        }
    }

    function add_to_WL(address[] memory _addresses, uint256[] memory _quantities) external onlyDeployer {
        for (uint256 i = 0; i < _addresses.length; i++) {
            WL_spots[_addresses[i]] += _quantities[i];
        }
    }    
    function add_to_FM(address[] memory _addresses, uint256[] memory _quantities) external onlyDeployer {
        for (uint256 i = 0; i < _addresses.length; i++) {
            FM_spots[_addresses[i]] += _quantities[i];
        }
    }    

    
    function withdraw(address payable recipient, uint256 amount) external onlyDeployer {
        recipient.transfer(amount);
    }

}
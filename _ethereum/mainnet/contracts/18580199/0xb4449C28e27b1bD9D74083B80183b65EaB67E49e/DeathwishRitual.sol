//SPDX-License-Identifier: EVERYONE DIES                                                                      
//                                                    ..                                                        
//                                                   .:c.                                                       
//                                                  .cdo.                                                       
//                                                .;oocooc;'.                                                   
//                                                .odcclloxxdl:.                                                
//                                                 ;do:colccoxkx;                                               
//                                                 .lxc;oOxl::okx,                                              
//                                                 'oxc';cclxc,oOc                                              
//                                                 :xl'','od:d;;x,                                              
//                                                .cx:.c:.;;cd,',                                               
//                                                 .cl,;;',;:.                                                  
//                                                   ';,...                                                     
//                                           ..','..        ..,;cccc:;,.                                        
//                                         ..:x0KK0Oxo:;. .;ld0XX0kxxxxd,                                       
//                                        .oxdddddooxkdc,...';ldddxkkOKK;                                       
//                                         :XWNNNX0xoooodxkOOOO0XNWNXXWx.                                       
//                                        .xNNNNNNKx0WNNNWNNNK0X0OXKkKK;                                        
//                                       .oKXNNNNNocKX0kxdONkcoKkcOXxOd.                                        
//                                       .dxkNKOXNlcXNXXOoooldXXllXNddo                                         
//                                        .,k0x0NNk;dNNNNNNXXNNO:xWWxld'                                        
//                                     ...'x0lxWNWK::XNNNNNNNNNKl:OO:cKk....                                    
//                                  .':c,;OWKcckOkc;xNNNNNNNNNNNKoc:l0NNO;:kOxl.                                
//                                .;;cxkdkNNN0dlccoOKKKKXNNNNNNNNNXXNNNKk',0NNWk.                               
//                               .;,.cKNNNNNNWWX0xl:;;,;ldOXNNNWWNXKKXNOlcox0XW0,.                              
//                               'lo;;kKXXXXKOl;',:oxxxoc:::coooc;'';d0Oko;;::d0ko,                             
//                              ;dkkd:,;:cc:,.,cxKXNNNNNXXKkolcloolccccc:cokd'.:kX0l.                           
//                             :xkkOKKOdlccldOXNWMMMMMMMWWWMMWWWWWWNNNNNNXK0Oo'';dXNO,                          
//                            ;xkOKWWMMWWWWMMMMWMWKOxddx0XNMWMWWMWWWMMMMWMMWX0d,,;dNNKc                         
//                           ':cd0WWMMMMMWMMWMWKd:,;:cld0XNMMWWWMNOoxXMWMMWMWWNl,;:0NNXl                        
//                          .,,;:0MWMMMMMMWXOxc;:d0NWWWMMMMWMWWWMNKdl0MWMMMMWMMO;;,dNNWXl                       
//                          .'.:xNMWMMMMMMWKxdkKWMWNXK00OOOOOKNWWWWWWWWMWNWMMMW0c;':XNNWK;                      
//                          .,oOOxdooxOKWMMMMMWXkl;,'...     .,oXWWMMWMMWO0WMMW0dc;,kNNWWo                      
//                         .oK0:. .    .:OWMNOc'.....           'OWMMMMMNdxWMMW0xdc'lXNWXc                      
//                       .lK0c...'.      ;KNl..',.               cNMMWWKllKWNWWKkkx;'oOOl.                      
//                      ;0Xd. .,'        ;X0' .;'                ,KMWMNl;OWWKKWXOkkx;.,'                        
//                     '0Wd. .,'        .kWK, .;'                ,KWWMX;;0NNOkXN0kkOd'.'                        
//                     .dX: .,;.       .xWMNl .,,.               .OMWWWo'lXXdd0XKkkkx'':.                       
//                      .do..,;'      ,kWWWWO, .,.                dWMWMX;'00coO0XOkkx,,c.                       
//                       .lc...''.  .l000NWMNd. ',.               oWMWMK;;0l;dxOKOxkx;:c.                       
//                     .'.;OOc,...,o0Nd..'oXWXo..,,.             .kWWWMKlox':ooOKklxkcc:                        
//                   ;dkxO0XWWXOk0NMW0;..  lNWXc..,,..          .oNWWMMXxxc'::lO0o;dOdo'                        
//                  ,KWWWMMMMMMMMWMMXc...  .OWWK: ..',,''.....':ONWWWMWNx;....lOO:,xkkd.                        
//                  .xWWWMMMMWMMMWMMx.',..  dWMWXxc;,,,;;::cokXWMMWMMWMMW0o:,..ld,;kdl:.                        
//                   .lxodxdx0WMWWWWO,.....,OMWMMWWNXXXXXNNWWMMMMWMMMMMMMMMWkc,.;':k;''                         
//                     .''',,;ox0NWWWXOkxxkKWWWMMNKOxddoooooddx0WWWMMWMMMMWKc;:.'.cl...                         
//                              .;kNWWMMMMWWMWMMXOxxkkkkxxdoollx0XNNNX0xdol:;;',,.,.                            
//                               'cOWWMMNKKX00NWWWMMMMMWWNKkdo:.',;:ooc::;,'. .,.                               
//                              .,cxOOOOkxxdox0XNWMNOxkXX0OO0d,,;.                                              
//                             ;x:..',;;;;cxx:;;;ldocc;;dKXNKo::.                                               
//                            ;xk,.lKXNW0x; .c0KO;.xWWXo..,c:;'.                                                
//                            ... .,:lodc:' ,0NKN0,;oodc.                                                       
//                                          ,xd,;o,                                                             
//

pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract DeathwishRitual is Ownable {
    address public constant DW365_CONTRACT = 0x67E3e965CE5Ae4D6a49ac643205897aCB32fCF6e;
    address public constant CANDLES_CONTRACT = 0x521945fDCEa1626E056E89A3abBDEe709cf3a837;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IERC721 public dw365 = IERC721(DW365_CONTRACT);
    IERC1155 public candles = IERC1155(CANDLES_CONTRACT);

    bool public ritualActive = true;

    mapping(uint256 => uint8) public ritualPerformed;

    event RitualPerformed(uint256 dw365TokenId, uint256 candleType, address owner);

    function performRitual(uint256 dw365TokenId, uint8 candleType) external {
        require(candleType == 1 || candleType == 2 || candleType == 3, "Invalid candle token type.");
        require(dw365.ownerOf(dw365TokenId) == msg.sender, "You must own the DW365 token.");
        require(ritualActive, "The ritual is not active.");

        require(ritualPerformed[dw365TokenId] == 0, "Ritual has already been performed with this DW365 token.");

        ritualPerformed[dw365TokenId] = candleType;

        candles.safeTransferFrom(msg.sender, BURN_ADDRESS, candleType, 1, "");

        emit RitualPerformed(dw365TokenId, candleType, msg.sender);
    }

    function setRitual(bool state) external onlyOwner {
        ritualActive = state;
    }
}
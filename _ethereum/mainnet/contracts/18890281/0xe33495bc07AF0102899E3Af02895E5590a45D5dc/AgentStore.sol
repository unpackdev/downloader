/**
    AgentStore
    Marketplace for blockchain AI models.
    
    Website: youragent.store
    Twitter: twitter.com/youragentstore

                                                  
                        iv                        
                     igDZBuQqi                    
                  iPgu   P  iXQKi                 
               iPZE     iD     igbIi              
            iUdqiiiJi    Z    vv siPMU            
          UgPi   B  rKu  U ikui  B   rMMJ         
       KBIi      B     YKXK      B      ibBY      
      BUEv       B   iKBUrEXi    B      ivUQR     
      B          B JBBV  q vBBK  B   sEKi  iB     
      B        ii ZBi    X    PBdK uLi     rB     
      B       iuuI irv   u   rr qB di      rQ     
      B    iXPL  B    iirIiJv  iqB  iVPv   iQ     
      BvivJv     B     PQBi   PL B     ivurQg     
      BrBBi      B   ViiBiiPPJ   B      iPgZg     
      B   vEKi   B ir iQiiDgrri  B   rPEr  iR     
      B      LbJ PjDEMQi k rbIqZrR sqv     rQ     
      B        Yv  gQu  iq   uBPi ii       vQ     
      B      JdJ D   rb  u  vBL  DiVEr     rB     
      B   JQPi   B     rLgirJK   B   vdDv  iQ     
      BrJji      B      ru  V    B      vsrgB     
      IBP        B      sMPv     B        QBi     
        iPQui    B    YYLV rVv   B    iKQk        
           vgQj  B ijJi  g   ijJiB  XBPi          
              vDDBr      Z      vBRPr             
                 rPEv    D    YgSi                
                    uRgiib rEgY                   
                       sBBqL                      
                                                



**/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract AgentStore is ERC20 {
    constructor(uint256 initialSupply) ERC20("AgentStore", "AGENT") {
        _mint(msg.sender, initialSupply);
    }
}
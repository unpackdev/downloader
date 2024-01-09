// SPDX-License-Identifier: MIT
// Reference: https://www.cl.cam.ac.uk/~mgk25/ucs/utf-8-history.txt
// Rewrite by sjy.eth in Solidity

pragma solidity >=0.4.22 <0.9.0;

library  UTF8 {
  
  struct Tab {
          uint32	cmask;
          uint32	cval;
          uint32	shift;
          uint64	lmask;
          uint64	lval;
  }

  function tabForUTF8() internal pure returns (Tab[] memory) {
        Tab[] memory tab = new Tab[](6); //statck memory, less gas used
        tab[0] = Tab(0x80, 0x00, 0*6, 0x7F,0);
        tab[1] = Tab(0xE0, 0xC0, 1*6, 0x7FF,      0x80);
        tab[2] = Tab(0xF0, 0xE0, 2*6, 0xFFFF,     0x800);
        tab[3] = Tab(0xF8, 0xF0, 3*6, 0x1FFFFF,   0x10000);
        tab[4] = Tab(0xFC, 0xF8, 4*6, 0x3FFFFFF,  0x200000);
        tab[5] = Tab(0xFE, 0xFC, 5*6, 0x7FFFFFFF, 0x4000000);
        return tab;
  }

  //reference: https://www.cl.cam.ac.uk/~mgk25/ucs/utf-8-history.txt
  function decode(string memory s) external pure returns (int retCode, uint32[] memory) {
        Tab[] memory tab = tabForUTF8();
        uint64 l;
        uint32 c0;
        uint32 c;
        uint32 nc;
        uint si;
        uint ui;
        bool matched;
        bytes memory ss = bytes(s);
        uint32[] memory unicodes = new uint32[](ss.length); //at most
        if(ss.length == 0)
            return (0, new uint32[](0));
        while(si < ss.length) {
            nc = 0;
            c0 = uint8(ss[si]) & 0xff;
            l = c0;
            matched = false;
            for(uint i=0; i<tab.length; i++) {
              Tab memory t = tab[i];
              nc++;
              if((c0 & t.cmask) == t.cval) {
                l &= t.lmask;
                if(l < t.lval)
                  return (-1, unicodes);
                unicodes[ui] = uint32(l);
                ui++;
                matched = true;
                si++;
                break;
              }
              if (ss.length <= nc)
                return (-2, unicodes);
              si++;
              c = (uint8(ss[si]) ^ 0x80) & 0xFF;
              if(c & 0xC0 == 1)
                return (-3, unicodes);
              l = (l<<6) | c;
            }
            if (!matched)
                return (-4, unicodes);
        }
        uint32[] memory result = new uint32[](ui);
        for (uint i=0; i<ui; i++) {
            result[i] = unicodes[i];
        }
        return (0, result); 
  }

  function encode(uint32[] memory unicodes) external pure returns (bytes memory) {
        Tab[] memory tab = tabForUTF8();
        uint8[] memory s = new uint8[](unicodes.length * 5);
        uint64 l;
        uint32 c;
        uint32 nc;
        uint si;
        for (uint i = 0; i < unicodes.length; i++) {
            l = unicodes[i];
            nc = 0;
            for(uint j = 0; j < tab.length; j++) {
                nc++;
                Tab memory t = tab[j];
                if(l <= t.lmask) {
                    c = t.shift;
                    s[si] = uint8(t.cval | (l>>c));
                    si++;
                    while(c > 0) {
                        c -= 6;
                        s[si] = uint8(0x80 | ((l>>c) & 0x3F));
                        si++;
                    }
                    break;
                }
            }
        }
        bytes memory result = new bytes(si);
        for (uint i=0; i<si; i++) {
            result[i] = bytes1(s[i]);
        }
        return result;
  }
}

pragma solidity >=0.8.0 <0.9.0;

import "./base64.sol";
import "./Strings.sol";
import "./SSTORE2.sol";

import "./NFTImage.sol";

import "./console.sol";

interface DefaultReverseResolver {
  function name(bytes32 node) external view returns (string memory);
}

interface ENS {
  function resolver(bytes32 node) external view returns (address);
}

interface ReverseRegistrar {
  function node(address addr) external pure returns (bytes32);
}

contract Capsule21InvitationRenderer {
    using Strings for uint24;
    using Strings for address;
    
    ENS public ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    ReverseRegistrar public reverseResolver = ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    function addressToEnsName(address addr) public view returns (string memory) {
        bytes32 node = reverseResolver.node(addr);
        address resolvedAddr = ens.resolver(node);
        
        if (resolvedAddr == address(0)) return addr.toHexString();
        
        return DefaultReverseResolver(resolvedAddr).name(node);
    }
    
    struct Invitation {
        uint24 id;
        uint24[10] gradientColors;
        bool isRadialGradient;
        uint24 textColor;
        uint8 fontSize;
        uint16 linearGradientAngleDeg;
        address textPointer;
        address descriptionPointer;
        uint32 eventTime;
        uint32 mintStart;
        uint24 mintDuration;
        uint24 editionSize;
    }
    
    struct ExtraTokenInfo {
        uint24 invitationId;
        uint24 editionNumber;
        address to;
        address from;
    }
    
    constructor() {}
    
    function tokenImage(
        uint tokenId,
        Invitation memory invitation,
        ExtraTokenInfo memory extraTokenInfo
    ) public view returns (string memory) {
        string[2] memory widthAndHeight = ["1200", "1500"];
        string[2] memory messageIdandText = [invitation.id.toString(), string(SSTORE2.read(invitation.textPointer))];
        
        return _tokenImage(
            messageIdandText,
            invitation.textColor,
            invitation.isRadialGradient,
            invitation.fontSize,
            invitation.linearGradientAngleDeg,
            invitation.gradientColors,
            extraTokenInfo.to,
            extraTokenInfo.from,
            widthAndHeight
        );
    }
    
    function _tokenImage(
      string[2] memory messageIdandText,
      uint24 textColor,
      bool isRadialGradient,
      uint8 fontSize,
      uint16 linearGradientAngleDeg,
      uint24[10] memory gradientColors,
      address to,
      address from,
      string[2] memory widthAndHeight
    ) private view returns (string memory) {
        string[14] memory parts;
        
        parts[0] = string(NFTImage.buildGradientString(
            isRadialGradient,
            linearGradientAngleDeg,
            gradientColors
        ));
        
        parts[1] = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 487.5' class='x3fvufWE1e3H1xpo'><foreignObject x='0' y='0' width='390' height='487.5'><div style='background:";
        
        parts[2] = ";color:#";
        
        parts[3] = string(abi.encodePacked(";position:absolute;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column' xmlns='http://www.w3.org/1999/xhtml'><style>",
        
        NFTImage.fontDeclarations(),
        
        "svg.x3fvufWE1e3H1xpo,svg.x3fvufWE1e3H1xpo *{", NFTImage.monoFontStack(), "box-sizing:border-box;margin:0;padding:0;border:0;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;overflow-wrap:break-word}</style><div style='", NFTImage.buildFontMetrics(fontSize), NFTImage.sansFontStack(), "flex:1;padding:16px;white-space:pre-wrap;overflow:hidden'>"));
        
        parts[4] = string(abi.encodePacked("</div><div style='white-space:pre;background:rgba(0,0,0,.5);color:#fff;padding:16px;font-size:12px;line-height:calc(4/3);display:flex;flex-direction:column'><div style='", NFTImage.sansCondensedFontStack(), "letter-spacing:1.25px;font-weight:500;margin-bottom:8px'>CAPSULE 21 INVITATION #"));
        
        parts[5] = "</div><div>from   ";
        
        parts[6] = "\nto     ";
        
        parts[7] = "</div></div></div></foreignObject></svg>";
        
        parts[8] = Base64.encode(abi.encodePacked(
            abi.encodePacked(parts[1], parts[0]),
            abi.encodePacked(parts[2], Utils.toHexColor(textColor)),
            abi.encodePacked(parts[3], Utils.escapeHTML(messageIdandText[1])),
            abi.encodePacked(parts[4], messageIdandText[0]),
            abi.encodePacked(parts[5], addressToEnsName(from)),
            abi.encodePacked(parts[6], addressToEnsName(to)),
            parts[7]
        ));
        
        parts[9] = string(abi.encodePacked("<svg viewBox='0 0 390 487.5' width='", widthAndHeight[0], "' height='", widthAndHeight[1], "' xmlns='http://www.w3.org/2000/svg'><image width='100%' height='100%' href='data:image/svg+xml;base64,"));
        parts[10] = "' /></svg>";
        
        parts[11] = Base64.encode(abi.encodePacked(
            parts[9],
            parts[8],
            parts[10]
        ));
        
        return string(abi.encodePacked("data:image/svg+xml;base64,", parts[11]));
    }
}

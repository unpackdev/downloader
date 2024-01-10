// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//                                    WAGMIKXNW
//                                  Nkc;;;;;:o0W
//                  WXKKKNW        Wx';odoool,,xW
//              WWNkc:;::::o0N     Nl'ldc:::lo;,kW
//            WN00d';odddoc,':kN   Wk';o::::;lo':X
//           W0xOx,,dddlcclol;'c0W  No.:l::c::o;,kXW
//           W0xOx',dxo:::::lol,,kW  Xc.:c:c::o;,ox0N
//            WX0Oo.;odl::cc::lo;'xW  K;':::;:l,,ddON
//              WWNk:,;loc::c::co;'xW Wx';:,;:c':k0N
//                  NOl;,:llc:::co;,kW 0,';',:;'xWW
//                    WKx:,;clc:;:l,;0 0,';',,'lN
//                       W0o;,:l:;:c'lXd.......:llodk0NW
//                         WXd;,::,;..;,',;::ccccc:;;;:lxKW
//                           WXd'...,:ldddddddddddddddoc;;l0W
//                           WOc',codddddddddddddddddddddo;,lK
//                         WOc,;ldxddddddddddddddddddddddddl,;kK
//                        Xo',ldddddddddddddddddddddddddddddo;,ok
//                       Kc';ldxdddxxddddddddddddddddddo::cloo,,dk
//                      K:':odddolc;;;ldddddddddddddddc':l,':ll':k
//                     Nl';ldddoc;.GM;.lxddddddddddddd:'GN;.;ldc'oN
//                    Wx',codddoc;';c,;odddddddddddddddc;;:clodo,;K
//                    X:'codddddollccldxdddddoollcccccllooddddddc'd
//                    k',loddxddddddoc:;,,''..,;,..;:'..;,'.;oddl'c
//                   Wo':odddddddc,',;..:kxo'.oKd.,OXl.cKk' .:ddd,,K
//                   K:,loddddddc. ,O0: 'l:'. .'.  .'. .:,   ;ddd;,O
//                   k,;oddddddo'   ..                       ,ddd;'k
//                   l':ldddddd:.                            ;ddd:'k
//                  x,'cldddddd,      ...... .              .:ddd;'O
//                  o';lodddddd,  .',,,;;;;,,;,,'''..       .lddd,,0
//                 k;'coddddddd:..,,;;;;:cclclllllllc;'.   .:dddo,;K
//                Ko':loxddddddo' .,;;;cloooooollllc,'''.  ;dddxo':X
//                0;,codddddddddl..'..,'.,''''''''..'o:. .:ddddxc.oW
//               Xc':coddddddddddl,. :Oo..lkx: 'kO, ':,':odddddd:'x
//               o':lodddddddddddddl,',' 'oxd:..::..';cddddddddd,,0
//              d';lddddddddddddddddddlc;;,,,,,;;:lodxddddddddxl.cN
//             k',clddddddddddddddddddddxxxxxddxxdddddddddddddd:.dW
//////////

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract Loons is ERC721A, Ownable {
    
    event PreSaleToggled(bool indexed newStatus);
    event PublicSaleToggled(bool indexed newStatus);
    
    // URI
    string public baseURI;
    string _contractUri;

    // settings
    uint16  public constant maxMint = 6970; // in reality 6969
    uint16  public constant maxPresaleSupply = 5001; // in reality 5000
    uint256 public teamLoons = 255;  // in reality 254
    uint8   public constant maxPresaleMints = 3; //in reality 2
    uint    public constant price = 0.059 ether;
    uint    public constant publicPrice = 0.069 ether;
    uint8   public constant maxMintPerWallet = 9; // in reality 8
    uint256 public presaleMinted = 0;

    bool    public isPublicSaleActive = false;
    bool    public isPresaleActive = false;

    bytes32 private _OGMerkleRoot;
    bytes32 private _presaleMerkleRoot;

    constructor (
        bytes32 presaleRoot,
        bytes32 ogRoot
    ) ERC721A("Loons", "LOON") {
        _presaleMerkleRoot = presaleRoot;
        _OGMerkleRoot = ogRoot;
        _contractUri = "https://toontown.land/contract/metadata.json";
    }

    mapping(address => uint256) public mintedOG;
    mapping(address => uint256) public mintedPresale;
    mapping(address => uint256) public mintedPublic;

    function ogMint(
        bytes32[] calldata ogProof
    )
    public
    payable
    {
        require(isPresaleActive, "Presale is not active");
        require(msg.value == price, "INSUFFICIENT_PAYMENT");  // 0.059
        require(mintedOG[msg.sender] + 2 == 2, "ALREADY_MINTED_OG");
        require(totalSupply() + 2 < maxMint, "SOLD_OUT"); // 6969 + 1
        require(MerkleProof.verify(ogProof, _OGMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "NO_OG");
        mintedOG[msg.sender] = 2;
        
    unchecked {
        presaleMinted += 2;
    }
        _safeMint(msg.sender, 2);
    }

    function presaleMint(
        uint256 numberOfTokens,
        bytes32[] calldata presaleProof
    )
    public
    payable
    {
        require(isPresaleActive, "Presale is not active");
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(mintedPresale[msg.sender] + numberOfTokens < maxPresaleMints, "MAX_PRESALE_MINTS");
        require(mintedPresale[msg.sender] + numberOfTokens < maxPresaleSupply, "EXCEEDS_MAX_PRESALE_SUPPLY");
        require(totalSupply() + numberOfTokens < maxMint, "SOLD_OUT");
        require(MerkleProof.verify(presaleProof, _presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_WHITELIST_PROOF");

        unchecked {
            mintedPresale[msg.sender] += numberOfTokens;
            presaleMinted += numberOfTokens;
        }
        _safeMint(msg.sender, numberOfTokens);

    }

    function mint(
        uint256 numberOfTokens
    )
    public
    payable
    {
        require(isPublicSaleActive, "Public sale is not active");
        require(msg.value == publicPrice * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(totalSupply() + numberOfTokens < maxMint, "SOLD_OUT");
    unchecked {
        mintedPublic[msg.sender] += numberOfTokens;
    }
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintForTeam(uint256 numberOfTokens) external onlyOwner {
        require(numberOfTokens < teamLoons, "EXCEEDS_MAX_MINT_FOR_TEAM");
        require(teamLoons - numberOfTokens >= 0, "ALL_TEAM_LOONS_MINTED");
        require(totalSupply() + numberOfTokens < maxMint, "SOLD_OUT");

        teamLoons -= numberOfTokens;

        unchecked {
            presaleMinted += numberOfTokens;
        }
        
        _safeMint(msg.sender, numberOfTokens);
    }

    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setOGRoot(bytes32 newOGRoot) external onlyOwner {
        _OGMerkleRoot = newOGRoot;
    }

    function setPresaleRoot(bytes32 newPresaleRoot) external onlyOwner {
        _presaleMerkleRoot = newPresaleRoot;
    }

    function togglePublicSale() external onlyOwner {
        require(! isPresaleActive, "Presale is still active");
        
        isPublicSaleActive = !isPublicSaleActive;
        
        emit PublicSaleToggled(isPublicSaleActive);
    }

    function togglePresale() external onlyOwner {
        require(! isPublicSaleActive, "PublicSale is already active");
        
        isPresaleActive = !isPresaleActive;

        emit PreSaleToggled(isPresaleActive);
    }

    // Finance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0xe0749181CB74a71187A4F2d510E9f68375A7070d).transfer(balance * 25 / 100);
        payable(0x5c70c527c74fDff309AC71702a50348361AfA163).transfer(balance * 25 / 100);
        payable(0xE81EF5e6f722D6c38ab456DAb4B5F62eF4FefC25).transfer(balance * 25 / 100);
        payable(0xb1E4f2F2E15897adb32ebB4A8f28f3B0EA7C5309).transfer(balance * 25 / 100);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// https://getfuckd.xyz / @GetFuckdNFT
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xxOXWWNWWMMMWNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'....;,',:okKK0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,      ......;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.  ....''',;,...:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:   .,,;cc:;:clc;. .xWMWN0xxxOOO0KXXNNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.  .;:::ccclc:,....lKWNd'........''',,;;:::::xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWo   '::::cc:,...;c:.,oxd'  .''...,:ccc::::::'.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.  .;:;;'.....':odc.  .........  .cdl,.......xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  ''.   ',.   ,oo' .collloo;.   ;dc.     'xNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.      'c'.,  .:o, .co;....     ;dc..lddkKWMXOXNNMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'  .   .::.:l.  ':. 'cl,         'lc..o00Ododl:llo0kkNX0NMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMNk;. .:l.  .c; .'.      .,cc;;;.    . ':..lo;,'.',,''''',c:ckOk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMXo,..,d0d.  .c;     ..',. .;'...   .::..;..dl.''';:oxxolccc:,,,:oxx0WWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMk,.,xXXKo.  .c:.     .:d:..'....   .cc..,..:,  .   'dl..........'..;ldKMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMN0ONMWXKd.  .:l..,.  .lo, .'.lOx,  .cc..,.   .cl,. .'.           ....'ck0KWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWNXXKKKOxo.   .c;..  .;cl' ''.,:,....ll..,.   'kNO.         ..       .;,,oxKWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMN0dlc;,'.......       . ..',.'c..',''',;;;:c;..'.   ,0Wx.    .:c;,....  ....'..;xXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWNk,...',;::ccclllllloool'  ..  .,.  .                 :XNl     '0MWXKOkxdooooc'   .oKMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMXx. ,kXNWWWMWWWWNXXXKK0kx,               .,;;,..       cNX;     ,KMMMMMMMMMMMMMXk;.  'xNMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWKc.  lWMMMNx:;;,,'.....      .;c:.      'd0K0kkxxo,     cN0'     ,kkKWMMMMMMMMMMMMNk,   ;OWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWXd.   oWMMMX;                 cXMK;     ,0WKl'....lOc    :NO'      . cXMNOoxXMMMMMMMMXo.  .dNMMMMMMMMMMMMM
// MMMMMMMMMMMMMNKl.   oWMMMX:                 ;KMX;    .kMXc       ,,    :NO.     .. ;XMO'  'xNMMMMMMMW0:   cXMMMMMMMMMMMM
// MMMMMMMMMMMMMNKc    lNMMMXc....        .    '0MX:    ,KWx.             :NO'   'oO: ;KWx.    ;OWMMMMMMMNo.  lNMMMMMMMMMMM
// MMMMMMMMMWXKK0x;    :XMMMWXKKK0o.  ,'       .xMNl    :XN: ..           :XK:.;d0x;..dWWo      .xWMMMMMMMNo. .kMMMMMMMMMMM
// MMMMMMMW0c'.....    .dKWMWKxdol:. .lc        oWWd.   cXX; ':'.    ;c.  ;KWXK0d' .;xNMWo  .    '0MMMMMMMMK,  lWMMMMMMMMMM
// MMMMMMNd,','',,;'...'..dW0,      .cx;        lNMk.   cXX: ,k0Ol. .x0,  ,0WMWo   :0NWMWo .c:   .xMMMMMMMMNl  cNMMMMMMMMMM
// MMMMMNx..;c:,,:c:,;cc;.'O0' ..   :00;  ..    :NMO.   :KNl ,0NXx. .xK;  ,OXXK0c. .cKMMWo .dx.  .kMMMMMMMMWo  cNMMMMMMMMMM
// MMMMWKd:'':ll;:l:;ll:'.,OO' ..   cNX:  ..    ;XMO.   ,0Wx..xXKl. .OX:  ,Ok;.c0k,  ,OWWd .xo.  ;dOWMMW00WNc .xWMMMMMMMMMM
// MMMMMWKOx:..::;:;;;..:dkX0, .    cNWo  .'    ,KMO.   .dWK; ':;. .oNNc  'kx.  ,OKo. .kWx..'. .l0c,kKNK;.kO' ,KMMMMMMMMMMM
// MMMMMMWNK0d,.',''.  '0MMMK;      :NMO'  .    ;KM0'    ;KWO,.  .;xNMK;  .xk.   .xX0:..dOoccld0WMO:o:ld. ', .xWMMMMMMMMMMM
// MMMMMMMMNXKOl....   'OMMMX;      ;KMWx.      oWM0'     cXWN0O0KNMMNo   .kO,    .lXNk;.:KMMMWMMMNKx. ...  .dNMMNNMMMMMMMM
// MMMMMMMMMWXK0x,     .OMMMX:      .OMMWO:...'dXMM0'      ;kNMMMMWNO:.   ,0X:      cKKo. cNMKo0KdO0:..:xl. .kWXKXNWMMMMMMM
// MMMMMMMMMMMNXKOc.   .dXXX0:  .    cXMMMWXKKNWMMWx.       .,llol:'.     .oOc       .. .:OWMXkd; .'':dOko'  ,o;;kxONWWMMMM
// MMMMMMMMMMMMMNKk'    .....  .;.    cXMMMMMMMMMXd. ...          .,cl'     ..    .c;,;oOXMMMM0:. .ckolkOxl,;,  ,OKNWWMMMMM
// MMMMMMMMMMMMMWX0o.       'ldxOo.    'o0NWWNXOo'  'oko'.       'xNX0l.    ..    .dOOO0KK0Oxd;';':kx;'lkOxdxl..dWMMMMMMMMM
// MMMMMMMMMMMMMWNK0kolclodkXMMNK0l.     ..,;,.  .,dKXK0OxollldxOXWWNXKOxolcoc.    ........    .oddo,.',lkxkx,.dNMMMMMMMMMM
// MMMMMMMMMMMMMMWNNXXNNNWMMMMMWNK0o'       .';cd0NMMMWNNNNNWWWMMMMMMWWWWWMWXd.                .,ol'.co:coo:''xWMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOxolllokKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:.......'',,;:codl,.. .',....,oKWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkkkkOO00KKKKXXXNXKOxolcccldONWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNNNWWWWWWMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "./ERC721Burnable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract GetFuckd is ERC721Burnable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public TOKEN_LIMIT = 4444;
    uint256 public ALLOWLIST_MINT_LIMIT_PER_WALLET = 2;
    uint256 public PUBLIC_MINT_LIMIT_PER_WALLET = 2;
    uint256 public OWNER_MINT_LIMIT = 400;

    bool public BASE_URI_FROZEN = false;

    bool public ALLOWLIST_MINTABLE = false;
    bool public PUBLIC_MINTABLE = false;

    bytes32 public merkleRoot;

    mapping(address => uint256) public publicMintCounterForAddress;
    mapping(address => uint256) public allowlistMintCounterForAddress;

    uint256 public mintCounterForOwner;
    uint256 public burnedTokenCounter;

    Counters.Counter private _tokenIdCounter;
    string public baseTokenURI = "https://getfuckd.xyz/metadata/";

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setDefaultRoyalty(msg.sender, 800);
    }

    function allowlistMint(uint256 amount, bytes32[] calldata merkleProof)
        public
    {
        require(
            ALLOWLIST_MINTABLE == true,
            "GetFuckd: Allowlist not ready to get fuckd! (Allowlist mint closed)"
        );
        require(
            allowlistMintCounterForAddress[msg.sender] + amount <=
                ALLOWLIST_MINT_LIMIT_PER_WALLET,
            "GetFuckd: You're already fuckd enough! (Limit reached)"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "GetFuckd: Invalid Proof"
        );

        mintMultiple(amount, msg.sender);
        allowlistMintCounterForAddress[msg.sender] =
            allowlistMintCounterForAddress[msg.sender] +
            amount;
    }

    function mint(uint256 amount) public {
        require(
            PUBLIC_MINTABLE == true,
            "GetFuckd: Public not ready to get fuckd! (Public mint closed)"
        );
        require(
            publicMintCounterForAddress[msg.sender] + amount <=
                PUBLIC_MINT_LIMIT_PER_WALLET,
            "GetFuckd: You're already fuckd enough! (Limit reached)"
        );

        mintMultiple(amount, msg.sender);
        publicMintCounterForAddress[msg.sender] =
            publicMintCounterForAddress[msg.sender] +
            amount;
    }

    function ownerMint(uint256 amount) public onlyOwner {
        require(
            mintCounterForOwner + amount <= OWNER_MINT_LIMIT,
            "GetFuckd: You're already fuckd enough!"
        );

        mintMultiple(amount, msg.sender);
        mintCounterForOwner = mintCounterForOwner + amount;
    }

    function mintMultiple(uint256 amount, address tokenReceiver)
        internal
        virtual
    {
        require(
            TOKEN_LIMIT >= amount + _tokenIdCounter.current(),
            "GetFuckd: No fucks given (All Tokens minted)"
        );

        for (uint256 i; i < amount; i++) {
            _mint(tokenReceiver, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }

    function withdrawal() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintableStages(bool _allowlistMintable, bool _publicMintable)
        public
        virtual
        onlyOwner
    {
        ALLOWLIST_MINTABLE = _allowlistMintable;
        PUBLIC_MINTABLE = _publicMintable;
    }

    function setBaseURI(string memory _baseTokenUri) public virtual onlyOwner {
        require(!BASE_URI_FROZEN, "GetFuckd: BaseURI can't be changed anymore");
        baseTokenURI = _baseTokenUri;
    }

    function freezeBaseURI() public virtual onlyOwner {
        BASE_URI_FROZEN = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - burnedTokenCounter;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        burnedTokenCounter = burnedTokenCounter + 1;
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

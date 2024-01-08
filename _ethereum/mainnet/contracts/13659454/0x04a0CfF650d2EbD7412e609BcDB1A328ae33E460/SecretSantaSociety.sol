// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";

// @author: wenbali.io

// ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// ccccccccccccccccccccccccccccc:::;:::;:::ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// ccccccccccccccccccccccccccc;............,:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccc;............ .;ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccc,..............':::::::::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccc,..............';:::::::::;;;;;;;;::::ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccc;. ........';coodddddddddooollccc:::::;;;;;;:cccccccccccccccccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccc:'........cdddddddddddddddddddddddddddollcc::;;;;;::ccccccccccccccccccccccccccccccccccccccccc
// ccccccccccccccccccccccccccc:;'.....,oddddddddddddddddddddddddddddddddddoolc::;;;;::cccccccccccccccccccccccccccccccccccc
// ccccccccccccccccccccccccccccccc::::;,coddddddddddddddddddddddddddddddddddddddolc:;;;;:ccccccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccccccccccc;,;clodddddddddddddddddddddddddddddddddddddddddolc:;;;::ccccccccccccccccccccccccccccc
// cccccccccccccccccccccccccccccccc:,,:llloddddddddddddddddddddddddddooolcc::loddooolcc::;,'',:ccccccccccccccccccccccccccc
// cccccccccccccccccccccccccccccc:;;:llllloddddddddddddddddooolc:::;,'........',''.............';:cccccccccccccccccccccccc
// cccccccccccccccccccccccccccc:;;:llllcc:clolclooolcc::;,,''....................................,cccccccccccccccccccccccc
// cccccccccccccccccccccccccc:;;;::;,'..........''................................................,:cccccccccccccccccccccc
// cccccccccccccccccccccccc;'..'....................................................................,:cccccccccccccccccccc
// ccccccccccccccccccccc:;...........................................................................':ccccccccccccccccccc
// cccccccccccccccccccc:'.............................................................................,ccccccccccccccccccc
// cccccccccccccccccccc,. .........................................................................'..':cccccccccccccccccc
// ccccccccccccccccccc;.....................................................................';cldkOKOc,:cccccccccccccccccc
// cccccccccccccccccc;...................................................................:dOKXNWWWWNN0c;cccccccccccccccccc
// ccccccccccccccccc,..............................................'.';:ccloddc,'..,cdkxocdKNNWWWWWWNNO:;ccccccccccccccccc
// cccccccccccccccc;.............'',;:ccllc;..........'',,;::;,..,:occk0000000xxkkxO0000OxllkXNWWWWWWNXx::cccccccccccccccc
// ccccccccccccccc:.......,:coxk0KKXNNNNNWNOoc,,codxkkkOO00000koodxkxxO0000000000000000000kocxKNWWWWWNX0l;:ccccccccccccccc
// ccccccccccccccc,.';cdk0XNWWWWWWWWWWWWWWWNXxlxO000000000000000000000000000000000000000000OdcdKNWWWWNNO:':ccccccccccccccc
// ccccccccccccccc;lOKXNWWWWWWWWWWWWWWWWWWNXkldO000000Oxddxk000000000000000000OkxdxkO0000000OdcdXNWWWWNXd;:ccccccccccccccc
// cccccccccccccc:lOXXNNWWWWWWWWWWWWWWWWWNN0ook0000Od:;;;;,',lk000000OO00000xc,',;;;;:d000000OdcxNWWWWWNKo;:cccccccccccccc
// ccccccccccccc::xXXNNWWWWWWWWWWWWWWWWWWWNxlxO000Ol':xOOOkdc,lO000KOdx0000Oc,cdkO0Od:,o000000OllKWWWWWWN0l;:ccccccccccccc
// ccccccccccccc:l0XXXNNWWWWWWWWWWWWWWWWWNKolk00000xxOkdddxxxxO00000kox00000OxxxxdddOOxx00000Ox::OWWWWWWNNOc;ccccccccccccc
// ccccccccccccc:dXXXXNNWWWWWWWWWWWWWWWWWNOloO0000000xlodxdddodO0K00klx0000Ododxdddook0000000Ol;dXWWWWWWWNXx;:cccccccccccc
// cccccccccccc::lkXXXNWWWWWWWWWWWWWWWWWWNkldO000000OodxddllddlxKK00kld0000xldddolokdo0000000kldXWWWWWWWWWNKo;:ccccccccccc
// cccccccccccc:,,xXXXNWWWWWWWWWWWWWWWWWWNkldO0000000doxdoooxolkKK00Ood0000kloddooxkox0000000xo0WWWWWWWWWWNNOc;ccccccccccc
// ccccccccccccc;cOXXXNWWWWWWWWWWWWWWWWWWNOcldkO000000xddooollx0000K0ooO0000xlloooddx00000000ddXWWWWWWWWWWWNXo;:cccccccccc
// ccccccccccccc;l0XXXNWWWWWWWWWWWWWWWWWWNKo;;lO0000000OxdddkOO000000dlk0000OkxdddkO00000000xoONWWWWWWWWWWWNNOc;cccccccccc
// ccccccccccccc;l0XXXNWWWWWWWWWWWWWWWWWWWNX0kookkkOO0000000000000000kld00000000000000OkxxdocxXWWWWWWWWWWWWWNXd;:ccccccccc
// ccccccccccccc;cOXXXNWWWWWWWWWWWWWWWWWWWWNNN0ocoooddxkO000000000000OooO0000000000OkxdooooclKNWWWWWWWWWWWWWNN0c;ccccccccc
// ccccccccccccc:cOXXNNWWWWWWWWWWWWWWWWWWWWWWWNKocoooooodxO00000000000xlx00000000Okdoooooc:lONWWWWWWWWWWWWWWWNXx;:cccccccc
// ccccccccccccc::kXXNNWWWWWNXXWWWWWWWWWWWWWWWWNKocooooooodxO0000000000olk000000kdoooool:,:ONWWWWWWWWWWWWWWWWNN0c;cccccccc
// ccccccccccccc:;dXXNNWWWWWXkONNWWWWWWWWWWWWWWWNKoclclooooodx000000000kldO000OxdoooooclkOKNWWWWWWWWWWWWWWWWWWNKo;:ccccccc
// cccccccccccccc;oKXXNWWWWW0x0XNNWWWWWWWWWWWWWWWNKd;,:cloooooxO00000000xldO0OxdooooclxKNNNWWWWWWWWWWWWWWWWWWWNXk::ccccccc
// cccccccccccccc;l0XXNWWWWNkxKXXXNWWWWWWWWNXNWWWWWXkx0kolcloodxO00000000xldOxdoolclxKNWWWWWWWWWWWWWWWWWWWWWWWNNOc;ccccccc
// cccccccccccccc;cOXXNWWWWKxxO0KXXNNWWWWWNOxKWWWWWWWWWWN0dc,;;:oO00000000xlllccldOXNWWWWWWWWWN0KNWWWWWWWWWWWWNNKl;ccccccc
// cccccccccccccc::kXXNWWWW0d:,l0XXNNWWX0kkoox0NWWWWWWNKkxxxxkkdoxddk000000x::cloxkKNWWWWWWWWN0olxOKNWWNNNWWWWWNKo;ccccccc
// cccccccccccccc::kXXNWWWWNX0dd0XXNWWKxkxlco:lKWWWWNOddkKNWWWWNK00ocoxkOOxdoONNX0kxdkKNWWWWNOcccldxxKNXOKWWWWWNXd;:cccccc
// cccccccccccccc::kXXNWWWWWWWOxKXXNWXxO0olcl:oXWWWKdoONWWWWWWWWNXOlcdxdl:oOKNWWWWWNKxokXWWWNd;lc;dOkd0NkkNWWWNNXk::cccccc
// cccccccccccccc::kXXNWWWWWWNkxKXXNWOdKOd00kOXNWNOlxXWWWWWWWWN0occxXWWNXxokXWWWWWWWWNKdo0NWWKxddOxxKddX0dONWWNXX0c;cccccc
// cccccccccccccc;cOXXNWWWWWWNkxXXXXN0d00oONWWWWKxlkNWWWWWWWN0ocdkKNNNWWWNOdokXWWWWWWWWXxlONWWWNNNxxXdoOo;oXWNXX0kl;cccccc
// cccccccccccccc;c0XXNNWWWWWNxkXXXXNXkdKOox0KOxoxKNWWWWWNKkl:cxkkxxxkOOOxddoccdKNWWWWWWNOodOXWWNko00olc;lOXNNXx;'';cccccc
// cccccccccccccc;c0XXXNNWWWWNkkXXXXXNXkokOkxxxOXNWWWNX0dlccclkX0dokXKxokK0dO0c':lxKNWWWWWXOddxxdd0OldOdd0XXNNNx,,;:cccccc
// cccccccccccccc;l0XXXXNNWWWNkxXXXXXXNN0doxk0KXXK0kxdol;cOXxokOo:lkOkooxkdoxkooxlcoddkKXNWWNXK0OkdokXKxOXXXNNWKl;cccccccc
// cccccccccccccc;oKXXXXXNNWWNkxXXXXXXXNWNKkxdddddddxOKXKOOOoo0Ol;dKKxlk0kod0OdoxOXNKkxddxxxxxxdddkKNWXxkXXXXNNNd;:ccccccc
// ccccccccccccc::dXXXXXXNWWWNkxKXXXXXXNNWWWWNNNNNNNWWWWWWN0l:c:;;:clc:cllc:cclokNWWWWWNXK0OOO0KNNWWWWXkkXXXXXNWO::ccccccc
// ccccccccccccc:;ldokXXNNWWWWOdKXXXXXXXNNWWWWWWWWWWWWWWWWWKdx0OkkxxxxxxxkkkO0KkkXWWWWWWWWWWWWWWWWWWWWXxkXXXXXNWKc;ccccccc
// ccccccccccccc:;'',dXXNNWWWW0d0XXXXXXXXNNWWWWWWWWWWWWWWWWXxkNWWWWWWWWWWWWWWWNkkXWWWWWWWWWWWWWWWWWWWWXxxXXXNNNWXo;ccccccc
// ccccccccccccccc:;:kXXNNWWWWKxookXXXXXXNNWWWWWWWWWWWWWWWWXxx0XWWWWWWWWWWWWWWNkkNWWWWWWWWWWWWWWWWWWWWXxxXXXNNWWNd;:cccccc
// cccccccccccccccc;l0XXNWWWWWNklcdKXXXXXNNWWWWWWWWWWWWWWWWNk:cONNWWWWWWWWWWN0dokNWWWWWWWWWWWWWWWWWWWWKxkXXXNNWWNk::cccccc
// ccccccccccccccc::xXXXNNWWWWWNXOd0XXXXXXNNWWWWWWWWWWWWWWWWXOdxNWWWWWWWWWWWNxokKWWWWWWWWWWWWWWWWWWWWW0xOXXXXNWWWOc:cccccc
// cccccccccccccc:;oKXXXNWNWWWWWWXxxXXXXXXXNNWWWWWWWWWWWWWWWWNkdKWWWWWWWWWWWXdkNWWWWWWWWWWWWWWWWWWWW0xdd0XXXXNWWW0c;cccccc
// cccccccccccccc;:OXXXNNWWWWWWWWWKdOXXXXXXXNNWWWWWWWWWWWWWWWW0okXNWWWWWWWWWKdONWWWWWWWWWWWWWWWWWWWNklldKXXXXNWWWXl;cccccc
// cccccccccccccc;lKXXXNNWWWWWWWWWNOdOXXXXXXXNNWWWWWWWWWWWWWWWNxokKWWWWWWWWWOd0WWWWWWWWWWWWWWWWWWWWKxOKKXXXXXNWWWXo;cccccc
// ccccccccccccc:;oXXXXNNWWWWWWWWWWKlc0XXXXXXXXNNWWWWWWWWWWWWWWKdcxNWWWWWWWNkdXWWWWWWWWWWWWWWWWWWWNkxKXXXXXXXNWWWNd;:ccccc
// ccccccccccccc:;dXXXXXNNWWWWWWWNOlcco0XXXXXXXXNNWWWWWWWWWWWWWNOooONWWWWWWXxkNWWWWWWWWWWWWWWWWWWW0dOXXXXXXXXNWWWNx;:ccccc
// ccccccccccccc:;dXXXXXXNNWWWNXOo:okklo0XXXXXXXXXNNWWWWWWWWWWWWNXkdKNWWWWW0x0WWWWWWWWWWWWWWWWWWWXo:kXXXXXXXXNWWWNx;:ccccc
// ccccccccccccc:;oKXXXXXXXKOdl:.'oOOOklo0XXXXXXXXXXNNWWWWWWWWWWWWNkdKWWWWXxkNWWWWWWWWWWWWWWWWWWNxllcdKXXXXXNWWWWWk::ccccc
// cccccccccccccc;l0XXX0kdl:;;;',dOOOOOkloOkkKKKXXXXXNNWWWWWWWWWWWWXkdxkKXxdKWWWWWWWWWWWWWWWWWWNklxOd:oKXXXXNWWWWNx;:ccccc
// cccccccccccccc::oxoc:;;::::,'oOOOOOOOkolc:lcl0XXXXXNWWWWWWWWWWNWWN0xdddxKNWWWWWWWWWWWWWWWNWNklxOOOd:l0XXXNNWWWNx;:ccccc
// ccccccccccccc:;'',;:::::::;'cOOOOOOOOOOkkxlolo0XXXXNWWWWWWWWWWWWWWWWNKKXWWWWWWWWWWWWWWXOddxdlxOOOOOd:lKXXXNWWWNd;:ccccc
// cccccccccccc:,',;;;;;;::::';xOOOOOOOOOOOOOOOxlo0XXXNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKo;coodkOOOOOOOo;oXXXNNWWXl;cccccc
// ccccccccccc;',::;,,,,,',:,,oOOOOOOOOOOOOOOOOOxlo0XXXXNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWXdlxkOOOOOOOOOOOOc;kXXNNWWOc:cccccc
// cccccccccc:',:::::::::;;;':kOOOOOOOOOOOOOOOOOOxco0XXXXXNNNWWWWWWWWWWWWWWWWWWWWWWWWWXdokOOOOOOOOOOOOOOx;,xXXNWNx;:cccccc
// cccccccccc;';:::::::::::;'cOOOOOOOOOOOOOOOOOOOOkllOXXXXXXNNNWWWWWWWWWWWWWWWWWWWWWWKdokOOOOOOOOOOOOOOOOc.'xXNWKo;ccccccc
// ccccccccc:',::::::::::::;'lOOOOOOOOOOOOOOOOOOOOOkocxKXXXXXXNNNWWWWWWWWWWWWWWWWWWN0ookOOOOOOOOOOOOOOOOOd'.:ONNOc;ccccccc
// ccccccccc;',::::::::::::;':kOOOOOOOOOOOOOOOOOOOOOOdco0K0KXXXXNWWWWWWWWWWWWWWWWWXkodOOOOOOOOOOOOOOOOOOkl..,oXXd;:ccccccc
// ccccccccc,';:::::::::::::,';cldxkkOOOOOOOOOOOOOOOOOklll:lOXXXNNNWWWWWWWWWWWNOOOdokOOOOOOOOOOOOOOOkxoc;..;,:kkc:cccccccc
// cccccccc:'':::::::::::ccc:;,'.'',,;;::loxkOOOOOOOOOOOxodo:o0XXXXNNWWWWWWWWKxcclxOOOOOOOOOOkxdlc:;,'..',;:;',::ccccccccc
// cccccccc:'':::::::::::ccc::::;;;,,,'''..',;ldkOOOOOOOOOOx;.:xKXXXNNWWWWWNklokOOOOOOOOkxoc;,'...'',;;;:::::,.;cccccccccc
// cccccccc:',::::::::::::ccc:::cc::::::::;;,'..,cxOkxkOOOOx;,::cdkXXK0XWNOo';kOOOOOOOkl;'..',;;;::::::::::::;',cccccccccc
// cccccccc;',::::::::::::cccc:::::::::::::::;;,'.';,',:ldOk:,ll:;:oxc,okoc:,ckOOkxxxc,..,,;::::::::::::::::::'':ccccccccc
// cccccccc;',:::::::::::ccccccc:::::::::::;;::;;;,',,,'.'okc,cooolc:::::clc,ckkd;'''..,,',,,,;;::::::::::::::,';ccccccccc
// cccccccc;';:::::::::ccccccccccc::::::::;',:::::::::::;':kl,coooooooooollc,:ko'.'',',,.'::'';;;:::::::::::::;';ccccccccc
// cccccccc,';:::::::::cccccccccccc:::::::;'',,:::::::::c,;xd,:oooooooooooll';kc.';;:'':'.,:,';:::::::::::::::;';ccccccccc
// cccccccc,';::::::::::cccccccc:::::::::::'..;:::::::::c;,dx;;looooooooolll',xl.';::;.';..,;'.;:::;,::::::::c;';ccccccccc
// cccccccc;';::::::::::ccccccccc::::::::::'.';:::::::::c;,ok;,looooooooooll',dl.';:::,.';..,:'.;:;'';::::cccc:',ccccccccc
// cccccccc;';::::::::::ccccccccc::::::::::'.';:::::::::c;,lk:,looooooolooll,'ol.';:;;;'.:;..,,';:,..;cccccccc:',ccccccccc
// cccccccc;';:::::::::::cccccc::c:::::::::,.,::::::::::::,lk:,colloooooolll;'oo.':::;;'';;..,;::c:..;cccccccc:',ccccccccc
// cccccccc;',:::::::::::cccccc::::::::::::,.,::::::::::c:,ckc'cooolllllllll;'lo'.;:::::;,,,;:::cc:'.:cccccccc;';ccccccccc
// cccccccc;',:::::::::::ccccccc::::::::::;'';:::::::::cc:,ckc'cooolllllllll:'lx,.;::::::::::::::c:..:cccccccc,':ccccccccc
// cccccccc:',:::::::::::cccccccc:::::::::;.';:::::::::cc:,ckc':llllllllllll:'cx;.;:::::::::::::cc;..:cccccccc,':ccccccccc

contract SecretSantaSociety is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextGiftedAmount;

    // Provenance - Artwork Sequence Established Beforehand and Untouched
    string public constant PROVENANCE_HASH =
        "ae7bef7dc7ffab5f1d74ad39232f62f2166369307e3f60809b34a5ec7eb53940";

    // Donation Wallet - secretsantasociety.eth
    // All outgoing transactions to be monitored for donations
    // see withdraw() function - Hardcoded 10%
    address public donationWallet = 0x27632f8E0c9951d9E9c97e7AeC18a85d2D5188dc;

    // Contract URI
    string private _contractURI;
    // Unrevealed URI
    string private _unrevealedURI;

    // Sale
    // actual supply qty is one less (gas savings in comparison operations)
    uint256 public constant NFT_SUPPLY = 5556; //actually 5555
    uint256 public constant MAX_TOKENS_PRESALE = 8; //actually 7
    uint256 public constant MAX_TOKENS_PUBLIC_SALE = 16; //actually 15
    uint256 public constant MINT_PRICE = 0.055 ether;

    // Dates
    uint256 public constant PRESALE_START_TIME = 1637524800; // 2:00 pm CST November 21th 2021
    uint256 public constant PRESALE_STOP_TIME = 1637784000; // 2:00 pm CST November 24th 2021
    uint256 public constant PUBLIC_SALE_START_TIME = 1637956800; // 2:00pm CST November 26th 2021

    // Start/pause sale
    bool public saleStarted; //defaults to false

    // array of nice listed addresses
    mapping(address => bool) public niceListedAddresses;
    // array of ipfs CIDs mapped to tokenIds
    mapping(uint256 => string) private _tokenUriList;
    // array of presale minters
    mapping(address => uint256) public mintedOnPresale;

    // Events
    event SaleStateFlipped(bool state);
    event PresaleMinted(address indexed _who, uint8 indexed _amount);
    event Minted(address indexed _who, uint8 indexed _amount);
    event GiftMinted(address recepient);
    event FundsWithdrawn(uint256 balance);
    event FallbackHit(address indexed _who, uint256 indexed _amount);

    constructor() ERC721("Secret Santa Society", "SSS") {
        // skip the 0; gas savings
        _nextTokenId.increment();
        _nextGiftedAmount.increment();
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1; // total supply is one less than next id
    }

    function giftedAmount() public view returns (uint256) {
        return _nextGiftedAmount.current() - 1; // actual gifted is one less that next amount
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        if (!_hasCID(tokenId)) {
            return string(_unrevealedURI);
        } else {
            return string(_tokenUriList[tokenId]);
        }
    }

    // verify that the CID has been set for the requested token
    function _hasCID(uint256 tokenId) private view returns (bool) {
        return !(bytes(_tokenUriList[tokenId]).length == 0);
    }

    function presaleMint(uint8 amountToMint) public payable {
        require(saleStarted == true, "Sale not active");
        require(block.timestamp > PRESALE_START_TIME, "Presale not started");
        require(block.timestamp < PRESALE_STOP_TIME, "Presale ended");
        require(niceListedAddresses[msg.sender], "Presale not listed");
        require(MINT_PRICE.mul(amountToMint) == msg.value, "Incorrect amount");
        require(
            mintedOnPresale[msg.sender] + amountToMint < MAX_TOKENS_PRESALE,
            "Presale too many"
        );
        require(
            amountToMint > 0 && amountToMint < MAX_TOKENS_PRESALE,
            "Presale 1-7 Santas"
        );

        mintedOnPresale[msg.sender] += amountToMint;
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
        emit PresaleMinted(msg.sender, amountToMint);
    }

    function mint(uint8 amountToMint) public payable {
        require(
            saleStarted && block.timestamp > PUBLIC_SALE_START_TIME,
            "Sale not active"
        );
        require(totalSupply() < NFT_SUPPLY, "Exceeds max supply");
        require(totalSupply() + amountToMint < NFT_SUPPLY, "Out of tokens");
        require(
            amountToMint > 0 && amountToMint < MAX_TOKENS_PUBLIC_SALE,
            "Mint: 1-15 per tx"
        );
        require(MINT_PRICE.mul(amountToMint) == msg.value, "Incorrect amount");

        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
        emit Minted(msg.sender, amountToMint);
    }

    /*
    Owner functions
    */

    // start/stop the sell
    function flipSaleState() external onlyOwner {
        saleStarted = !saleStarted;
        emit SaleStateFlipped(saleStarted);
    }

    // Updates the contract uri; just in case
    function setContractUri(string memory contractUri) external onlyOwner {
        _contractURI = contractUri;
    }

    // Updates the reveal uri; just in case
    function setUnrevealedUri(string memory unrevealedUri) external onlyOwner {
        _unrevealedURI = unrevealedUri;
    }

    // MFC!
    function giftMint(address[] calldata recipients) external onlyOwner {
        require(
            totalSupply() + recipients.length < NFT_SUPPLY,
            "Gifting exceeds max supply"
        );
        require(recipients.length > 0, "Recipients > 0");
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], _nextTokenId.current());
            _nextGiftedAmount.increment();
            _nextTokenId.increment();
            emit GiftMinted(recipients[i]);
        }
    }

    function batchTokenUriList(
        uint256 startingTokenId,
        string[] memory tokenUriList
    ) external onlyOwner {
        uint256 lastToken = startingTokenId + tokenUriList.length - 1;
        require(tokenUriList.length > 0, "List > 0");
        require(startingTokenId > 0 && _exists(lastToken), "Out of range");
        uint256 count;
        for (uint256 i = startingTokenId; i < lastToken + 1; i++) {
            _tokenUriList[i] = tokenUriList[count++];
        }
        delete lastToken;
        delete count;
    }

    function setTokenUri(uint256 tokenId, string memory tokenUri)
        external
        onlyOwner
    {
        require(_exists(tokenId), "Out of range");
        _tokenUriList[tokenId] = tokenUri;
    }

    // good boys and girls live here
    function batchNicelist(address[] memory niceList) external onlyOwner {
        for (uint256 i = 0; i < niceList.length; i++) {
            niceListedAddresses[niceList[i]] = true;
        }
    }

    // Owner withdraw and fund Donation Wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(donationWallet),
            (address(this).balance * 10) / 100
        );
        Address.sendValue(payable(msg.sender), address(this).balance);
        emit FundsWithdrawn(balance);
    }

    // A fallback function in case someone sends ETH to the contract
    receive() external payable {
        emit FallbackHit(msg.sender, msg.value);
    }
}

pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: GPL-3.0-or-later

/*

kkkkkkkOK0kkOXN0kkOXKkkkkkk0WMMM0kXMMMW0kkkkOXMMMNOdoodkXMWWKxoood0WMMMNOkkkk0NMMMW0doookXMWKkkkKMMN0kkkkONXkkkkkkkOK0kkOXMW0xoooxKWMXkkkOXMKkkONXkxkk
........l:...x0;..,Oo......:XMWX:,0MWMK;.....xMM0:.    .,ONx'.    .lXNd,......;kWXl.    .,kNl...oWM0,....'ko........c:...kXl.    .'xNd....dWo..'OKdl;.
;.   .':o,  .x0'  .kl   .,,oN0c'.'kNMMk.     cWNc   ',   :x'  .:.  .xd.  .,'.  '0d   ';.  ,0l   lWMd.     lx;.    ':o,  .xd.  .:.  'Oo    ;Xo  .kW0ocd
Wx.  '0WK,  .x0'  .kl   cNWWK;   .,kMWo   .  ,KX;   dO;..cl.  ;Kd..'dc   lKk;  .xc   oK,  .kl   lWWc  ..  :XMx.  ,0WK,  .xl   lX;  .xo    .xo  .kk..lx
Mk.  '0MK;   ok.  .kl   :KKXO'  .dllNX;  ',  .kX;   c00KXNx.  .x0KXNXc   oXO;  .dc   oNOxxkKc   lWK,  ,,  '0Mk.  ,KMK,  .xl   lX:  .dl     cc  .kO:;;;
Mk.  '0MK,   ..   .kl    ..l0:   ,;.oO'  :l   dWo    ..,lK0,    .':kXc   oXO;  .d:   oMMMMMWc   lWO.  cc  .xMk.  ,KMK,  .xl   lX:  .dl   . .,  .kKo;,,
Mk.  '0MK,   ..   .kl   .''lX0,  .;:xd.  ox.  cNNxc,'.   :X0o;,.   .xc   oXO;  .d:   oMMMMMNc   lWd   dd   lWk.  ,KMK,  .xl   lX:  .dl  .;.    .kMWdc:
Mk.  '0MK,  .oO'  .kl   cXNWWMXo. lNWl   .'   ,0NXXXXd.  'ONXXXK;   c:   lXO;  .dc   oNkooxKc   lNc   ..   ;Xk.  ,KMK,  .xl   lX:  .dl  .o,    .kMWOxo
Mk.  '0MK,  .x0'  .kl   cXNWMMMWKl;kX;        .xo..'kk.  ,o;..lKc   lc   oKk;  .xc   o0,  .kl   l0,        .Ok.  ,KMK,  .xl   lK;  .xo  .kl    .OWNNXc
Mk.  '0MK;  .x0'  .kl   ..'lNMMMMWdxO.  .dk,   ol   .'   :k'  .,.  .xo   ':,.  'Od   .,.  ,0l   lk.  'xx'   dk.  ,KMK,  .xx.  .,.  'Oo  .kO.   .kKdol.
MO,..:KMXc..'kK:..;Od......cXMMMMM0kx,..cXWo...o0o'.....:0Wk;.....'dNKc.      'xNXo'.....;ONo...od'..lNNl...dO,..cXMXc..,kNd'.....,kWd..,ONl...;0WWWNl
MNK00KWMWX00KNWK00KWN000000XWMMMMMWWNKK0XWMN000XWWXOxkkKWMMMN0kxkOXWMMN0dllooxKWWMMXOkkk0NMWX000XX000XMMX000XNK00XWMWX00KNMMXOkkk0NMMNK0KNWX000KNMMMWX

*/

/// @author: galaxis.xyz - The platform for decentralized communities.

import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC1820Registry.sol";
import "./ReentrancyGuard.sol";
import "./IERC777Recipient.sol";
import "./IERC777.sol";

import "./community_interface.sol";
import "./sale_configuration.sol";
import "./recovery.sol";
import "./IRNG.sol";
import "./dusty.sol";
import "./card_with_card.sol";
import "./token_interface.sol";

struct sale_data {
    uint256 maxTokens;
    uint256 mintPosition;
    address[] wallets;
    uint16[] shares;
    uint256 fullPrice;
    uint256 discountPrice;
    uint256 presaleStart;
    uint256 presaleEnd;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 dustPrice;
    bool areTokensLocked;
    uint256 maxFreeEC;
    uint256 totalFreeEC;
    uint256 maxDiscount;
    uint256 totalDiscount;
    uint256 freePerAddress;
    uint256 discountedPerAddress;
    string tokenPreRevealURI;
    address signer;
    bool presaleIsActive;
    bool saleIsActive;
    bool dustMintingActive;
    uint256 freeClaimedByThisUser;
    uint256 discountedClaimedByThisUser;
    address etherCards;
    address DUST;
    address ecVault;
    uint256 maxPerSaleMint;
    uint256 MaxUserMintable;
    uint256 userMinted;
    bool randomReceived;
    bool secondReceived;
    uint256 randomCL;
    uint256 randomCL2;
    uint256 ts1;
    uint256 ts;
}

struct sale_params {
    uint256 projectID;
    token_interface token;
    IERC721 ec;
    address dust;
    uint256 maxTokens;
    uint256 maxDiscount; //<--- max sold in presale across presale dust / eth
    uint256 maxPerSaleMint;
    uint256 clientMintLimit;
    uint256 ecMintLimit;
    uint256 discountedPerAddress; //<-- should apply to all presale
    uint256 freeForEC; //<-- for EC card holders
    uint256 discountPrice; //<-- for EC card holders - if zero not available should have *** dust ***
    uint256 discountDustPrice; //<-- for EC card holders - if zero not available should have *** dust ***
    uint256 fullPrice;
    address signer;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 presaleStart;
    uint256 presaleEnd;
    uint256 fullDustPrice;
    address[] wallets;
    uint16[] shares;
}

// check approval limit - start / end of presale

contract The_Association_Sales is
    sale_configuration,
    Ownable,
    recovery,
    ReentrancyGuard,
    dusty,
    card_with_card
{
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public immutable projectID;
    token_interface public _token;

    uint256 immutable _MaxUserMintable;
    uint256 _userMinted;

    uint256 _ts1;
    uint256 _ts2;

    address private immutable _DUST;
    IERC721 private immutable _EC;

    uint16 public batchNumber;

    mapping(address => uint256) _freeClaimedPerWallet;
    mapping(address => uint256) _discountedClaimedPerWallet;

    event RandomProcessed(
        uint256 stage,
        uint256 randUsed_,
        uint256 _start,
        uint256 _stop,
        uint256 _supply
    );
    event batchWhitelistMint(uint16 indexed batchNumber, address receiver);
    event ETHPresale(address from, uint256 number_of_items, uint256 price);
    event ETHSale(address buyer, uint256 number_to_buy, uint256 ethAmount);
    event Allowed(address, bool);

    modifier onlyAllowed() {
        require(
            _token.permitted(msg.sender) || (msg.sender == owner()),
            "Unauthorised"
        );
        _;
    }

    // the constructor takes the bare minimum to conduct a presale and sale.

    constructor(sale_params memory sp)
        dusty(
            sp.dust,
            sp.signer,
            sp.fullDustPrice,
            sp.discountDustPrice,
            sp.maxPerSaleMint,
            sp.wallets,
            sp.shares
        )
        card_with_card(sp.signer)
    {
        projectID = sp.projectID;
        _EC = sp.ec;
        _token = sp.token;
        _DUST = sp.dust;
        _MaxUserMintable = sp.maxTokens - (sp.clientMintLimit + sp.ecMintLimit);

        _maxSupply = sp.maxTokens;
        _maxDiscount = sp.maxDiscount;

        _discountedPerAddress = sp.discountedPerAddress;
        _discountPrice = sp.discountPrice;
        _fullPrice = sp.fullPrice;

        _saleStart = sp.saleStart;
        _saleEnd = sp.saleEnd;

        _presaleStart = sp.presaleStart;
        _presaleEnd = sp.presaleEnd;

        _maxFreeEC = sp.freeForEC;
    }

    function _split(uint256 amount) internal {
        //  console.log("num wallets",wallets.length);
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = (amount * shares[j]) / 1000;
            if (j == wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent, ) = wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function setup(uint16 _batchNumber) external onlyAllowed {
        batchNumber = _batchNumber;
    }

    function checkDiscountAvailable(address buyer)
        public
        view
        returns (
            bool[3] memory,
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        bool _final = false;

        return (
            [false, false, true],
            _final, // _final,
            _discountedClaimedPerWallet[buyer], // EC
            presold[buyer], // Not in use.
            _token.availableToMint()
        );
    }

    function mint_approved(
        vData memory info,
        uint256 number_of_items_requested,
        uint16 _batchNumber
    ) external {
        require(batchNumber == _batchNumber, "!batch");
        address from = msg.sender;
        require(verify(info), "Unauthorised access secret");
        _discountedClaimedPerWallet[msg.sender] += 1;
        require(
            _discountedClaimedPerWallet[msg.sender] <= 1,
            "Number exceeds max discounted per address"
        );
        presold[from] = 1;
        _mintCards(number_of_items_requested, from);
        emit batchWhitelistMint(_batchNumber, msg.sender);
    }

    // make sure this respects ec_limit and client_limit
    function mint(uint256 numberOfCards) external {
        _discountedClaimedPerWallet[msg.sender] += numberOfCards;
        require(
            _discountedClaimedPerWallet[msg.sender] <= maxPerSaleMint,
            "Number exceeds max discounted per address"
        );
        require(checkSaleIsActive(), "sale is not open");
        require(
            numberOfCards <= maxPerSaleMint,
            "Exceeds max per Transaction Mint"
        );
        _mintPayable(numberOfCards, msg.sender, _fullPrice);
    }

    function _mintPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal override {
        _mintCards(numberOfCards, recipient);
    }

    function _mintCards(uint256 numberOfCards, address recipient)
        internal
        override(dusty, card_with_card)
    {
        _userMinted += numberOfCards;
        require(
            _userMinted <= _MaxUserMintable,
            "This exceeds maximum number of user mintable cards"
        );
        _token.mintCards(numberOfCards, recipient);
    }

    function _mintDiscountCards(uint256 numberOfCards, address recipient)
        internal
        override(dusty, card_with_card)
    {
        _totalDiscount += numberOfCards;
        require(
            _maxDiscount >= _totalDiscount,
            "Too many discount tokens claimed"
        );
        _mintCards(numberOfCards, recipient);
    }

    function _mintDiscountPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal override(card_with_card) {
        require(msg.value == numberOfCards.mul(price), "wrong amount sent");
        _mintDiscountCards(numberOfCards, recipient);
        // _split(msg.value);
    }

    function setSaleDates(uint256 _start, uint256 _end) external onlyAllowed {
        _saleStart = _start;
        _saleEnd = _end;
    }

    function setPresaleDates(uint256 _start, uint256 _end)
        external
        onlyAllowed
    {
        _presaleStart = _start;
        _presaleEnd = _end;
    }

    function setMaxPerSaleMint(uint256 _maxPerSaleMint) external onlyOwner {
        maxPerSaleMint = _maxPerSaleMint;
    }

    function checkSaleIsActive() public view override returns (bool) {
        if ((_saleStart <= block.timestamp) && (_saleEnd >= block.timestamp))
            return true;
        return false;
    }

    function checkPresaleIsActive() public view override returns (bool) {
        if (
            (_presaleStart <= block.timestamp) &&
            (_presaleEnd >= block.timestamp)
        ) return true;
        return false;
    }

    function setWallets(
        address payable[] memory _wallets,
        uint16[] memory _shares
    ) public onlyOwner {
        require(_wallets.length == _shares.length, "!l");
        wallets = _wallets;
        shares = _shares;
    }

    receive() external payable {
        _split(msg.value);
    }

    function tellEverything(address addr)
        external
        view
        returns (sale_data memory)
    {
        // if community module active - get the community.taken[msg.sender]

        token_interface.TKS memory tokenData = _token.tellEverything();
        return
            sale_data(
                _maxSupply,
                tokenData._mintPosition,
                wallets,
                shares,
                _fullPrice,
                _discountPrice,
                _presaleStart,
                _presaleEnd,
                _saleStart,
                _saleEnd,
                _dustPrice,
                tokenData._lockTillSaleEnd,
                _maxFreeEC,
                _totalFreeEC,
                _maxDiscount,
                _totalDiscount,
                _freePerAddress,
                _discountedPerAddress,
                _token.tokenPreRevealURI(),
                _signer,
                checkPresaleIsActive(),
                checkSaleIsActive(),
                checkSaleIsActive() &&
                    (fullDustPrice > 0 || discountDustPrice > 0),
                _freeClaimedPerWallet[addr],
                _discountedClaimedPerWallet[addr],
                address(_EC),
                _DUST,
                _ecVault,
                maxPerSaleMint,
                _MaxUserMintable,
                _userMinted,
                tokenData._randomReceived,
                tokenData._secondReceived,
                tokenData._randomCL,
                tokenData._randomCL2,
                tokenData._ts1,
                tokenData._ts2
            );
    }
}

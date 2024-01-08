pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
//import "./console.sol";
import "./ECDSA.sol";
import "./SkeletonCrew.sol";

/* 

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM
Nk,'cooooooooooolcOWMMMMMMWKl,cooooooooooo:oXMMMMMMMMMMMMMMMMMN0xd0MMMMMMMMMMMMMMMMMMMMMMMMXkddddddddddddddddxxxxxxdclxkkxxxxkkkkkkxxxxxxkk0NN0ddkOxOO
O' .:dx0KKKKKKKKKolKMMMMMM0;.:0KKKKKKKKOxo;lXMMMMMMMMMMMMMMNKOkkkx0MMMMMMMMMMMMMMMMMMMMMMWk,.o0KKKKKKKKKKKKKKK000OxllxOdc:lkKOdok0KKkl;;ooOdokOOOdlOOO
O'    .;kKKKKKKKK0ldNMMMMXc.'kKKKKKKKKx;..:OWMWNXKKKXXNWWKdlxOKK0dxKK00XWNKKKXNNKK00KNWMM0,.c0KKKKKK00OOOOO0KKKKKd;l0Kkc;. 'lod0KKKx' .:cxKKd;oddXOooo
NOxo;  .lKK00KKKKKklkWMMWx..dKK0KKKKKKo:d0NWX00000O0000K0c.'kKKKKOkkkdlxdldkkkkkkkkkkxkXKc.cOK0kdl:,'.....,d0KKKk,,kKKOdOO; .cOKKKx. ,O0dkKK0:'xWMMMMM
MMMMK, .oK0dd0KKKKKdl0MM0'.c0Kdd0KKKKKdlKMXkxOKKkl:oOKKKO: 'kKKK0dcclldl;dKKKOOO0KKKKKxl,  'cc,...,;::'  .o0KKKKl.,OKKKkxX0, :0KKO, 'OXxxKKK0:.cNMMMMM
MMMMK, .dK0:,xKKKKK0ooXX:.;OKx,:0KKKKKdl00ld0KKOdc.'xKKKKl.'kKKK0l'',l:.cxoc:'.':x0KKK0l'.  .:okKXNWNk,.;kKKKKKKl..dKKKKxxXk.'xKKd..dXxx0KKKx. lNMMMMM
MMMMO' .xKO; ;OKKKKKOlol..xKO: ,OKKKKKxld::OKKKkO0xk00kol;.'kKKK0xOXXk,.;clllodxkOKKKK0dO0xkXWMMMMMXo..l0KKKKKKk:. .o0KK0kxx;.cx0k;,dxx0KK0d' 'OMMMMMM
MMMMk. 'kKk' .c0KKKKKk;..lKKl. 'kKKKKKkc,.c0KKKOO0Oxoolld:.'kKKK0x0MMNkldk0KK0dc,:kKKK0dOMMMMMMMMW0;.,xKKKKKK0dlkk; .,ok00Okxdl;:odxkO0Oxl,. ;OWMMMMMM
MMMWx. ,OKx'  .dKKKKKKo.:OKx'  .xKKKKKO:. :0KKKKKkdk0NNX0l.'kKKK0xkWNx,l0KKKKdl;..dKKK0dOMMMMMMMNd..cOKKKKKKkloKWMXx:...',;;:clxkdc:;,'....:xXMMMMMMMM
MMMWo. :0Kd;.  ,kKKKKK0xOKOl:. .xKKKKK0c. .xKKKKK00000000d..oKKKK0kko..xKKKKKkxo,:kKKKKxkNMMMMW0:.,xKKKKKK0dcxNMMMMMWKOxoodxOXWMMMWXOkxxk0XWMMMMMMMMMM
MMMNl  c0Kolx,  :OKKKKKKK0ook, .dKKKKK0l:' 'xKKKKKKKKKKK0d' .lOKKKK0l..c0KKKKK0OxxkKKKKklkNMMNx'.cOKKKKKKOll0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNc .lKKloXx. .l0KKKKKKdl0K; .oKKKKKKook; .:dOKKKKKOkk0Xk;  .:oxOOo'  ,okOOkoc,..ldl:;:kNMKc.'d0KKKKK0xlxXMMMMMMWXkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMX: .oK0ldNNl  .lOKKKKkckWX:  lKKKKKKooXXd;...,;::cokXWMMNkc,....,lOd'. .';lxOx,.,ldk0NMWk,.:kKKKKKKOolOWMMMMMWKxooolxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMK, .xK0ldWMXc   .,:clcdNMNc  cKKKKKKdl0MMNKkdodxOKWMMMMMMMWNKOxoxXMMNOxxk0NMMWK0NWMMMMXl..o0KKKKKKk:;okkkkkkxddx0KxcdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MWXd..l0KKdlkKXXkc;'.  .lXWN0c.'xKKKKKKOooOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.;kKKKKKKKKOxxxxxxxxkk0KKKxckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
k:;ldkKKKKKkdockWWWNKOk0NKo;codOKKKKKKKK0kdloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo. ;OKKKKKKKKKKKKKKKKKKKKKKKxcOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
. .ldddddddddo;xWMMMMMMMNc  ;oddddddddddddd:cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  .ckkkkkkkkkkkkkkkkkkkkkkdcxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
             .c0MMMMMMMMX:                .'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.   ......................,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:;;;;;;;;;;;:dXMMMMMMMMMNx:;;;;;;;;;;;;;;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'.......................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

*/

//// @author:  Blockchain platform powered by Ether Cards - https://ether.cards

contract metaZooSale is Ownable {
    using SafeMath for uint256;

    event WhiteListSale(uint256 tokenCount, address receiver, uint256 role);
    event PurchaseSale(uint256 tokenCount, address buyer);

    /* 
    using tokenIndex to retrieve tokenID to send.
    Sale with start at 5 eth and decrease by 0.1 eth every 15 minutes for 12 hours.
    */

    uint256 public startingPrice = 5 ether;
    // Whitelist time
    uint256 public whitelist_sales;
    uint256 public whitelist_sales_end;
    // DSP
    uint256 public sales_start;
    uint256 public sales_end;

    address public nft_sales;
    uint256 public sales_duration = 12 hours;
    bool public setupStatus = true;
    uint256 public maxDecreaseSold = 0;
    uint256 public maxDecreaseNFTs = 500;

    uint256 public whiteListSold = 0;
    uint256 public maxWhiteListNFTs = 4300;

    address public presigner;
    uint256 public whiteListPrice = 0.1 ether;
    mapping(address => uint256) public whitelist_claimed;

    address payable[] _wallets = [
        payable(0xA3cB071C94b825471E230ff42ca10094dEd8f7bB), 
        payable(0xA807a452e20a766Ea36019bF5bE5c5f4cbDE7563), 
        payable(0x77b94A55684C95D59A8F56a234B6e555fC79997c) 
    ];

    uint256[] _shares = [70, 180, 750];

    function _split(uint256 amount) internal {
        // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 1000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }
    function whiteListBySignature(
        address _recipient,
        uint256 _tokenCount,
        bytes memory signature,
        uint64 _role
    ) public payable {
        require(
            whiteListSalesActive(),
            "Sales has not started or ended , please chill sir."
        );
        require(_role == 1 || _role == 2, "One or Two none else will do");
        require(verify(_role, msg.sender, signature), "Unauthorised");
        require(msg.value >= _tokenCount * (whiteListPrice), "Price not met");
        uint256 this_taken = whitelist_claimed[msg.sender] + _tokenCount;

        whitelist_claimed[msg.sender] = this_taken;
        require(
            _role >= whitelist_claimed[msg.sender],
            "Too many tokens requested"
        );
        whiteListSold += _tokenCount;
        require(whiteListSold <= maxWhiteListNFTs, "sold out");
        SkeletonCrew(nft_sales).mintCards(_tokenCount, _recipient);
        _split(msg.value);
        emit WhiteListSale(_tokenCount, _recipient, _role);
    }

    function verify(
        uint64 _amount,
        address _user,
        bytes memory _signature
    ) public view returns (bool) {
        require(_user != address(0), "NativeMetaTransaction: INVALID__user");
        bytes32 _hash =
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(_user, _amount))
            );
        require(_signature.length == 65, "Invalid signature length");
        address recovered = ECDSA.recover(_hash, _signature);
        return (presigner == recovered);
    }

    function currentPrice() public view returns (uint256) {
        uint256 gap = block.timestamp - sales_start;
        uint256 counts = gap / (15 minutes);
        if (gap >= sales_duration) {
            return 0.2 ether;
        }
        return startingPrice - (counts * 0.1 ether);
    }

    function whiteListRemainingTokens() public view returns (uint256) {
        return maxWhiteListNFTs - whiteListSold;
    }

    function decreaseRemainingTokens() public view returns (uint256) {
        return (maxDecreaseNFTs + whiteListRemainingTokens()) - maxDecreaseSold;
    }

    constructor(
        uint256 _whitelist_sales,
        uint256 _sales_start,
        address _nft_sales,
        address _presigner
    ) {
        whitelist_sales = _whitelist_sales;
        whitelist_sales_end = _whitelist_sales + 3 days;
        sales_start = _sales_start;
        sales_end = sales_start + 12 hours;
        nft_sales = _nft_sales;
        presigner = _presigner;
    }

    function purchase(uint256 _amount) public payable {
        require(
            salesActive(),
            "Sales has not started or ended , please chill sir."
        );
        require(msg.value >= _amount.mul(currentPrice()), "Price not met");
        require(decreaseRemainingTokens() >= _amount, "sold out");
        maxDecreaseSold += _amount;
        SkeletonCrew(nft_sales).mintCards(_amount, msg.sender);
        _split(msg.value);

        emit PurchaseSale(_amount, msg.sender);
    }

    function whiteListMint(uint64 _amount, address _receiver) public onlyOwner {
        SkeletonCrew(nft_sales).mintCards(_amount, _receiver);
    }

    function salesActive() public view returns (bool) {
        return (block.timestamp > sales_start && block.timestamp < sales_end);
    }

    function whiteListSalesActive() public view returns (bool) {
        return (block.timestamp > whitelist_sales &&
            block.timestamp < whitelist_sales_end);
    }

    function sales_how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < sales_start, "Started");
        uint256 gap = sales_start - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function whitelist_how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < whitelist_sales, "Started");
        uint256 gap = whitelist_sales - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function changePresigner(address _presigner) external onlyOwner {
        presigner = _presigner;
    }

    function resetSalesStatus(
        uint256 _whitelist_sales,
        uint256 _sales_start,
        address _nft_sales,
        bool _setupStatus
    ) external onlyOwner {
        whitelist_sales = _whitelist_sales;
        whitelist_sales_end = _whitelist_sales + 2 days;
        sales_start = _sales_start;
        sales_end = _sales_start + 12 hours;
        nft_sales = _nft_sales;
        setupStatus = _setupStatus;
    }

    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    struct theKitchenSink {
        uint256 startingPrice;
        // Whitelist time
        uint256 whitelist_sales;
        uint256 whitelist_sales_end;
        // DSP
        uint256 sales_start;
        uint256 sales_end;
        address nft_sales;
        uint256 sales_duration;
        bool setupStatus;
        uint256 maxDecreaseSold;
        uint256 maxDecreaseNFTs;
        uint256 whiteListSold;
        uint256 maxWhiteListNFTs;
        address presigner;
        uint256 whiteListPrice;
        uint256 whiteListRemaining;
        uint256 decreaseRemaining;
    }

    function tellEverything() external view returns (theKitchenSink memory) {
        return
            theKitchenSink(
                startingPrice,
                whitelist_sales,
                whitelist_sales_end,
                sales_start,
                sales_end,
                nft_sales,
                sales_duration,
                setupStatus,
                maxDecreaseSold,
                maxDecreaseNFTs,
                whiteListSold,
                maxWhiteListNFTs,
                presigner,
                whiteListPrice,
                whiteListRemainingTokens(),
                decreaseRemainingTokens()
            );
    }
}

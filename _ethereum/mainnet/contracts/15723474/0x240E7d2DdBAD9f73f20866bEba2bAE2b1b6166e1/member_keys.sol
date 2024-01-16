// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces.sol";
import "./ERC721A.sol";
import "./Strings.sol";

//
//       ██████╗ ██╗ ██████╗  █████╗ ███╗   ██╗ █████╗ ███╗   ███╗███████╗███████╗   ██╗ ██████╗
//      ██╔════╝ ██║██╔════╝ ██╔══██╗████╗  ██║██╔══██╗████╗ ████║██╔════╝██╔════╝   ██║██╔═══██╗
//      ██║  ███╗██║██║  ███╗███████║██╔██╗ ██║███████║██╔████╔██║█████╗  ███████╗   ██║██║   ██║
//      ██║   ██║██║██║   ██║██╔══██║██║╚██╗██║██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║   ██║██║   ██║
//      ╚██████╔╝██║╚██████╔╝██║  ██║██║ ╚████║██║  ██║██║ ╚═╝ ██║███████╗███████║██╗██║╚██████╔╝
//       ╚═════╝ ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚═╝╚═╝ ╚═════╝
//
//
//
//
//                               .:~!7??77~^.          .^~7????7~^.
//                            .!Y5PPPPPPPPPPP5?^    :?5PGGGGGGGGGGP5?:
//                          :JPPPPY7~^:::^!J5PPP5!~5PPGPY7~^::^~7YPGGG5~
//                         7PPP5!.           ^YPPGGPP5~.          .!5GPGY.
//                        ?P5PJ.               ~7777!                JPPG5.
//                       ~P55Y                                        JPPPJ
//                       Y55P!         ~555555555555555555557         ^GPPP
//                       Y55P!         ~Y55555555555555555557         ^GPPP
//                       ~P55Y                                        JPPPJ
//                        ?P5PJ.               ~7777!                JPPG5.
//                         7PPP5!.           ^YPPGGPP5~.          .!5GPGY.
//                          :JPPPPY7~^:::^!J5PPP5!~5PPGPY7~^::^~7YPGGG5~
//                            .!Y5PPPPPPPPPPP5?^    :?5PGGGGGGGGGGP5?:
//                               .:~!7??77~^.          .^~7????7~^.
//
//
//
//         ███╗   ███╗███████╗███╗   ███╗██████╗ ███████╗██████╗     ██╗  ██╗███████╗██╗   ██╗
//         ████╗ ████║██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗    ██║ ██╔╝██╔════╝╚██╗ ██╔╝
//         ██╔████╔██║█████╗  ██╔████╔██║██████╔╝█████╗  ██████╔╝    █████╔╝ █████╗   ╚████╔╝
//         ██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗    ██╔═██╗ ██╔══╝    ╚██╔╝
//         ██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║    ██║  ██╗███████╗   ██║
//         ╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝   ╚═╝
//
//  Learn more at https://giganames.io/member-keys
//

contract GigaNamesMemberKeys is ERC721A {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant PRESALE_QTY = 1_000;
    uint256 public constant WALLET_MINT_LIMIT = 3;
    uint256 private constant TICKS_PER_WINDOW = 15;

    bool public selfMint = false;
    uint256 public presalePrice = 0.1 ether;
    // During public sale (after `PRESALE_QTY` minted), price is dynamically adjusted
    // starting from `publicSalePriceBase` and increasing by `publicSalePriceStep`
    // for each sale within `publicSalePriceWindow` minutes rolling window.
    // This means the price increases during high demand and gradually returns to `publicSalePriceBase`.
    // This is done to protect our existing users from newcomer activity bursts.
    uint256 public publicSalePriceBase = 0.2 ether;
    uint256 public publicSalePriceStep = 0.001 ether;
    uint256 public publicSalePriceWindow = 15; // minutes

    address private _owner;
    address private _minter;
    string private _metadataBaseURI;
    mapping(uint256 => uint256) private _ticks;
    mapping(uint256 => uint256) public _unclaimedReferralsByReferrerUid;

    modifier isOwner() {
        require(msg.sender == _owner, 'Not authorized');
        _;
    }

    constructor(string memory metadataUri) ERC721A("GigaNames.io Member Key", "GGNM") {
        _owner = msg.sender;
        _metadataBaseURI = metadataUri;
    }

    // This will refund any ETH above what's needed for the mint back to the sender
    function mint(uint256 qty, uint256 referredBy) external payable {
        require(tx.origin == msg.sender, "Smart contract mints not allowed");
        require(selfMint, "Self-mint not enabled yet");
        require(_totalMinted() + qty <= MAX_SUPPLY, "Sold out");
        require(balanceOf(msg.sender) + qty <= WALLET_MINT_LIMIT, "Per-wallet mint limit exceeded");

        uint256 refund;
        uint256 total = qty * effectivePrice();
        require(msg.value >= total, "Insufficient funds");
        if (msg.value > total)
            refund = msg.value - total;

        _updateMintState(qty, referredBy);

        _mint(msg.sender, qty);

        if (refund > 0) {
            (bool sent,) = msg.sender.call{value : refund}("");
            require(sent, "Could not process refund");
        }
    }

    function effectivePrice() public view returns (uint256) {
        if (_totalMinted() < PRESALE_QTY) // presale
            return presalePrice;
        else {
            // public sale
            uint256 tick = _latestTick();
            uint256 tickDuration = _tickDuration();
            uint256 salesPerWindow;
            for (uint256 i; i < TICKS_PER_WINDOW; i++) {
                salesPerWindow += _ticks[tick];
                tick = tick - tickDuration;
            }
            return publicSalePriceBase + salesPerWindow * publicSalePriceStep;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_metadataBaseURI, tokenId.toString(), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    // REFERRAL STUFF

    // User's referral UID is last 4 bytes of user address' keccak256()
    function referrerUid(address addr) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(addr)) & 0x00000000000000000000000000000000000000000000000000000000ffffffff);
    }

    // Returns number of claimable keys
    function claimableKeys(address addr) public view returns (uint256) {
        return unclaimedReferrals(addr) / 10;
    }

    // Returns number of keys referred by addr and not yet claimed
    function unclaimedReferrals(address addr) public view returns (uint256) {
        return _unclaimedReferralsByReferrerUid[referrerUid(addr)];
    }

    // Users can always claim their Member Key referral rewards here
    function claimKeys(uint256 keysToClaim) external {
        if (keysToClaim == 0 || keysToClaim > claimableKeys(msg.sender))
            keysToClaim = claimableKeys(msg.sender);
        require(keysToClaim > 0, "Nothing to claim");
        require(_totalMinted() + keysToClaim <= MAX_SUPPLY, "Amount to claim exceeds remaining supply");

        // note - claiming keys does not affect dynamic pricing
        if (_unclaimedReferralsByReferrerUid[referrerUid(msg.sender)] >= keysToClaim * 10)
            _unclaimedReferralsByReferrerUid[referrerUid(msg.sender)] = _unclaimedReferralsByReferrerUid[referrerUid(msg.sender)] - keysToClaim * 10;
        else
            _unclaimedReferralsByReferrerUid[referrerUid(msg.sender)] = 0;

        _mint(msg.sender, keysToClaim);
    }

    // PRIVATE STUFF

    function _updateMintState(uint256 qty, uint256 referredBy) private {
        _updateTicks(qty);
        if (referredBy > 0)
            _unclaimedReferralsByReferrerUid[referredBy] += qty;
    }

    function _updateTicks(uint256 qty) private {
        _ticks[_latestTick()] += qty;
    }

    function _latestTick() private view returns (uint256) {
        return (block.timestamp / _tickDuration()) * _tickDuration();
    }

    function _tickDuration() private view returns (uint256) {
        return publicSalePriceWindow * 60 / TICKS_PER_WINDOW;
    }

    // ADMIN STUFF

    function mintFor(uint256 qty, address addr, uint256 referredBy) external {
        require(msg.sender == _minter || msg.sender == _owner, "Not authorized");
        require(_totalMinted() + qty <= MAX_SUPPLY, "Sold out");

        _updateMintState(qty, referredBy);

        _safeMint(addr, qty);
    }

    function adminWithdraw(address payable recipient) external isOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool sent,) = recipient.call{value : address(this).balance}("");
        require(sent, "Could not process the withdrawal");
    }

    // Allows admin to rescue any ERC20 tokens should they be accidentally sent here
    function adminWithdrawToken(address token) external isOwner {
        IERC20(token).transfer(_owner, IERC20(token).balanceOf(address(this)));
    }

    function setMetadataBaseUri(string memory uri) external isOwner {
        _metadataBaseURI = uri;
    }

    function toggleSelfMint() external isOwner {
        selfMint = !selfMint;
    }

    function setMinter(address minter) external isOwner {
        _minter = minter;
    }

    function updatePricing(uint256 _presalePrice, uint256 _publicSalePriceBase, uint256 _publicSalePriceStep, uint256 _publicSalePriceWindow) external isOwner {
        presalePrice = _presalePrice;
        publicSalePriceBase = _publicSalePriceBase;
        publicSalePriceStep = _publicSalePriceStep;
        publicSalePriceWindow = _publicSalePriceWindow;
    }
}
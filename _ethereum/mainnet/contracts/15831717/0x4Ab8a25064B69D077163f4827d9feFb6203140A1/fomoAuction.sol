// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC20.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./AccessControlEnumerable.sol";

pragma solidity >=0.8.7;

contract MemeTokenWrapper {
    using SafeMath for uint256;
    IERC20 public meme;

    constructor(address _memeAddress) {
        meme = IERC20(_memeAddress);
    }

    uint256 private _totalSupply;
    uint256 internal _bonusFee = 10; // default 10%
    // Objects balances [id][address] => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(uint256 => uint256) private _totalDeposits;
    mapping(uint256 => uint256) private _winnerBonus;
    //KEYS info
    mapping(uint256 => mapping(address => uint256))
        internal _keysBonusByAddress;
    mapping(uint256 => address[]) internal _keysAddresses;
    mapping(uint256 => mapping(address => uint256))
        internal _keysCountByAddress;
    mapping(uint256 => uint256) private _keysTotalCount;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalDeposits(uint256 id) public view returns (uint256) {
        return _totalDeposits[id];
    }

    function winnerBonus(uint256 id) public view returns (uint256) {
        return _winnerBonus[id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _balances[id][account];
    }

    function bonusOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _keysBonusByAddress[id][account];
    }

    function poolInfoByAddress(address account, uint256 id)
        public
        view
        returns (
            uint256 winnerPool,
            uint256 keysTotal,
            uint256 keys,
            uint256 bonus
        )
    {
        winnerPool = _winnerBonus[id];
        keysTotal = _keysTotalCount[id];
        keys = _keysCountByAddress[id][account];
        bonus = _keysBonusByAddress[id][account];
    }

    function bid(
        uint256 id,
        uint256 amount,
        bool isFunBid
    ) public virtual {
        isFunBid ? _funBid(id, amount) : _bid(id, amount);
    }

    function _bid(uint256 id, uint256 amount) internal {
        uint256 balance = balanceOf(msg.sender, id);
        uint256 amountAdd = amount.sub(balance);
        _totalSupply = _totalSupply.add(amountAdd);
        _totalDeposits[id] = _totalDeposits[id].add(amountAdd);
        _balances[id][msg.sender] = amount;

        meme.transferFrom(msg.sender, address(this), amountAdd);
    }

    function _funBid(uint256 id, uint256 amount) internal {
        uint256 balance = balanceOf(msg.sender, id);
        uint256 amountAdd = amount.sub(balance);

        _totalSupply = _totalSupply.add(amountAdd);
        _totalDeposits[id] = _totalDeposits[id].add(amountAdd);
        // 10% to the bonus, 90% to the balance
        uint256 bonusAdd = (amount.mul(_bonusFee)).div(100);
        uint256 balanceAdd = amount.sub(bonusAdd);
        _balances[id][msg.sender] = balanceAdd;

        uint256 keysBonusAdd = bonusAdd.div(2);
        uint256 winnerBonusAdd = bonusAdd.sub(keysBonusAdd);
        //step0: winnerBonusAdd, 50%
        _winnerBonus[id] = _winnerBonus[id].add(winnerBonusAdd);

        //step1: keysBonusAdd to the keys owners, 50%
        if (_keysTotalCount[id] > 0) {
            uint256 bonusAddPerKey = keysBonusAdd.div(_keysTotalCount[id]);
            for (uint256 i = 0; i < _keysTotalCount[id]; ++i) {
                address account = _keysAddresses[id][i];
                _keysBonusByAddress[id][account] = _keysBonusByAddress[id][
                    account
                ].add(bonusAddPerKey);
            }
        }

        //step2: update keys info
        _keysAddresses[id].push(msg.sender); // add address
        _keysTotalCount[id] = _keysTotalCount[id].add(1); // add 1 key
        _keysCountByAddress[id][msg.sender] = _keysCountByAddress[id][
            msg.sender
        ].add(1);

        meme.transferFrom(msg.sender, address(this), amountAdd);
    }

    function withdraw(uint256 id) public virtual {
        uint256 amount = balanceOf(msg.sender, id);
        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _totalDeposits[id] = _totalDeposits[id].sub(amount);
            _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
            meme.transfer(msg.sender, amount);
        }
    }

    function withdrawBonus(uint256 id) public virtual {
        uint256 amount = bonusOf(msg.sender, id);
        if(amount > 0){
            _totalSupply = _totalSupply.sub(amount);
            _totalDeposits[id] = _totalDeposits[id].sub(amount);
            _keysBonusByAddress[id][msg.sender] = 0;
            meme.transfer(msg.sender, amount);
        }
    }

    function _emergencyWithdraw(address account, uint256 id) internal {
        uint256 amount = _balances[id][account];

        _totalSupply = _totalSupply.sub(amount);
        _totalDeposits[id] = _totalDeposits[id].sub(amount);
        _balances[id][account] = _balances[id][account].sub(amount);
        meme.transfer(account, amount);
    }

    function _end(
        uint256 id,
        address highestBidder,
        address artist,
        address daoAddress,
        uint256 fee,
        uint256 amount
    ) internal {
        // win artwork
        _totalSupply = _totalSupply.sub(amount);
        uint256 daoFee = (amount.mul(fee)).div(100);
        _totalDeposits[id] = _totalDeposits[id].sub(amount);
        _balances[id][highestBidder] = 0;
        meme.transfer(artist, amount.sub(daoFee));
        meme.transfer(daoAddress, daoFee);
        // win bonus
        _totalSupply = _totalSupply.sub(_winnerBonus[id]);
        _totalDeposits[id] = _totalDeposits[id].sub(_winnerBonus[id]);
        uint256 daoFee2 = (_winnerBonus[id].mul(fee)).div(100);
        uint256 bonus = _winnerBonus[id].sub(daoFee2);
        _winnerBonus[id] = 0;
        meme.transfer(highestBidder, bonus);
        meme.transfer(daoAddress, daoFee2);
    }
}

interface MEME721 {
    function totalSupply(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function mint(address _to, uint256 _baseTokenID) external;

    function create(uint256 _maxSupply) external returns (uint256 tokenId);
}

interface MEME1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function createCard() external returns (uint256);
}

contract FunAuction is
    Ownable,
    ReentrancyGuard,
    MemeTokenWrapper,
    AccessControlEnumerable,
    IERC1155Receiver,
    IERC721Receiver
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private auctionID;
    address public daoAddress;
    uint256 public daoFee;
    uint256 public maxBid;

    address private keyAddress;

    bytes32 public constant CREATE_ROLE = keccak256("CREATE_ROLE");

    // info about a particular auction
    struct AuctionInfo {
        uint256 poolID;
        uint256 auctionID;
        address artist;
        uint256 fee;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint256 originalAuctionEnd;
        uint256 extension;
        address highestBidder;
        uint256 highestBid;
        bool auctionEnded;
        bool isFunBid;
        NFTInfo nftInfo;
    }

    struct NFTInfo {
        address nftAddress;
        uint256 tokenID;
        bool isArtistContract;
        bool isERC721;
        uint256 keyTokenID;
    }

    mapping(uint256 => AuctionInfo) public auctionsById;
    uint256[] public auctions;

    // Events that will be fired on changes.
    event BidPlaced(address indexed user, uint256 indexed id, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed id, uint256 amount);
    event Ended(address indexed user, uint256 indexed id, uint256 amount);

    constructor(
        address _memeAddress,
        address _daoAddress,
        address _keyAddress
    ) MemeTokenWrapper(_memeAddress) {
        daoAddress = _daoAddress;
        keyAddress = _keyAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function auctionStart(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionStart;
    }

    function artist(uint256 id) public view returns (address) {
        return auctionsById[id].artist;
    }

    function auctionEnd(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionEnd;
    }

    function pingappleNFTTokenID(uint256 id) public view returns (uint256) {
        return auctionsById[id].nftInfo.tokenID;
    }

    function highestBidder(uint256 id) public view returns (address) {
        return auctionsById[id].highestBidder;
    }

    function highestBid(uint256 id) public view returns (uint256) {
        return auctionsById[id].highestBid;
    }

    function ended(uint256 id) public view returns (bool) {
        return block.timestamp >= auctionsById[id].auctionEnd;
    }

    function daoAddressFee(uint256 id) public view returns (uint256) {
        return auctionsById[id].fee;
    }

    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function setdaoAddress(address account) public onlyOwner {
        daoAddress = account;
    }

    function setMaxBid(uint256 _maxBid) public onlyOwner {
        maxBid = _maxBid;
    }

    function setKey1155(address _keyAddress) public onlyOwner {
        keyAddress = _keyAddress;
    }

    function setdaoFee(uint256 fee) public onlyOwner {
        daoFee = fee;
    }

    function setMemeAddress(address _memeAddress) public onlyOwner {
        meme = IERC20(_memeAddress);
    }

    function create(
        uint256 poolID,
        address artistAddress,
        uint256 start,
        uint256 duration,
        uint256 extension, // in minutes
        address nftAddress,
        bool isArtistContract,
        bool isERC721,
        uint256 nftTokenID,
        address nftHolder,
        bool isFunBid
    ) external onlyRole(CREATE_ROLE) returns (uint256 id) {
        AuctionInfo storage auction = auctionsById[auctionID.current()];
        require(
            auction.artist == address(0),
            "FomoAuction::create: auction already created"
        );

        auction.poolID = poolID;
        auction.auctionID = auctionID.current();
        auction.artist = artistAddress;
        auction.fee = daoFee;
        auction.auctionStart = start;
        auction.auctionEnd = start.add(duration * 1 days);
        auction.originalAuctionEnd = start.add(duration * 1 days);
        auction.extension = extension * 60;
        auction.isFunBid = isFunBid;
        auction.nftInfo.nftAddress = nftAddress;
        auction.nftInfo.isArtistContract = isArtistContract;
        auction.nftInfo.isERC721 = isERC721;
        uint256 keytokenid = MEME1155(keyAddress).createCard();
        auction.nftInfo.keyTokenID = keytokenid;

        auctions.push(auctionID.current());

        auctionID.increment();

        if (!isArtistContract) {
            uint256 tokenId = MEME721(nftAddress).create(1);
            require(tokenId > 0, "FomoAuction::create: create did not succeed");
            auction.nftInfo.tokenID = tokenId;
        } else {
            auction.nftInfo.tokenID = nftTokenID;
            // transfer NFT to contract
            if (isERC721) {
                if (IERC721(nftAddress).ownerOf(nftTokenID) != address(this))
                    IERC721(nftAddress).safeTransferFrom(
                        nftHolder,
                        address(this),
                        nftTokenID
                    );
            } else {
                if (
                    IERC1155(nftAddress).balanceOf(address(this), nftTokenID) ==
                    0
                )
                    IERC1155(nftAddress).safeTransferFrom(
                        nftHolder,
                        address(this),
                        nftTokenID,
                        1,
                        ""
                    );
            }
        }
        return auction.auctionID;
    }

    function bid(
        uint256 id,
        uint256 amount,
        bool isFunBid
    ) public virtual override nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        require(
            auction.artist != address(0),
            "FomoAuction::bid: auction does not exist"
        );
        require(
            block.timestamp >= auction.auctionStart,
            "FomoAuction::bid: auction has not started"
        );
        require(
            block.timestamp <= auction.auctionEnd,
            "FomoAuction::bid: auction has ended"
        );

        require(
            amount >= (auction.highestBid).mul(101).div(100),
            "FomoAuction::bid: bid is less than highest bid"
        );

        require(isFunBid == auction.isFunBid, "FomoAuction::bid: error funbid");

        if (maxBid > 0) {
            require(amount <= maxBid, "FomoAuction::bid: max bid");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = amount;

        if (
            auction.extension > 0 &&
            auction.auctionEnd.sub(block.timestamp) <= auction.extension
        ) {
            auction.auctionEnd = block.timestamp.add(auction.extension);
        }

        super.bid(id, amount, isFunBid);
        if (isFunBid)
            MEME1155(keyAddress).mint(
                msg.sender,
                auction.nftInfo.keyTokenID,
                1
            );

        emit BidPlaced(msg.sender, id, amount);
    }

    function withdraw(uint256 id) public virtual override nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        uint256 amount = balanceOf(msg.sender, id);
        require(
            auction.artist != address(0),
            "FomoAuction::withdraw: auction does not exist"
        );
        require(amount > 0, "FomoAuction::withdraw: cannot withdraw 0");

        require(
            auction.highestBidder != msg.sender,
            "FomoAuction::withdraw: you are the highest bidder and cannot withdraw"
        );

        super.withdraw(id);
        emit Withdrawn(msg.sender, id, amount);
    }

    function withdrawBonus(uint256 id) public virtual override nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        uint256 amount = bonusOf(msg.sender, id);
        require(
            auction.artist != address(0),
            "FomoAuction::withdrawBonus: auction does not exist"
        );
        require(amount > 0, "FomoAuction::withdrawBonus: cannot withdraw 0");

        super.withdrawBonus(id);
        emit Withdrawn(msg.sender, id, amount);
    }

    function emergencyWithdraw(uint256 id) public onlyOwner {
        AuctionInfo storage auction = auctionsById[id];
        require(
            auction.artist != address(0),
            "FomoAuction::create: auction does not exist"
        );
        require(
            block.timestamp >= auction.auctionEnd,
            "FomoAuction::emergencyWithdraw: the auction has not ended"
        );
        require(
            !auction.auctionEnded,
            "FomoAuction::emergencyWithdraw: auction ended and item sent"
        );

        _emergencyWithdraw(auction.highestBidder, id);
        emit Withdrawn(auction.highestBidder, id, auction.highestBid);
    }

    function end(uint256 id) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        require(
            auction.artist != address(0),
            "FomoAuction::end: auction does not exist"
        );
        require(
            block.timestamp >= auction.auctionEnd,
            "FomoAuction::end: the auction has not ended"
        );
        require(
            !auction.auctionEnded,
            "FomoAuction::end: auction already ended"
        );

        auction.auctionEnded = true;

        _end(
            id,
            auction.highestBidder,
            auction.artist,
            daoAddress,
            auction.fee,
            balanceOf(auction.highestBidder, id)
        );
        if (auction.nftInfo.isArtistContract) {
            if (auction.nftInfo.isERC721) {
                IERC721(auction.nftInfo.nftAddress).safeTransferFrom(
                    address(this),
                    auction.highestBidder,
                    auction.nftInfo.tokenID
                );
            } else {
                IERC1155(auction.nftInfo.nftAddress).safeTransferFrom(
                    address(this),
                    auction.highestBidder,
                    auction.nftInfo.tokenID,
                    1,
                    ""
                );
            }
        } else {
            MEME721(auction.nftInfo.nftAddress).mint(
                auction.highestBidder,
                auction.nftInfo.tokenID
            );
        }

        emit Ended(auction.highestBidder, id, auction.highestBid);
    }

    function rescue721NFT(
        address nftAddress,
        uint256 nftID,
        address toAddress
    ) external onlyOwner {
        IERC721(nftAddress).safeTransferFrom(address(this), toAddress, nftID);
    }

    function rescue1155NFT(
        address nftAddress,
        uint256 nftID,
        uint256 amount,
        address toAddress
    ) external onlyOwner {
        IERC1155(nftAddress).safeTransferFrom(
            address(this),
            toAddress,
            nftID,
            amount,
            ""
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC1155).interfaceId;
    }
}

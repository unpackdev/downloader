pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

interface MapElevationRetriever {
    function getElevation(uint8 col, uint8 row) external view returns (uint8);
}

interface Etheria {
    function getOwner(uint8 col, uint8 row) external view returns(address);
    function setOwner(uint8 col, uint8 row, address newowner) external;
    function setName(uint8 col, uint8 row, string calldata _n) external;
}

contract EtheriaGlobalMarket is AccessControl, Initializable {

    /*
    Marketplace based on the Larvalabs OGs!
    */

    using SafeMath for uint256;

    string public name;
    uint public mapSize;

    Etheria public etheriav11;
    Etheria public etheriav12;

    uint public FEE;
    uint public feesToCollect;
    
    uint public GlobalBidIDCounter;

    struct Bid {
        uint8 col;
        uint8 row;
        uint amount;
        address bidder;
    }
    
    struct GlobalBid {
        uint bidid;
        uint amount;
        address bidder;
    }

    // A record of the highest Etheria bid
    // version => (tileIndex => Bid)
    mapping (string => mapping (uint => Bid)) public bids;
    mapping (string => mapping (uint => GlobalBid)) public globalbids;
    mapping (address => uint) public pendingWithdrawals;

    event EtheriaTransfer(string indexed version, uint indexed index, address from, address to);
    event EtheriaBidCreated(string indexed version, uint indexed index, uint amount, address bidder);
    event EtheriaGlobalBidCreated(string indexed version, uint indexed globalbidid, uint amount, address bidder);
    event EtheriaBidWithdrawn(string indexed version, uint indexed index, uint amount, address bidder);
    event EtheriaGlobalBidWithdrawn(string indexed version, uint indexed globalbidid, uint amount, address bidder);
    event EtheriaBought(string indexed version, uint indexed index, uint amount, address seller, address bidder);
    event EtheriaGlobalBought(string indexed version, uint indexed index, uint amount, uint globalbidid, address seller, address bidder);


    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, 0x568f02EE272909ae9352188D4EA406Df810Ba4dE);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x9260ae742F44b7a2e9472f5C299aa0432B3502FA);
        _setupRole(DEFAULT_ADMIN_ROLE, 0xD2927a91570146218eD700566DF516d67C5ECFAB);

        FEE = 20; //5%
        name = "EtheriaGlobalMarket";
        mapSize = 33;
        etheriav11 = Etheria(0x169332Ae7D143E4B5c6baEdb2FEF77BFBdDB4011);
        etheriav12 = Etheria(0xB21f8684f23Dbb1008508B4DE91a0aaEDEbdB7E4);
        GlobalBidIDCounter = 0;
    }

    function collectFees() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        uint amount = feesToCollect;
        feesToCollect = 0;
        uint forth = amount.div(4);
        uint remainder = amount.sub(forth).sub(forth).sub(forth);
        payable(0x448458Ac5EE15ae1b5f73dbA5bfA46046FEeEfDd).transfer(forth);
        payable(0x568f02EE272909ae9352188D4EA406Df810Ba4dE).transfer(forth);
        payable(0x9260ae742F44b7a2e9472f5C299aa0432B3502FA).transfer(forth);
        payable(0xD2927a91570146218eD700566DF516d67C5ECFAB).transfer(remainder);
    }

    function changeFee(uint newFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        FEE = newFee;
    }

    function _index(uint8 col, uint8 row) internal view returns (uint) {
        return col * mapSize + row;
    }

    function versionDispatcher(string calldata version) internal view returns (Etheria) {
        return keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("1.1")) ? etheriav11 : etheriav12;
    }

    function bid(string calldata version, uint8 col, uint8 row) public payable {
        //require(etheria.getOwner(col, row) != msg.sender);
        uint index = _index(col, row);
        require(msg.value > 0, "BID::Value is 0");
        Bid memory bid = bids[version][index];
        require(msg.value > bid.amount, "BID::New bid too low");
        //refund failing bid
        pendingWithdrawals[bid.bidder] += bid.amount;
        //new bid
        bids[version][index] = Bid(col, row, msg.value, msg.sender);
        emit EtheriaBidCreated(version, index, msg.value, msg.sender);
    }
    
    function increaseGlobalBidCounter() internal returns (uint) {
        GlobalBidIDCounter += 1;
        return GlobalBidIDCounter;
    }
    
    function globalbid(string calldata version) public payable {
        //require(etheria.getOwner(col, row) != msg.sender);
        //uint index = _index(col, row);
        uint globalbidid = increaseGlobalBidCounter();
        require(msg.value > 0, "BID::Value is 0");
        
        // Dont need to check old bids and not refund stuff
        
        //new globalbid
        globalbids[version][globalbidid] = GlobalBid(globalbidid, msg.value, msg.sender);
        emit EtheriaGlobalBidCreated(version, globalbidid, msg.value, msg.sender);
    }

    function withdrawBid(string calldata version, uint8 col, uint8 row) public {
        uint index = _index(col, row);
        Bid memory bid = bids[version][index];
        require(msg.sender == bid.bidder, "WITHDRAW_BID::Only bidder can withdraw his bid");
        emit EtheriaBidWithdrawn(version, index, bid.amount, msg.sender);
        uint amount = bid.amount;
        bids[version][index] = Bid(col, row, 0, address(0x0));
        msg.sender.transfer(amount);
    }

    function withdrawGlobalBid(string calldata version, uint globalbidid) public {
        GlobalBid memory globalbid = globalbids[version][globalbidid];
        require(msg.sender == globalbid.bidder, "WITHDRAW_BID::Only bidder can withdraw his bid");
        emit EtheriaGlobalBidWithdrawn(version, globalbidid, globalbid.amount, msg.sender);
        uint amount = globalbid.amount;
        globalbids[version][globalbidid] = GlobalBid(globalbidid, 0, address(0x0));
        msg.sender.transfer(amount);
    }

    function acceptBid(string calldata version, uint8 col, uint8 row, uint minPrice) public {
        Etheria etheria = versionDispatcher(version);
        require(etheria.getOwner(col, row) == msg.sender, "ACCEPT_BID::Only owner can accept bid");
        uint index = _index(col, row);
        Bid memory bid = bids[version][index];
        require(bid.amount > 0, "ACCEPT_BID::Bid amount is 0");
        require(bid.amount >= minPrice, "ACCEPT_BID::Min price not respected");
        // With the require getOwner we check already, if it can be assigned, no other checks needed
        etheria.setName(col, row, "");
        etheria.setOwner(col, row, bid.bidder);

        //collect fee
        uint fees = bid.amount.div(FEE);
        feesToCollect += fees;

        uint amount = bid.amount.sub(fees);
        bids[version][index] = Bid(col, row, 0, address(0x0));
        pendingWithdrawals[msg.sender] += amount;
        emit EtheriaBought(version, index, amount, msg.sender, bid.bidder);
        emit EtheriaTransfer(version, index, msg.sender, bid.bidder);
    }
    
    function acceptGlobalBid(string calldata version, uint8 col, uint8 row, uint globalbidid) public {
        Etheria etheria = versionDispatcher(version);
        require(etheria.getOwner(col, row) == msg.sender, "ACCEPT_BID::Only owner can accept bid");
        uint index = _index(col, row);
        GlobalBid memory globalbid = globalbids[version][globalbidid];
        require(globalbid.amount > 0, "ACCEPT_BID::Bid amount is 0");
        require(globalbid.bidid == globalbidid, "ACCEPT_BID::Bid ID somehow changed?");
        // With the require getOwner we check already, if it can be assigned, no other checks needed
		// Empty set Name
        etheria.setName(col, row, "");
        etheria.setOwner(col, row, globalbid.bidder);

        //collect fee
        uint fees = globalbid.amount.div(FEE);
        feesToCollect += fees;

        uint amount = globalbid.amount.sub(fees);
        globalbids[version][globalbidid] = GlobalBid(globalbidid, 0, address(0x0));
        pendingWithdrawals[msg.sender] += amount;
        emit EtheriaGlobalBought(version, index, amount, globalbidid, msg.sender, globalbid.bidder);
        emit EtheriaTransfer(version, index, msg.sender, globalbid.bidder);
    }


    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./Counters.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract ETHDubaiTicket {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIds;
    address payable public owner;

    uint256[90] public ticketOptions;
    Settings public settings;
    event Log(address indexed sender, string message);
    event Lint(uint256 indexed tokenId, string message);
    event LDiscount(address indexed sender, Discount discount, string message);
    event LMint(address indexed sender, MintInfo[] mintInfo, string message);
    enum Ticket {
        CONFERENCE,
        HOTEL_CONFERENCE,
        WORKSHOP1_AND_PRE_PARTY,
        WORKSHOP2_AND_PRE_PARTY,
        WORKSHOP3_AND_PRE_PARTY,
        HOTEL_WORKSHOP_AND_PRE_PARTY,
        HOTEL_WORKSHOP1_AND_PRE_PARTY,
        HOTEL_WORKSHOP2_AND_PRE_PARTY,
        HOTEL_WORKSHOP3_AND_PRE_PARTY,
        HOTEL2_WORKSHOP1_AND_PRE_PARTY,
        HOTEL2_WORKSHOP2_AND_PRE_PARTY,
        HOTEL2_WORKSHOP3_AND_PRE_PARTY,
        HOTEL2_CONFERENCE,
        WORKSHOP4_AND_PRE_PARTY,
        HOTEL_WORKSHOP4_AND_PRE_PARTY,
        HOTEL2_WORKSHOP4_AND_PRE_PARTY,
        HACKATHON_AND_CONFERENCE_ONLY,
        HOTEL_HACKATHON_AND_CONFERENCE_ONLY,
        HOTEL2_HACKATHON_AND_CONFERENCE_ONLY,
        HACKATHON_AND_PRE_PARTY,
        HOTEL_HACKATHON_AND_PRE_PARTY,
        HOTEL2_HACKATHON_AND_PRE_PARTY,
        WORKSHOP5_AND_PRE_PARTY,
        HOTEL_WORKSHOP5_AND_PRE_PARTY,
        HOTEL2_WORKSHOP5_AND_PRE_PARTY,
        WORKSHOP6_AND_PRE_PARTY,
        HOTEL_WORKSHOP6_AND_PRE_PARTY,
        HOTEL2_WORKSHOP6_AND_PRE_PARTY,
        WORKSHOP7_AND_PRE_PARTY,
        HOTEL_WORKSHOP7_AND_PRE_PARTY,
        HOTEL2_WORKSHOP7_AND_PRE_PARTY,
        WORKSHOP8_AND_PRE_PARTY,
        HOTEL_WORKSHOP8_AND_PRE_PARTY,
        HOTEL2_WORKSHOP8_AND_PRE_PARTY,
        WORKSHOP9_AND_PRE_PARTY,
        HOTEL_WORKSHOP9_AND_PRE_PARTY,
        HOTEL2_WORKSHOP9_AND_PRE_PARTY,
        WORKSHOP10_AND_PRE_PARTY,
        HOTEL_WORKSHOP10_AND_PRE_PARTY,
        HOTEL2_WORKSHOP10_AND_PRE_PARTY,
        WORKSHOP11_AND_PRE_PARTY,
        HOTEL_WORKSHOP11_AND_PRE_PARTY,
        HOTEL2_WORKSHOP11_AND_PRE_PARTY,
        WORKSHOP12_AND_PRE_PARTY,
        HOTEL_WORKSHOP12_AND_PRE_PARTY,
        HOTEL2_WORKSHOP12_AND_PRE_PARTY
    }
    EnumerableSet.AddressSet private daosAddresses;
    mapping(address => uint256) public daosQty;
    mapping(address => Counters.Counter) public daosUsed;
    mapping(address => uint256) public daosMinBalance;
    mapping(address => uint256) public daosDiscount;
    mapping(address => uint256) public daosMinTotal;
    mapping(address => Discount) public discounts;

    event LTicketSettings(
        TicketSettings indexed ticketSettings,
        string message
    );

    constructor() {
        emit Log(msg.sender, "created");
        owner = payable(msg.sender);
        settings.maxMint = 700;

        settings.ticketSettings = TicketSettings("early");

        ticketOptions[uint256(Ticket.CONFERENCE)] = 0.07 ether;
        ticketOptions[uint256(Ticket.HOTEL_CONFERENCE)] = 0.17 ether;
        ticketOptions[uint256(Ticket.WORKSHOP1_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP2_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP3_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.HOTEL_WORKSHOP_AND_PRE_PARTY)] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP1_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP2_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP3_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP1_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP2_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP3_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.HOTEL2_CONFERENCE)] = 0.3 ether;
        ticketOptions[uint256(Ticket.WORKSHOP4_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP4_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP4_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[
            uint256(Ticket.HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.10 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.3 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_HACKATHON_AND_CONFERENCE_ONLY)
        ] = 0.4 ether;
        ticketOptions[uint256(Ticket.HACKATHON_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_HACKATHON_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_HACKATHON_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP5_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP5_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP5_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP6_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP6_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP6_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP7_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP7_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP7_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP8_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP8_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP8_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP9_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP9_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP9_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP10_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP10_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP10_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP11_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP11_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP11_AND_PRE_PARTY)
        ] = 0.5 ether;
        ticketOptions[uint256(Ticket.WORKSHOP12_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP12_AND_PRE_PARTY)
        ] = 0.4 ether;
        ticketOptions[
            uint256(Ticket.HOTEL2_WORKSHOP12_AND_PRE_PARTY)
        ] = 0.5 ether;
    }

    struct Discount {
        uint256[] ticketOptions;
        uint256 amount;
    }

    struct TicketSettings {
        string name;
    }
    struct MintInfo {
        string ticketCode;
        uint256 ticketOption;
        string specialStatus;
    }
    struct Settings {
        TicketSettings ticketSettings;
        uint256 maxMint;
    }

    function setDiscount(
        address buyer,
        uint256[] memory newDiscounts,
        uint256 amount
    ) public returns (bool) {
        require(msg.sender == owner, "only owner");

        Discount memory d = Discount(newDiscounts, amount);
        emit LDiscount(buyer, d, "set discount buyer");
        discounts[buyer] = d;
        return true;
    }

    function setMaxMint(uint256 max) public returns (uint256) {
        require(msg.sender == owner, "only owner");
        settings.maxMint = max;
        emit Lint(max, "setMaxMint");
        return max;
    }

    function setTicketOptions(uint256 ticketOptionId, uint256 amount)
        public
        returns (bool)
    {
        require(msg.sender == owner, "only owner");
        ticketOptions[ticketOptionId] = amount;
        return true;
    }

    function setDao(
        address dao,
        uint256 qty,
        uint256 discount,
        uint256 minBalance,
        uint256 minTotal
    ) public returns (bool) {
        require(msg.sender == owner, "only owner");
        require(Address.isContract(dao), "nc");
        if (!daosAddresses.contains(dao)) {
            daosAddresses.add(dao);
        }
        daosQty[dao] = qty;
        daosMinBalance[dao] = minBalance;
        daosDiscount[dao] = discount;
        daosMinTotal[dao] = minTotal;
        return true;
    }

    function setTicketSettings(string memory name) public returns (bool) {
        require(msg.sender == owner, "only owner");
        settings.ticketSettings.name = name;
        emit LTicketSettings(settings.ticketSettings, "setTicketSettings");
        return true;
    }

    function cmpStr(string memory idopt, string memory opt)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((idopt))) ==
            keccak256(abi.encodePacked((opt))));
    }

    function getDiscount(address sender, uint256 ticketOption)
        public
        view
        returns (uint256[2] memory)
    {
        Discount memory discount = discounts[sender];
        uint256 amount = discounts[sender].amount;
        uint256 total = 0;
        bool hasDiscount = false;
        total = total + ticketOptions[ticketOption];

        if (amount > 0) {
            for (uint256 j = 0; j < discount.ticketOptions.length; j++) {
                if (discount.ticketOptions[j] == ticketOption) {
                    hasDiscount = true;
                }
            }
            if (!hasDiscount) {
                amount = 0;
            }
        }
        return [amount, total];
    }

    function getDaoDiscountView(uint256 amount)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256 minTotal = 0;
        if (amount == 0) {
            uint256 b = 0;

            for (uint256 j = 0; j < daosAddresses.length(); j++) {
                address dao = daosAddresses.at(j);
                if (daosDiscount[dao] > 0) {
                    ERC20 token = ERC20(dao);
                    b = token.balanceOf(msg.sender);
                    if (
                        b > daosMinBalance[dao] &&
                        daosUsed[dao].current() < daosQty[dao] &&
                        amount == 0
                    ) {
                        amount = daosDiscount[dao];
                        minTotal = daosMinTotal[dao];
                    }
                }
            }
        }
        return [amount, minTotal];
    }

    function getDaoDiscount(uint256 amount)
        internal
        returns (uint256[2] memory)
    {
        uint256 minTotal = 0;
        if (amount == 0) {
            uint256 b = 0;

            for (uint256 j = 0; j < daosAddresses.length(); j++) {
                address dao = daosAddresses.at(j);
                if (daosDiscount[dao] > 0) {
                    ERC20 token = ERC20(dao);
                    b = token.balanceOf(msg.sender);
                    if (
                        b > daosMinBalance[dao] &&
                        daosUsed[dao].current() < daosQty[dao] &&
                        amount == 0
                    ) {
                        amount = daosDiscount[dao];
                        daosUsed[dao].increment();
                        minTotal = daosMinTotal[dao];
                    }
                }
            }
        }
        return [amount, minTotal];
    }

    function getPrice(address sender, uint256 ticketOption)
        public
        returns (uint256)
    {
        uint256[2] memory amountAndTotal = getDiscount(sender, ticketOption);
        uint256 total = amountAndTotal[1];
        uint256[2] memory amountAndMinTotal = getDaoDiscount(amountAndTotal[0]);
        require(total > 0, "total = 0");
        if (amountAndMinTotal[0] > 0 && total >= amountAndMinTotal[1]) {
            total = total - ((total * amountAndMinTotal[0]) / 100);
        }

        return total;
    }

    function getPriceView(address sender, uint256 ticketOption)
        public
        view
        returns (uint256)
    {
        uint256[2] memory amountAndTotal = getDiscount(sender, ticketOption);
        uint256 total = amountAndTotal[1];
        uint256[2] memory amountAndMinTotal = getDaoDiscountView(
            amountAndTotal[0]
        );
        require(total > 0, "total = 0");
        if (amountAndMinTotal[0] > 0 && total >= amountAndMinTotal[1]) {
            total = total - ((total * amountAndMinTotal[0]) / 100);
        }

        return total;
    }

    function totalPrice(MintInfo[] memory mIs) public view returns (uint256) {
        uint256 t = 0;
        for (uint256 i = 0; i < mIs.length; i++) {
            t += getPriceView(msg.sender, mIs[i].ticketOption);
        }
        return t;
    }

    function totalPriceInternal(MintInfo[] memory mIs)
        internal
        returns (uint256)
    {
        uint256 t = 0;
        for (uint256 i = 0; i < mIs.length; i++) {
            t += getPrice(msg.sender, mIs[i].ticketOption);
        }
        return t;
    }

    function mintItem(MintInfo[] memory mintInfos)
        public
        payable
        returns (string memory)
    {
        require(
            _tokenIds.current() + mintInfos.length <= settings.maxMint,
            "sold out"
        );
        uint256 total = 0;

        string memory ids = "";
        for (uint256 i = 0; i < mintInfos.length; i++) {
            require(
                keccak256(abi.encodePacked(mintInfos[i].specialStatus)) ==
                    keccak256(abi.encodePacked("")) ||
                    msg.sender == owner,
                "only owner"
            );
            total += getPrice(msg.sender, mintInfos[i].ticketOption);
            _tokenIds.increment();
        }

        require(msg.value >= total, "price too low");
        //emit LMint(msg.sender, mintInfos, "minted");
        return ids;
    }

    function mintItemNoDiscount(MintInfo[] memory mintInfos)
        public
        payable
        returns (string memory)
    {
        require(
            _tokenIds.current() + mintInfos.length <= settings.maxMint,
            "sold out"
        );
        uint256 total = 0;

        string memory ids = "";
        for (uint256 i = 0; i < mintInfos.length; i++) {
            require(
                keccak256(abi.encodePacked(mintInfos[i].specialStatus)) ==
                    keccak256(abi.encodePacked("")) ||
                    msg.sender == owner,
                "only owner"
            );
            total += ticketOptions[mintInfos[i].ticketOption];
            _tokenIds.increment();
        }

        require(msg.value >= total, "price too low");
        //emit LMint(msg.sender, mintInfos, "minted");
        return ids;
    }

    function withdraw() public {
        uint256 amount = address(this).balance;

        (bool ok, ) = owner.call{value: amount}("");
        require(ok, "Failed");
        emit Lint(amount, "withdraw");
    }
}

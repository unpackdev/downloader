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

    uint256[20] public ticketOptions;
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
        HOTEL_WORKSHOP1_AND_PRE_PARTY,
        HOTEL_WORKSHOP2_AND_PRE_PARTY,
        HOTEL_WORKSHOP3_AND_PRE_PARTY
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
    uint256[] private initDiscounts;

    constructor() {
        emit Log(msg.sender, "created");
        owner = payable(msg.sender);
        settings.maxMint = 50;

        settings.ticketSettings = TicketSettings("early");

        ticketOptions[uint256(Ticket.CONFERENCE)] = 0.07 ether;
        ticketOptions[uint256(Ticket.HOTEL_CONFERENCE)] = 0.17 ether;
        ticketOptions[uint256(Ticket.WORKSHOP1_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP2_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[uint256(Ticket.WORKSHOP3_AND_PRE_PARTY)] = 0.12 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP1_AND_PRE_PARTY)
        ] = 0.32 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP2_AND_PRE_PARTY)
        ] = 0.32 ether;
        ticketOptions[
            uint256(Ticket.HOTEL_WORKSHOP3_AND_PRE_PARTY)
        ] = 0.32 ether;
        initDiscounts = [0, 2, 3, 4];
        setDiscount(
            0x114f2661D4eE895AE65cbbD302B7EdB32c5667e3,
            initDiscounts,
            15
        );
        setDiscount(
            0xe32bAC6E393199bb3881187F4feb52e28e973870,
            initDiscounts,
            15
        );
        setDiscount(
            0x3955Fc91B098db549947c3c646Cf1223aE4E08b5,
            initDiscounts,
            15
        );
        setDiscount(
            0x402A5F0e42B0134aBeC851b2656F31F7ee7A0ee4,
            initDiscounts,
            15
        );
        setDiscount(
            0x4C8418E3f8c1390dBc72314b642d5255FDa14dd8,
            initDiscounts,
            15
        );
        setDiscount(
            0x8588Be209727C471d31d77B844ED411BA068f73B,
            initDiscounts,
            15
        );
        setDiscount(
            0xc840D0A9bb73e1C76915c013804B7b6Cb67462ec,
            initDiscounts,
            15
        );
        setDiscount(
            0xF1E1F290A7167132725FAA917b119e16F2BC5fA3,
            initDiscounts,
            15
        );
        setDiscount(
            0x434Aa19BE9925388B114C8c814F74E93761Ed682,
            initDiscounts,
            15
        );
        setDiscount(
            0x43b30c00AA87967eB665Ed8d5558e06f55611344,
            initDiscounts,
            15
        );
        setDiscount(
            0x1A0d4d5b4F7F51e71A88Bf2b70177836ac893225,
            initDiscounts,
            15
        );
        setDiscount(
            0x6B703a7FD20efe6F5BADfdd57cc8Ec97FA3A1910,
            initDiscounts,
            15
        );
        setDiscount(
            0x524aD4d7da566383d993073193f81bB596aC6639,
            initDiscounts,
            15
        );
        setDiscount(
            0xC8F78497C72A2940Ca5bC1795c79d48d42B246A4,
            initDiscounts,
            15
        );
        setDiscount(
            0x1fa4aA8476D547f83EcC7f817CBA662f1F58F807,
            initDiscounts,
            15
        );
        setDiscount(
            0x98cdbFee2C5b945be3AdCA4A1815622c64E07D7e,
            initDiscounts,
            15
        );
        setDiscount(
            0x858989924f72DdeB80526a68EfB15677E8Cfad64,
            initDiscounts,
            15
        );
        setDiscount(
            0xc3F4DC5D0c288f2b83b63c44A810baBCe6d69dA4,
            initDiscounts,
            15
        );
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

pragma solidity >=0.8.11;
import "./ERC20.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";

contract DefiDubai {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    string private meetupLocationUrl;
    address payable public owner;
    ERC20 public erc20;
    uint256 public nextMeetupTimestamp;
    Counters.Counter public attendees;
    EnumerableSet.AddressSet private attendeesAddr;
    EnumerableSet.AddressSet private noshows;
    uint256 public maxAttendees;
    address[] private attendeesArr;
    uint256 public price;
    mapping(address => bool) newnoshows;

    constructor() payable {
        owner = payable(msg.sender);
        //optimism
        //erc20 = ERC20(0xE265FC71d45fd791c9ebf3EE0a53FBB220Eb8f75);
        //arbitrum
        //erc20 = ERC20(0xD27121251A0764FdBaD4dDa54390A541d9e44A30);
        //mainnet
        erc20 = ERC20(0xf0035f8146A62cb2554BE61b4BACA6425A13F0c9);
        nextMeetupTimestamp = 1643986800;
        maxAttendees = 15;
        price = 0.02 ether;
        setMeetupUrl(
            "hey habibi, the URL is in base64, you know how to convert aHR0cHM6Ly9kZWZpZHViYWktbGJhbmttZWV0dXAuc3VyZ2Uuc2gv"
        );
    }

    function getAttendees(address yourAddress)
        public
        returns (address[] memory)
    {
        if (
            EnumerableSet.length(attendeesAddr) > 0 &&
            attendeesAddr.contains(yourAddress)
        ) {
            delete attendeesArr;
            for (uint256 j = 0; j < EnumerableSet.length(attendeesAddr); j++) {
                attendeesArr.push(attendeesAddr.at(j));
            }
        }
        return attendeesArr;
    }

    function setToken(address addr) public {
        require(msg.sender == owner, "only owner");
        erc20 = ERC20(addr);
    }

    function setPrice(uint256 p) public {
        require(msg.sender == owner, "only owner");
        price = p;
    }

    function setNextMeetupAll(
        uint256 max,
        string memory url,
        uint256 timestamp
    ) public {
        require(msg.sender == owner, "only owner");
        setMaxAttendees(max);
        resetAttendees();
        setMeetupUrl(url);
        nextMeetupTimestamp = timestamp;
        attendees.reset();
        delete attendeesArr;
    }

    function setMaxAttendees(uint256 max) public {
        require(msg.sender == owner, "only owner");
        maxAttendees = max;
    }

    function resetAttendees() public {
        require(msg.sender == owner, "only owner");
        for (uint256 j = 0; j < EnumerableSet.length(attendeesAddr); j++) {
            EnumerableSet.remove(attendeesAddr, attendeesAddr.at(j));
        }
        attendees.reset();
    }

    function setMeetupUrl(string memory url) public {
        require(msg.sender == owner, "only owner");
        meetupLocationUrl = url;
    }

    function whereNextMeetupSir() private view returns (string memory) {
        return meetupLocationUrl;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "only owner");
        owner = payable(newOwner);
    }

    function setNoshows(address[] memory addresses) public {
        require(msg.sender == owner, "only owner");
        for (uint256 j = 0; j < EnumerableSet.length(noshows); j++) {
            EnumerableSet.remove(noshows, noshows.at(j));
        }
        for (uint256 j = 0; j < addresses.length; j++) {
            noshows.add(addresses[j]);
        }
    }

    function whereNextMeetupAgainSir(address yourAddress)
        public
        view
        returns (string memory)
    {
        if (attendeesAddr.contains(yourAddress)) {
            return whereNextMeetupSir();
        }
        return "habibi, you need to call rsvp() first";
    }

    function rsvp() public returns (string memory) {
        require(
            attendees.current() < maxAttendees,
            "sorry habibi, meetup is already full, maybe next time :)"
        );
        require(
            !attendeesAddr.contains(address(msg.sender)),
            "hold on habibi, you've already rsvp'ed"
        );
        if (!noshows.contains(address(msg.sender))) {
            require(erc20.transfer(msg.sender, 100 ether), "Failed");
        }
        attendees.increment();
        attendeesAddr.add(address(msg.sender));
        return whereNextMeetupSir();
    }

    function paidRSVP() public payable returns (string memory) {
        require(
            attendees.current() < maxAttendees,
            "sorry habibi, meetup is already full, maybe next time :)"
        );
        require(
            !attendeesAddr.contains(address(msg.sender)),
            "hold on habibi, you've already rsvp'ed"
        );
        require(msg.value >= price, "sorry habibi, not enough funds");
        if (!noshows.contains(address(msg.sender))) {
            require(erc20.transfer(msg.sender, 100 ether), "Failed");
        }
        attendees.increment();
        attendeesAddr.add(address(msg.sender));
        return whereNextMeetupSir();
    }

    function withdrawAll() public {
        require(msg.sender == owner, "only owner");
        uint256 erc20Balance = erc20.balanceOf(address(this));

        require(erc20.transfer(owner, erc20Balance), "Failed");
    }
}

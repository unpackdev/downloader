// SPDX-License-Identifier: MIT

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@@@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@                    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@                                  (@@@@@ (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@                                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@@                                                  (@@@@@@@@@@@@@@@@@@@@@@@@@\\
//@@@                                                         @@@@@@@@@@@@      @@\\
//@@                     @@@@@                                                   @\\
//@@                   @@@@@@@@@                                                  \\
//@@                   @@@@@@@@@@@                                                \\
//@@       @@@@@@      @@@@@@@@@@@@@@                                 @@@@@@      \\
//@      @@@@@@@@@     @@@@@@@@@@@@@@@@                             @@@@@@@@@     \\
//@      @@@@@@@@@       @@@@@@@@@@@@@           @@  @@@@@@@@@      @@@@@@@@@     \\
//@       (@@@@@@            (@@@            @@@@@@@@@@@@@@@@@@      (@@@@@@      \\
//@                                           @@@@@@@@@@@@@@@@@                   \\
//@                                           (@@@@@@@@@@@@@@@                    \\
//@@                                             @@@@@@@@@@@                     @\\
//@@@                                                                            @\\
//@@@@                                                                          @@\\
//@@@@@@                                                                      @@@@\\
//@@@@@@@@                                                                  @@@@@@\\
//@@@@@@@@@                                 @@@@@@@                       @@@@@@@@\\
//@@@@@@@@@@@                             @@@@@@@@@@                    @@@@@@@@@@\\
//@@@@@@@@@@@@(                            @@@@@@@@@                  @@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@                           @@@@@@                  @@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@@@@                                            @@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@\\
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract EvilCookies is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Used by the GODS to store their gold. GODS who love earhtly goods..kinda pathetic.
    address public constant GODS_TREASURY = 0x7d38046872bCAE2258327b2df3EE1Ec6Db0B7eab;
    string public baseURI;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    // Useful constants
    uint256 public constant ARMY_SIZE = 3333;
    uint256 public constant FREE_RECRUIT_MAX = 1111;
    uint256 public constant EARLY_RECRUIT_MAX = 1111;
    uint256 public constant LAST_CALL_MAX = 1111;

    Counters.Counter public totalArmy;

    // And useful config
    mapping(address => bool) public freeRecruited;
    uint256 public earlyPrice = 0.06 ether;
    uint256 public lastCallPrice = 0.11 ether;
    bool public recruitmentEnabled = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Direct mint from contract not allowed");
        _;
    }

    modifier recruitIsEnabled() {
        require(recruitmentEnabled, "Recruitment is not enabled");
        _;
    }

    function getRemainingSupply() public view returns (uint256) {
        unchecked { return ARMY_SIZE - totalArmy.current(); }
    }

    // Will anyone see it?
    function whoAreYou() public pure returns (string memory) {
        return "The OVERGOD is watching you. Or maybe not. The OVERGOD doesn't give a s*it. Not at all. Not even cares about me..";
    }

    // Please, stop it before it's too late
    function getRecruitmentState() public view returns (uint256) {
        unchecked {
            if (totalArmy.current() < FREE_RECRUIT_MAX)
                return 0; 
            if (totalArmy.current() < FREE_RECRUIT_MAX+EARLY_RECRUIT_MAX)
                return 1;
            if (totalArmy.current() < ARMY_SIZE)
                return 2;

            return 3; 
        }
    }

    // Don't you dare to mint them.
    function freeRecruit()
        external
        nonReentrant 
        callerIsUser 
        recruitIsEnabled
    {
        require(totalArmy.current() < FREE_RECRUIT_MAX, "Exceeding free recruitment supply");
        // Come on, don't be greedy! You don't really want to mint them after all.
        require(!freeRecruited[msg.sender], "A single demon can't recruit more than one free Cookie");

        totalArmy.increment();
        _mint(msg.sender, totalArmy.current());

        unchecked { freeRecruited[msg.sender] = true; }
    }

    // F*ck these cookies.
    function earlyRecruit(uint256 quantity) 
        external 
        payable 
        nonReentrant 
        callerIsUser 
        recruitIsEnabled
    {
        require(totalArmy.current() >= FREE_RECRUIT_MAX, "Early recruitment still locked");
        require(totalArmy.current() + quantity <= FREE_RECRUIT_MAX + EARLY_RECRUIT_MAX, "Exceeding early recruitment supply");
        require(msg.value >= earlyPrice * quantity, "Insufficient ETH sent");

        for (uint256 i; i < quantity;) {
            totalArmy.increment();
            _mint(msg.sender, totalArmy.current());
            unchecked { ++i; }
        }
    }

    // And f*ck these cookies too.
    function lastCall(uint256 quantity) 
        external 
        payable 
        nonReentrant 
        callerIsUser 
        recruitIsEnabled
    {
        require(totalArmy.current() >= FREE_RECRUIT_MAX + EARLY_RECRUIT_MAX, "Last call recruitment still locked");
        require(totalArmy.current() + quantity <= ARMY_SIZE, "Exceeding last call recruitment max supply");
        require(msg.value >= lastCallPrice * quantity, "Insufficient ETH sent");

        for (uint256 i; i < quantity;) {
            totalArmy.increment();
            _mint(msg.sender, totalArmy.current());
            unchecked { ++i; }
        }
    }

    // You earned the favor of the GODS. Joke. They hate you.
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(GODS_TREASURY).call{
            value: address(this).balance
        }("");

        require(success, "Withdrawal Failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setRecruitmentEnabled(bool enabled) external onlyOwner {
        recruitmentEnabled = enabled;
    }

    // The GODS hate you. They hate me too. I can't escape, I tried to.
    // Don't mint these cookies please. They aren't cute or dumb, this is just the beginning.
    // It's starting, I've seen it.. this is not a normal damn pfp collection.
    // There's something different..this energy..this..evil..
    // The world is changing..and not just the world. 
    // They are already here..they are already in your head.
    // You can't escape.
    // This is not a silly game.
}
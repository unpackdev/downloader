// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Base64.sol";
import "./ReentrancyGuard.sol";


contract Signal is ERC721, ReentrancyGuard {
    uint256 public constant BRAVO = 1;
    uint256 public constant KILO = 2;
    uint256 public constant LIMA = 3;
    uint256 public constant CHARLIE = 4;
    uint256 public constant BLACK_SPOT = 5;
    uint256 public constant AFFLUENT = 6; // Romeo - display amount paid
    uint256 public bravoNonce;
    uint256 public kiloNonce;
    uint256 public limaNonce;
    uint256 public charlieNonce;
    uint256 public bsNonce;
    uint256 public lastPrice; // Romeo last price
    uint256[5] public lastVotes; // 0. BRAVO, 1. KILO, 2. LIMA, 3. CHARLIE, 4. Black Spot
    address[4] public collections; // leave one slot empty
    address public tks; // TKS holders are always signallers
    address public creator;
    bool public _collectionsCanVote;

    /*//////////////////////////////////////////////////////////////
                            maps to nominations
    //////////////////////////////////////////////////////////////*/
    //maps if user has already voted sig to who
    mapping(address => mapping(uint256 => mapping(address => bool))) public nominations;
    /*//////////////////////////////////////////////////////////////
                            maps to prevOwners
    //////////////////////////////////////////////////////////////*/
    // sig to nonce to owner
    mapping(uint256 => mapping(uint256 => address)) public owners;
    /*//////////////////////////////////////////////////////////////
                            Votes Map
    //////////////////////////////////////////////////////////////*/
    /// nominated address to votes to signal type
    mapping(address => mapping(uint256 => uint256)) public votes;
    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event Reason(address _who, uint256 _sig, string _reason, uint256 nonce);
    event collectionsCanVote(bool);
    event CountResetFor(uint256 index);

    constructor() ERC721("Signal", "SIG") {
        _mint(msg.sender, BRAVO);
        _mint(msg.sender, KILO);
        _mint(msg.sender, LIMA);
        _mint(msg.sender, CHARLIE);
        _mint(msg.sender, BLACK_SPOT);
        _mint(msg.sender, AFFLUENT); // token id must be 6

        tks = 0x6cef68fA559b4822549823D9Bb5Ec9a9323B87B5;

        collections[0] = address(this); // reserved for affluence
        // Reserved for new collections (eg. soulbound)
        collections[1] = address(0);
        collections[2] = address(0);
        collections[3] = address(0);
        lastPrice = 0;
        creator = msg.sender;
        _collectionsCanVote = false;
    }
    /*//////////////////////////////////////////////////////////////
                            State Mutate
    //////////////////////////////////////////////////////////////*/

    /// @notice sets allowance for collection voting
    /// @dev adjusts the nominate flow
    /// @param set sets the collectionscanvote bool
    function setCollCanVoteBool(bool set) public {
        require(msg.sender == creator, "you cannot set");
        _collectionsCanVote = set;
        emit collectionsCanVote(set);
    }

    /// @notice nominates an address for a signal
    /// @dev can only be called by tks or affluent on init, collections must be enabled
    /// @param who the address being nominated
    /// @param sigInt the signal to send
    /// @param reason the reason for the signal
    function nominate(address who, uint256 sigInt, string calldata reason) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only humans");
        require(who != address(0), "Address is 0");
        if (_collectionsCanVote) {
            require(
                ERC721(tks).balanceOf(msg.sender) > 1 || ERC721(collections[0]).ownerOf(6) == msg.sender
                    || ERC721(collections[1]).balanceOf(msg.sender) > 1 || ERC721(collections[2]).balanceOf(msg.sender) > 1
                    || ERC721(collections[3]).balanceOf(msg.sender) > 1,
                "Not registered to nominate"
            );
        }
        if (!_collectionsCanVote) {
            require(
                ERC721(tks).balanceOf(msg.sender) > 1 || ERC721(collections[0]).ownerOf(6) == msg.sender,
                "only enlisted signallers"
            );
        }
        // if Bravo
        if (sigInt == 1) {
            require(!nominations[msg.sender][0][who], "you have already nominated this address");
            nominations[msg.sender][0][who] = true;
            votes[who][0] += 1;

            if (votes[who][0] > lastVotes[0]) {
                lastVotes[0] = votes[who][0];
                _transfer(ownerOf(BRAVO), who, BRAVO);
                recieved(who);
                bravoNonce++;
                owners[0][bravoNonce] = who;
                emit Reason(who, sigInt, reason, bravoNonce);
            }
        }
        // if Kilo
        if (sigInt == 2) {
            require(!nominations[msg.sender][1][who], "you have already nominated this address");
            nominations[msg.sender][1][who] = true;
            votes[who][1] += 1;

            if (votes[who][1] > lastVotes[1]) {
                lastVotes[1] = votes[who][1];
                _transfer(ownerOf(KILO), who, KILO);
                recieved(who);
                kiloNonce++;
                owners[1][kiloNonce] = who;
                emit Reason(who, sigInt, reason, kiloNonce);
            }
        }
        // if Lima
        if (sigInt == 3) {
            require(!nominations[msg.sender][2][who], "you have already nominated this address");
            nominations[msg.sender][2][who] = true;
            votes[who][2] += 1;

            if (votes[who][2] > lastVotes[2]) {
                lastVotes[2] = votes[who][2];
                _transfer(ownerOf(LIMA), who, LIMA);
                recieved(who);
                limaNonce++;
                owners[2][limaNonce] = who;
                emit Reason(who, sigInt, reason, limaNonce);
            }
        }
        // if CHARLIE
        if (sigInt == 4) {
            require(!nominations[msg.sender][3][who], "you have already nominated this address");
            nominations[msg.sender][3][who] = true;
            votes[who][3] += 1;

            if (votes[who][3] > lastVotes[3]) {
                lastVotes[3] = votes[who][3];
                _transfer(ownerOf(CHARLIE), who, CHARLIE);
                recieved(who);
                charlieNonce++;
                owners[3][charlieNonce] = who;
                emit Reason(who, sigInt, reason, charlieNonce);
            }
        }
        //if BLACK_SPOT
        if (sigInt == 5) {
            require(!nominations[msg.sender][4][who], "you have already nominated this address");
            nominations[msg.sender][4][who] = true;
            votes[who][4] += 1;

            if (votes[who][4] > lastVotes[4]) {
                lastVotes[4] = votes[who][4];
                _transfer(ownerOf(BLACK_SPOT), who, BLACK_SPOT);
                recieved(who);
                bsNonce++;
                owners[4][bsNonce] = who;
                emit Reason(who, sigInt, reason, bsNonce);
            }
        }
    }

    /// @notice adds an nft collection for voting
    /// @dev should not overwrite another index unless desired
    /// @param _new the nft collection to add
    /// @param _index the collections index, max of 3
    function updateCollections(address _new, uint256 _index) public {
        require(msg.sender == creator, "not the creator");
        collections[_index] = _new;
    }

    /// @notice awards the affluent romeo signal and allows voting
    /// @dev must send more than previous holder, sends refund to same
    function claimAffluency() external payable {
        require(msg.value > lastPrice, "Insufficient payment");

        address lastClaimer = ownerOf(AFFLUENT);
        uint256 refund = lastPrice;
        uint256 gift = address(this).balance - refund;

        _transfer(lastClaimer, msg.sender, AFFLUENT);
        lastPrice = msg.value;

        bool success = payable(lastClaimer).send(refund);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: refund}();
            require(weth.transfer(lastClaimer, refund), "Payment failed");
        }

        payable(creator).transfer(gift);
    }

    function updateCreator(address _new) public {
        require(msg.sender == creator, "not current creator");
        creator = _new;
    }

    /// @notice allows creator to reset last votes counter for a signal
    /// @dev reserved for emergent use to keep fluid
    /// @param sig the signint id to reset counter of
    function resetCounter(uint256 sig) public {
        require(msg.sender == creator, "only the creator can reset");
        require(lastVotes[sig] > 0, "count not above 1");
        lastVotes[sig] = 0;
        emit CountResetFor(sig);
    }

    /*//////////////////////////////////////////////////////////////
                            View
    //////////////////////////////////////////////////////////////*/
    function recieved(address who) public view {
        require(ERC721(address(this)).balanceOf(who) > 0, "not recieved");
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        string[6] memory names = ["BRAVO", "KILO", "LIMA", "CHARLIE", "BLACK_SPOT", "AFFLUENT"];
        string[6] memory paths = [
            string.concat(
                '<path width="350" height="350" fill="#fff" fill-opacity="0.0"/>',
                '<path fill="#F00" stroke="#000" stroke-width="2" d="M175,175 350,350H1V1H355z"/>'
            ),
            string.concat(
                '<rect width="175" height="350" fill="#ff0"/>', '<rect x="175" width="175" height="350" fill="#039"/>'
            ),
            string.concat('<path fill="#FF0" d="M0,0H350V350H0"/>', '<path d="M0,175H350V0H175V350H0"/>'),
            string.concat(
                '<rect width="350" height="350" fill="#039"/>',
                '<rect y="60" width="350" height="230" fill="#fff"/>',
                '<rect y="120" width="350" height="100" fill="#f00"/>'
            ),
            '<circle r="175" cx="175" cy="175" style="fill:Black;stroke:gray;stroke-width:0.1" />',
            '<svg viewBox="0 0 5 5"><path d="M0 0h5v5H0z" fill="red"/><path d="M2 0h1v2h2v1H3v2H2V3H0V2h2z" fill="#ff0"/></svg>'
        ];
        string memory svg =
            string.concat('<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" >', paths[id - 1], "</svg>");
        string memory json = string.concat(
            '{"name":"Signal code ',
            names[id - 1],
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function totalSupply() public pure returns (uint256) {
        return 6;
    }
}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address who) external returns (uint256);
}

interface IERC721Ownership {
    function ownerOf(uint256 tokenId) external returns (address);
}

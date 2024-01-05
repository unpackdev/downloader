//
//                 -/oyhhhhhdddddhys+/:`
//              -sddyo+//////++ossssyyhdho-
//            -yds/:-------:::/+oo++++++oydh/`
//          `sms/-----....---::/+++++++++/+ohd+`
//         -dh+--------...----://++++++//////+yd+`
//        /my:-..------..-----::/++++++/////:::+hh-
//       /my:...---:::..-----:::/+++++///:::::---sm:
//      `md+:-..--:::---::::::::/oo++//:::------..om:
//      /Nhhys/---:+syysso/::::/+oo++//:-..........sm-
//     -mysy++o:-:+o+o+//+o/-::/+oo++//:-..`````...-dh`
//     yd:+s+:/::::--:+ho::/-:/+ooo+++/::-...````...oN-
//    .Ny:::-::/:---..-::...-:+osooo++///:---.......+N-
//    -Ny/:--::/-----.....---+osoooo++++//::::::---.+N-
//    .Nh+/:::::--::---:::::/osssooo+++++//////:::--/N:
//    `Ndo+/::::-:::::::////+ossssooo+++++///////::-/N/
//     ymoo/:::-://////////+ossssssoooooo++++++++//:/N/
//     smsoosyyso+////////+oosssssssoooooo++++++++//+N:
//     sNs+//syyy+///////++ossssssssssssooooooooo+++yN-
//     +Nyo+/:+so+///////+oossssyyssssssssoooooooooomy
//     `mdossssossss+///+oossssyyyysssssssssssssooodm-
//      /Ns::+syso+///++oossssyyyyyyyyyyssssssssssym+
//      `dd/-.-::::/+++ossssyyyyyyyyyyyyyssssssssyms
//       smo----::/++ossssyyyyyhhhhyyyyyyssssssssmh`
//       :Ny:/::/+oossyyyyyyhhhhhhyyhyyysssooossdh.
//       `smso++ossyyyhhhdddddhhyyyyyyysssoooosdm.
//         /dddhhhhhddmmmmmdhhyyyyyyyssoooooooym:
//          `-//+yNdmddhhhhyyyyssyyyssooo+++o++d.
//               :Nmdhhyyyysssssssssooo+++++/:-oh+.
//            `-ohNmhhyyyssssssssssoo+++///:----hmmy-
//         ./ymNNNs+oyyysssssooossoo++//::-....ommmmms.
//     `:ohmNNNNN+:/++sssssooooooo+//:--......-ydddmmmms.
//  ./ymNmmmmmmNo---:/+ooooo++++/:--..........oddddmdddmmdyo:.
// dmmmmmmmmmmNh-....-/oso:--....````........oddddddddddmddhddd
// mddddmmmmmmN:..-/yhhhyyys+-```````````...odddddddddddmmddhhh
//            __  __            __              __
//      ___  / /_/ /_     _____/ /_____  ____  / /_______
//     / _ \/ __/ __ \   / ___/ __/ __ \/ __ \/ //_/ ___/
//    /  __/ /_/ / / /  (__  ) /_/ /_/ / / / / ,< (__  )
//    \___/\__/_/ /_/  /____/\__/\____/_/ /_/_/|_/____/
//
//                   created by Mr F
//            HTML/CSS and Graphics by Karl
//             Advanced Solidity by ToCsIcK
//
//             https://ethstonks.finance/
//            https://discord.gg/mDMyTksceR
//               https://t.me/ethstonks
//

pragma solidity >=0.7.0 <=0.8.1;

import "./ERC165.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract StonkNFT is ERC165, ERC721 {
    using Strings for uint256;

    mapping(address => bool) hasMintedPreMarket;
    mapping(address => bool) hasMinted;

    address public owner;

    address private stonk;

    constructor()
    ERC721("StonkNFT", "SNFT")
    {
        // Owner
        owner = msg.sender;

        // Set base URI for token metadata
        _setBaseURI("https://ethstonks.finance/meta/");
    }

    function setStonk(address _stonk)
    public
    {
        require(msg.sender == owner);
        stonk = _stonk;
    }

    function mintPreMarket(address player, uint playerId)
    public
    {
        // Only Stonks contract can mint
        require(msg.sender == address(stonk));

        // Check if player has already minted and record
        if (hasMintedPreMarket[player]) {
            return;
        }

        hasMintedPreMarket[player] = true;

        // Grab player's ID from stonk contract
        uint id = uint256(keccak256(abi.encodePacked("premarket_", playerId)));

        // Mint and set metadata URI
        _safeMint(player, id);
        _setTokenURI(id, string(abi.encodePacked("live/premarket/", playerId.toString())));
    }

    function mint(address player, uint playerId)
    public
    {
        // Only Stonks contract can mint
        require(msg.sender == address(stonk));

        // Check if player has already minted and record
        if (hasMinted[player]) {
            return;
        }

        hasMinted[player] = true;

        // Grab player's ID from stonk contract
        uint id = uint256(keccak256(abi.encodePacked("main_", playerId)));

        // Mint and set metadata URI
        _safeMint(player, id);
        _setTokenURI(id, string(abi.encodePacked("live/main/", playerId.toString())));
    }

    function mintRopstenBeta(address player, uint playerId)
    public
    {
        require(msg.sender == owner);

        // Grab player's ID from stonk contract
        uint id = uint256(keccak256(abi.encodePacked("ropsten_", playerId)));

        // Mint and set metadata URI
        _safeMint(player, id);
        _setTokenURI(id, string(abi.encodePacked("beta/ropsten/", playerId.toString())));
    }

    function mintRinkebyBeta(address player, uint playerId)
    public
    {
        require(msg.sender == owner);

        // Grab player's ID from stonk contract
        uint id = uint256(keccak256(abi.encodePacked("rinkeby_", playerId)));

        // Mint and set metadata URI
        _safeMint(player, id);
        _setTokenURI(id, string(abi.encodePacked("beta/rinkeby/", playerId.toString())));
    }
}
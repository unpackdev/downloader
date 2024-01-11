//                            ..    ////////////
//                          //. .////.///////////////////
//                     /////*.*/ ..///////////////////////////
//                  //////.. ///// ..////////////////////////////
//               ///////.. //////.// /.///////////////////////////// .
//            .//// //.. ////.//.. /. /.//////////////////////////////
//           ////////./ ///.. ////..   ..///////////////////////////////
//          ////////.  *.* /  ./////. /./// /////////////////////////////
//        //////////../ .  ///./..//././../////////////////////////////////
//       //////////.  . ///././    /./ /////////////#@(//@@@@/@////@@///////
//      //////////// . /..///////..// ./@@@@/@//@/@@//@@/@/@@@@@///@@@&//////
//      ///////////// .// //.././//... @@//@@@@/@@/@@@@//@@////@@@@@@@@@@,///
//     //////////////. / .../ ///.... ./@@@//&@/@@/@@//@@/@@/  ////@@@@@@@////
//     /////////////. .. /../. ////// ../@///,@@@(//%@      @@@@@///@@////////
//     /////////////../. /./ . / ./(/// @@//  ////  ///@@///@@@/@///@@////.*//
//     ///////////////// /. /../ .//#(#@@/@@///@@@@@@//@@@@///#@@@(/@@///////.
//     //////////////#./ ..//../ ../.@@@///////@@//@@@/@@@@@@/@@@@///@@//////.
//      /////////////#//..///..// .//@@@/////@/@@@@@@/@@@///@@@@//////########
//      ////////@@///..///#//. // .///@@@//@@@////@//////////////#/%//(####.###
//       //////@//////  ./@/..//// .///@@@@@/////////#/@//(//@////#######(.###
//        ////@/////////@@/..////// .///////@@@@@///////(###########.########
//         ///////@///%@//..///////./ ////####################..#,########
//           ////@///////. //////##############*##..#################
//            @//(////.. ///####.###.#.,################*           //
//            @@ /////  /######.#######        @@@       ///////////
//                  ///###/#####   @ ////////////////////////////
//                    ####..  @//////////////////////////////
//                     ##&  //////@/////////////////////*
//                                   ///////////

// On the Purple Coast...
//
// This space time mist is inspired by and connected to our experience on the
// west coast over the last ten years. The energy signature is uplifting,
// playful and majestic with a depth of complexity.
//
// The mist blasts away the lingering tendrils of unrequited love from the
// auric field and calls in the expansive frequency of unconditional love.
//
// There is a feeling on that Pacific Coast of expansiveness and possibility
// that feels different than anywhere else on earth.
//
// Purple Coast reminds us that there are many layers to existence,
// consciousness and sensorial experiences in the multiverse. Working with the
// beautiful and multi-layered plant souls, water molecules and flower essences,
// we have found that interdimensional portals sometimes open.
//
// Portals of...
//
// Of waking up in a chilly cabin a redwood grove with the love of my younger
// years in the bed next to me but still so far away.
//
// Of stepping out of a car on a very steep street in San Francisco and having
// a glass bottle of purple coast mist fall out of our pocket and shatter on the
// street as an offering to the lands.
//
// Of dancing on the ruins of a castle built at the height of an artist
// community on a peninsula into the pacific bay waters wearing sparkly capes
// and carrying sparklers.
//
// Of hummingbirds dancing and kissing midair above me as I marvel at the
// flowers walking on a pacific coast bluff as I hear the mountain stream that
// ends in the pacific calls for me to bring the sacred valley green heart
// stone into her depths.
//
// Of whales just off the coast connecting their spirit field to the people on
// the cliffs drinking tea.
//
// Of purple sand underfoot at sunrise in a purple cape.
//
// Of what YOU are transforming into BEING!!

// PHOTOGRAPHY & SPACE MAGIC MISTS BY @mabfire
// https://www.1111.codes/

// SMART CONTRACT & WEB EXPERIENCE BY @arithmetric
// https://www.constellate.io/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

import "./base64.sol";

contract Origin is ERC721Enumerable, Ownable, ReentrancyGuard {
    // This contract allows for 11 tokens.
    uint256 public constant MAX_SUPPLY = 11;

    // Each token is assigned an element according to its minting sequence.
    string[] public ELEMENTS = [
        "Fire", // 0
        "Air", // 1
        "Water", // 2
        "Earth" // 3
    ];

    // There are 4 elements.
    uint256 public constant NUM_ELEMENTS = 4;

    // Up to 3 tokens will be assigned to each element.
    uint256 public constant TOKENS_PER_ELEMENT = 3;

    // Each token's title is comprised of 5 essences selected at mint time, and
    // these essences are specified and stored using their index in this array.
    string[] public ESSENCES = [
        "Magical", // 0
        "Sensorial", // 1
        "Intergalactic", // 2
        "Shimmering", // 3
        "Shining", // 4
        "Sparkling", // 5
        "Unrequited", // 6
        "Unconditional", // 7
        "Purple", // 8
        "Ephemeral", // 9
        "Gossamer", // 10
        "Inner", // 11
        "Coast", // 12
        "Sea", // 13
        "Ocean", // 14
        "Expanse", // 15
        "Doorway", // 16
        "Portal", // 17
        "Gate", // 18
        "Key", // 19
        "Cliff", // 20
        "Love", // 21
        "Fog", // 22
        "Sunset", // 23
        "Sunrise", // 24
        "Beginning", // 25
        "Space", // 26
        "Time", // 27
        "Spacetime", // 28
        "Journey", // 29
        "Sand", // 30
        "Wave", // 31
        "Mist", // 32
        "Seaweed", // 33
        "Trees", // 34
        "Depths", // 35
        "Embrace", // 36
        "Magic", // 37
        "Shifts", // 38
        "Creates", // 39
        "Glows", // 40
        "Travels", // 41
        "Transmutes", // 42
        "Dives", // 43
        "Regenenerates", // 44
        "Mists", // 45
        "Seeds", // 46
        "Grows", // 47
        "Envelops", // 48
        "Transforms", // 49
        "Loves", // 50
        "Aligns", // 51
        "Completes", // 52
        "Yearns", // 53
        "Fondly", // 54
        "Tenderly", // 55
        "Sweetly", // 56
        "Deeply", // 57
        "Lovingly", // 58
        "Magically", // 59
        "If", // 60
        "With", // 61
        "The", // 62
        "And", // 63
        "Of", // 64
        "Along", // 65
        "Next", // 66
        "How", // 67
        "When", // 68
        "What" // 69
    ];

    // There are 70 essences.
    uint256 public constant NUM_ESSENCES = 70;

    // Each token is associated with a photograph stored on IPFS. The images are
    // stored with the following URL prefix, then the token number, then `.jpg`.
    // For example:
    // ipfs://zdj7WktQVgbbSQ46wqc77e5by9sKSPd6RXKp62GE4uFyb1CxY/1.jpg
    string public baseImageURI =
        "ipfs://zdj7WktQVgbbSQ46wqc77e5by9sKSPd6RXKp62GE4uFyb1CxY/";

    // Stores the element for each token.
    mapping(uint256 => uint256) public tokenElement;

    // Stores the 5 essences for each token.
    mapping(uint256 => uint256[]) public tokenEssences;

    // Stores the sequence in which the tokens are minted.
    uint256[] public tokenSequence;

    // Initializes the Purple Coast Origin (PC0) NFT contract.
    constructor() ERC721("Purple Coast Origin", "PC0") {}

    // Returns the current price to mint a token. The first 3 tokens cost
    // 0.1111 ETH, the next 3 tokens cost 0.07474 ETH, and the next 3 tokens
    // cost 0.03838 ETH. The remaining 2 are reserved for the owner to claim.
    function getPrice() public view returns (uint256) {
        if (tokenSequence.length < 3) {
            return 111100000000000000;
        }
        if (tokenSequence.length < 6) {
            return 74740000000000000;
        }
        if (tokenSequence.length < 9) {
            return 38380000000000000;
        }
        require(false, "Token is not mintable");
        return 0;
    }

    // Allows anyone to mint a token by specifying an unminted token ID and
    // 5 essences and paying the current mint price.
    function mint(uint256 tokenId, uint256[] calldata _essences)
        public
        payable
        nonReentrant
        returns (uint256)
    {
        require(msg.value == getPrice(), "Incorrect price paid");
        return _handleMintClaim(tokenId, _essences);
    }

    // Allows the owner to claim a token without payment.
    function claim(uint256 tokenId, uint256[] calldata _essences)
        public
        onlyOwner
        returns (uint256)
    {
        return _handleMintClaim(tokenId, _essences);
    }

    // Internal function for validating inputs and minting the token.
    function _handleMintClaim(uint256 tokenId, uint256[] calldata _essences)
        internal
        returns (uint256)
    {
        require(tokenId > 0 && tokenId <= 11, "Token ID is invalid");
        require(!_exists(tokenId), "Token is already minted");
        require(
            _essences.length == 5 &&
                _essences[0] >= 0 &&
                _essences[0] < NUM_ESSENCES &&
                _essences[1] >= 0 &&
                _essences[1] < NUM_ESSENCES &&
                _essences[2] >= 0 &&
                _essences[2] < NUM_ESSENCES &&
                _essences[3] >= 0 &&
                _essences[3] < NUM_ESSENCES &&
                _essences[4] >= 0 &&
                _essences[4] < NUM_ESSENCES,
            "Essences are not valid"
        );

        _safeMint(_msgSender(), tokenId);
        tokenEssences[tokenId] = _essences;
        tokenElement[tokenId] = SafeMath.div(
            tokenSequence.length,
            TOKENS_PER_ELEMENT
        );
        tokenSequence.push(tokenId);
        return tokenId;
    }

    // Generates Base64-encoded JSON for the tokenURI response, which includes
    // the token title, image, and attributes (element and essences).
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory title;
        string memory attrs;
        for (uint256 i = 0; i < 5; i++) {
            title = string(
                abi.encodePacked(
                    title,
                    ESSENCES[tokenEssences[tokenId][i]],
                    " "
                )
            );
            attrs = string(
                abi.encodePacked(
                    attrs,
                    '{"trait_type": "Essence ',
                    Strings.toString(i + 1),
                    '", "value": "',
                    ESSENCES[tokenEssences[tokenId][i]],
                    '"}, '
                )
            );
        }
        string memory json = string(
            abi.encodePacked(
                '{"name": "',
                title,
                '", "image": "',
                baseImageURI,
                Strings.toString(tokenId),
                '.jpg", "attributes": [',
                attrs,
                '{"trait_type": "Element", "value": "',
                ELEMENTS[tokenElement[tokenId]],
                '"}]}'
            )
        );
        string memory output = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
        return output;
    }

    // Allows the owner to withdraw any balance from the contract.
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }
}

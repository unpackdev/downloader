// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//
// ██╗  ██╗██╗███╗   ██╗ ██████╗      ██████╗ ███████╗    ████████╗██╗  ██╗███████╗    ███╗   ███╗██╗███╗   ██╗███████╗██████╗ ███████╗
// ██║ ██╔╝██║████╗  ██║██╔════╝     ██╔═══██╗██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    ████╗ ████║██║████╗  ██║██╔════╝██╔══██╗██╔════╝
// █████╔╝ ██║██╔██╗ ██║██║  ███╗    ██║   ██║█████╗         ██║   ███████║█████╗      ██╔████╔██║██║██╔██╗ ██║█████╗  ██████╔╝███████╗
// ██╔═██╗ ██║██║╚██╗██║██║   ██║    ██║   ██║██╔══╝         ██║   ██╔══██║██╔══╝      ██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██╔══██╗╚════██║
// ██║  ██╗██║██║ ╚████║╚██████╔╝    ╚██████╔╝██║            ██║   ██║  ██║███████╗    ██║ ╚═╝ ██║██║██║ ╚████║███████╗██║  ██║███████║
// ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝      ╚═════╝ ╚═╝            ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝
//
// “King of the Miners” is a smart contract where NFTs can only be minted by finding a set of specific magic numbers within a hash.
// Your NFT can be stolen by another player if they find a higher amount of occurrences of the given magic number within a given hash.
//
// Hashes are generated as below, an NFT can be claimed by submitting a uint256 nonce
//
// `keccak(abi.encodePacked(address msg.sender, uint256 nonce, uint256 tokenId))`
//
// Images are generated using stable diffusion prompts related to the magic numbers
//
// R.I.P. proof of work, long live the merge

import "./ERC721.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./StringUtils.sol";

contract ProofOfWorkToken is ERC721 {
    /*--------------------------------------*\
    |**************** EVENTS ****************|
    \*--------------------------------------*/
    event NewKingOfTheMiners(
        address indexed miner,
        uint256 indexed token_id,
        uint256 occurrences
    );

    mapping(uint256 => string) public proofs;
    mapping(uint256 => uint256) public highest_occurrences;
    uint256 private num_proofs;

    constructor() ERC721("king of the miners", "POW") {
        proofs[1] = "deadbeef";
        proofs[2] = "1337";
        proofs[3] = "c0ffee";
        proofs[4] = "42";
        proofs[5] = "dec0de";
        proofs[6] = "00";

        num_proofs = 6;
    }

    /*--------------------------------------*\
    |*********** CALCULATING PROOF **********|
    \*--------------------------------------*/

    /*
     * Generates hash for the given token + nonce.
     */
    function getHash(uint256 nonce, uint256 token)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, nonce, token));
    }

    /*
     * Counts the occurrences of the given needle in the hex-encoded proof bytes generated thru getNonce
     */
    function countOccurrences(bytes32 hash, string memory needle)
        public
        pure
        returns (uint256)
    {
        return
            StringUtils.count(
                StringUtils.toSlice(Strings.toHexString(uint256(hash), 32)),
                StringUtils.toSlice(needle)
            );
    }

    /*--------------------------------------*\
    |***************** ERC721 ***************|
    \*--------------------------------------*/

    /*
     * Mints a new NFT if the amount of occurrences exceed the previous highest amount of occurrences
     */
    function claimWithNonce(uint256 token, uint256 nonce) public {
        require(token > 0 && token <= num_proofs, "this token does not exist");

        string memory proof = proofs[token];
        bytes32 hash = getHash(nonce, token);
        uint256 occurrences = countOccurrences(hash, proof);

        require(
            occurrences > highest_occurrences[token],
            "not the highest occurrence"
        );

        if (_ownerOf[token] == address(0)) {
            _mint(msg.sender, token);
        } else {
            _burn(token);
            _mint(msg.sender, token);
        }

        highest_occurrences[token] = occurrences;
        emit NewKingOfTheMiners(msg.sender, token, occurrences);
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id > 0 && id <= num_proofs, "this token does not exist");

        string memory proof = proofs[id];
        string memory score = Strings.toString(highest_occurrences[id]);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"description":"someone made his cpu and or gpu go brrrrrr for a digital jpeg","image_url":"ipfs://QmZkptYpqw2vWEB5bk5cs8kuQqgczi4jAQ3BNER6eTL4af/',
                                    proof,
                                    '.jpg","name":"',
                                    proof,
                                    '","attributes":[{"trait_type":"Proof of work score","value":',
                                    score,
                                    "}]}"
                                )
                            )
                        )
                    )
                )
            );
    }
}

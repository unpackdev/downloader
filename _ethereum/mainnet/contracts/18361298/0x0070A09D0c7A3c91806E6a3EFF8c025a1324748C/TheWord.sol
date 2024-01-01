//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Verifier.sol";

/* Reference Poseidon hasher library contract using 6 inputs */
library Poseidon {
    function poseidon(uint256[6] memory) public pure returns (uint256) {}
}

contract TheWord {
    /// STRUCTS ///
    struct Round {
        uint256 commitment; // the hash of the secret phrase
        uint256 prize; // the value of locked up ether to burn when when round is over
        string shoutedBy; // the address of the user who shouted the secret phrase
        bool active; // true if round can be shouted, false if over or doesn't exist
    }

    // Standard Groth16 proof elements
    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    /// VARIABLES ///

    // Circom R1CS Verifier contract
    Groth16Verifier verifier;

    // Address to burn ether to
    address payable public burnLocation = payable(0x00);

    // index of rounds
    uint256 public round;

    // map round index to round storage
    mapping(uint256 => Round) public rounds;

    /// EVENTS ///
    event NewRound(
        uint256 round,
        uint256 commitment,
        string username,
        uint256 prize
    );
    event Shouted(uint256 round, string shoutedBy);
    event PrizeAdded(uint256 round, uint256 added);

    /// MODIFIERS ///

    /**
     * Prevent function from being called if given index does not point to active round
     * @param _round - the round index to check for activity status
     */
    modifier active(uint256 _round) {
        require(rounds[_round].active, "Round is not active");
        _;
    }

    /**
     * Constructs new TheWord contract
     * @param _verifier - the address of the deployed circom r1cs verifier for the word proofs
     */
    constructor(address _verifier) {
        verifier = Groth16Verifier(_verifier);
    }

    /// EXTERNAL FUNCTIONS ///

    /**
     * Create a new round, optionally funding a prize for shouting
     * @dev cannot guarantee the secret phrase is within length requirement (could solve in circuit)
     *
     * @param _commitment - the hash of the secret phrase for which knowledge must be proven
     * @param _username - the username of the user proving their knowledge of the secret phrase
     * @param _proof - the groth16 proof that demonstrates the creator knows the secret phrase
     */
    function newRound(
        uint256 _commitment,
        string memory _username,
        Groth16Proof calldata _proof
    ) external payable {
        // convert username to uint256
        uint256 username = stringToUint(_username);

        // check that the proof is valid
        require(
            verifier.verifyProof(
                _proof.a,
                _proof.b,
                _proof.c,
                [_commitment, username]
            ),
            "Invalid proof"
        );

        // create a new round
        round++;
        rounds[round].commitment = _commitment;
        rounds[round].prize = msg.value;
        rounds[round].active = true;

        // emit event announcing new round
        emit NewRound(round, _commitment, _username, msg.value);
    }

    /**
     * End a round by shouting the secret phrase
     * @dev todo: maybe ecrecover a signature on secret for shoutedBy
     *
     * @param _round - the round index
     * @param _secret - the secret phrase that hashes to the round commitment
     * @param _username - the username of the user proving their knowledge of the secret phrase
     */
    function shout(
        uint256 _round,
        string calldata _secret,
        string memory _username
    ) external active(_round) {
        // convert the secret phrase to field elements
        uint256[6] memory felts = secretToFelts(_secret);

        // compute the hash of the phrase
        uint256 hash = hashPhrase(felts);

        // compare the hash to the commitment
        require(hash == rounds[_round].commitment, "Invalid secret phrase");

        // burn ether if prize exists for round and mark round as inactive
        endRound(_round, _username);

        // emit event announcing round end
        emit Shouted(_round, _username);
    }

    /**
     * Adds a prize to a round that has already been created
     * @param _round - the round to add a prize to
     */
    function fundPrize(uint256 _round) external payable active(_round) {
        rounds[_round].prize += msg.value;
        emit PrizeAdded(_round, msg.value);
    }

    /// INTERNAL FUNCTIONS ///

    /**
     * Send ether from the contract to the burn address, and mark as inactive
     * @dev this function is only ever called by shout which provides the `active` modifier check
     *
     * @param _round - the round to burn ether from
     * @param _shoutedBy - the username of the user who shouted the secret phrase
     */
    function endRound(uint256 _round, string memory _shoutedBy) internal {
        rounds[_round].active = false;
        rounds[_round].shoutedBy = _shoutedBy;
        if (rounds[_round].prize > 0) {
            burnLocation.transfer(rounds[_round].prize);
        }
    }

    /// VIEW/ PURE FUNCTIONS ///

    /**
     * Converts a secret phrase as utf8 bytes into 6 serialized bn254 field elements
     *
     * @param _secret - the secret phrase, utf8 encoded, to convert to field elements
     * @return felts - the 6 field elements representing the secret phrase
     */
    function secretToFelts(
        string calldata _secret
    ) public pure returns (uint256[6] memory felts) {
        bytes memory secret = bytes(_secret);
        require(
            secret.length <= 180,
            "secret too long: must be <= 200 characters"
        );

        for (uint256 i = 0; i < 6; i++) {
            uint256 start = i * 31;
            uint256 end = (i + 1) * 31;

            bytes memory chunk = new bytes(32);

            for (uint256 j = start; j < end && j < secret.length; j++) {
                chunk[j - start + 1] = secret[j];
            }

            bytes32 chunk32;
            assembly {
                chunk32 := mload(add(chunk, 32))
            }

            felts[i] = uint256(chunk32);
        }
    }

    /**
     * Hashes the 6 field elements representing secret phrase into the public commitment
     *
     * @param _felts - the preimage to hash
     * @return - the poseidon hash commiting to the secret phrase
     */
    function hashPhrase(
        uint256[6] memory _felts
    ) public pure returns (uint256) {
        return Poseidon.poseidon(_felts);
    }

    function stringToUint(string memory source) public pure returns (uint256 result) {
        bytes memory tempString = bytes(source);
        if (tempString.length == 0) {
            return 0x0;
        }
        
        // For each byte, shift result and insert the byte
        for (uint256 i = 0; i < tempString.length; i++) {
            result = (result << 8) | uint256(uint8(tempString[i]));
        }
    }
}

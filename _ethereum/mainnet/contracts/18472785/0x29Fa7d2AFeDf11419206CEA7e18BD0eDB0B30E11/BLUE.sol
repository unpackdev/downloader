// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC20.sol";

contract BLUE is ERC20 {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    mapping(address => bool) public alreadyClaimed;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    function mint(Signature memory serverSignature) public {

        //     |\__/,|   (`\
        //   _.|o o  |_   ) )
        // -(((---(((--------
        // | hi anon
        // | whether you're a searcher or protocol
        // | or a builder, do reach out to us!
        // | devs.aori.io
        // ------------------

        // Check that the sender hasn't already claimed
        require(alreadyClaimed[msg.sender] != true, "Already claimed");

        // Compute the sender hash
        bytes32 senderHash = keccak256(
            abi.encode(
                msg.sender,
                "BLUE"
            )
        );

        // Check that the server signature corresponds to the sender hash
        require(
            owner == ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        senderHash
                    )
                ),
                serverSignature.v,
                serverSignature.r,
                serverSignature.s
            ),
             "Server signature does not correspond to sender hash"
        );

        // Let the sender claim their 1000 tokens
        alreadyClaimed[msg.sender] = true;
        _mint(msg.sender, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function name() public view virtual override returns (string memory) {
        return "BLUE";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "BLUE";
    }
}
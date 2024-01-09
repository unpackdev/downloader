// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///  _                   _       
/// |_|_____ ___ ___ ___| |_ ___ 
/// | |     | . | . |  _|  _|_ -|
/// |_|_|_|_|  _|___|_| |_| |___|
///         |_|                  

import "./VRFConsumerBase.sol";



///              _               _      _____ _____ _____ ___ ___ 
///  ___ ___ ___| |_ ___ ___ ___| |_   |  |  | __  |   __|_  |   |
/// |  _| . |   |  _|  _| .'|  _|  _|  |  |  |    -|   __|  _| | |
/// |___|___|_|_|_| |_| |__,|___|_|     \___/|__|__|__|  |___|___|
                                                              
/// @title Tactical Tangrams VRP20 randomness contract
/// @author tacticaltangrams.io, based on a sample taken from https://docs.chain.link/docs/chainlink-vrf/
/// @notice Requests random seed for each generation
abstract contract VRFD20 is VRFConsumerBase {




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @dev Note that these parameter values differ per network, see https://docs.chain.link/docs/vrf-contracts/
    /// @param _vrfCoordinator Chainlink VRF Coordinator address
    /// @param _link           LINK token address
    /// @param _keyHash        Public key against which randomness is created
    /// @param _fee            VRF Chainlink fee in LINK
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
    }


    /// @notice Request generation seed
    /// @dev Only request when last request is: older than 30 minutes and (seed has not been requested or received) and (previous generation seed has been received)
    /// @param requestForGeneration Generation for which to request seed
    function requestGenerationSeed(uint requestForGeneration) internal
        lastGenerationSeedRequestTimedOut()
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );

        // Do not check whether seed has already been requested; requests can theoretically timeout
        require(
            (generationSeed[requestForGeneration] == 0) ||            // not requested
            (generationSeed[requestForGeneration] == type(uint).max), // not received
            "Seed already requested or received"
        );

        // Verify that previous generation seed has been received, when applicable
        if (requestForGeneration > 1)
        {
            require(
                generationSeed[requestForGeneration-1] != type(uint).max,
                "Previous generation seed not received"
            );
        }

        lastGenerationSeedRequestTimestamp = block.timestamp;

        bytes32 requestId = requestRandomness(keyHash, fee);
        generationSeedRequest[requestId] = requestForGeneration;
        generationSeed[requestForGeneration] = type(uint).max;
    }


    /// @notice Cast uint256 to bytes
    /// @param x Value to cast from
    /// @return b Bytes representation of x
    function toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }


    /// @notice Receive generation seed
    /// @dev Only possible when generation seed has not been received yet
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint generation = generationSeedRequest[requestId];

        require(
            (generation >= 1) && (generation <= 7),
            "Invalid generation"
        );

        if (generation > 1)
        {
            require(
                generationSeed[generation-1] != type(uint).max,
                "Previous generation seed not received"
            );
        }

        require(
            generationSeed[generation] == type(uint).max,
            "Random number not requested or already received"
        );

        generationSeed[generation] = randomness;
        generationHash[generation] = keccak256(toBytes(randomness));

        processGenerationSeedReceived(generation);
    }




    /// @notice Method invoked when randomness for a valid request has been received
    /// @dev Implement this method in inheriting contract. Random number is stored in generationSeed[generation]
    /// @param generation Generation number for which random number has been received
    function processGenerationSeedReceived(uint generation) virtual internal;


    /// @notice Allow re-requesting of generation seeds after GENERATION_SEED_REQUEST_TIMEOUT (30 minutes)
    /// @dev In the very unlikely event that a request is never answered, re-requesting should be allowed
    modifier lastGenerationSeedRequestTimedOut()
    {
        require(
            (lastGenerationSeedRequestTimestamp + GENERATION_SEED_REQUEST_TIMEOUT) < block.timestamp,
            "Not timed out"
        );
        _;
    }


    /// @notice Chainlink fee in LINK for VRF
    /// @dev Set this to 0.1 LINK for Rinkeby, 2 LINK for mainnet
    uint private immutable fee;

    bytes32 private immutable keyHash;

    uint lastGenerationSeedRequestTimestamp = 0;
    uint GENERATION_SEED_REQUEST_TIMEOUT    = 1800; // 30 minutes request timeout

    mapping(bytes32 => uint) public generationSeedRequest;
    mapping(uint    => uint) public generationSeed;
    mapping(uint    => bytes32) public generationHash;
}

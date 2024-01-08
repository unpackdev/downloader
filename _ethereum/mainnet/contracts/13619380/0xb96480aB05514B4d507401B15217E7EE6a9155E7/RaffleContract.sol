// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract RaffleContract is Ownable {
    struct Raffle {
        uint256 seed;
        string listURI;
    }

    Raffle[] private raffles;

    /**
     * @dev Generates a random number and adds the IPFS link to the raffle data
     */
    function addRaffle(string memory _listURI) external onlyOwner {
        raffles.push(Raffle(_generateSeed(), _listURI));
    }

    /**
     * @dev Returns the IPFS link for the raffle
     */
    function getRaffleURI(uint256 _raffleId)
        external
        view
        returns (string memory)
    {
        require(_raffleId < raffles.length, "Invalid raffle id");

        return raffles[_raffleId].listURI;
    }

    /**
     * @dev Returns a list of random numbers for the given input
     * This output is deterministic, by using the seed generated when
     * the raffle was created.
     */
    function getRaffleResults(
        uint256 _raffleId,
        uint256 _totalParticipants,
        uint256 _quantity,
        uint256 _offset
    ) external view returns (uint256[] memory) {
        require(_raffleId < raffles.length, "Invalid raffle id");

        uint256[] memory results = new uint256[](_quantity);
        for (uint256 i = _offset; i < _quantity + _offset; i++) {
            results[i - _offset] = _getRandomNumber(
                _totalParticipants,
                raffles[_raffleId].seed,
                i
            );
        }

        return results;
    }

    /**
     * @dev Generates a pseudo-random number using the seed of a raffle.
     */
    function _getRandomNumber(
        uint256 _upper,
        uint256 _seed,
        uint256 _index
    ) private pure returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(_seed, _index)));

        return random % _upper;
    }

    /**
     * @dev Generates a pseudo-random seed for a raffle.
     */
    function _generateSeed() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        raffles.length,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AccessControlEnumerable.sol";

import "./VRFConsumerBase.sol";

/// Manage PostalCodes of Propertys
contract PostalCodeProvider is AccessControlEnumerable, VRFConsumerBase {
    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;

    // Available
    uint32[] private o;
    uint32[] private s;

    // Chainlink VRF
    bytes32 public _requestId;
    uint256 public _randomSeed;

    // Implementation Free Space
    uint256[48] private __gap;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        keyHash = _keyHash;
        fee = _fee;
    }

    /// @dev Set Available mints
    function pushAvailable(uint32[] memory _available)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint16 i; i < _available.length; i++) {
            o.push(_available[i]);
            s.push(_available[i]);
        }
    }

    /// @dev Initialize Randomness using chainlink
    function randomizeTokenIds()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /// @dev Callback function for Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        _requestId = requestId;
        _randomSeed = randomness;
    }

    // change to internal
    function shuffle() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 randomness = _randomSeed;
        // Yates Shuffle algorithm
        for (uint16 i = 0; i < s.length - 2; i++) {
            // Get a random integer j between [i, n)
            uint256 j = (randomness % (s.length - 1 - i + 1)) + i;

            // exchange a[i] and a[j]
            uint32 temp = s[i];

            s[i] = s[j];
            s[j] = temp;

            randomness = uint256(keccak256(abi.encode(randomness, i)));
        }
    }

    function getTokenId(uint256 tokenId) external view returns (uint256) {
        uint256 pos = binarySearch(0, o.length - 1, tokenId);
        return s[pos];
    }

    function getAvailable()
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint32[] memory)
    {
        return s;
    }

    function binarySearch(
        uint256 l,
        uint256 r,
        uint256 x
    ) internal view returns (uint256) {
        // Check base case
        if (r >= l) {
            uint256 mid = l + (r - l) / 2;

            // If element is present at the middle itself
            if (o[mid] == x) {
                return mid;
            }
            // If element is smaller than mid, then it
            //can only be present in left subarray
            else if (o[mid] > x) {
                return binarySearch(l, mid - 1, x);

                // Else the element can only be present
                // in right subarray
            } else {
                return binarySearch(mid + 1, r, x);
            }
        } else {
            // Element is not present in the array
            revert("Element is not present in the array");
        }
    }
}

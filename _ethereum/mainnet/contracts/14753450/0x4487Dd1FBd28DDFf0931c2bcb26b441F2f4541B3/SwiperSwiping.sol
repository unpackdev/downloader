//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./MerkleProof.sol";

import "./SwiperSwipingSetup.sol";

contract SwiperSwiping is Initializable, SwiperSwipingSetup {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        SwiperSwipingSetup.__SwiperSwipingSetup_init();
    }

    function claimTower1(bytes32[] memory _proof, uint256[] memory _tokenIds) external {
        _claim(_proof, _tokenIds, true);
    }

    function claimTower2(bytes32[] memory _proof, uint256[] memory _tokenIds) external {
        _claim(_proof, _tokenIds, false);
    }

    function getTokenIdsToClaimTower1(address _addr, uint256[] calldata _tokenIds) public view returns (uint256[] memory) {
        return _getTokenIdsToClaim(_addr, _tokenIds, true);
    }

    function getTokenIdsToClaimTower2(address _addr, uint256[] calldata _tokenIds) public view returns (uint256[] memory) {
        return _getTokenIdsToClaim(_addr, _tokenIds, false);
    }

    function _claim(bytes32[] memory _proof, uint256[] memory _tokenIds, bool isTower1) internal {
        SwiperInfo storage info = isTower1 ? addressToClaimInfoTower1[msg.sender] : addressToClaimInfoTower2[msg.sender];
        require(!info.hasClaimedAll,"Tokens already claimed");
        bytes32 _merkleRoot = isTower1 ? merkleRootTower1 : merkleRootTower2;
        address _towerAddress = isTower1 ? tower1Address : tower2Address;

        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _tokenIds));

        require(
            MerkleProof.verify(_proof, _merkleRoot, _leaf),
            "Proof invalid"
        );

        uint256 _counter;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _token = _tokenIds[i];
            // If the merkle has claimed the token OR the user claimed the token by some other means, skip it.
            if(info.tokenIdsClaimed.contains(_token) || wnd.ownerOf(_token) != _towerAddress) {
                continue;
            }
            info.tokenIdsClaimed.add(_token);
            // Pull token from tower1 contract
            wnd.transferFrom(_towerAddress, msg.sender, _token);
            if(++_counter == maxBatchSize) {
                return;
            }
        }
        // Got through the entire loop that was in the merkle, mark done forever
        info.hasClaimedAll = true;
    }

    // Returns the tokenIds that have not been claimed from the given array. 
    // Will contain 0's when tokens have been partially claimed.
    function _getTokenIdsToClaim(address _addr, uint256[] calldata _tokenIds, bool isTower1) internal view returns(uint256[] memory) {
        SwiperInfo storage info = isTower1 ? addressToClaimInfoTower1[_addr] : addressToClaimInfoTower2[_addr];
        uint256[] memory _retVal = new uint256[] (_tokenIds.length);
        uint256 _counter = 0;
        if(info.hasClaimedAll) {
            return _retVal;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _token = _tokenIds[i];
            if(!info.tokenIdsClaimed.contains(_token)) {
                _retVal[_counter++] = _token;
            }
        }
        return _retVal;
    }
}
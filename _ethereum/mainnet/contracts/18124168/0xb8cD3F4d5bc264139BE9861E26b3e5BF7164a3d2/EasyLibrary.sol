// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

library EasyLibrary {
    error SkewedArrays();

    /**
    Batch contains a set amount of token IDs and details for minting and metadata uri structure.
    */
    struct Batch {
        uint[3] bRangeNext; //0 = start, 1 = end, 2 = nextToken to try mint
        string[2] bURI; //metadata uri 0 = prefix, 1 = suffix
        
        bool bRevealed; //revealed state
        bool bPaused; //pause state
        bool bBindOnMint; //bind on mint state, true = tokens cannot be moved after mint
        bool bMintInOrder; //state if tokens will be minted in numeric order

        bool bRollSwapAllow; //state if tokens can have it's roll swapped
        bool bRollInUse; //state if tokens will have a random roll when minted
        uint[2] bRollRange; //excluded Min & included Max of random roll
        uint bRollCost; //price for swapping roll
        
        uint bCost; //cost to mint each token
        uint bLimit; //max amount a wallet can mint, 0 = no limit
        uint bSupply; //supply of each token within the batch, 0 = no limit

        uint bTriggerPoint; //point to trigger next cost
        uint bNextCost; //cost is set to this after trigger point is met
        uint bMintStartDate; //date in unix timestamp to open mint
        
        uint[] bRequirementTokens; //tokens required to be held for minting
        uint[] bRequirementAmounts; //amount required for each token required
        address[] bRequirementAddresses; //address for the requirements
        bool[] bRequirementContractType; //true = ERC1155 , false = ERC721
    }

    /**
    Tier is a whitelist but active during public mint.
    - tLimit is the limited amount that tier is allowed
        a minter is then moved into the next tier when the limit is met
    - tCost is the cost for that tier
    - tRoot is the Merkle Root of the tier list
    */
    struct Tier {
        uint256 tLimit;
        uint256 tCost;
        bytes32 tRoot;
    }

    /**
    @dev Returns a random number between excluded rollLimitMin and included rollLimitMax for a given batch _fromBatch.
    @return A string representing the randomly selected roll within the specified range.
    */
    function randomRoll(uint256 seed, uint256 rollCounter, uint256 rollLimitMax, uint256 rollLimitMin) internal view returns (string memory) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            seed,
            rollCounter,
            block.timestamp,
            msg.sender
        ))) % (rollLimitMax);

        if (random < rollLimitMin) {
            return Strings.toString(rollLimitMax - (random + 1));
        } else {
            return Strings.toString(random + 1);
        }
    }

    function validateRoll(uint256 _roll, bool rollSwapAllow, uint256 rollLimitMin, uint256 rollLimitMax, uint256 _balance, uint256 rollCost) internal view {
        require(rollSwapAllow, "!RR");
        require(_roll > rollLimitMin && _roll <= rollLimitMax, "!R");
        require(_balance > 0, "!O");
        require(msg.value >= (rollCost), "$?");
    }

    function validateTier(bytes32[] calldata proof, bytes32 leaf, Tier[] storage tiers) public view returns (bool, uint8) {
        if (tiers.length != 0) {
            for (uint8 i = 0; i < tiers.length; i++) {
                if (MerkleProof.verify(proof, tiers[i].tRoot, leaf)) {
                    return (true, i);
                }
            }
        }
        
        return (false, 0);
    }

    function hasSufficientTokens(address[] memory _tokenContract, address _account, uint256[] memory _tokens, uint256[] memory _amounts, bool[] memory _cType) internal view returns (bool) {
        if(_tokens.length != _amounts.length) {
            revert SkewedArrays();
        }
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            if(_cType[i]) {
                IERC1155 tokenContract = IERC1155(_tokenContract[i]);
                uint256 _userTokenBalance = tokenContract.balanceOf(_account, _tokens[i]);
                if (_userTokenBalance < _amounts[i]) {
                    return false;
                }
            } else {
                IERC721 tokenContract = IERC721(_tokenContract[i]);
                address _tokenOwner = tokenContract.ownerOf(_tokens[i]);
                if (msg.sender != _tokenOwner) {
                    return false;
                }
            }
        }
        
        return true;
    }
}
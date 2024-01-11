// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./OwnableOperators.sol";

import "./EtherealStatesVRFUpdated.sol";
import "./EtherealStatesDNA.sol";

/// @title EtherealStatesRevealManager
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, dievardump@gmail.com)
/// @notice EtherealStates Reveal logic
contract EtherealStatesRevealManager is
    OwnableOperators,
    EtherealStatesVRFUpdated
{
    error NotRevealed();
    error WrongContext();

    /// @notice emitted whenever the DNA changes.
    event TokenDNAChanged(
        address operator,
        uint256 indexed tokenId,
        bytes32 oldDNA,
        bytes32 newDNA
    );

    /// @notice emitted whenever the random seed is set for a request
    event RequestFulfilled(uint256 requestId, uint256 seed);

    struct RevealGroup {
        uint256 requestId;
        uint256 endTokenId;
    }

    /// @notice NFT holder
    address public etherealstates;

    /// @notice DNA Generator contract
    address public dnaGenerator;

    /// @notice the next group id to reveal
    uint256 public nextGroupId;

    /// @notice seeds for each request sent
    mapping(uint256 => uint256) public seeds;

    /// @notice this allows to save the DNA in the contract instead of having to generate
    ///         it every time we call tokenDNA()
    mapping(uint256 => bytes32) public revealedDNA;

    mapping(uint256 => RevealGroup) public revealedGroups;

    constructor(
        address etherealstates_,
        address dnaGenerator_,
        VRFConfig memory vrfConfig_
    ) EtherealStatesVRFUpdated(vrfConfig_) {
        etherealstates = etherealstates_;
        dnaGenerator = dnaGenerator_;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function hasHoldersTrait(uint256 tokenId) public view returns (bool) {
        return IEtherealStates(etherealstates).hasHoldersTrait(tokenId);
    }

    /// @notice Get the DNA for a given tokenId
    /// @param tokenId the token id to get the DNA for
    /// @return dna the DNA
    function tokenDNA(uint256 tokenId) public view returns (bytes32 dna) {
        dna = revealedDNA[tokenId];

        if (dna == 0x0) {
            (, uint256 seed, ) = groupForTokenId(tokenId, 0);
            if (seed == 0) {
                revert NotRevealed();
            }
            dna = _tokenDNA(tokenId, seed);
        }
    }

    /// @notice Get the DNA for a range of ids
    /// @param startId the token id to start at
    /// @param howMany how many to fatch
    /// @return dnas the DNAs
    function tokensDNA(uint256 startId, uint256 howMany)
        public
        view
        returns (bytes32[] memory dnas)
    {
        uint256 tokenId;

        (
            RevealGroup memory group,
            uint256 seed,
            uint256 currentGroupId
        ) = groupForTokenId(startId, 0);

        bytes32 dna;
        dnas = new bytes32[](howMany);

        for (uint256 i; i < howMany; i++) {
            tokenId = startId + i;
            // if not in this group, select next group
            if (tokenId > group.endTokenId) {
                (group, seed, currentGroupId) = groupForTokenId(
                    tokenId,
                    currentGroupId + 1 // start at next group
                );
            }

            // break the loop if no seed for this group
            if (seed == 0) break;

            dna = revealedDNA[tokenId];
            if (dna == 0x0) {
                dna = _tokenDNA(tokenId, seed);
            }
            dnas[i] = dna;
        }
    }

    /// @notice Returns the group info for a tokenId
    /// @param tokenId the token id
    /// @param startAtGroupId where to start in the groups
    /// @return the group info
    /// @return the seed
    /// @return the group id
    function groupForTokenId(uint256 tokenId, uint256 startAtGroupId)
        public
        view
        returns (
            RevealGroup memory,
            uint256,
            uint256
        )
    {
        uint256 nextGroupId_ = nextGroupId + 1;
        RevealGroup memory group;
        for (; startAtGroupId <= nextGroupId_; startAtGroupId++) {
            group = revealedGroups[startAtGroupId];
            // if we found the right group
            if (group.endTokenId >= tokenId) {
                break;
            }
        }

        return (group, seeds[group.requestId], startAtGroupId);
    }

    /////////////////////////////////////////////////////////
    // Setters                                             //
    /////////////////////////////////////////////////////////

    /// @notice Allows to save the DNA of a tokenId so it doesn't need to be recomputed
    ///         after that
    /// @param tokenId the token id to reveal
    /// @return dna the DNA
    function revealDNA(uint256 tokenId) external returns (bytes32 dna) {
        (, uint256 seed, ) = groupForTokenId(tokenId, 0);

        // make sure the group has a seed
        if (seed == 0) {
            revert NotRevealed();
        }

        dna = revealedDNA[tokenId];

        // only reveal if not already revealed
        if (dna == 0x0) {
            dna = _tokenDNA(tokenId, seed);
            revealedDNA[tokenId] = dna;
            emit TokenDNAChanged(msg.sender, tokenId, 0x0, dna);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice Allows an Operator to update a token DNA, for reasons
    /// @dev the DNA must have been revealed before
    /// @param tokenId the token id to update the DNA of
    /// @param newDNA the new DNA
    function updateTokenDNA(uint256 tokenId, bytes32 newDNA)
        external
        onlyOperator
    {
        bytes32 dna = revealedDNA[tokenId];
        if (dna == 0x0) {
            revert NotRevealed();
        }

        revealedDNA[tokenId] = newDNA;
        emit TokenDNAChanged(msg.sender, tokenId, dna, newDNA);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to update dna generator
    /// @param newGenerator the new address of the dna generator
    function setDNAGenerator(address newGenerator) external onlyOwner {
        dnaGenerator = newGenerator;
    }

    /// @notice Allows owner to start the reveal process for the last batch of items minted
    function nextReveal() external onlyOwner {
        // only call if requestId is 0
        if (requestId != 0) {
            revert WrongContext();
        }

        uint256 requestId_ = _requestRandomWords();

        // create next group
        uint256 groupId = nextGroupId++;
        revealedGroups[groupId] = RevealGroup(
            requestId_,
            IEtherealStates(etherealstates).totalMinted()
        );
    }

    /// @notice Allows owner to update the VRFConfig if something is not right
    function setVRFConfig(VRFConfig memory vrfConfig_) external onlyOwner {
        vrfConfig = vrfConfig_;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // called when ChainLink answers with the random number
    function fulfillRandomWords(uint256 requestId_, uint256[] memory words)
        internal
        override
    {
        seeds[requestId_] = words[0];
        emit RequestFulfilled(requestId_, words[0]);

        // allow next reveal
        requestId = 0;
    }

    function _tokenDNA(uint256 tokenId, uint256 seed)
        internal
        view
        returns (bytes32)
    {
        return
            EtherealStatesDNA(dnaGenerator).generate(
                uint256(keccak256(abi.encode(seed, tokenId))),
                hasHoldersTrait(tokenId)
            );
    }
}

interface IEtherealStates {
    function totalMinted() external view returns (uint256);

    function hasHoldersTrait(uint256 tokenId) external view returns (bool);

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}

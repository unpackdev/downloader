// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./VRFConsumerBase.sol";
import "./SpeakerHeadsBase.sol";

contract SpeakerHeads is SpeakerHeadsBase, VRFConsumerBase {
    using Address for address;
    using Strings for uint256;

    string public provenanceHash;
    bool public revealed;
    bool public specialEditionsRevealed;
    bool public randomOffsetGenerated;

    uint256 internal _tokenOffset;
    uint256 internal _linkFee;
    bytes32 internal _linkKeyHash;

    string internal _baseTokenURI;
    string internal _unrevealedTokenURI;
    string internal _specialEditionsURI;

    constructor(
        string memory unrevealedTokenURI,
        address teamAddress,
        address signer,
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee
    )
        VRFConsumerBase(vrfCoordinator, linkToken)
        SpeakerHeadsBase(teamAddress, signer)
    {
        _teamAddress = teamAddress;
        _unrevealedTokenURI = unrevealedTokenURI;

        _linkKeyHash = linkKeyHash;
        _linkFee = linkFee;
    }

    function tokenOffset() public view returns (uint256) {
        return _tokenOffset;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        uint256 numberSpecialReserved = _numSpecialEditionToken();
        if (tokenId < numberSpecialReserved) {
            // These are special edition tokens
            require(_exists(tokenId), "Query for nonexistent token");
            if (specialEditionsRevealed) {
                return
                    string(
                        abi.encodePacked(
                            _specialEditionsURI,
                            metadataId(tokenId).toString()
                        )
                    );
            } else {
                return _unrevealedTokenURI;
            }
        } else {
            // These are all the others
            if (revealed) {
                return
                    string(
                        abi.encodePacked(
                            _baseURI(),
                            metadataId(tokenId).toString()
                        )
                    );
            } else {
                return _unrevealedTokenURI;
            }
        }
    }

    function metadataId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Query for nonexistent token");

        if (!revealed) {
            return tokenId;
        }

        uint256 numberSpecialReserved = _numSpecialEditionToken();
        if (tokenId < numberSpecialReserved) {
            return tokenId;
        } else {
            return
                ((tokenId + tokenOffset()) %
                    (MAX_SUPPLY - numberSpecialReserved)) +
                numberSpecialReserved;
        }
    }

    function setUnrevealedTokenURI(string memory newURI) public onlyOwner {
        _unrevealedTokenURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI)
        public
        onlyOwner
        isNotRevealed
    {
        _baseTokenURI = _newBaseURI;
    }

    function setSpecialEditionsURI(string memory _newSpecialEditionsURI)
        public
        onlyOwner
        isSpecialEditionsNotRevealed
    {
        _specialEditionsURI = _newSpecialEditionsURI;
    }

    /**
     * @dev reveal metadata of tokens.
     * @dev only can call one time, and only owner can call it.
     * @dev function will request to chainlink oracle and receive random number.
     * @dev contract will get this number by fulfillRandomness function.
     * @dev You should transfer 2 LINK token to contract, before call this function
     */
    function reveal() public onlyOwner isNotRevealed {
        require(bytes(provenanceHash).length > 0, "Provenance hash not set");
        require(bytes(_baseTokenURI).length > 0, "BaseURI not set");
        require(randomOffsetGenerated, "Must generate random offset");
        revealed = true;
    }

    function generateRandomOffset() public onlyOwner isNotRevealed {
        require(
            LINK.balanceOf(address(this)) >= _linkFee,
            "Insufficient $LINK balance"
        );
        requestRandomness(_linkKeyHash, _linkFee);
    }

    function revealSpecialEditions()
        public
        onlyOwner
        isSpecialEditionsNotRevealed
    {
        require(
            bytes(_specialEditionsURI).length > 0,
            "SpecialEditionsURI not set"
        );
        specialEditionsRevealed = true;
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        _tokenOffset = randomNumber;
        randomOffsetGenerated = true;
    }

    /**
     * @dev set ProvenanceHash only once.
     * @notice ProvenanceHash should not be set already
     */

    function setProvenanceHash(string memory _provenanceHash)
        public
        onlyOwner
        isNotRevealed
    {
        require(
            bytes(provenanceHash).length == 0,
            "Provenance hash already set"
        );
        provenanceHash = _provenanceHash;
    }

    /**
     * @dev withdraw remaining link token
     */
    function withdrawLinkToken(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) {
            to = msg.sender;
        }
        if (amount == 0) {
            amount = LINK.balanceOf(address(this));
        }

        LINK.transfer(to, amount);
    }

    modifier isNotRevealed() {
        require(!revealed, "Must not be revealed");
        _;
    }

    modifier isRevealed() {
        require(revealed, "Must be revealed");
        _;
    }

    modifier isSpecialEditionsNotRevealed() {
        require(!specialEditionsRevealed, "SEs must not be revealed");
        _;
    }
}

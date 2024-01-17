// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OBYToken.sol";
import "./BlackSquareNFT.sol";


contract OBYTransfer_V1 {
    using Strings for uint256;

    OBYToken obyToken;
    BlackSquareNFT blackSquare;

    uint256 constant OBY_PER_CYCLE = 300;
    uint256 constant TOKENS_PER_EDITION = 25;

    address owner;

    bool public claimable;

    struct BlacksquareEdition {
        uint256[TOKENS_PER_EDITION] tokens;
        uint256 illuminationTimeStamp;
        uint256 cycle;
    }

    struct ClaimableOBY {
        uint256 tokenId;
        uint256 claimablereward;
    }

    mapping(uint256 => mapping(uint256 => bool)) public _claimedInCycle;
    mapping (uint256 => BlacksquareEdition) public _blacksquareEditions;
    mapping(uint256 => uint256) public _editionOfToken;
    mapping(address => bool) private _eligibles;

    event RewardWithdrawn(uint256 amount, address sender);

    constructor(address _blackSquareAddress, address _obyAddress, bool _claimable) {
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        obyToken = OBYToken(_obyAddress);
        owner = msg.sender;
        claimable = _claimable;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OBYTransfer: caller is not eligible");
        _;
    }

    modifier onlyEligible() {
        require(owner == msg.sender || _eligibles[msg.sender ] == true, "IlluminaNFT: caller is not eligible");
        _;
    }

    function setEligibles(address _eligible) public onlyOwner {
        _eligibles[_eligible] = true;
    }

    function setClaimable (bool _claimable) public onlyEligible {
        claimable = _claimable;
    }

    function getTransferableOBY () public view returns (uint256) {
        uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);

        uint256 transferableOBY = 0;

        if (tokens.length > 0) {

            for (uint256 i = 0; i < tokens.length; i++ ) {
                uint256 editionId = _editionOfToken[tokens[i]];
                BlacksquareEdition memory edition = _blacksquareEditions[editionId];

                for (uint256 j = 1; j <= edition.cycle; j++) {
                    if (!_claimedInCycle[tokens[i]][j]) {
                        if (j == edition.cycle && edition.illuminationTimeStamp < block.timestamp) {
                            transferableOBY += OBY_PER_CYCLE;
                        } else if (j != edition.cycle) {
                            transferableOBY += OBY_PER_CYCLE;
                        }
                    }
                }
            }
        }
        return transferableOBY;
    }

    function transferOBYToken () external {
        if (claimable == true) {
            uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);

            uint256 transferableOBY = 0;

            if (tokens.length > 0) {

                for (uint256 i = 0; i < tokens.length; i++ ) {
                    uint256 editionId = _editionOfToken[tokens[i]];
                    BlacksquareEdition memory edition = _blacksquareEditions[editionId];

                    for (uint256 j = 1; j <= edition.cycle; j++) {
                        if (!_claimedInCycle[tokens[i]][j]) {
                            if (j == edition.cycle && edition.illuminationTimeStamp < block.timestamp) {
                                transferableOBY += OBY_PER_CYCLE;
                                _claimedInCycle[tokens[i]][j] = true;
                            } else if (j != edition.cycle) {
                                transferableOBY += OBY_PER_CYCLE;
                                _claimedInCycle[tokens[i]][j] = true;
                            }
                        }
                    }
                }
            }

            if (transferableOBY > 0) {
                obyToken.mint(msg.sender, transferableOBY);
            }

             emit RewardWithdrawn(transferableOBY, msg.sender);
        }
    }


    function checkForTransferableOBYPerToken (uint256 _tokenId) public view returns (uint256) {
        uint256 editionId = _editionOfToken[_tokenId];
        BlacksquareEdition memory edition = _blacksquareEditions[editionId];

        uint256 transferableOBY = 0;

         for (uint256 j = 1; j <= edition.cycle; j++) {
            if (!_claimedInCycle[_tokenId][j]) {
                if (j == edition.cycle && edition.illuminationTimeStamp < block.timestamp) {
                    transferableOBY += OBY_PER_CYCLE;
                } else if (j != edition.cycle) {
                    transferableOBY += OBY_PER_CYCLE;
                }
            }
        }

        return transferableOBY;
    }

    function updateEdition(uint256 _cycle, uint256 _illuminationTimeStamp, uint256 _editionId) public onlyEligible {
        _blacksquareEditions[_editionId].illuminationTimeStamp = _illuminationTimeStamp;
        _blacksquareEditions[_editionId].cycle = _cycle;
    }


    function updateIlluminationDate(uint256 _illuDate, uint256 _editionId) public onlyEligible {
        _blacksquareEditions[_editionId].illuminationTimeStamp = _illuDate;
        _blacksquareEditions[_editionId].cycle++;
        
    }


    function setEditions(BlacksquareEdition[] memory _editions) public onlyEligible {
        for (uint256 i = 0; i < _editions.length; i++) {
            _blacksquareEditions[i].illuminationTimeStamp = _editions[i].illuminationTimeStamp;
            _blacksquareEditions[i].cycle = 1;

            setEditionTokens(_editions[i], i);
        }
    }

    function setEditionTokens(BlacksquareEdition memory _edition, uint256 editionId) internal {
        for (uint256 i = 0; i < _edition.tokens.length; i++) {
            _editionOfToken[_edition.tokens[i]] = editionId;
        }
    }

    function getBlacksquarEditions () public view returns (BlacksquareEdition[] memory) {
        BlacksquareEdition[] memory editions = new BlacksquareEdition[](7);

        for (uint256 editionCounter = 0; editionCounter < 7; editionCounter++){
            editions[editionCounter] = _blacksquareEditions[editionCounter];
        }
        return editions;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// OpenZeppelin Contracts @ version 4.3.2
import "./ERC721.sol";
import "./Ownable.sol";

contract ClaimAgainstERC721WithFeeMinimal is Ownable {

    // Controlled variables
    uint256 private claimCountTracker;
    mapping(uint256 => address) public tokenIdToClaimant;
    mapping(address => uint256[]) public claimantToTokenIds;

    event ClaimedAgainstTokenId(address indexed claimant, uint256 indexed tokenId, uint256 timestamp);
    event UpdatedPayoutScheme(address indexed updatedBy, address[] payoutAddresses, uint16[] payoutAddressBasisPoints, uint256 timestamp);

    // Config variables
    ERC721 qualifyingToken;
    uint256 public openingTimeUnix;
    uint256 public closingTimeUnix;
    uint256 public claimFee;
    address[] public payoutAddresses;
    uint16[] public payoutAddressBasisPoints;

    constructor(
        address _qualifyingTokenAddress,
        uint256 _openingTimeUnix,
        uint256 _closingTimeUnix,
        uint256 _claimFee,
        address[] memory _payoutAddresses,
        uint16[] memory _payoutAddressBasisPoints
    ) {
        require(_payoutAddresses.length > 0, "ClaimAgainstERC721::constructor: _payoutAddresses must contain at least one entry");
        require(_payoutAddresses.length == _payoutAddressBasisPoints.length, "ClaimAgainstERC721::constructor: each payout address must have a corresponding basis point share");
        qualifyingToken = ERC721(_qualifyingTokenAddress);
        openingTimeUnix = _openingTimeUnix;
        closingTimeUnix = _closingTimeUnix;
        claimFee = _claimFee;
        uint256 totalBasisPoints;
        for(uint256 i = 0; i < _payoutAddresses.length; i++) {
            require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000), "ClaimAgainstERC721::constructor: _payoutAddressBasisPoints may not contain values of 0 and may not exceed 10000 (100%)");
            totalBasisPoints += _payoutAddressBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "ClaimAgainstERC721::constructor: _payoutAddressBasisPoints must add up to 10000 together");
        payoutAddresses = _payoutAddresses;
        payoutAddressBasisPoints = _payoutAddressBasisPoints;
    }

    function claimAgainstTokenIds(uint256[] memory _tokenIds) public payable {
        uint256 tokenIdsLength = _tokenIds.length;
        require(tokenIdsLength > 0, "ClaimAgainstERC721::claimAgainstTokenIds: no token IDs provided");
        require(block.timestamp >= openingTimeUnix, "ClaimAgainstERC721::claimAgainstTokenIds: claims have not yet opened");
        require(block.timestamp < closingTimeUnix, "ClaimAgainstERC721::claimAgainstTokenIds: claims have closed");
        require(msg.value == (claimFee * tokenIdsLength), "ClaimAgainstERC721::claimAgainstTokenIds: incorrect claim fee provided");
        for(uint256 i = 0; i < tokenIdsLength; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenIdToClaimant[tokenId] == address(0), "ClaimAgainstERC721::claimAgainstTokenIds: token with provided ID has already been claimed against");
            require(qualifyingToken.ownerOf(tokenId) == msg.sender, "ClaimAgainstERC721::claimAgainstTokenIds: msg.sender does not own specified token");
            tokenIdToClaimant[tokenId] = msg.sender;
            emit ClaimedAgainstTokenId(msg.sender, tokenId, block.timestamp);
            // Do anything else that needs to happen for each tokenId here
        }
        // Do anything else that needs to happen once per collection of claim(s) here
    }

    // Fee distribution logic below

    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

    function distributeFees() public onlyOwner {
        uint256 feeCutsTotal;
        uint256 balance = address(this).balance;
        for(uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 feeCut;
            if(i < (payoutAddresses.length - 1)) {
                feeCut = getPercentageOf(balance, payoutAddressBasisPoints[i]);
            } else {
                feeCut = (balance - feeCutsTotal);
            }
            feeCutsTotal += feeCut;
            (bool feeCutDeliverySuccess, ) = payoutAddresses[i].call{value: feeCut}("");
            require(feeCutDeliverySuccess, "ClaimAgainstERC721::distributeFees: Fee cut delivery unsuccessful");
        }
    }

    // This function should only be included if all payoutAddress parties trust the deployer of this contract not to be malicious
    // This function mainly serves as a fallback to correct the payment scheme if there is an issue making a payout to a particular address in the payment scheme or another error in the scheme
    function updateFeePayoutScheme(
        address[] memory _payoutAddresses,
        uint16[] memory _payoutAddressBasisPoints
    ) public onlyOwner {
        require(_payoutAddresses.length > 0, "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddresses must contain at least one entry");
        require(_payoutAddresses.length == _payoutAddressBasisPoints.length, "ClaimAgainstERC721::updateFeePayoutScheme: each payout address must have a corresponding basis point share");
        uint256 totalBasisPoints;
        for(uint256 i = 0; i < _payoutAddresses.length; i++) {
            require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000), "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddressBasisPoints may not contain values of 0 and may not exceed 10000 (100%)");
            totalBasisPoints += _payoutAddressBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddressBasisPoints must add up to 10000 together");
        payoutAddresses = _payoutAddresses;
        payoutAddressBasisPoints = _payoutAddressBasisPoints;
        emit UpdatedPayoutScheme(msg.sender, _payoutAddresses, _payoutAddressBasisPoints, block.timestamp);
    }

}

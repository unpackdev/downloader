// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./MoToken.sol";
import "./MoTokenManager.sol";
import "./StringUtil.sol";
import "./Ownable.sol";

/// @title Factory contract for MoTokenManager
/** @notice This contract creates MoTokenManager for a given MoToken.
 *  This also gives us a way to get MoTokenManager give a token symbol.
 */
contract MoTokenManagerFactory is Ownable {
    /// @dev Mapping points to the token manager of a given token's symbol
    mapping(bytes32 => address) public symbolToTokenManager;

    /// @dev Holds all the mo token symbols
    bytes32[] public symbols;

    /// @dev Mapping points to the senior token symbol for a junior token symbol
    mapping(bytes32 => bytes32) public linkedSrTokenOf;

    /// @dev Index used while creating MoTokenManager
    uint16 public tokenId;

    event MoTokenManagerAdded(
        address indexed from,
        bytes32 indexed tokenSymbol,
        address indexed tokenManager
    );
    event JrTokenLinkedToSrToken(
        bytes32 indexed jrToken,
        bytes32 indexed srToken
    );

    /// @notice Adds MoTokenManager for a given MoToken
    /// @param _token Address of MoToken contract
    /// @param _tokenManager Address of MoTokenManager contract
    /// @param _stableCoin Stable coin contract address
    /// @param _initNAV Initial NAV value
    /// @param _rWADetails Address of RWADetails contract

    function addTokenManager(
        address _token,
        address _tokenManager,
        address _stableCoin,
        uint64 _initNAV,
        address _rWADetails
    ) external onlyOwner {
        MoToken mt = MoToken(_token);
        string memory tokenSymbol = mt.symbol();
        require((bytes(tokenSymbol).length > 0), "IT");

        bytes32 tokenBytes = StringUtil.stringToBytes32(tokenSymbol);
        require(symbolToTokenManager[tokenBytes] == address(0), "AE");

        tokenId = tokenId + 1;
        symbolToTokenManager[tokenBytes] = _tokenManager;

        MoTokenManager tManager = MoTokenManager(_tokenManager);
        tManager.initialize(
            tokenId,
            _token,
            _stableCoin,
            _initNAV,
            _rWADetails
        );

        symbols.push(tokenBytes);

        emit MoTokenManagerAdded(msg.sender, tokenBytes, _tokenManager);
    }

    /// @notice Links a Junior token to Senior token.
    /// @param _jrToken Symbol of MoJuniorToken
    /// @param _srToken Symbol of Senior MoToken

    function linkJrTokenToSrToken(bytes32 _jrToken, bytes32 _srToken)
        external
        onlyOwner
    {
        require(symbolToTokenManager[_jrToken] != address(0), "NT");
        require(symbolToTokenManager[_srToken] != address(0), "NT");

        address juniorTokenAddress = MoTokenManager(
            symbolToTokenManager[_jrToken]
        ).token();

        address seniorTokenAddress = MoTokenManager(
            symbolToTokenManager[_srToken]
        ).token();

        MoToken(juniorTokenAddress).linkToSeniorToken(seniorTokenAddress);
        MoToken(seniorTokenAddress).linkToJuniorToken(juniorTokenAddress);
        emit JrTokenLinkedToSrToken(_jrToken, _srToken);
    }
}

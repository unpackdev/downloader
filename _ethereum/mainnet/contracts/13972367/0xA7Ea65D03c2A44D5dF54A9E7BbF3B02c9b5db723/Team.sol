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

import "./Context.sol";




///              _               _      _____               
///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ _____ 
/// |  _| . |   |  _|  _| .'|  _|  _|    | | | -_| .'|     |
/// |___|___|_|_|_| |_| |__,|___|_|      |_| |___|__,|_|_|_|
                                                        
/// @title Tactical Tangrams Team contract
/// @author tacticaltangrams.io
/// @notice Contains wallet and share details for personal payouts
contract Team is Context {

    uint internal constant TEAM_SIZE = 4;
    uint internal constant TEAM_SHARE_RECORD_SIZE = 3;
    uint internal constant TEAM_SHARE_MINT_OFFSET = 0;
    uint internal constant TEAM_SHARE_SECONDARY_OFFSET = 1;
    uint internal constant TEAM_SHARE_SECONDARY_PAID_OFFSET = 2;




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @dev Initializes team addresses. Note that this is only meant for deployment flexibility; the team size and rewards are fixed in the contract
    /// @param _teamAddresses    List of team member's addresses; first address is emergency address
    constructor(address payable[TEAM_SIZE] memory _teamAddresses)
    {
        for (uint teamIndex = 0; teamIndex < teamAddresses.length; teamIndex++)
        {
            teamAddresses[teamIndex] = _teamAddresses[teamIndex];
        }

    }


    /// @notice Returns the team member's index based on wallet address
    /// @param _address Wallet address of team member
    /// @return (bool, index) where bool indicates whether the given address is a team member
    function getTeamIndex(address _address) internal view returns (bool, uint) {
        for (uint index = 0; index < TEAM_SIZE; index++) {
            if (_address == teamAddresses[index]) {
                return (true, index);
            }
        }

        return (false, 0);
    }


    /// @notice Checks whether given address is a team member
    /// @param _address Address to check team membership for
    /// @return True when _address is a team member, False otherwise
    function isTeamMember(address _address) internal view returns (bool) {
        (bool _isTeamMember,) = getTeamIndex(_address);
        return _isTeamMember;
    }


    /// @notice Team member's addresses
    /// @dev Team member information in other arrays can be found at the corresponding index.
    address payable[TEAM_SIZE] internal teamAddresses;

    /// @notice The emergency address is used when things go wrong; no personal payout is possible anymore after emergency payout
    bool internal emergencyCalled = false;

    /// @notice Mint shares are paid out only once per address, after public minting has closed
    bool[TEAM_SIZE] internal mintSharePaid = [ false, false, false, false ];

    /// @notice Mint and secondary sales details per team member
    /// @dev Flattened array: [[<mint promille>, <secondary sales promille>, <secondary sales shares paid>], ..]
    uint[TEAM_SIZE * TEAM_SHARE_RECORD_SIZE] internal teamShare = [
        450, 287, 0,
        300, 287, 0,
        215, 286, 0,
         35, 140, 0
    ];
}

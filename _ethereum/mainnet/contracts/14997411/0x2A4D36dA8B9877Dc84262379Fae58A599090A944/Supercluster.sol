// SPDX-License-Identifier: GPL-3.0-or-later

/// @title SUPERCLUSTER BY DAVE KRUGMAN
/// @author Transient Labs

/*
  ____  _   _ ____  _____ ____   ____ _    _   _ ____ _____ _____ ____  
 / ___|| | | |  _ \| ____|  _ \ / ___| |  | | | / ___|_   _| ____|  _ \ 
 \___ \| | | | |_) |  _| | |_) | |   | |  | | | \___ \ | | |  _| | |_) |
  ___) | |_| |  __/| |___|  _ <| |___| |__| |_| |___) || | | |___|  _ < 
 |____/ \___/|_|   |_____|_| \_\\____|_____\___/|____/ |_| |_____|_| \_\
                                                                        
*/

pragma solidity ^0.8.9;

import "Shatter.sol";

contract Supercluster is Shatter {

    /// @param _name is the name of the contract and piece
    /// @param _symbol is the symbol
    /// @param _royaltyRecipient is the royalty recipient
    /// @param _royaltyPercentage is the royalty percentage to set
    /// @param _admin is the admin address
    /// @param _minShatters is the minimum number of replicates
    /// @param _maxShatters is the maximum number of replicates
    /// @param _shatterTime is time after which replication can occur
    /// @param _description is the piece description
    /// @param _image is the piece image URI
    constructor (string memory _name, string memory _symbol,
        address _royaltyRecipient, uint256 _royaltyPercentage, address _admin,
        uint256 _minShatters, uint256 _maxShatters, uint256 _shatterTime,
        string memory _description, string memory _image)
        Shatter(_name, _symbol, _royaltyRecipient, _royaltyPercentage, _admin,
                _minShatters, _maxShatters, _shatterTime, _description, _image)
    {}
}
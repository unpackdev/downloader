// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Shatter
/// @author Transient Labs

pragma solidity ^0.8.9;

/*
_____/\\\\\\\\\\\____/\\\_________________________________________________________________________________        
 ___/\\\/////////\\\_\/\\\_________________________________________________________________________________       
  __\//\\\______\///__\/\\\____________________________/\\\__________/\\\___________________________________      
   ___\////\\\_________\/\\\__________/\\\\\\\\\_____/\\\\\\\\\\\__/\\\\\\\\\\\_____/\\\\\\\\___/\\/\\\\\\\__     
    ______\////\\\______\/\\\\\\\\\\__\////////\\\___\////\\\////__\////\\\////____/\\\/////\\\_\/\\\/////\\\_    
     _________\////\\\___\/\\\/////\\\___/\\\\\\\\\\_____\/\\\_________\/\\\_______/\\\\\\\\\\\__\/\\\___\///__   
      __/\\\______\//\\\__\/\\\___\/\\\__/\\\/////\\\_____\/\\\_/\\_____\/\\\_/\\__\//\\///////___\/\\\_________  
       _\///\\\\\\\\\\\/___\/\\\___\/\\\_\//\\\\\\\\/\\____\//\\\\\______\//\\\\\____\//\\\\\\\\\\_\/\\\_________ 
        ___\///////////_____\///____\///___\////////\//______\/////________\/////______\//////////__\///__________
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/                                                           
*/

import "ERC721A.sol";
import "EIP2981AllToken.sol";
import "Ownable.sol";
import "Base64.sol";
import "Strings.sol";

contract Shatter is ERC721A, EIP2981AllToken, Ownable {
    using Strings for uint256;

    bool public isShattered;
    bool public isFused;
    uint256 public shatterStartIndex;
    uint256 public immutable minShatters;
    uint256 public immutable maxShatters;
    uint256 public shatters;
    uint256 public immutable shatterTime;
    address public admin;
    string private image;
    string private description;
    string[] private traitNames;
    string[] private traitValues;

    modifier adminOrOwner {
        require(msg.sender == admin || msg.sender == Ownable.owner(), "Address not admin or owner");
        _;
    }

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
        ERC721A(_name, _symbol) EIP2981AllToken(_royaltyRecipient, _royaltyPercentage) Ownable() 
    {
        admin = _admin;
        minShatters = _minShatters;
        maxShatters = _maxShatters;
        shatterTime = _shatterTime;
        description = _description;
        image = _image;
    }

    /// @notice function to change the royalty info
    /// @dev requires admin or owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    /// @param newAddr is the new royalty payout addresss
    /// @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external adminOrOwner {
        require(newAddr != address(0), "Cannot set royalty receipient to the zero address");
        require(newPerc < 10000, "Cannot set royalty percentage above 10000");
        royaltyAddr = newAddr;
        royaltyPerc = newPerc;
    }

    /// @notice function to set the admin address on the contract
    /// @dev requires owner
    /// @param _admin is the new admin address
    function setAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0), "New admin cannot be the zero address");
        admin = _admin;
    }

    /// @notice function to set the piece description
    /// @dev requires owner or admin
    /// @param _description is the new description
    function setDescription(string calldata _description) external adminOrOwner {
        description = _description;
    }

    /// @notice function to set the traits
    /// @dev requires owner or admin
    /// @param _traitNames are the names of the traits
    /// @param _traitValues are the values of each trait, index paired
    function setTraits(string[] memory _traitNames, string[] memory _traitValues) external adminOrOwner {
        require(_traitNames.length == _traitValues.length, "Array lengths must be equal");
        traitNames = _traitNames;
        traitValues = _traitValues;
    }

    /// @notice function for minting the 1/1 to the owner's address
    /// @dev requires owner or admin
    /// @dev requires that shatters is equal to 0 -> meaning no piece has been minted
    /// @dev using _mint function as owner() should always be an EOA or trusted entity
    function mint() external adminOrOwner {
        require(shatters == 0, "Already minted the first piece");
        shatters = 1;
        _mint(Ownable.owner(), 1);
    }

    /// @notice function for owner of token 0 to unlock the piece and turn it into an edition
    /// @dev requires msg.sender to be the owner of token 0
    /// @dev requires a number of editions less than or equal to maxShatters or greater than or equal to minShatters
    /// @dev requires isShattered to be false
    /// @dev requires block timestamp to be greater than or equal to shatterTime
    /// @dev purposefully not letting approved addresses shatter as we want owner to be the only one to shatter the token
    /// @dev if number of editions == 1, fuse occurs at the same time
    /// @param _shatters is the total number of editions to make. Can be set between minShatters and maxShatters. This number is the total number of editions that will live on this contract
    function shatter(uint256 _shatters) external {
        require(!isShattered, "Already is shattered");
        require(msg.sender == ERC721A.ownerOf(0), "Caller is not owner of token 0");
        require(_shatters >= minShatters && _shatters <= maxShatters, "Cannot set number of editions above max or below the min");
        require(block.timestamp >= shatterTime, "Cannot shatter prior to shatterTime");

        isShattered = true;
        shatters = _shatters;
        if (_shatters > 1) {
            shatterStartIndex = 1;
            _burn(0);
            _mint(msg.sender, _shatters);
        } else {
            isFused = true;
        }
    }

    /// @notice function to fuse editions back into a 1/1
    /// @dev requires msg.sender to own all of the editions
    /// @dev can't have already fused
    /// @dev must be shattered
    /// @dev purposefully not letting approved addresses fuse as we want the owner to have only control over fusing
    function fuse() external {
        require(!isFused, "Already is fused");
        require(isShattered, "Can't fuse if not already shattered");
        for (uint256 i = shatterStartIndex; i < shatterStartIndex + shatters; i++) {
            require(msg.sender == ERC721A.ownerOf(i), "Msg sender must own all editions");
            _burn(i);
        }
        isFused = true;
        shatters = 1;
        _mint(msg.sender, 1);
    }

    /// @notice function to override tokenURI
    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        require(ERC721A._exists(tokenId), "URI query for nonexistent token");
        string memory name = ERC721A.name();
        string memory attr = "[";
        string memory shatterStr = "No";
        string memory fuseStr = "No";
        for (uint256 i; i < traitNames.length; i++) {
            attr = string(abi.encodePacked(attr, '{"trait_type": "', traitNames[i], '", "value": "', traitValues[i], '"},'));
        }
        if (shatters > 1) {
            shatterStr = "Yes";
            name = string(abi.encodePacked(name, ' #', tokenId.toString(), '/', shatters.toString()));
            attr = string(abi.encodePacked(attr, '{"trait_type": "Edition", "value": "', tokenId.toString(), '"},{"trait_type": "Shattered", "value": "', shatterStr, '"},{"trait_type": "Fused", "value": "', fuseStr, '"}'));
        } else {
            if (isShattered) {
                shatterStr = "Yes";
            }
            if (isFused) {
                fuseStr = "Yes";
            }
            attr = string(abi.encodePacked(attr, '{"trait_type": "Shattered", "value": "', shatterStr, '"},{"trait_type": "Fused", "value": "', fuseStr, '"}'));
        }
        attr = string(abi.encodePacked(attr, "]"));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked(
                    '{"name": "', name, '",',
                    '"description": "', description, '",',
                    '"attributes": ', attr, ',',
                    '"image": "', image, '"}'
                )))
            )
        );
    }

    /// @notice overrides supportsInterface function
    /// @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    /// @return boolean saying if this contract supports the interface or not
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, EIP2981AllToken) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }
}
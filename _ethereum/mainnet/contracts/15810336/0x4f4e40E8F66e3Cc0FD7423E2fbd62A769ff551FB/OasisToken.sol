// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC721.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Token
 * @notice  . Standard ERC-20 for the Oasis. Mintable by assigned Minters or by burning a Crazy Camels NFT.
 */

contract OasisToken is ERC20, Ownable {
    /// ERRORS ///

    error NotMinter();
    error InvalidArguments();

    /// STATE VARIABLES ///

    address public immutable crazyCamels;
    address public immutable oasisGraveyard;
    uint128 public immutable tokensPerCrazyCamel;
    mapping(address => bool) public minter;

    /// EVENTS ///

    event Claimed(address indexed claimer, uint256 indexed camelsBurned);

    /// CONSTRUCTOR ///

    constructor(
        address _crazyCamels,
        address _oasisGraveyard,
        uint128 _tokensPerCrazyCamel
    ) ERC20("Oasis Token", "OST") {
        crazyCamels = _crazyCamels;
        oasisGraveyard = _oasisGraveyard;
        tokensPerCrazyCamel = _tokensPerCrazyCamel;
    }

    /// OWNER FUNCTIONS ///

    function addMinter(address _minter) external onlyOwner {
        minter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        minter[_minter] = false;
    }

    /// MINTER FUNCTIONS ///

    function mint(address _to, uint256 _amount) external {
        if (!minter[msg.sender]) revert NotMinter();
        _mint(_to, _amount);
    }

    /// USER FUNCTIONS ///

    function claim(uint256[] calldata _tokenIds) external {
        if (1 > _tokenIds.length) revert InvalidArguments();

        for (uint256 i = 0; i < _tokenIds.length; i++)
            IERC721(crazyCamels).transferFrom(msg.sender, oasisGraveyard, _tokenIds[i]);

        _mint(msg.sender, _tokenIds.length * tokensPerCrazyCamel);

        emit Claimed(msg.sender, _tokenIds.length);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: Member Lounde: Train Meta
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./Ownable.sol";

//------------------------------------------------------------------------------
// interfaces
//------------------------------------------------------------------------------

/**
 * Lounge interface.
 */
interface ILounge {

  function mint(address to, uint256 id, uint256 amount)
    external;

  function burn(address to, uint256 id, uint256 amount)
    external;

  function balanceOf(address account, uint256 id)
    external view returns (uint256);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external view returns (uint256[] memory);

  function uri(uint256 tokenId)
    external view returns (string memory);

}

//------------------------------------------------------------------------------
// Member Lounge: Train Meta
//------------------------------------------------------------------------------

/**
 * @title Member Lounge: Train Meta
 */
contract MLTrainMeta is Ownable
{

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    /**
     * Emited when train hop attempted.
     */
    event TrainHop(address indexed owner, uint256 current, uint256 next, bool success);

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // member lounge contract
    ILounge private immutable _lounge;

    // train tokens
    uint256[] private _trains;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(bytes(_lounge.uri(tokenId)).length != 0, "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

    modifier hasBalance(address owner, uint256 trainIdx) {
        require(_lounge.balanceOf(owner, _trains[trainIdx]) > 0, "invalid balance");
        _;
    }

    //-------------------------------------------------------------------------

    modifier canHop(uint256 trainIdx) {
        require(trainIdx + 1 < _trains.length , "invalid hop");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(address lounge, uint256[] memory trains)
    {
        _lounge = ILounge(lounge);
        _trains = trains;
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    function pushTrain(uint tokenId)
        public
        onlyOwner
        validTokenId(tokenId)
    {
        _trains.push(tokenId);
    }

    //-------------------------------------------------------------------------

    function popTrain()
        public
        onlyOwner
    {
        _trains.pop();
    }

    //-------------------------------------------------------------------------
    // helper functions
    //-------------------------------------------------------------------------

    /**
     * @dev Create a Pseudo-random number using block info.
     */
    function _random(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
      return uint256(keccak256(
          abi.encodePacked(
              address(this),
              block.difficulty,
              blockhash(block.number),
              block.timestamp,
              msg.sender,
              tokenId)));
    }

    //-------------------------------------------------------------------------
    // methods
    //-------------------------------------------------------------------------

    /**
     * @dev Return list of passes staked by staker.
     */
    function getTrains()
        public
        view
        returns (uint256[] memory)
    {
        return _trains;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns users train balances.
     */
    function balances(address user)
        public
        view
        returns (uint256[] memory)
    {
        address[] memory addresses = new address[](_trains.length);
        for (uint256 i = 0; i < addresses.length; ++i) {
            addresses[i] = user;
        }
        return _lounge.balanceOfBatch(addresses, _trains);
    }

    //-------------------------------------------------------------------------

    /**
     * Hop to next tain, 50% chance of making it.
     */
    function hopTrain(uint256 trainIdx)
        external
        hasBalance(msg.sender, trainIdx)
        canHop(trainIdx)
    {
        uint256 current = _trains[trainIdx];
        uint256 next    = _trains[trainIdx + 1];

        // current always gets burned
        _lounge.burn(msg.sender, current, 1);

        // 50% chance they make it to the next train
        uint256 random = _random(current);
        bool madeIt    = random & 0x1 == 0x1;
        if (madeIt) {
            _lounge.mint(msg.sender, next, 1);
        }

        // track hops
        emit TrainHop(msg.sender, current, next, madeIt);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";

import "./Ownable.sol";
import "./Pausable.sol";
import "./RecoverableERC721Holder.sol";

interface ITunnel {
    function sendMessage(bytes calldata _message) external;
}

/// @dev A simple contract to orchestrate comings and going from the GHG Tunnel System
contract Harbour is Ownable, Pausable, RecoverableERC721Holder {

    address public tunnel;

    address public ggold;
    address public wood;

    address public goldhunters;
    address public ships;
    address public houses;

    mapping (address => address) public reflection;

    constructor(
        address _tunnel,
        address _ggold, 
        address _wood,
        address _goldhunters,
        address _ships, 
        address _houses
    ) {
        tunnel = _tunnel;
        ggold = _ggold;
        wood = _wood;
        goldhunters = _goldhunters;
        ships = _ships;
        houses = _houses;
        _pause();
    }

    //////////////   OWNER FUNCTIONS   //////////////

    // Travel is pausable
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Creates a mapping between L1 <-> L2 Contract Equivalents
    function setReflection(address _key, address _reflection) external onlyOwner {
        reflection[_key] = _reflection;
        reflection[_reflection] = _key;
    }

    //////////////   USER FUNCTIONS   ///////////////

    function travel(
        uint256 _ggoldAmount, 
        uint256 _woodAmount,
        uint16[] calldata _goldhunterIds,
        uint16[] calldata _shipIds,
        uint16[] calldata _houseIds
    ) external whenNotPaused {
        uint256 callsIndex = 0;

        bytes[] memory calls = new bytes[](
            (_ggoldAmount > 0 ? 1 : 0) + 
            (_woodAmount > 0 ? 1 : 0) +
            (_goldhunterIds.length > 0 ? 1 : 0) +
            (_shipIds.length > 0 ? 1 : 0) +
            (_houseIds.length > 0 ? 1 : 0)
        );

        if (_ggoldAmount > 0) {
            ICoin(ggold).burn(msg.sender, _ggoldAmount);
            calls[callsIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(ggold)], msg.sender, _ggoldAmount);
            callsIndex++;
        }

        if (_woodAmount > 0) {
            ICoin(wood).burn(msg.sender, _woodAmount);
            calls[callsIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(wood)], msg.sender, _woodAmount);
            callsIndex++;
        }

        if (_goldhunterIds.length > 0) {
            _stakeMany(goldhunters, _goldhunterIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(goldhunters)], msg.sender, _goldhunterIds);
            callsIndex++;
        }

        if (_shipIds.length > 0) {
            _stakeMany(ships, _shipIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(ships)], msg.sender, _shipIds);
            callsIndex++;
        }

        if (_houseIds.length > 0) {
            _stakeMany(houses, _houseIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(houses)], msg.sender, _houseIds);
            // no need to increment callsIndex as this is last call
        }

        ITunnel(tunnel).sendMessage(abi.encode(reflection[address(this)], calls));
    }

    //////////////   INTERNAL FUNCTIONS   /////////////

    function _stakeMany(address nft, uint16[] calldata ids) internal {
        for(uint i = 0; i < ids.length; i++) {
            IToken(nft).safeTransferFrom(msg.sender, address(this), ids[i]);
        }
    }

    modifier onlyTunnel {
        require(msg.sender == tunnel, "ERROR: Msg.Sender is Not Tunnel");
        _;
    }

    function mintToken(address token, address to, uint256 amount) external onlyTunnel { 
        ICoin(token).mint(to, amount);
    }

    function unstakeMany(address nft, address harbourUser, uint16[] calldata ids) external onlyTunnel {
        for(uint i = 0; i < ids.length; i++) {
            IToken(nft).safeTransferFrom(address(this), harbourUser, ids[i]);
        }
    }
}
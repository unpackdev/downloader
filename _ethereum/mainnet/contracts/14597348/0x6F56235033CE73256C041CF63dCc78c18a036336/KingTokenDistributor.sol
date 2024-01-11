pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";

/// @title   King Token Distributor
/// @notice  Distributes King tokens for Incooom Genesis and Kings Gala
/// @author  JeffX
contract KingTokenDistributor {
    using SafeERC20 for IERC20;

    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if ID has already been claimed
    error IDAlreadyClaimed();

    /// STATE VARIABLES ///

    /// @notice King Token
    address public immutable kingToken;
    /// @notice Incooom Genesis
    address public immutable incooomGenesis;
    /// @notice Kings Gala
    address public immutable kingsGala;
    /// @notice Owner
    address public immutable owner;

    /// @notice Amount of King per Genesis
    uint256 public constant kingPerGenesis = 3333000000000000000000;
    /// @notice Amount of King per King's Gala
    uint256 public constant kingPerGala = 3690000000000000000000;

    /// @notice Genesis ID to if King has been claimed for
    mapping(uint256 => bool) public genesisIDClaimed;
    /// @notice King's Gala ID to if King has been claimed for
    mapping(uint256 => bool) public kingsGalaIDClaimed;

    /// CONSTRUCTOR ///

    /// @param _kingToken      Address of King token
    /// @param _incoomGenesis  Address of Incoom Genesis
    /// @param _kingsGala      Address of King's Gala
    /// @param _owner          Address of owner
    constructor(
        address _kingToken,
        address _incoomGenesis,
        address _kingsGala,
        address _owner
    ) {
        kingToken = _kingToken;
        incooomGenesis = _incoomGenesis;
        kingsGala = _kingsGala;
        owner = _owner;
    }

    /// USER FUNCTION ///

    /// @notice               Claims King for Genesis and King's Gala tokens
    /// @param _genesisIDs    Array of IDs for Genesis
    /// @param _kingsGalaIDs  Array of IDs for King's Gala
    /// @param _to            Address where King will be sent
    function claim(
        uint256[] calldata _genesisIDs,
        uint256[] calldata _kingsGalaIDs,
        address _to
    ) external {
        uint256 kingToSend;

        if(_genesisIDs.length > 0) {
            kingToSend += claimForGenesis(_genesisIDs);
        }

        if(_kingsGalaIDs.length > 0) {
            kingToSend += claimForKingsGala(_kingsGalaIDs);
        }

        if(kingToSend > 0) {
            IERC20(kingToken).safeTransfer(_to, kingToSend);
        }
    }

    /// PRIVATE FUNCTIONS ///

    /// @notice              Returns amount of King to be sent for Genesis tokens if no revert
    /// @param _ids          Array of IDs for Genesis
    /// @return kingToSend_  King to send for `_ids `
    function claimForGenesis(uint256[] calldata _ids) private returns (uint256 kingToSend_) {
        for (uint256 i; i < _ids.length; ++i) {
            if (IERC721(incooomGenesis).ownerOf(_ids[i]) != msg.sender)
                revert NotOwner();
            if (genesisIDClaimed[_ids[i]] == true) revert IDAlreadyClaimed();
            genesisIDClaimed[_ids[i]] = true;
        }

        return kingPerGenesis * _ids.length;
    }

    /// @notice              Returns amount of King to be sent for King's Gala tokens if no revert
    /// @param _ids          Array of IDs for King's Gala
    /// @return kingToSend_  King to send for `_ids `
    function claimForKingsGala(uint256[] calldata _ids) private returns (uint256 kingToSend_) {
        for (uint256 i; i < _ids.length; ++i) {
            if (IERC721(kingsGala).ownerOf(_ids[i]) != msg.sender)
                revert NotOwner();
            if (kingsGalaIDClaimed[_ids[i]] == true) revert IDAlreadyClaimed();
            kingsGalaIDClaimed[_ids[i]] = true;
        }

        return kingPerGala * _ids.length;
    }

    /// OWNER FUNCTION ///

    /// @notice         Owner of contracts transfers specified token
    /// @param _token   Address of token being send
    /// @param _to      Address where `_token` is being sent
    /// @param _amount  Amount of `_token` that is being sent
    function transferToken(address _token, address _to, uint256 _amount) external {
        if(msg.sender != owner) revert NotOwner();
        IERC20(_token).safeTransfer(_to, _amount);
    }
}

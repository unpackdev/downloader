// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///              _               _      _____ _       _       
///  ___ ___ ___| |_ ___ ___ ___| |_   |   __| |_ ___| |_ ___ 
/// |  _| . |   |  _|  _| .'|  _|  _|  |__   |  _| .'|  _| -_|
/// |___|___|_|_|_| |_| |__,|___|_|    |_____|_| |__,|_| |___|

/// @title Tactical Tangrams State contract
/// @author tacticaltangrams.io
/// @notice Implements the basis for Tactical Tangram's state machine
abstract contract State {


    /// @notice Emit state changes
    /// @param oldState Previous state
    /// @param newState Current state
    event StateChanged(StateType oldState, StateType newState);


    /// @notice Change to new state when state change is allowed
    /// @dev Virtual methods changeState* have to be implemented. Invalid state changes have to be reverted in each changeState* method
    /// @param _from State to change from
    /// @param _to   State to change to
    function changeState(StateType _from, StateType _to) internal
    {
        require(
            (_from != _to) &&
            (StateType.ALL == _from || state == _from),
            INVALID_STATE_CHANGE
        );

        bool stateChangeHandled = false;

        if (StateType.PREMINT == _to)
        {
            stateChangeHandled = true;
            changeStatePremint();
        }
        else if (StateType.MINT == _to)
        {
            stateChangeHandled = true;
            changeStateMint();
        }
        else if (StateType.MINTCLOSED == _to)
        {
            stateChangeHandled = true;
            changeStateMintClosed();
        }

        // StateType.GENERATIONSTARTED cannot be set over setState, this is done implicitly by processGenerationSeedReceived

        else if (StateType.GENERATIONCLOSING == _to)
        {
            stateChangeHandled = true;
            changeStateGenerationClosing();
        }
        else if (StateType.GENERATIONCLOSED == _to)
        {
            stateChangeHandled = true;
            changeStateGenerationClosed();
        }

        require(
            stateChangeHandled,
            INVALID_STATE_CHANGE
        );

        state = _to;

        emit StateChanged(_from, _to);

        if (StateType.MINTCLOSED == _to) {
            changeStateMintClosedAfter();
        }
    }


    function changeStatePremint()           internal virtual;
    function changeStateMint()              internal virtual;
    function changeStateMintClosed()        internal virtual;
    function changeStateMintClosedAfter()   internal virtual;
    function changeStateGenerationStarted() internal virtual;
    function changeStateGenerationClosing() internal virtual;
    function changeStateGenerationClosed()  internal virtual;


    /// @notice Verify allowed states
    /// @param _either Allowed state
    /// @param _or     Allowed state
    modifier inEitherState(StateType _either, StateType _or) {
        require(
            (state == _either) || (state == _or),
            INVALID_STATE
        );
        _;
    }


    /// @notice Verify allowed state
    /// @param _state Allowed state
    modifier inState(StateType _state) {
        require(
            state == _state,
            INVALID_STATE
        );
        _;
    }



    /// @notice Verify allowed minimum state
    /// @param _state Minimum allowed state
    modifier inStateOrAbove(StateType _state) {
        require(
            state >= _state,
            INVALID_STATE
        );
        _;
    }


    /// @notice List of states for Tactical Tangrams
    /// @dev When in states GENERATIONSTARTED, GENERATIONCLOSING or GENERATIONCLOSED, Tan.currentGeneration indicates the current state
    enum StateType
    {
        ALL               ,
        DEPLOYED          , // contract has been deployed
        PREMINT           , // only OG and WL minting allowed
        MINT              , // only public minting allowed
        MINTCLOSED        , // no more minting allowed; total mint income stored, random seed for gen 1 requested
        GENERATIONSTARTED , // random seed available, Tans revealed
        GENERATIONCLOSING , // 80-100% Tans swapped
        GENERATIONCLOSED    // 100% Tans swapped, random  seed for next generation requested for gen < 7
    }


    StateType public state = StateType.DEPLOYED;


    string private constant INVALID_STATE        = "Invalid state";
    string private constant INVALID_STATE_CHANGE = "Invalid state change";
}

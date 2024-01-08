pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./ERC20PresetFixedSupply.sol";
import "./AccessControlRci.sol";
import "./ICompetition.sol";

contract Token is AccessControlRci, ERC20PresetFixedSupply
{
    mapping (address => bool) private _authorizedCompetitions;

    event CompetitionAuthorized(address indexed competitionAddress);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_)
    ERC20PresetFixedSupply(name_, symbol_, initialSupply_, msg.sender)
    {
        _initializeRciAdmin();
    }

    function increaseStake(address target, uint256 amountToken)
    public
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - increaseStake: This competition is not authorized.");
        uint256 senderBal = _balances[msg.sender];
        uint256 senderStake = ICompetition(target).getStake(msg.sender);

        ICompetition(target).increaseStake(msg.sender, amountToken);
        transfer(target, amountToken);

        require((senderBal - _balances[msg.sender]) == amountToken, "Token - increaseStake: Sender final balance incorrect.");
        require((ICompetition(target).getStake(msg.sender) - senderStake) == amountToken, "Token - increaseStake: Sender final stake incorrect.");

        success = true;
    }

    function decreaseStake(address target, uint256 amountToken)
    public
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - decreaseStake: This competition is not authorized.");
        uint256 senderBal = _balances[msg.sender];
        uint256 senderStake = ICompetition(target).getStake(msg.sender);

        ICompetition(target).decreaseStake(msg.sender, amountToken);

        require((_balances[msg.sender] - senderBal) == amountToken, "Token - decreaseStake: Sender final balance incorrect.");
        require(senderStake - (ICompetition(target).getStake(msg.sender)) == amountToken, "Token - decreaseStake: Sender final stake incorrect.");

        success = true;
    }

    function setStake(address target, uint256 amountToken)
    external
    returns (bool success)
    {
        require(_authorizedCompetitions[target], "Token - setStake: This competition is not authorized.");
        uint256 currentStake = ICompetition(target).getStake(msg.sender);
        require(currentStake != amountToken, "Token - setStake: Your stake is already set to this amount.");
        if (amountToken > currentStake){
            increaseStake(target, amountToken - currentStake);
        } else{
            decreaseStake(target, currentStake - amountToken);
        }
        success = true;
    }

    function getStake(address target, address staker)
    external view
    returns (uint256 stake)
    {
        require(_authorizedCompetitions[target], "Token - getStake: This competition is not authorized.");
        stake = ICompetition(target).getStake(staker);
    }


    function authorizeCompetition(address competitionAddress)
    external
    onlyAdmin
    {
        require(competitionAddress != address(0), "Token - authorizeCompetition: Cannot authorize 0 address.");
        _authorizedCompetitions[competitionAddress] = true;

        emit CompetitionAuthorized(competitionAddress);
    }

    function competitionIsAuthorized(address competitionAddress)
    external view
    returns (bool authorized)
    {
        authorized = _authorizedCompetitions[competitionAddress];
    }
}
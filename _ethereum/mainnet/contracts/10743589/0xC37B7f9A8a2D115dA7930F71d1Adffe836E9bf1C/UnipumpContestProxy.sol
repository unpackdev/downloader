pragma solidity ^0.7.0;

interface IUnipumpContest
{
}
contract UnipumpContestProxy is IUnipumpContest
{
    IUnipumpContest public contest;
    address immutable owner;

    constructor()
    {
        owner = msg.sender;
    }

    function setContest(IUnipumpContest _contest) public
    {
        require (msg.sender == owner, "Owner only");
        contest = _contest;
    }
}
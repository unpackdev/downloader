pragma solidity ^0.8.2;
interface ITicketBooth {
    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256 _result);
}
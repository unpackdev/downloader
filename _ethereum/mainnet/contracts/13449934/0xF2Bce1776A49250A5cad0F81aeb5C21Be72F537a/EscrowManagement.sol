// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

abstract contract ERC1155Interface{
	function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public virtual;
}

abstract contract ERC721Interface{
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual;
}

abstract contract ERC20Interface{
    function transfer(address recipient, uint256 amount) public virtual returns(bool);
}

contract EscrowManagement is ReentrancyGuard, ERC721Holder, ERC1155Holder{
    address[] internal teamMembers;
    mapping (address => uint8) internal teamMembersSplit;
    
    modifier onlyTeamMembers(){
        require(teamMembersSplit[msg.sender] > 0, "No team member");
        _;
    }
    function _getTeamMembers() internal view returns(address[] memory){
        return teamMembers;
    }
    
    function getTeamMemberSplit(address teamMember) public view returns(uint8){
        return teamMembersSplit[teamMember];
    }
    /*
    *   Escrow and withdrawal functions for decentral team members
    */
    function _addTeamMemberSplit(address teamMember, uint8 split) internal{
        require(teamMembersSplit[teamMember] == 0, "Team member already added");
        require(split<101, "Split too big");
        teamMembers.push(teamMember);
        teamMembersSplit[teamMember] = split;
    }

    function _transferSplit(address from, address to, uint8 split) internal{
        // transfer split from one member to another
        // the caller has to be a team member
        require(split <= teamMembersSplit[from], "Split too big");
        if (teamMembersSplit[to] == 0) {
            // if to was not yet a team member, then welcome
            teamMembers.push(to);
        }
        teamMembersSplit[from] = teamMembersSplit[from] - split;
        teamMembersSplit[to] = teamMembersSplit[to] + split;
    }

    function transferSplit(address from, address to, uint8 split) public nonReentrant onlyTeamMembers(){
        // the from has the be the caller for team members
        require(msg.sender == from, "Not the sender");
        _transferSplit(from, to, split);
    }
    
	// withdraw - pays out the team members by the defined distribution
	// every call pays out the actual balance to all team members
    // this function can be called by anyone
    function withdraw() public nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        uint256 amountOfTeamMembers = teamMembers.length;
        require(amountOfTeamMembers >0, "0 team members found");
        // in order to distribute everything and take care of rests due to the division, the first team members gets the rest
        // i=1 -> we start with the second member, the first goes after the for
        bool success;
        for (uint256 i=1;  i<amountOfTeamMembers; i++) {
            uint256 payoutAmount = balance /100 * teamMembersSplit[teamMembers[i]];
            // only payout if amount is positive
            if (payoutAmount > 0){
                (success, ) = (payable(teamMembers[i])).call{value:payoutAmount}("");
                //(payable(teamMembers[i])).transfer(payoutAmount);
                require(success, "Withdraw failed");
            }
        }
        // payout the rest to first team member
        (success, ) = (payable(teamMembers[0])).call{value:address(this).balance}("");
        //(payable(teamMembers[0])).transfer(address(this).balance);
        require(success, "Withdraw failed-0");
    }
    
    // this function is for safety, if no team members have been defined
    function _withdrawToOwner(address owner) internal{
        require(teamMembers.length == 0, "Team members are defined");
        (bool success, ) = (payable(owner)).call{value:address(this).balance}("");
        //(payable(owner)).transfer(address(this).balance);
        require(success, "Withdraw failed.");
    }
    
    // these functions are meant to help retrieve ERC721, ERC1155 and ERC20 tokens that have been sent to this contract
    function _withdrawERC721(address _contract, uint256 id, address to) internal{
        // withdraw a 721 token
        ERC721Interface ERC721Contract = ERC721Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC721Contract.safeTransferFrom(address(this), to,id);
    }
    
    function _withdrawERC1155(address _contract, uint256[] memory ids, uint256[] memory amounts, address to) internal{
        // withdraw a 1155 token
        ERC1155Interface ERC1155Contract = ERC1155Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC1155Contract.safeBatchTransferFrom(address(this),to,ids,amounts,'');
    }
    
    function _withdrawERC20(address _contract, address to, uint256 amount) internal{
        // withdraw a 20 token
        ERC20Interface ERC20Contract = ERC20Interface(_contract);
        // transfer ownership from this contract to the specified address
        ERC20Contract.transfer(to, amount);
    }
    
}
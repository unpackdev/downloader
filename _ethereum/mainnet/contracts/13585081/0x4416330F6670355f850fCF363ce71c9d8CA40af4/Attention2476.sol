// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./AdminControl.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./SafeMath.sol";
import "./ERC1155Burnable.sol";

/**
 * @title Attention2476 contract
 * 
 * @author @FrankPoncelet
 * Owner Artchick
 * 
 */

contract Attention2476 is AdminControl, ERC1155Receiver{
    using SafeMath for uint256;
    
    address public contractAddress2476;
    
    struct DepositInfo {
        mapping (address => uint256)  amount;       // current staked 2476
        address[] wallet;       // Wallet that did stake
        bool inUse;             // to find if mapping exists
        uint index;             // index of project in the array
    }
    
    struct ProjectInfo {
        string project;         // the project name
        uint tokens;            // amount of tokens staked.
        
    }
    
    // A record of the stakes
    mapping (string => DepositInfo) private stakesByProject;
    mapping (address => string) public stakesByAddress;
    ProjectInfo[] private projects ;
    
    event DepositToken(address indexed to, uint amount, string project);
    event WithDrawDeposit(address indexed to, uint amount, string project);
    event BurnDeposit(uint amount, string project);
    
    bool public stakeIsActive;
    bool public emergencyLock=false;
    address private constant WALLET2476 = 0x0b8F4C4E7626A91460dac057eB43e0de59d5b44F;
    
    uint public minStake = 50;

    constructor(){
    }
    
    /**    
    * Set 2476 block emergency escape.
    * WARNING: you can't turn it back on!
    */
    function LockEmergencyHatch() external onlyOwner {
        emergencyLock=true;
    }
    
    /**    
    * Set 2476 Attention contract on/off
    */
    function flipStakeState() external onlyOwner {
        stakeIsActive = !stakeIsActive;
    }
    
    /**    
    * Set 2476 Token contract address
    */
    function set2476Contract(address payable newAddress) public onlyOwner {
         contractAddress2476 = newAddress;
    }
    /**    
    * Set a new minimum stake.
    */
    function setMinimumStake(uint amount) public onlyOwner{
        minStake=amount;
    }
    
    /**
     * Stake tokens to a project
     */
    function depositTokens( uint256 total,string memory project ) external {
        require(total>=minStake, "Attention2476 : you are not staking the min amount of coins.");
        require(stakeIsActive, "Attention2476: staking must be active to deposit Tokens!");
        require(bytes(project).length > 2 , "Attention2476 : Bad project name");
        require(keccak256(abi.encodePacked(stakesByAddress[msg.sender])) == (keccak256(abi.encodePacked(("")))),"Attention2476 : Wallet is already promoting a project.");
        require(IERC1155(contractAddress2476).balanceOf(msg.sender,2476)>=total,"Attention2476 : Wallet has insuficient tokens.");

        stakesByAddress[msg.sender]=project;
        if (!stakesByProject[project].inUse){
            stakesByProject[project].inUse = true;
            stakesByProject[project].index= projects.length;
            projects.push(ProjectInfo(project,total));
        } else {
            projects[stakesByProject[project].index].tokens += total;
        }
            stakesByProject[project].amount[msg.sender]=total;
            stakesByProject[project].wallet.push(msg.sender);
            
        IERC1155(contractAddress2476).safeTransferFrom(
            msg.sender, address(this),2476, total,"");
        emit DepositToken(msg.sender, total, project);
    }
    
    /**
     * Stake tokens to a project
     */
    function withDrawTokens(string memory project) external {
        require(keccak256(abi.encodePacked(stakesByAddress[msg.sender])) != (keccak256(abi.encodePacked(("")))),"Attention2476 : Wallet is NOT promoting a project.");
        require(stakesByProject[project].inUse,"Attention2476 :Project not Found.");
        stakesByAddress[msg.sender]="";
        uint amount = stakesByProject[project].amount[msg.sender];

        projects[stakesByProject[project].index].tokens -= stakesByProject[project].amount[msg.sender];
        stakesByProject[project].amount[msg.sender]=uint256(0);

        if(projects[stakesByProject[project].index].tokens==0){ // project is empty, lets remove it.
            delete stakesByProject[project].wallet;
            stakesByProject[project].inUse = false;
            // delete from project array
            uint lastIndex = projects.length - 1;
            string memory lastProject = projects[lastIndex].project;
            uint lastAmount = projects[lastIndex].tokens;
            // swap index 
            projects[stakesByProject[project].index].project=lastProject;
            projects[stakesByProject[project].index].tokens=lastAmount;
            stakesByProject[lastProject].index=stakesByProject[project].index;
            projects.pop();
        }
        emit WithDrawDeposit(msg.sender, amount, project);
        IERC1155(contractAddress2476).safeTransferFrom(address(this),msg.sender, 2476, amount,"" );
    }
    
    /**
     * Burn tokens to a project
     */
    function burnDeposit(string memory project) external adminRequired{
        require(stakesByProject[project].inUse,"Attention2476 : NO such project!");
        uint256 total =0;
        for (uint i = 0; i < stakesByProject[project].wallet.length; i++) {
            // burn each wallet entry
            if (stakesByProject[project].wallet[i]!=address(0)){
                
                stakesByAddress[stakesByProject[project].wallet[i]]="";
                total += stakesByProject[project].amount[stakesByProject[project].wallet[i]];
            }
        }

        // reset the array
        delete stakesByProject[project].wallet;
        stakesByProject[project].inUse = false;
        // delete from project array
        uint lastIndex = projects.length - 1;
        string memory lastProject = projects[lastIndex].project;
        uint lastAmount = projects[lastIndex].tokens;
        projects[stakesByProject[project].index].project=lastProject;
        projects[stakesByProject[project].index].tokens=lastAmount;
        stakesByProject[lastProject].index=stakesByProject[project].index;
        projects.pop();
        
        emit BurnDeposit(total, project);
        ERC1155Burnable(contractAddress2476).burn(address(this),2476, total); 
    }
    
     /**
      * Return the token balance of the contract.
      * 
      */
    function tokensInHolding() public view returns (uint){
         return IERC1155(contractAddress2476).balanceOf(address(this),2476);
    }

    /**
     * Retrieve all project names.
     */
    function getProjects() public view returns (ProjectInfo[] memory){
        return projects;
    }
    
    /**
     * Retrieve project by Index.
     */
    function getProjectsByIndex(uint index) public view returns (ProjectInfo memory){
        return projects[index];
    }
    
    /**
     * Send all the staked tokens out of the contract so we can migrate them to the next version.
     * Calling this will turn off staking on the contract.
     * 
     */
    function emergencyTransfer() external onlyOwner{
        require(!emergencyLock,"Attention2476 : Lock activated, can no monger be called.");
        stakeIsActive=false;
        uint total = tokensInHolding();
        IERC1155(contractAddress2476).safeTransferFrom(address(this),WALLET2476, 2476, total,"" );
    }
    
    /**
     * Methods needed to be an ERC1155 Reciever
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}



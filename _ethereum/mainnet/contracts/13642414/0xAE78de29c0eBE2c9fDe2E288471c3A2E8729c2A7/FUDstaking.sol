// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./AdminControl.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./SafeMath.sol";
import "./ERC1155Burnable.sol";

/**
 * @title AttentionFUD contract
 * 
 * @author @FrankPoncelet
 * @dev @FuegoNFT
 * 
 */

contract AttentionFUD is AdminControl, ERC1155Receiver{
    using SafeMath for uint256;
    
    address public contractAddressFUD;
    
    struct DepositInfo {
        mapping (address => uint256)  amount;       // current staked FUD
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
    address private constant WALLETFUD = 0x756624F2c0816bFb6a09E6d463c695b39a146629;
    
    uint public minStake = 20;

    constructor(){
    }
    
    /**    
    * Set FUD block emergency escape.
    * WARNING: you can't turn it back on!
    */
    function LockEmergencyHatch() external onlyOwner {
        emergencyLock=true;
    }
    
    /**    
    * Set FUD Attention contract on/off
    */
    function flipStakeState() external onlyOwner {
        stakeIsActive = !stakeIsActive;
    }
    
    /**    
    * Set FUD Token contract address
    */
    function setFUDContract(address payable newAddress) public onlyOwner {
         contractAddressFUD = newAddress;
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
        require(total>=minStake, "AttentionFUD : you are not staking the min amount of coins.");
        require(stakeIsActive, "AttentionFUD: staking must be active to deposit Tokens!");
        require(bytes(project).length > 2 , "AttentionFUD : Bad project name");
        require(keccak256(abi.encodePacked(stakesByAddress[msg.sender])) == (keccak256(abi.encodePacked(("")))),"AttentionFUD : Wallet is already promoting a project.");
        require(IERC1155(contractAddressFUD).balanceOf(msg.sender,7123)>=total,"AttentionFUD : Wallet has insuficient tokens.");

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
            
        IERC1155(contractAddressFUD).safeTransferFrom(
            msg.sender, address(this),7123, total,"");
        emit DepositToken(msg.sender, total, project);
    }
    
    /**
     * Stake tokens to a project
     */
    function withDrawTokens(string memory project) external {
        require(keccak256(abi.encodePacked(stakesByAddress[msg.sender])) != (keccak256(abi.encodePacked(("")))),"AttentionFUD : Wallet is NOT promoting a project.");
        require(stakesByProject[project].inUse,"AttentionFUD :Project not Found.");
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
        IERC1155(contractAddressFUD).safeTransferFrom(address(this),msg.sender, 7123, amount,"" );
    }
    
    /**
     * Burn tokens to a project
     */
    function burnDeposit(string memory project) external adminRequired{
        require(stakesByProject[project].inUse,"AttentionFUD : NO such project!");
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
        ERC1155Burnable(contractAddressFUD).burn(address(this),7123, total); 
    }
    
     /**
      * Return the token balance of the contract.
      * 
      */
    function tokensInHolding() public view returns (uint){
         return IERC1155(contractAddressFUD).balanceOf(address(this),7123);
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
        require(!emergencyLock,"AttentionFUD : Lock activated, can no monger be called.");
        stakeIsActive=false;
        uint total = tokensInHolding();
        IERC1155(contractAddressFUD).safeTransferFrom(address(this),WALLETFUD, 7123, total,"" );
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
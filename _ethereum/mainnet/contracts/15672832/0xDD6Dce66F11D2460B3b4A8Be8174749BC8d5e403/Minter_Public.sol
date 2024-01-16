// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./IKonduxFounders.sol";
import "./ITreasury.sol";
import "./AccessControlled.sol";

contract MinterPublic is AccessControlled {

    uint256 public price;

    bool public paused;

    IKonduxFounders public konduxFounders;
    ITreasury public treasury;

    constructor(address _authority, address _konduxFounders, address _vault) 
        AccessControlled(IAuthority(_authority)) {        
            require(_konduxFounders != address(0), "Kondux address is not set");
            konduxFounders = IKonduxFounders(_konduxFounders);
            require(_vault != address(0), "Vault address is not set");
            treasury = ITreasury(_vault);
            price = 0.25 ether;
            paused = false;
    }      

    function setPaused(bool _paused) public onlyGovernor {
        paused = _paused;
    }

  
    function publicMint() public payable isActive returns (uint256) {
        require(konduxFounders.totalSupply() < 650, "No more NFTs left");
        require(msg.value >= price, "Not enough ETH sent");
        treasury.depositEther{ value: msg.value }();
        return _mintFounders();
    }


    function setTreasury(address _treasury) public onlyGovernor {
        treasury = ITreasury(_treasury);
    }

    function setKonduxFounders(address _konduxFounders) public onlyGovernor {
        konduxFounders = IKonduxFounders(_konduxFounders);
    }

    function setPrice(uint256 _price) public onlyGovernor {
        price = _price;
    }
    


    // ** INTERNAL FUNCTIONS **

    function _mintFounders() internal returns (uint256) {
        uint256 id = konduxFounders.safeMint(msg.sender);
        return id;
    }


    // ** MODIFIERS **


    modifier isActive() {
        require(!paused, "Pausable: paused");
        _;
    }


}
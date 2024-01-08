// SPDX-License-Identifier: MIT

//@title "The Kaiju's not so Contraceptive Contraption" AKA the KCC !!

//@author Made with love(i would have said tears there) by Warno0. Kaiju #1323

/*@notice Any user should first go to the KaijuKingz and Rwaste contract to approve the tokens !
There is no cost whatsoever to use this app.
This project will be used to apply for a tutorship (truition ?) with the Kaiju DAO.
If by any chances your Kaiju, Baby or Rwaste ended up stuck in the contract, contact me on the Kaiju's Discord and everything
will be sent back to you.
Enjoy your babies !!*/

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Interfaces.sol";

contract KaijuDnaCollector is Ownable {
    using SafeERC20 for IERC20;
    
    //@dev the bool for stoping the breeds
    bool public active;
    
    //@dev addresses of the Kaiju and Rwaste contracts
    address public rwaste;
    address public kaiju;
    
    //@dev the contract's Kaiju
    uint256 myKaijuId;
    
    //@dev Interfaces
    //@dev big K and R are interfaces small k and r are addresses
    IKaiju public Kaiju;
    IRWaste public Rwaste;
    
    constructor(address _kaiju, address _rwaste) {
        kaiju = _kaiju;
        rwaste = _rwaste;
        Kaiju = IKaiju(kaiju);
        Rwaste = IRWaste(rwaste);
        active = true;
    }
    
    //@dev set the addresses for the interfaces and the IERC calls
    function setKaijuAddress(address _address) public onlyOwner {
        kaiju = _address;
        Kaiju = IKaiju(kaiju);
    }
    
    function setRwasteAddress(address _address) public onlyOwner {
        rwaste = _address;
        Rwaste = IRWaste(rwaste);
    }
    
    //@dev allows to stop breeding
    function setActive() public onlyOwner {
        active =! active;
    }
    
    //@dev send a Kaiju to the contract and save the ID for use in breeding
    function sendKaiju(uint256 _id) public onlyOwner{
        Kaiju.safeTransferFrom(msg.sender, address(this), _id, "");
        myKaijuId = _id;
    }
    
    //@notice stop the breeding functions if there is no more genesis in the contract
    //@dev only work if there was a Kaiju previously
    function retrieveKaiju(uint256 _id) public onlyOwner {
        Kaiju.safeTransferFrom(address(this), msg.sender, _id, "");
        if(Kaiju.balanceGenesis(address(this)) == 0) {
            active = false;
        }
    }
    
    //@dev claim the Rwaste from Kaijus held in the contract
    function claimRwaste(bool keepInContract) public onlyOwner {
        uint256 beforeClaim = IERC20(rwaste).balanceOf(address(this));
        Rwaste.claimReward();
        uint256 claimedRwaste = IERC20(rwaste).balanceOf(address(this)) - beforeClaim;
        if(keepInContract == false){
            IERC20(rwaste).safeTransfer(owner(), claimedRwaste);
        }
    }
    
    //@dev send the Rwaste to owner's wallet
    function retrieveRwaste() public onlyOwner{
        uint256 bal = IERC20(rwaste).balanceOf(address(this));
        require(bal > 0,                                                                                        "No Rwaste to collect");
        IERC20(rwaste).safeTransfer(owner(), bal);
    }
    
    function donate() public payable {
        require(msg.value > 0, "0");
        //Thank you kind Kaiju :D
    }
    
    function retrieveDonations() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0,                                                                                        "No donations to collect");
        payable(msg.sender).transfer(bal);
    }
    
    //@dev get a genesis id from the user
    function _getUserKaijuId(address _address) public view returns(uint256){
        uint256 id = Kaiju.maxGenCount();
        uint256 i = 0;
        while(id >= Kaiju.maxGenCount()){
            id = Kaiju.walletOfOwner(_address)[i];
            i++;
        }
        return id;
    }
    
    //@dev calculate the id of the baby to return after fusion
    function _getBabyId() private view returns(uint256 id){
        id = Kaiju.maxGenCount() + Kaiju.babyCount();
    }
    
    /*@dev send the user's Kaiju and Rwaste to the contract to mint
    a baby then send the baby and the Kaiju back
    
    @dev looking at it after the facts i could have implemented a loop for users to mint
    multiple babys at once.
    i will also keep it as is because it is my first contract and that will give me
    a point of reference in the future*/
    function breed() public {
        
        require(active,                                                                                          "sorry, the system is not live at the moment!");
        require(Kaiju.balanceGenesis(msg.sender) > 0 && IERC20(rwaste).balanceOf(msg.sender) >= 750 ether,       "You need a Kaiju and 750 Rwaste to do this!");
        require(Kaiju.balanceGenesis(address(this)) > 0,                                                         "Sorry, my Kaiju went for a walk");
        
        uint256 UserKaijuId = _getUserKaijuId(msg.sender);
        uint256 BabyId = _getBabyId();
        
        Kaiju.safeTransferFrom(msg.sender, address(this), UserKaijuId, "");
        IERC20(rwaste).safeTransferFrom(msg.sender, address(this), 750 ether);
        
        Kaiju.fusion(myKaijuId, UserKaijuId);
        
        Kaiju.safeTransferFrom(address(this), msg.sender, BabyId, "");
        Kaiju.safeTransferFrom(address(this), msg.sender, UserKaijuId, "");
    }
    
    //@dev same as above but uses the contract's Rwaste and send the baby back to the contract's owner
     function breedForTheContract() public {
        
        require(active,                                                                                         "Sorry, the system is not live at the moment!");
        require(IERC20(rwaste).balanceOf(address(this)) >= 750 ether,                                           "Looks like i don't have enougth Rwaste to do this!");
        require(Kaiju.balanceGenesis(msg.sender) > 0,                                                           "You forgot your Kaiju in your lab !");
        require(Kaiju.balanceGenesis(address(this)) > 0,                                                        "Sorry, my Kaiju went for a walk");
        
        uint256 BabyId = _getBabyId();
        uint256 UserKaijuId = _getUserKaijuId(msg.sender);
        
        Kaiju.safeTransferFrom(msg.sender, address(this), UserKaijuId, "");
        
        Kaiju.fusion(myKaijuId, UserKaijuId);
        
        Kaiju.safeTransferFrom(address(this), owner(), BabyId, "");
        Kaiju.safeTransferFrom(address(this), msg.sender, UserKaijuId, "");
    }
    
    //@dev some ERC standard shenanigans
    function onERC721Received(address, address, uint256, bytes calldata) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
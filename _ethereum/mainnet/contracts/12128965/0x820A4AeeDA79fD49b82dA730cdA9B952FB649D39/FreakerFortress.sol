pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./EtherFreakers.sol";
import "./FreakerAttack.sol";


contract FreakerFortress is ERC721, ERC721Holder {

	address public manager;
	uint128 public joinFeeWei = 1e17;
	uint128 public attackFeeWei = 5e17;
	address public etherFreakersAddress;
	address public attackContract;
	uint8 public maxRemoteAttackers = 4;

	constructor(address author, address _etherFreakersAddress) ERC721("FreakerFortress", "FEFKR") {
        manager = author;
        etherFreakersAddress = _etherFreakersAddress;
    }

    modifier ownerOrApproved(uint128 freakerID) { 
    	require(_isApprovedOrOwner(msg.sender, freakerID), "FreakerFortress: caller is not owner nor approved");
    	_; 
    }

    modifier managerOnly() { 
    	require(msg.sender == manager, "FreakerFortress: caller is not owner nor approved");
    	_; 
    }
    
    function depositFreaker(address payable mintTo, uint128 freakerID) payable external {
        require(msg.value >= joinFeeWei, "FreakerFortress: Join fee too low");
        EtherFreakers(etherFreakersAddress).transferFrom(msg.sender, address(this), freakerID);
        _safeMint(mintTo, freakerID, "");
    }

    // attack contract only 
    function depositFreakerFree(address payable mintTo, uint128 freakerID) payable external {
        require(msg.sender == attackContract, "FreakerFortress: Attack contract only");
        EtherFreakers(etherFreakersAddress).transferFrom(msg.sender, address(this), freakerID);
        _safeMint(mintTo, freakerID, "");
    }

    function withdrawFreaker(address to, uint128 freakerID) payable external ownerOrApproved(freakerID) {
        EtherFreakers(etherFreakersAddress).safeTransferFrom(address(this), to, freakerID);
        _burn(freakerID);
    }

    function discharge(uint128 freakerID, uint128 amount) public {
        require(ownerOf(freakerID) == msg.sender, "FreakerFortress: only owner");
        // calculate what the contract will be paid before we call
        uint128 energy = EtherFreakers(etherFreakersAddress).energyOf(freakerID);
        uint128 capped = amount > energy ? energy : amount;
        EtherFreakers(etherFreakersAddress).discharge(freakerID, amount);
        // pay owner 
        address owner = ownerOf(freakerID);
        payable(owner).transfer(capped);
    }

    function charge(uint128 freakerID) payable ownerOrApproved(freakerID) public {
       EtherFreakers(etherFreakersAddress).charge{value: msg.value}(freakerID);
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        return EtherFreakers(etherFreakersAddress).tokenURI(tokenID);
    }

    // this is to handle tokens sent to the contract 
    function claimToken(address to, uint256 freakerID) payable external {
        require(!_exists(freakerID), "FreakerFortress: token has owner");
        require(EtherFreakers(etherFreakersAddress).ownerOf(freakerID) == address(this), "FreakerFortress: fortress does not own token");
    	_safeMint(to, freakerID, "");
    }

    // these methods allow someone to pay to have members of the fortress 
    // attack a target

    function createAttackContract() external {
    	require(attackContract == address(0), "FreakerFortress: attack contract already exists");
    	attackContract = address(new FreakerAttack(payable(address(this)), etherFreakersAddress)); 
    }

    function remoteAttack(uint128[] calldata freakers, uint128 sourceId, uint128 targetId) external payable returns(bool response) {
    	require(msg.value >= attackFeeWei, "FreakerFortress: Attack fee too low");
        require(attackContract != address(0), "FreakerFortress: attack contract does not exist");
    	require(EtherFreakers(etherFreakersAddress).ownerOf(targetId) != address(this), "FreakerFortress: cannot attack freak in fortress");
    	require(!EtherFreakers(etherFreakersAddress).isEnlightened(targetId), "FreakerFortress: target is enlightened");
    	require(freakers.length <= maxRemoteAttackers, "FreakerFortress: too many attackers");
    	for(uint i=0; i < freakers.length; i++){
			EtherFreakers(etherFreakersAddress).transferFrom(address(this), attackContract, freakers[i]);
		}
		response = FreakerAttack(attackContract).attack(payable(msg.sender), sourceId, targetId);
		FreakerAttack(attackContract).sendBack(freakers);
    }

    // owner methods

    function updateFightFee(uint128 _fee) external managerOnly {
        attackFeeWei = _fee;
    }

    function updateJoinFee(uint128 _fee) external managerOnly {
        joinFeeWei = _fee;
    }

    function updateManager(address _manager) external managerOnly {
        manager = _manager;
    }

    function updateMaxRemoteAttackers(uint8 count) external managerOnly {
        maxRemoteAttackers = count;
    }

    function payManager(uint256 amount) external managerOnly {
        require(amount <= address(this).balance, "FreakerFortress:  amount  too high");
        payable(manager).transfer(amount);
    }

    // payable

    receive() payable external {
        // nothing to do
    }
}
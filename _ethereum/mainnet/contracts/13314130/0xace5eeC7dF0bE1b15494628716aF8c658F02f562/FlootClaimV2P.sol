// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./console.sol";

import "./IERC721EnumerableUpgradeable.sol";

interface Floot721 is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract FLOOTClaimsProxy is Initializable, ERC721HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);
    event LuckyFuck(uint256, address);
    event ChosenFuck(uint256, address);

    uint256 public currentFloots;
    bool public halt;
    Floot721 public floot;
    PayoutInfo[] public payoutInfo; // keeps track of payout deets
    //NFTClaimInfo[] public nftClaimInfo;
    struct FlootIDinfo {
        uint256 tokenID;        // ID of FLOOT token
        uint256 rewardDebt;     // amount the ID is NOT entitled to (ie previous distros and claimed distros)
        uint256 pending;
        uint256 paidOut;        // amount paid out to ID
        bool tracked;
    }
    struct PayoutInfo {
        address payoutToken;        // Address of LP token contract.
        uint256 balance;            // total amount of payout in contract
        uint256 pending;            // pending payouts
        uint256 distroPerFloot;     // amount each FLOOT is entitled to
        uint256 paidOut;            // total paid out to FLOOTs
    }
    struct NFTClaimInfo {
        address nftContract;
        uint256 tokenID;
        uint256 luckyFuck;
        bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;
    mapping (uint256 => mapping (uint256 => FlootIDinfo)) public flootIDinfo;     // keeps track of pending and claim rewards
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _floot) public initializer {
        __Ownable_init();
        __ERC721Holder_init();
        __UUPSUpgradeable_init();
        floot = Floot721(_floot);
        halt = false;
        addPayoutPool(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        updateNewHolders(floot.totalSupply(),0);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    receive() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {

        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
            random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function random721(address nftContract, uint256 tokenID) internal {
        // updatePayout(0);
        
        uint256 luckyFuck = pickLuckyFuck();
        
        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,luckyFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[luckyFuck].push(newClaim);

        emit LuckyFuck(luckyFuck, nftContract);
    }

    function send721(address nftContract, uint256 tokenID, uint256 chosenFuck) public {
        ERC721Upgradeable(nftContract).safeTransferFrom(msg.sender, address(this), tokenID, 'true');

        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,chosenFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[chosenFuck].push(newClaim);

        emit ChosenFuck(chosenFuck, nftContract);
    }

    function pickLuckyFuck() internal view returns (uint) {
        uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentFloots)));
        return (rando % currentFloots) + 1;
    }
    
    function fundEther() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }
    
    function ethBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function updatePayout(uint256 _pid) public {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();
        require(flootSupply > 0, "No one owns Floot yet");
        uint256 totalDebt;
        uint256 newFloots;
        
        if(flootSupply > currentFloots){
            newFloots = flootSupply - currentFloots;
            updateNewHolders(newFloots, _pid);
        }
        
        uint256 totalPaidOut;

        uint256 currentBalance;

        for (uint256 tokenIndex = 0; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            totalPaidOut += flootIDinfo[_pid][tokenID].paidOut;
            totalDebt += flootIDinfo[_pid][tokenID].rewardDebt;
        }

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20Upgradeable(payout.payoutToken).balanceOf(address(this));
        }

        uint256 totalDistro = currentBalance + totalPaidOut + totalDebt;
        payout.distroPerFloot = totalDistro * 1000 / flootSupply;
        payout.balance = totalDistro;
    }
    
    function updateNewHolders(uint256 newFloots, uint256 _pid) internal {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();

        for (uint256 tokenIndex = currentFloots; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[_pid][tokenID].rewardDebt = payout.distroPerFloot / 1000;
            flootIDinfo[_pid][tokenID].tracked = true;
        }
        
        currentFloots += newFloots;
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed && luckyFloot[index].nftContract == _nftContract && luckyFloot[index].tokenID == _nftId){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimAcctPending(uint256 _pid) public {
        require(!halt, 'Claims temporarily unavailable');
        updatePayout(_pid);
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256[] memory userInventory = floot.walletInventory(msg.sender);
        require(userInventory.length > 0);
        uint256 pending = payout.distroPerFloot * userInventory.length / 1000;
        uint256 payoutPerTokenID;
        uint256 paidout;
        uint256 rewardDebt;

        uint256 claimAmount;

        // get payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            paidout += flootIDinfo[_pid][userInventory[index]].paidOut;
            rewardDebt += flootIDinfo[_pid][userInventory[index]].rewardDebt;
        }

        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt;
            payoutPerTokenID = claimAmount / userInventory.length; }
        else {
            return; 
        }

        // add new payout to each tokenID's paid balance 
        for (uint256 index = 0; index < userInventory.length; index++) {
            flootIDinfo[_pid][userInventory[index]].paidOut += payoutPerTokenID; }

        payout.paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        
        //updatePayout(_pid);
    }

    function claimTokenPending(uint256 _pid, uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender);
        
        updatePayout(_pid);
        
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_tokenID].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_tokenID].rewardDebt;

        uint256 claimAmount;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt; }
        else{ return; }

        // add new payout to each tokenID's paid balance 
        flootIDinfo[_pid][_tokenID].paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        payout.paidOut += claimAmount;
        //updatePayout(_pid);
    }

    function viewNFTsPending(uint _tokenID) public view returns(NFTClaimInfo[] memory){
        return nftClaimInfo[_tokenID];
    }
    
    function viewAcctPending(uint256 _pid, address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;
        
        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            pending += viewTokenPending(_pid,userInventory[index]);
        }
        
        return pending;
    }
    
    function viewTokenPending(uint256 _pid, uint256 _id) public view returns(uint256){
        PayoutInfo storage payout = payoutInfo[_pid];
        if(!flootIDinfo[_pid][_id].tracked){
            return 0;
        }
        //uint256 pending = viewLatestClaimAmount(_pid) / 1000;
        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_id].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_id].rewardDebt;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            return pending - paidout - rewardDebt; }
        else {
            return 0; 
        }
    }

    function viewNumberNftPending(address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;

        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
                if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                    pending++;
                }
            }
        }
        return pending;
    }

    function addPayoutPool(address _payoutToken) public onlyOwner {
        payoutInfo.push(PayoutInfo({
            payoutToken: _payoutToken,
            balance: 0,
            pending: 0,
            distroPerFloot: 0,
            paidOut: 0
        }));
        for (uint256 tokenIndex = 0; tokenIndex < floot.totalSupply(); tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[payoutInfo.length - 1][tokenID].tracked = true;
        }
    }

    function rescueTokens(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20Upgradeable(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }
    
    function rescueTokens2(address _recipient, IERC20Upgradeable _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        _ERC20address.safeTransfer(_recipient, _amount); //use of the _ERC20 safetransfer
        return true;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeFloot(address _newFloot) public onlyOwner {
        floot = Floot721(_newFloot);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }

    function payoutPoolLength() public view returns(uint) {
        return payoutInfo.length;
    }

    function depositERC20(uint _pid, IERC20Upgradeable _tokenAddress, uint _amount) public {
        require(payoutInfo[_pid].payoutToken == address(_tokenAddress));
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        updatePayout(_pid);
    }
}
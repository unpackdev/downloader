// SPDX-License-Identifier: MIT                                                                                                                                                                                                
//  ,-----.          ,--.            ,--.  ,--.          ,--.              ,--.                   
//  |  |) /_  ,--,--.|  |-.,--. ,--. |  '--'  | ,---.  ,-|  | ,---.  ,---. |  ,---.  ,---.  ,---. 
//  |  .-.  \' ,-.  || .-. '\  '  /  |  .--.  || .-. :' .-. || .-. || .-. :|  .-.  || .-. || .-. |
//  |  '--' /\ '-'  || `-' | \   '   |  |  |  |\   --.\ `-' |' '-' '\   --.|  | |  |' '-' '' '-' '
//  `------'  `--`--' `---'.-'  /    `--'  `--' `----' `---' .`-  /  `----'`--' `--' `---' .`-  / 
//                         `---'                             `---'                         `---'  
// By Exolith                                                                             

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "SafeMath.sol";

pragma solidity >=0.7.0 <0.9.0;

contract BabyHedgehog is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string private _name = "BabyHedgehog";
    string private _symbol = "BHG";
    
    bool private _saleOn = false;

    uint256 public cost = 0.044 ether;
    uint256 public maxSupply = 4444;
    uint256 private _reserved = 44;

    string private _currentBaseURI;
    string public baseExtension = ".json";

    address private _dev;

    uint256 public reflectFee = 5;
    uint256 public devFee = 5;

    // Int for total fee amount
    uint256 private _reflectedFeeTotal = 0;
    //Int for total claimed rewards 
    uint256 private _totalClaimedRewards = 0; 
    // Mapping from tokenId to claimed token rewards
    mapping(uint256 => uint256) private _claimedTokenRewards;

    uint256 constant MIN_CLAIM_AMOUNT = 0.005 ether; 

    event Sale(address from, address to, uint256 value);
    event ClaimRewards(address to, uint256 value);
    event ReflectFee(uint256 fee, uint256 totalFee);

    // These 4444 cute baby hedgehogs are now playing around on the Ethereum blockchain and are looking for a new, lovely home. 
    // Offer them a nice place to live and get rewarded with Ethereum.
    constructor(string memory baseURI, address dev) ERC721(_name, _symbol) {
        setBaseURI(baseURI);
        _dev = dev;

        //Dev gets the first 3 baby hedgehogs
        _safeMint(_dev, 0);
        _safeMint(_dev, 1);
        _safeMint(_dev, 2);
    }

    // Public functions
    function mint(uint256 amount) public payable {
        uint256 supply = totalSupply();

        require(saleOn(),                                               "Sale is off.");
        require(amount <= 20,                                           "You can mint a maximum of 20 Baby Hedgehogs.");
        require(supply.add(amount) <= maxSupply.sub(_reserved),         "Exceeds Max Supply.");
        require(msg.value >= cost.mul(amount),                          "Sent Ether is not correct.");

        //Reflect Fee to Token Owners
        uint256 rFee = msg.value.mul(reflectFee).div(100);
        _reflectFee(rFee);

        uint256 transferAmount = msg.value.sub(rFee);
        _payDev(transferAmount);
        
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
    }


    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        
        if (from != address(0) && from != to) {
            _safeClaimRewards(from);
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }


    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            //Pay Fee to Dev
            uint256 dFee = msg.value.mul(devFee).div(100);
            _payDev(dFee);

            //Reflect Fee to Token Owners
            uint256 rFee = msg.value.mul(reflectFee).div(100);
            _reflectFee(rFee);

            uint256 transferAmount = msg.value.sub(dFee).sub(rFee);

            (bool success, ) = payable(from).call{value: transferAmount}("");
            require(success);

            emit Sale(from, to, transferAmount);
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        if (msg.value > 0) {
            //Pay Fee to Dev
            uint256 dFee = msg.value.mul(devFee).div(100);
            _payDev(dFee);

            //Reflect Fee to Token Owners
            uint256 rFee = msg.value.mul(reflectFee).div(100);
            _reflectFee(rFee);

            uint256 transferAmount = msg.value.sub(dFee).sub(rFee);

            (bool success, ) = payable(from).call{value: transferAmount}("");
            require(success);

            emit Sale(from, to, transferAmount);
        }

        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            //Pay Fee to Dev
            uint256 dFee = msg.value.mul(devFee).div(100);
            _payDev(dFee);

            //Reflect Fee to Token Owners
            uint256 rFee = msg.value.mul(reflectFee).div(100);
            _reflectFee(rFee);

            uint256 transferAmount = msg.value.sub(dFee).sub(rFee);

            (bool success, ) = payable(from).call{value: transferAmount}("");
            require(success);

            emit Sale(from, to, transferAmount);
        }

        _safeTransfer(from, to, tokenId, _data);
    }


    /**
     * Return the total reflected fee from all users
     */
    function getTotalReflectedFee() public returns (uint256) {
        return _getTotalReflectedFee(); 
    }

    /**
     * Return the total claimed rewards from all users
     */
    function getTotalClaimedRewards() public returns (uint256) {
        return _getTotalClaimedRewards(); 
    }

    /**
     * Return the total unclaimed rewards from all users
     */
    function getTotalUnclaimedRewards() public returns (uint256) {
        return _getTotalUnclaimedRewards(); 
    }

    /**
     * Return the total rewards for a owner from all his owned nfts
     */
    function getTotalRewards(address owner) public returns (uint256) { 
        return _getTotalRewards(owner);
    }

    /**
     * Return the unclaimed rewards for a owner for all his owned nfts
     */
    function getUnclaimedRewards(address owner) public returns (uint256, uint256[] memory) {
        return _getUnclaimedRewards(owner);
    }

    /**
     * Claim the rewards for a owner. Only the owner can claim his rewards
     */
    function claimRewards() public returns (uint256) { 
        return _claimRewards(msg.sender);
    }

    /**
     * Return true if sale is on
     */
    function saleOn() public view returns (bool){
        return _saleOn;
    }

    /**
     * Return amount of reserved hedgehogs for giveaway
     */
    function reserved() public view returns (uint256) {
        return _reserved; 
    }

    /**
     * Helper Function to return all owners of the baby hedgehogs
     */
    function getAllOwners() public returns (address[] memory) {
        uint256 supply = totalSupply(); 

        address[] memory owners = new address[](supply); 
        for (uint256 i = 0; i < supply; i++) {
            owners[i] = ERC721.ownerOf(ERC721Enumerable.tokenByIndex(i));
        }
        return owners;
    }

    /**
     * Helper Function to return all baby hedgehogs of given owner
     */
    function getAllTokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }


    // Internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function _payDev(uint256 fee) internal {
        (bool success, ) = payable(_dev).call{ value: fee }("");
        require(success);
    }

    function _getTotalReflectedFee() internal returns (uint256) {
        return _reflectedFeeTotal; 
    }

    function _getTotalClaimedRewards() internal returns (uint256) {
        return _totalClaimedRewards; 
    }

    function _getTotalUnclaimedRewards() internal returns (uint256) {
        require(_reflectedFeeTotal > _totalClaimedRewards, "No unclaimend rewards available!");

        return _reflectedFeeTotal.sub(_totalClaimedRewards); 
    }

    function _getTotalRewards(address owner) internal returns (uint256) {
        require(_reflectedFeeTotal >= MIN_CLAIM_AMOUNT, "Not enough Rewards to claim"); 

        uint256 balance = ERC721.balanceOf(owner);
        require(balance > 0, "Owner must have at least one Token for claiming rewards.");

        uint256 supply = ERC721Enumerable.totalSupply(); 
        uint256 totalRewards = _reflectedFeeTotal.div(supply).mul(balance);

        return totalRewards; 
    }

    function _safeGetTotalRewards(address owner) internal returns (uint256) {
        if (_reflectedFeeTotal < MIN_CLAIM_AMOUNT) return 0; 

        uint256 balance = ERC721.balanceOf(owner);
        if (balance < 1) return 0;

        uint256 supply = ERC721Enumerable.totalSupply(); 
        uint256 totalRewards = _reflectedFeeTotal.div(supply).mul(balance);

        return totalRewards; 
    }

    function _getUnclaimedRewards(address owner) internal returns (uint256, uint256[] memory) {
        uint256 balance = ERC721.balanceOf(owner);
        require(balance > 0, "Owner must have at least one Token for claiming rewards.");

        uint256 ownerRewardsTotal = _getTotalRewards(owner); 

        require(ownerRewardsTotal >= MIN_CLAIM_AMOUNT, "Owners total rewards are too small to claim."); 

        uint256 ownersRewardsEach = ownerRewardsTotal.div(balance); 

        uint256 unclaimedRewardsTotal = 0; 
        uint256[] memory unclaimedRewards = new uint256[](balance); 
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
            uint256 unclaimedReward = ownersRewardsEach.sub(_claimedTokenRewards[tokenId]);
            unclaimedRewards[i] =  unclaimedReward;
            unclaimedRewardsTotal = unclaimedRewardsTotal.add(unclaimedReward);
        }

        return (unclaimedRewardsTotal, unclaimedRewards);

    }

    function _safeGetUnclaimedRewards(address owner) internal returns (uint256, uint256[] memory) {
        uint256 balance = ERC721.balanceOf(owner);
        if (balance < 1) return (0, new uint256[](0));

        uint256 ownerRewardsTotal = _safeGetTotalRewards(owner); 

        if (ownerRewardsTotal < MIN_CLAIM_AMOUNT) return (0, new uint256[](0)); 

        uint256 ownersRewardsEach = ownerRewardsTotal.div(balance); 

        uint256 unclaimedRewardsTotal = 0; 
        uint256[] memory unclaimedRewards = new uint256[](balance); 
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
            uint256 unclaimedReward = ownersRewardsEach.sub(_claimedTokenRewards[tokenId]);
            unclaimedRewards[i] =  unclaimedReward;
            unclaimedRewardsTotal = unclaimedRewardsTotal.add(unclaimedReward);
        } 

        return (unclaimedRewardsTotal, unclaimedRewards);
    }

    function _claimRewards(address owner) internal returns (uint256) {
        (uint256 unclaimedRewardsTotal, uint256[] memory unclaimedRewards)  = _getUnclaimedRewards(owner);
        require(unclaimedRewardsTotal >= MIN_CLAIM_AMOUNT, "Claimable rewards are to small."); 

        for (uint256 i = 0; i < unclaimedRewards.length; i++) {
            uint256 tokenId = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
            _claimedTokenRewards[tokenId] = _claimedTokenRewards[tokenId].add(unclaimedRewards[i]); 
        }

        _totalClaimedRewards = _totalClaimedRewards.add(unclaimedRewardsTotal); 

        (bool success, ) = payable(owner).call{value: unclaimedRewardsTotal}("");
        require(success);

        emit ClaimRewards(owner, unclaimedRewardsTotal); 

        return unclaimedRewardsTotal;
    }

    function _safeClaimRewards(address owner) internal returns (uint256) {
        (uint256 unclaimedRewardsTotal, uint256[] memory unclaimedRewards)  = _safeGetUnclaimedRewards(owner);
        if (unclaimedRewardsTotal < MIN_CLAIM_AMOUNT) return unclaimedRewardsTotal;

        for (uint256 i = 0; i < unclaimedRewards.length; i++) {
            uint256 tokenId = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
            _claimedTokenRewards[tokenId] = _claimedTokenRewards[tokenId].add(unclaimedRewards[i]); 
        }

        _totalClaimedRewards = _totalClaimedRewards.add(unclaimedRewardsTotal); 

        (bool success, ) = payable(owner).call{value: unclaimedRewardsTotal}("");
        require(success);

        emit ClaimRewards(owner, unclaimedRewardsTotal); 

        return unclaimedRewardsTotal;
    }

    function _reflectFee(uint256 fee) internal {
        _reflectedFeeTotal = _reflectedFeeTotal.add(fee); 

        emit ReflectFee(fee, _reflectedFeeTotal);
    }


    // Owner functions
    function startSale() public onlyOwner{
        _saleOn = true;
    }

    function stopSale() public onlyOwner{
        _saleOn = false;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
       _currentBaseURI = newBaseURI;
    }

    function setDevFee(uint256 newDevFee) public onlyOwner {
        devFee = newDevFee;
    }

    function setReflectFee(uint256 newReflectFee) public onlyOwner {
        reflectFee = newReflectFee;
    }

    function setDevWallet(address devWallet) public onlyOwner {
        _dev = devWallet; 
    }

    function giveAway(address to, uint256 amount) external onlyOwner() {
        require(amount <= _reserved, "Exceeds reserved Baby Hedgehogs supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < amount; i++){
            _safeMint(to, supply + i );
        }

        _reserved.sub(amount);
    }
}
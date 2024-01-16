// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./Ownable.sol";
import "./Address.sol";

contract NewFeeCollector is Ownable {
    uint256 public hsiMarketPlaceCollection;
    uint256 public hexartMarketPlaceCollection;
    uint256 public hexartArtistFeeCollection;

    enum CollectorTypes {
        BUYBURN,
        BUYDISTRIBUTE,
        HEXMARKET,
        HEDRONFLOW,
        BONUS
    }

    struct FeesCollectors {
        address payable feeAddress;
        uint256 share;
        uint256 hexArtShare;
        uint256 artistShare;
        uint256 amount;
    }

    mapping(uint256 => FeesCollectors) public feeMap;
    mapping(address => bool) public whitelistedAddresses;

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "Not have permission");
        _;
    }

    receive() external payable {}

    /**
     *@notice Set Fee collector wallet details
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function setFees(
        CollectorTypes feeType,
        address payable wallet,
        uint256 share,
        uint256 _hexArtShare,
        uint256 _artistShare
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");
        require(
            uint256(feeType) >= 0 && uint256(feeType) < 5,
            "Invalid fee type"
        );

        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            hexArtShare: _hexArtShare,
            artistShare: _artistShare,
            amount: 0
        });
    }

    /**
     *@notice Update Fee collector wallet address and share
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function updateFees(
        CollectorTypes feeType,
        address payable wallet,
        uint256 share,
        uint256 _hexArtShare,
        uint256 _artistShare
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");
        require(
            uint256(feeType) >= 0 && uint256(feeType) < 5,
            "Invalid fee type"
        );
        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            hexArtShare: _hexArtShare,
            artistShare: _artistShare,
            amount: feeMap[uint256(feeType)].amount
        });
    }

    /**
     *@notice Assigns fees amount to fee collector structs
     *@param  value, buying amount for NFT, recieved from marketplace
     *@param  addShare, total fees share amount for NFT, recieved from marketplace
     */
    function manageFees(uint256 value, uint256 addShare)
        external
        isWhitelisted(msg.sender)
    {
        for (uint256 i = 0; i < 5; i++) {
            uint256 shareAmount = updateAmount(i, value, addShare);
            addShare = addShare - shareAmount;
        }
    }

    /**
     *@notice Assigns fees amount to fee collector structs
     *@param  value, buying amount for hexart, recieved from hex marketplace
     */
    function manageHexArtFees(uint256 value)
        external
        isWhitelisted(msg.sender)
    {
        require(value > 0, "value should not be 0");
        for (uint256 i = 0; i < 5; i++) {
            updateHexArtAmount(i, value);
        }
    }

    /**
     *@notice Assigns fees amount to fee collector structs
     *@param  value, artistFee , recieved from hex marketplace
     */
    function manageArtistFees(uint256 value)
        external
        isWhitelisted(msg.sender)
    {
        require(value > 0, "value should not be 0");
        for (uint256 i = 0; i < 5; i++) {
            updateArtistAmount(i, value);
        }
    }

    /**
     *@notice Claim Hexmarket amount
     */
    function claimHexmarket() external {
        uint256 id = uint256(CollectorTypes.HEXMARKET);
        claimBalances(id);
        claimHedronFlow();
    }

    /**
     *@notice Claim Bonus amount
     */
    function claimBonus() external {
        uint256 id = uint256(CollectorTypes.BONUS);
        claimBalances(id);
    }

    /**
     *@notice Claim HedronFlow amount
     */
    function claimHedronFlow() public {
        uint256 id = uint256(CollectorTypes.HEDRONFLOW);
        claimBalances(id);
    }

    /**
     *@notice Claim Buy and Burn amount
     */
    function claimBuyBurn() external {
        uint256 id = uint256(CollectorTypes.BUYBURN);
        claimBalances(id);
    }

    /**
     *@notice Claim Buy and distribute  amount.
     */
    function claimBuyDistribute() external {
        uint256 id = uint256(CollectorTypes.BUYDISTRIBUTE);
        claimBalances(id);
    }

    /**
     *  @notice Withdraw the extra eth available after distribution.
     */
    function withdrawDust() public onlyOwner {
        uint256 withdrawableAmount;
        uint256 nonWithdrawableAmount;
        for (uint256 i = 0; i < 5; i++) {
            nonWithdrawableAmount += feeMap[i].amount;
        }
        withdrawableAmount = address(this).balance - nonWithdrawableAmount;
        require(withdrawableAmount > 0, "No extra ETH is available");
        payable(msg.sender).transfer(withdrawableAmount);
    }

    /**
    @notice Add asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function addAssetToWhitelist(address _addressToWhitelist) public onlyOwner {
        require(
            Address.isContract(_addressToWhitelist),
            "Only contract address are allowed"
        );
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    /**
    @notice Remove asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function removeAssetFromWhitelist(address _addressToWhitelist)
        public
        onlyOwner
    {
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    /**
     *@notice  Get balance of this contract.
     *@return uint
     */
    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /**
     *@notice Update amount to fee collector structs used by manageFees function
     *@param   id, Index of COLLECTORTYPES
     *@param  value, buying amount for NFT, recieved from marketplace
     *@param  addShare, total fees share amount for NFT, recieved from marketplace
     */
    function updateAmount(
        uint256 id,
        uint256 value,
        uint256 addShare
    ) internal returns (uint256) {
        uint256 shareAmount = (value * feeMap[id].share) / 1000000;
        if (shareAmount <= addShare) {
            feeMap[id].amount = feeMap[id].amount + shareAmount;
            hsiMarketPlaceCollection = hsiMarketPlaceCollection + shareAmount;
        } else {
            feeMap[id].amount = feeMap[id].amount + addShare;
            hsiMarketPlaceCollection = hsiMarketPlaceCollection + addShare;
        }

        return shareAmount;
    }

    /**
     *@notice Update amount to fee collector structs used by manageFees function
     *@param   id, Index of COLLECTORTYPES
     *@param  value, buying amount for NFT, recieved from marketplace
     */
    function updateHexArtAmount(uint256 id, uint256 value)
        internal
        returns (uint256)
    {
        uint256 shareAmount = (value * feeMap[id].hexArtShare) / 1000000;

        feeMap[id].amount = feeMap[id].amount + shareAmount;
        hexartMarketPlaceCollection = hexartMarketPlaceCollection + shareAmount;

        return shareAmount;
    }

    /**
     *@notice Update amount to fee collector structs used by manageFees function
     *@param   id, Index of COLLECTORTYPES
     *@param  value, buying amount for NFT, recieved from marketplace
     */
    function updateArtistAmount(uint256 id, uint256 value)
        internal
        returns (uint256)
    {
        uint256 shareAmount = (value * feeMap[id].artistShare) / 100;

        feeMap[id].amount = feeMap[id].amount + shareAmount;
        hexartArtistFeeCollection = hexartArtistFeeCollection + shareAmount;

        return shareAmount;
    }

    /** 
     @notice Claim Balance for the type of COLLECTORTYPES
     *@param  id, Index of COLLECTORTYPES
    */
    function claimBalances(uint256 id) internal {
        uint256 totalAmount = feeMap[id].amount;
        require(
            totalAmount <= getBalance() && totalAmount > 0,
            "Not enough balance to claim"
        );
        feeMap[id].amount = 0;
        feeMap[id].feeAddress.transfer(totalAmount);
    }
}

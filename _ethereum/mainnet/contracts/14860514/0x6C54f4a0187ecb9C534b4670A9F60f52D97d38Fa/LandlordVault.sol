/* SPDX-License-Identifier: MIT

Smart contract written by: idecentralize.eth

*/
pragma solidity 0.8.11;


import "./NFTContract.sol";
import "./yVault.sol";
import "./IWETH.sol";
import "./ICollector.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract LandlordVault is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{

    NFTContract landlords;
    IWETH weth;
    yVault yETH;
    address public royaltiesCollector;
    address public rentCollector;
    address public teamWallet;
    uint256 public royaltiesBalance;
    uint256 public rentBalance;
    uint256 public accRoyaltiesPerNFT;
    uint256 public accRentPerNFT;
    uint256 genesisTokens;

    uint256[] landlordsID;
    uint256[] landlordShares;

    mapping(uint256 => uint256) royaltiesPaid;
    mapping(uint256 => uint256) rentPaid;

    event RentDue(address collector, uint256 amount);
    event RoyaltiesDue(address collector, uint256 amount);
    event Collected(address account, uint256 amount);

    modifier onlyLandlord() {
        require(landlords.balanceOf(msg.sender) > 0, "ERROR : Not a landlord!");
        _;
    }

    modifier onlyLandlordContract() {
        require(msg.sender == address(landlords), "ERROR : Not the lanlord!");
        _;
    }


    function initialize(
        address landlordsNft, 
        uint256[] memory ids, 
        uint256[] memory shares,
        address _teamwallet
        ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        landlordsID = ids;
        landlordShares = shares;
        teamWallet = _teamwallet;
        landlords = NFTContract(payable(landlordsNft));
        yETH = yVault(0xa258C4606Ca8206D8aA700cE2143D7db854D168c);
        weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        genesisTokens = 10000;
    }


    /// @notice Collect the pending rent from collectors

    function collectPendingRent() external onlyLandlord nonReentrant {
        updateRentShares(); 
    }
    /// @notice Collect the pending OpenSea Royalties
    function collectPendingRoyalties() external onlyLandlord nonReentrant {
        updateRoyaltiesSahres();
    }

    /// @notice View Pending royalties
    function pendingRoyalties() public view returns (uint256 pending) {
        return address(royaltiesCollector).balance;
    }

    /// @notice View Pending rent to be staked
    function pendingRent() public view returns (uint256 pending) {
        return address(rentCollector).balance;
    }

    /// @notice Claim you rent for all your NFT

    function payTheLandlord() external onlyLandlord nonReentrant {
        updateRentShares();
        uint256 balance = landlords.balanceOf(msg.sender);
        uint256 id;
        uint256 i = 0;
        uint256 thisRent = 0;
        uint256 totalRent = 0;
        for (i == 0; i < balance; i++) {
            id = landlords.tokenOfOwnerByIndex(msg.sender, i);
            thisRent = (accRentPerNFT - rentPaid[id]);
            totalRent += thisRent;
            rentPaid[id] += thisRent;
        }
        uint256 amount = pullFromYearn(totalRent);
        rentBalance -= totalRent;
        payLandlord(msg.sender, amount);
        emit Collected(msg.sender, amount);
    }

    ///@notice to be called to claim your royalties
    function payTheRoyalties() external onlyLandlord nonReentrant {
        updateRoyaltiesSahres();
        uint256 balance = landlords.balanceOf(msg.sender);
        uint256 id;
        uint256 i = 0;
        uint256 thisRoyalties = 0;
        uint256 totalRoyalties = 0;
        for (i == 0; i < balance; i++) {
            id = landlords.tokenOfOwnerByIndex(msg.sender, i);
            if (id <= genesisTokens) {
                thisRoyalties = (accRoyaltiesPerNFT - royaltiesPaid[id]);
                totalRoyalties += thisRoyalties;
                royaltiesPaid[id] += thisRoyalties;
            }
        }
        uint256 amount = pullFromYearn(totalRoyalties);
        royaltiesBalance -= totalRoyalties;
        payLandlord(msg.sender, amount);

        emit Collected(msg.sender, amount);
    }



    ///@notice  pull the funds from holding contract and deposit them into yearn for yETH so we earn on the rent
    ///@return amount in yETH
    function pullFromCollector(address _collector)
        internal
        returns (uint256 amount)
    {
        uint256 amountToPull = (_collector).balance;
        ICollector(_collector).pullEther();

        uint256 percent = amountToPull / 100 ;
        uint256 amountToYearn;

        if(_collector == royaltiesCollector){
        
        amountToYearn = percent * 30 ;
        splitRoyalties(percent);

        }else{ 
         amountToYearn = percent * 75 ;
         payable(teamWallet).transfer(amountToPull - amountToYearn);

        }
      
        weth.deposit{value: amountToYearn}();
        
        weth.approve(address(yETH), amountToYearn);
     
        amount = yETH.deposit(amountToYearn);
        
        return amount;
    }

    function splitRoyalties(uint256 percent) internal {

        uint i = 0;
        uint len = landlordsID.length;
        for(i == 0; i < len; i++){
           uint amount = landlordShares[i] * percent;
           address member = landlords.ownerOf(landlordsID[i]);
           payable(member).transfer(amount);

        }

    }

    ///@notice  pull the funds from holding contract and deposit them into yearn for yETH so we earn on the rent
    ///@return yield in yETH
    function pullFromYearn(uint256 _amountToPull)
        internal
        returns (uint256 yield)
    {


        yETH.approve(address(yETH), _amountToPull);
        uint256 returned = yETH.withdraw(_amountToPull, address(this));
        weth.approve(address(weth), returned);
        weth.withdraw(returned);
        return returned;
    }

    ///@notice view function returns the expected rental/royalties incomes to be paid to the account in Ether (all NFTs)
    ///@return rent for an account

    function RentAccumulated() public view returns (uint256 rent) {
        uint256 balance = landlords.balanceOf(msg.sender);
        uint256 id;
        uint256 i = 0;
        rent = 0;
        for (i == 0; i < balance; i++) {
            id = landlords.tokenOfOwnerByIndex(msg.sender, i);
            rent += (accRentPerNFT - rentPaid[id]);
        }
        return (rent * currentRate()) / 1e18;
    }

    ///@notice view function returns the expected rental/royalties incomes to be paid to the account in Ether (all NFTs)
    ///@return royalties for an account

    function RoyaltiesAccumulated() public view returns (uint256 royalties) {
        uint256 balance = landlords.balanceOf(msg.sender);
        uint256 id;
        uint256 i = 0;
        royalties = 0;

        for (i == 0; i < balance; i++) {
            id = landlords.tokenOfOwnerByIndex(msg.sender, i);
            if (id <= genesisTokens) {
                royalties += (accRoyaltiesPerNFT - royaltiesPaid[id]);
            }else{

            }
        }
        return (royalties * currentRate()) / 1e18;
    }

    ///@notice Update rent shares

    function updateRentShares() internal {
        if (pendingRent() > 0) {
            uint256 amount = pullFromCollector(address(rentCollector));
            rentBalance += amount;
            accRentPerNFT += (amount / landlords.totalSupply());
        }
    }

    ///@notice Update ret shares

    function updateRoyaltiesSahres() internal {
        if (pendingRoyalties() > 0) {
            uint256 amount = pullFromCollector(address(royaltiesCollector));
            royaltiesBalance += amount;
            accRoyaltiesPerNFT += (amount / genesisTokens);
        }
    }

    /// @notice Return the currentRate from yearn

    function currentRate() internal view returns (uint256 rate) {
        rate = yETH.pricePerShare();
        return rate;
    }

    ///@notice return the full value of this vault

    function currentVaultValue() internal view returns (uint256) {
        return (yETH.balanceOf(address(this)) * currentRate()) / 1e18;
    }

    ///@notice pay the rent to the landlord
    function payLandlord(address _landlord, uint256 _amount) internal {

        (bool success, ) = payable(_landlord).call{value: _amount}("");
        require(success);
        
    }

    ///@notice set newly minted debt
    ///@dev Must be called on mint.

    function updateDebtOf(uint256 id) external onlyLandlordContract {
        updateRentShares();
        rentPaid[id] = accRentPerNFT;
    }

    function setRentCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid collector");
        rentCollector = _collector;
    }

    function setRoyaltiesCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid collector");
        royaltiesCollector = _collector;
    }

    /// @notice pause or unpause the contract

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    receive() external payable {
        // allow contract to receive ETH
    }

    function balanceShares() public onlyOwner {
        uint amount = yETH.balanceOf(address(this));
        royaltiesBalance += amount;
        accRoyaltiesPerNFT += (amount / genesisTokens);
    }
}

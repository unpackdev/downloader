// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AbstractERC1155Factory.sol";
import "./ReentrancyGuard.sol";

contract OmniPass is AbstractERC1155Factory, ReentrancyGuard {

    // ======== ERC1155 Token Id =========
    uint256 constant MINT_PASS_ID = 0;

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public constant  MAX_MINTS_PER_ADDRESS = 100;
    uint256 public maxSupply = 20000;

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;

    // ======== Sale Status =========    
    bool public saleIsActive = false;

    // ======== Redeem Contract =========
    address public redeemContract;
    bool public redeemContractSet;
    bool public redeemEnabled;

    // ======== Cost =========
    uint256 public constant TOKEN_PRICE_ETH = 0.1 ether;

    // ======== Fund Management =========
    // Omniya Wallet
    address public withdrawalAddress = 0x0FE7be1Ce87D153AdFBf1573E3Db77bbD9E0f549; 

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    } 

    // ======== Mint =========
    /// @notice Mint tokens
    /// @param amount Quantity of tokens to mint
    function mint(uint256 amount)  public payable nonReentrant {
        require(totalSupply(0) + amount <= maxSupply, "Exceeds max token supply!");
        require(saleIsActive, "Sale is not active!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        require(addressToMintCount[msg.sender] + amount <= MAX_MINTS_PER_ADDRESS, "Exceeds max mint per address!");

        transferFunds(amount);
        _mint(msg.sender, MINT_PASS_ID, amount, "");
        addressToMintCount[msg.sender] += amount;
    } 
    
    /// @notice Allows owner to mint team tokens
    /// @param to The address to send the minted tokens to
    /// @param amount The amount of tokens to mint
    function mintTeamTokens(address to, uint256 amount) public onlyOwner {        
        require(totalSupply(0) + amount <= maxSupply, "Exceeds max token supply!");
        
         _mint(to, MINT_PASS_ID, amount, "");
    }      

    // ======== Redeem Management =========
    /// @notice Allows mint pass owner to burn a mint pass. Can only be called from Redeem contract
    /// @param account The address redeeming the mint passes
    /// @param amount The amount of mint passes to burn
    function burnFromRedeem(address account, uint256 amount) external {
        require(redeemContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        require(redeemEnabled, "Burn from redeem disabled!");

        _burn(account, MINT_PASS_ID, amount);
    }  

    /// @notice Allows owner to set the redeem contract
    /// @param _redeemContract The address of the redeem contract
    function setRedeemContract(address _redeemContract) external onlyOwner {
        redeemContract = _redeemContract;  
        redeemContractSet = true;
    } 

    /// @notice Allows toggles the redeem feature
    function toggleRedeem() external onlyOwner {
        redeemEnabled = !redeemEnabled;
    }    

    // ======== Metadata =========
    function setURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }    

    // ======== State Management =========
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // ======== Token Supply Management=========
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    /// @notice Decrease max token supply
    /// @param newMaxTokenSupply maximum token supply
    function decreaseTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(maxSupply > newMaxTokenSupply, "Max token supply can only be decreased!");
        require(newMaxTokenSupply >= totalSupply(0), "Max token supply has to be greeather than or equal to total supply!");
        maxSupply = newMaxTokenSupply;
    }
 
    // ======== Withdraw =========
    /// @notice Transfers funds to withdrawal address
    /// @param qty Quantity of tokens to purchase
    function transferFunds(uint256 qty) private {
        if(msg.value == qty * TOKEN_PRICE_ETH) { 
            (bool success, ) = payable(withdrawalAddress).call{value: qty * TOKEN_PRICE_ETH}("");
            require(success, "Transfer failed!");
        } else {
          revert("Invalid payment!");
        }
    }
    
    /// @notice Sets a new withdrawal address
    /// @param newWithdrawalAddress New withdrawal address
    function setWithdrawalAddress(address newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = newWithdrawalAddress;
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool success);

    function transfer(address _to, uint _tokens) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external returns (uint256);
}

contract AncoraPublic is Ownable {
    bool public cancelPublicSaleBool = false;
    bool public PublicSaleActive = false;
    

    uint public tokenPrice = 0.00000368645 ether; //0.1 / ethprice
    uint public hardcap = 50 ether; // 50000 / eth price


    struct ListToVesting {
        address investor;
        uint256 percent;
    }

	ListToVesting[] public listInvetorVesting; 

    address public tokenAddress;
    
    uint64 constant private SCALING = 10 ** 18;
    uint128 public minDeposit = 0.1 ether;
    // uint128 public maxDeposit = 0.5 ether;
    // uint128 public maxDeposit;
    uint256 public tokensForClaiming;
    
    uint256 public totalEthDeposited;
    // uint256 public softcap = 60 ether; //100.000$ softcap
    
    IERC20 erc20Contract;

    mapping(address => uint256) public deposits;
    mapping(address => bool) public whitelist;
     mapping(address => bool) public whitelistF;

    event AddressAdded(address indexed account);
    event AddressRemoved(address indexed account);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Sender is not whitelisted.");
        _;
    }
    constructor() {
        address _tokenAddress =address(0x47e6d0DFA00637F35528ff28d371D6263f73B334);
        require(_tokenAddress != address(0), "Error: INVALID_TOKEN_ADDRESS");
        // minDeposit = 0.3 ether;
        // maxDeposit = 1000000000000000000;
        tokenAddress = _tokenAddress;
        erc20Contract = IERC20(tokenAddress);

    }

    event DepositTokens(
        address indexed _address,
        uint256 _tokensForClaiming
    );


    event CancelPublicSale(address indexed _address, uint256 _amount);

    event DepositETH(address indexed _address, uint256 _amount);

    event ClaimTokens(address indexed _address, uint256 _amount);

    event WithdrawETH(address indexed _address, uint256 _amount);

    /*
    * Used by the PublicSale to deposit the tokens for the PublicSale
    */
    function depositTokens(
        uint256 _tokensForClaiming
    ) public onlyOwner {
        // require(tokensForClaiming == 0, "Error: TOKENS_ALREADY_DEPOSITED"); 
        erc20Contract.transferFrom(_msgSender(), address(this), _tokensForClaiming);
        tokensForClaiming += _tokensForClaiming;

        emit DepositTokens(_msgSender(), tokensForClaiming);
    }

    /*
    * Used by the PublicSale creator to cancel the PublicSale
    */
    function cancelPublicSale() external onlyOwner {
        require(!cancelPublicSaleBool, "Error: FAILED_LAUNCH_CANCELLED");
        cancelPublicSaleBool = true;

        // owner withdrawing previously deposited tokens
        erc20Contract.transfer(owner(), erc20Contract.balanceOf(address(this)));

        emit CancelPublicSale(_msgSender(), tokensForClaiming );
    }

    function startPublicSale() external onlyOwner {
        PublicSaleActive = true;
    }

    function stopPublicSale() public onlyOwner {
        PublicSaleActive = false;
    }

    /*
    * Method where users participate in the PublicSale
    */
    function depositETH() external payable {
        // require(areDepositsActive(), "Error: DEPOSITS_NOT_ACTIVE");
        require(msg.value >= minDeposit, "Error: MIN_DEPOSIT_AMOUNT");
        // if(!whitelistF[msg.sender]){
        //     require(msg.value <= maxDeposit, "Error: MAX_DEPOSIT_AMOUNT");
        // }
        
        require(PublicSaleActive, "Error: Not Started Yet");
        // require(whitelist[msg.sender], "Error: Not in Whitelist");
        // require(!cancelPublicSaleBool, "Error: PublicSale_IS_CANCELLED");

        deposits[_msgSender()] += msg.value;
        totalEthDeposited += msg.value;

        (bool transferSuccess, ) = owner().call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");

        // get list user info dep
        ListToVesting memory investor1;
		investor1.investor = msg.sender;
		investor1.percent = msg.value;
        listInvetorVesting.push(investor1);

        emit DepositETH(_msgSender(), msg.value);
    }

    /*
    * After liquidity is added to Uniswap with this method users are able to claim their token share
    */
    function claimTokens() external returns (uint256) {
        // require(hasDepositsFinished(), "Error: CLAIMING_NOT_ACTIVE");
        // require(getCurrentTokenShare() > 0, "Error: INVALID_TOKEN_SHARE");
        require(!cancelPublicSaleBool, "Error: PublicSale_IS_CANCELLED");
        
        // if(totalEthDeposited >= softcap){
        //     uint256 userTokens = getCurrentTokenShare();
        //     deposits[_msgSender()] = 0;
        //     erc20Contract.transfer(_msgSender(), userTokens*4/10); // tge 40%

        //     emit ClaimTokens(_msgSender(), userTokens);

        //     return userTokens;
        // }
        // else{
        uint256 userTokens = ((deposits[_msgSender()] * SCALING )/ tokenPrice );
        deposits[_msgSender()] = 0;
        erc20Contract.transfer(_msgSender(), userTokens*4/10); //tge 40%

        emit ClaimTokens(_msgSender(), userTokens);

        return userTokens;
        // }
        
    }

    /*
    * If the PublicSale is cancelled users are able to withdraw their previously deposited ETH
    */
    function getFund() public onlyOwner payable {
        
        uint256 contractBalance = address(this).balance;
        
        (bool transferSuccess, ) = owner().call{value: contractBalance}("");
        require(transferSuccess, "Failed to Invest");

        emit WithdrawETH(owner(), contractBalance);

    }
     function changeMin(uint128 minprice) public onlyOwner {
        
        require(minprice <= 0.25 ether, "min >= 0.25 ether is wrong ");

        minDeposit = minprice;
    }

    /*
    * Returning the current token share for the current user
    */
    // function getCurrentTokenShare() public view returns (uint256) {
    //     if (deposits[_msgSender()] > 0) {
    //         return (((deposits[_msgSender()] * SCALING) / totalEthDeposited) * tokensForClaiming) / SCALING;
    //     } else {
    //         return 0;
    //     }
    // }
    function getRateToken() public view returns (uint256) {
        return (totalEthDeposited * SCALING) / tokensForClaiming /SCALING;
    }

    function getContractBalance() public view returns (uint256) {
        return totalEthDeposited;
    }

    function areDepositsActive() public view returns (bool) {
        return PublicSaleActive && tokensForClaiming != 0 ;
        
    }
    

    function hasDepositsFinished() public view returns (bool) {
        return !PublicSaleActive;
    }

	function getInvestorlist()public  view returns( ListToVesting[] memory ) {
		return listInvetorVesting;
	}
    
    function addInvestors(address[] memory investors, uint256[] memory amounts) public onlyOwner {
    require(investors.length == amounts.length, "Array length mismatch");
    
    for (uint256 i = 0; i < investors.length; i++) {
        ListToVesting memory item = ListToVesting({
            investor: investors[i],
            percent: amounts[i]
        });
        
        listInvetorVesting.push(item);
    }
 }
     function addAddress(address account) public onlyOwner{
        whitelist[account] = true;
        emit AddressAdded(account);
    }
    function addAddressF(address account) public onlyOwner{
        whitelistF[account] = true;
        emit AddressAdded(account);
    }

    function removeAddress(address account) public onlyOwner{
        whitelist[account] = false;
        emit AddressRemoved(account);
    }

    function userClaim() public view returns (uint256) {
        return ((deposits[_msgSender()] * SCALING )/ tokenPrice );
    }

    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }

    function addAddresses(address[] memory accounts) public onlyOwner{
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
            emit AddressAdded(accounts[i]);
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

contract LevenToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() initializer {}

    using SafeMathUpgradeable for uint256;
    // Max supply 1 Trillion token
    uint256 private _maxSupply;
    uint256 private _maxPreSaleBuyLimit;
    uint256 private _price;
    uint256 private _totalPreSalePool;
    uint256 private _soldPreSaleAmount;
    uint256 private _totalTeamPool;
    uint256 private _distributedTeamPoolAmount;
    uint256 private _totalAirDropPool;
    uint256 private _utilizedAirDropAmount;

    function initialize() external initializer {
        _maxSupply = 1000000000000 * 10**decimals();
        _maxPreSaleBuyLimit = 2 * 10**decimals();
        _price = 0;
        _totalPreSalePool = 50000000 * 10**decimals();
        _totalTeamPool = 50000000 * 10**decimals();
        _totalAirDropPool = 50000000 * 10**decimals();
        _soldPreSaleAmount = 0;
        _distributedTeamPoolAmount = 0;
        _utilizedAirDropAmount = 0;
        __ERC20_init("Leven Token", "LEVEN");
        __Ownable_init();
    }

    /**
     * @dev This function is use to accept ether in contract address.
     */
    receive() external payable {}

    /**
     * @dev Used to get maximum supply
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Used to get token price
     */
    function getPrice() public view returns (uint256) {
        return _price;
    }

    /**
     * @dev Used to get pre sale buy limit to buy token
     */
    function getMaxPreSaleBuyLimit() public view returns (uint256) {
        return _maxPreSaleBuyLimit;
    }

    /**
     * @dev Used to get pre sale pool amonut
     */
    function getPreSalePool() public view returns (uint256) {
        return _totalPreSalePool;
    }

    /**
     * @dev Used to get team pool amonut
     */
    function getTeamPool() public view returns (uint256) {
        return _totalTeamPool;
    }

    /**
     * @dev Used to get air drop pool amonut
     */
    function getAirDropPool() public view returns (uint256) {
        return _totalAirDropPool;
    }

    /**
     * @dev Used to get distributed team pool amonut
     */
    function getDistributedTeamAmount() public view returns (uint256) {
        return _distributedTeamPoolAmount;
    }

    /**
     * @dev Used to get sold presale amonut
     */
    function getSoldPreSaleAmount() public view returns (uint256) {
        return _soldPreSaleAmount;
    }

    /**
     * @dev Used to get available ether balance
     */
    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRequiredLockedBalance() public view returns (uint256) {
       uint256 requiredLockBalance = _totalPreSalePool
            .add(_totalAirDropPool)
            .add(_totalTeamPool);
        uint256 lockedPoolAmount = _soldPreSaleAmount
            .add(_utilizedAirDropAmount)
            .add(_distributedTeamPoolAmount);
        requiredLockBalance = requiredLockBalance.sub(lockedPoolAmount);
        return requiredLockBalance;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            balanceOf(address(this)) >= amount,
            "The contract has insufficient token balance to transfer"
        );
        require(balanceOf(address(this)) >= getRequiredLockedBalance().add(amount), "Locking amount exceeded");
        _transfer(address(this), recipient, amount);
        return true;
    }

    /**
     * @dev Remember that only owner can call whenever needs to mint more tokens and total supply should not greater than 10T.
     * @param tokenAddress token will minted to given wallet address
     * @param tokenAmount The token amount to be mint
     */
    function mintToken(address tokenAddress, uint256 tokenAmount)
        external
        virtual
        onlyOwner
    {
        require(
            _maxSupply >= (totalSupply() + tokenAmount),
            "Tokens cannot be minted more than the maximum supply"
        );
        _mint(tokenAddress, tokenAmount);
    }

    /**
     * @dev Used to withdraw the ETH from Contract.
     * @param receiverAddress wallet address where to transfer ETH hold by contract
     * @param ethAmount amount to be tranfer
     */
    function withdrawETH(address receiverAddress, uint256 ethAmount)
        external
        virtual
        onlyOwner
    {
        require(
            ethAmount <= address(this).balance,
            "Unable to transfer ether form contract to given address due to insufficient ether balance"
        );
        payable(receiverAddress).transfer(ethAmount);
    }

    /**
     * @dev Used to update token price
     * @param newPrice updated price
     */
    function updatePrice(uint256 newPrice) external virtual onlyOwner {
        require(newPrice > 0, "Invalid price amount");
        _price = newPrice;
    }

    /**
     * @dev Used to update max ether limit while buying
     * @param newLimit updated buy limit
     */
    function updateMaxPreSaleBuyLimit(uint256 newLimit)
        external
        virtual
        onlyOwner
    {
        require(newLimit > 0, "Invalid Ether Limit");
        _maxPreSaleBuyLimit = newLimit;
    }

    /**
     * @dev Used to buy presale token
     */
    function publicSale() external payable {
        require(_price > 0, "Invalid Price, It should not be zero");
        require(
            msg.value > 0,
            "Invalid Amount, It should not be less than or equal to zero"
        );
        require(
            _maxPreSaleBuyLimit > msg.value,
            "Unable to buy token due to maximum purchase limit reached"
        );

        uint256 calculatedLevenToken = msg.value.mul(10**decimals()).div(
            _price
        );

        require(
            (_totalPreSalePool >= (_soldPreSaleAmount + calculatedLevenToken)),
            "Pre-sale pool limit exceeded"
        );
        payable(address(this)).transfer(msg.value);
        _transfer(address(this), _msgSender(), calculatedLevenToken);
        _soldPreSaleAmount = _soldPreSaleAmount.add(calculatedLevenToken);
    }

    /**
     * @dev Used to allocate token to the dev team
     * @param receiverAddress address where to transfer the token
     * @param amount quantity of token
     */
    function distributeToTeam(address receiverAddress, uint256 amount)
        external
        virtual
        onlyOwner
    {
        require(
            _totalTeamPool >= (_distributedTeamPoolAmount + amount),
            "Team pool limit exceeded"
        );
        require(
            amount > 0,
            "Invalid Amount, It should not be less than or equal to zero"
        );
        _transfer(address(this), receiverAddress, amount);
        _distributedTeamPoolAmount = _distributedTeamPoolAmount + amount;
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        virtual
        onlyOwner
    {
        require(
            tokenAmount > 0,
            "Invalid Amount, It should not be less than or equal to zero"
        );
        IERC20Upgradeable(tokenAddress).transfer(owner(), tokenAmount);
    }
}

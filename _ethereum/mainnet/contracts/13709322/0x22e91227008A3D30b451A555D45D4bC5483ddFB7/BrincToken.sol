// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./ICurve.sol";

contract BrincToken is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyTaxRateChanged(uint256 oldRate, uint256 newRate);
    event SellTaxRateChanged(uint256 oldRate, uint256 newRate);
    event BuyTaxScaleChanged(uint256 oldScale, uint256 newScale);
    event SellTaxScaleChanged(uint256 oldScale, uint256 newScale);

    IERC20 private _reserveAsset;
    uint32 private _fixedReserveRatio;
    uint256 private _buyTaxRate;
    uint256 private _buyTaxScale;
    uint256 private _sellTaxRate;
    uint256 private _sellTaxScale;
    ICurve private _curveAddress;


    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param name             curve token name
     * @param symbol           curve token symbol
     * @param reserveAsset     reserve asset address
     * @param buyTaxRate       value between 1 & 100 for owner revenue on mint/buy
     * @param sellTaxRate      value between 1 & 100 for owner revenue on burn/sell
     * @param reserveRatio     reserve ratio, represented in ppm (2-2000000)
     * @param curveAddress     address of the curve formula instance
     */
    constructor (
        string memory name,
        string memory symbol,
        address reserveAsset,
        uint256 buyTaxRate,
        uint256 buyTaxScale,
        uint256 sellTaxRate,
        uint256 sellTaxScale,
        uint32 reserveRatio,
        address curveAddress
    ) public ERC20(name, symbol) {
        require(reserveAsset != address(0), "BrincToken:constructor:Reserve asset invalid");
        require(buyTaxRate > 0, "BrincToken:constructor:Buy tax rate cant be 0%");
        require(buyTaxRate <= 100, "BrincToken:constructor:Buy tax rate cant be more than 100%");
        require(sellTaxRate > 0, "BrincToken:constructor:Sell tax rate cant be 0%");
        require(sellTaxRate <= 100, "BrincToken:constructor:Sell tax rate cant be more than 100%");
        require(buyTaxScale >= 100, "Buy tax scale can't be < 100");
        require(buyTaxScale <= 100000, "Buy tax scale can't be > 100 000");
        require(sellTaxScale >= 100, "Sell tax scale can't be < 100");
        require(sellTaxScale <= 100000, "Buy tax scale can't be > 100 000");
        _fixedReserveRatio = reserveRatio;
        _buyTaxRate = buyTaxRate;
        _buyTaxScale = buyTaxScale;
        _sellTaxRate = sellTaxRate;
        _sellTaxScale = sellTaxScale;
        _reserveAsset = IERC20(reserveAsset);
        _curveAddress = ICurve(curveAddress);
    }

    /**
     * @dev address of the underlining reserve asset
     *
     * @return reserveAssetAddress
     */
    /// #if_succeeds {:msg "Returns reserveAssetAddress"}
        /// $result == address(_reserveAsset);
    function reserveAsset() public view returns (address) {
        return address(_reserveAsset);
    }

    /**
     * @dev curve forumla instance address
     *
     * @return curveAddress
     */
    /// #if_succeeds  {:msg "Returns curveAddress"}
        /// $result == address(_curveAddress);
    function curveAddress() public view returns (address) {
        return address(_curveAddress);
    }

    /**
     * @dev reserve ratio set for the curve formula
     *
     * @return reserveRatio
     */
    /// #if_succeeds  {:msg "Returns reserveRatio"}
        /// $result == _fixedReserveRatio;
    function reserveRatio() public view returns (uint32) {
        return _fixedReserveRatio;
    }

    // Tax
    /**
     * @dev tax rate specified to direct reserve assets to owner on mint/buy
     *
     * @return buyTaxRate
     */
    /// #if_succeeds  {:msg "Returns taxRate"}
        /// $result == _buyTaxRate;
    function buyTaxRate() public view returns (uint256) {
        return _buyTaxRate;
    }

    /**
     * @dev Buy Tax Scale.
     * If buyTaxScale = 100 and buyTaxRate = 1, buyTax will effectively be 1%
     * If buyTaxScale = 1000 and buyTaxRate = 1, buyTax will effectively be 0.1%
     *
     * @return buyTaxScale
     */
    /// #if_succeeds {:msg "Returns buyTaxScale"}
        /// $result == _buyTaxScale;
    function buyTaxScale() public view returns (uint256) {
        return _buyTaxScale;
    }

    /**
     * @dev tax rate specified to direct reserve assets to owner on burn/sell
     *
     * @return sellTaxRate
     */
    /// #if_succeeds {:msg "Returns sellTaxRate"}
        /// $result == _sellTaxRate;
    function sellTaxRate() public view returns (uint256) {
        return _sellTaxRate;
    }

    /**
     * @dev Sell Tax Scale.
     * If sellTaxScale = 100 and sellTaxRate = 1, sellTax will effectively be 1%
     * If sellTaxScale = 1000 and sellTaxRate = 1, sellTax will effectively be 0.1%
     *
     * @return sellTaxScale
     */
    /// #if_succeeds {:msg "Returns sellTaxScale"}
        /// $result == _sellTaxScale;
    function sellTaxScale() public view returns (uint256) {
        return _sellTaxScale;
    }

    // Curve
    /**
     * @dev calculates the cost to mint a specified amount of collateral tokens
     *
     * @param amount tokens to mint
     *
     * @return cost
     */
    /// #if_succeeds {:msg "Returns correct mintCost"}
        /// $result == fundCost(totalSupply(), _reserveAsset.balanceOf(address(this)), _fixedReserveRatio, amount);
    function mintCost(uint256 amount) public view returns(uint256) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        return fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
    }

    /**
     * @dev calculates the reward for burning specified amount of curve tokens
     *
     * @param amount tokens to burn
     *
     * @return reward
     */
    /// #if_succeeds  {:msg "Returns burnReward"}
        /// $result == liquidateReserveAmount(totalSupply(), _reserveAsset.balanceOf(address(this)), _fixedReserveRatio, amount);
    function burnReward(uint256 amount) public view returns(uint256) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        return liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
    }

    /**
     * @dev initialises the curve, the total supply needs to be more than zero for
     * the curve to be calculated
     *
     * @param _firstReserve          initial reserve token
     * @param _firstSupply           initial supply of curve tokens
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The owner to hold initial minted token"}
        /// this.balanceOf(msg.sender) == _firstSupply;
    /// #if_succeeds {:msg "The contract should have the correct intial reserve amount"}
        /// _reserveAsset.balanceOf(address(this)) == _firstReserve;
    function init(uint256 _firstReserve, uint256 _firstSupply) external onlyOwner {
        require(totalSupply() == 0, "BrincToken:init:already minted");
        require(_reserveAsset.balanceOf(address(this)) == 0, "BrincToken:init:non-zero reserve asset balance");
        require(_reserveAsset.transferFrom(_msgSender(), address(this), _firstReserve), "BrincToken:init:Reserve asset transfer failed");
        _mint(_msgSender(), _firstSupply);
	}

    /**
     * @dev sets the tax rate stored in the buyTaxRate variable
     *
     * @param _rate                    new tax rate in percentage (integer between 1 and 100)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The buyTaxRate was set properly"}
        /// _buyTaxRate == _rate;
    function setBuyTaxRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100 && _rate >= 0, "BrincToken:setTax:invalid tax rate (1:100)");
        uint256 oldRate = _buyTaxRate;
        _buyTaxRate = _rate;
        emit BuyTaxRateChanged(oldRate, _buyTaxRate);
    }

    /**
     * @dev sets the buy tax scale stored in the buyTaxScale variable
     *
     * @param _scale new tax scale (integer between 100 and 100000)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The buyTaxScale was set properly"}
        /// _buyTaxScale == _scale;
    function setBuyTaxScale(uint256 _scale) external onlyOwner {
        require(_scale <= 100000 && _scale >= 100, "invalid buy tax scale (100:100000)");
        uint256 oldScale = _buyTaxScale;
        _buyTaxScale = _scale;
        emit BuyTaxScaleChanged(oldScale, _buyTaxScale);
    }

    /**
     * @dev sets the tax rate stored in the sellTaxRate variable
     *
     * @param _rate                    new tax rate in percentage (integer between 1 and 100)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The correct _sellTaxRate has been set"}
        /// _sellTaxRate == _rate;
    function setSellTaxRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100 && _rate >= 0, "BrincToken:setTax:invalid tax rate (1:100)");
        uint256 oldRate = _sellTaxRate;
        _sellTaxRate = _rate;
        emit SellTaxRateChanged(oldRate, _sellTaxRate);
    }

    /**
     * @dev sets the sell tax scale stored in the sellTaxScale variable
     *
     * @param _scale new sell tax scale (integer between 100 and 100000)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The sellTaxScale was set properly"}
        /// _sellTaxScale == _scale;
    function setSellTaxScale(uint256 _scale) external onlyOwner {
        require(_scale <= 100000 && _scale >= 100, "invalid sell tax scale (100:100000)");
        uint256 oldScale = _sellTaxScale;
        _sellTaxScale = _scale;
        emit SellTaxScaleChanged(oldScale, _sellTaxScale);
    }

    // CURVE
    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of reserve tokens to get the target amount for
     *
     * @return target
     */
    /// #if_succeeds {:msg "The purchase amount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The purchase amount should be correct - case _reserveWeight = MAX_WEIGHT"}
        /// let postTax := _removeBuyTaxFromSpecificAmount(_amount) in
        /// _reserveWeight == 1000000 ==>  $result == _supply.mul(postTax) / _reserveBalance;

    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 postTax = _removeBuyTaxFromSpecificAmount(_amount);
        return _curveAddress.purchaseTargetAmount(
            _supply,
            _reserveBalance,
            _reserveWeight,
            postTax
        );
    }

     /**
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The sell amount should be correct - case _amount = 0"} 
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The sell amount should be correct - case _reserveWeight = MAX_WEIGHT"}
        /// _reserveWeight == 1000000 ==> $result == _removeSellTax(_reserveBalance.mul(_amount) / _supply);
    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 reserveValue = _curveAddress.saleTargetAmount(
            _supply,
            _reserveBalance,
            _reserveWeight,
            _amount
        );
        uint256 gross = _removeSellTax(reserveValue);
        return gross;
    }

     /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of requested pool tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          requested amount of pool tokens
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The fundCost amount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The fundCost amount should be correct - case _reserveRatio = MAX_WEIGHT"}
        /// _reserveRatio == 1000000 ==> $result == _addBuyTax(_curveAddress.fundCost(_supply, _reserveBalance, _reserveRatio, _amount));
    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 reserveTokenCost = _curveAddress.fundCost(
            _supply,
            _reserveBalance,
            _reserveRatio,
            _amount
        );
        uint256 net = _addBuyTax(reserveTokenCost);
        return net;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of pool tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio))
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of pool tokens to liquidate
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _amount = _supply"}
        /// _amount == _supply ==> $result == _removeSellTax(_reserveBalance);
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _reserveRatio = MAX_WEIGHT"}
        /// _reserveRatio == 1000000 ==> $result == _removeSellTax(_amount.mul(_reserveBalance) / _supply);
    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 liquidateValue = _curveAddress.liquidateReserveAmount(
            _supply,
            _reserveBalance,
            _reserveRatio,
            _amount
        );
        uint256 gross = _removeSellTax(liquidateValue);
        return gross;
    }


    /**
     * @dev allows for the minting of tokens
     * @param account the account to mint the tokens to
     * @param amount the uint256 amount of tokens to mint
     *
     * @notice see note on mintForSpecificReserveAmount - this function should be used when there is
     * a target amount of main tokens (the tokens native to this contract) to be minted
     */
    /// #if_succeeds {:msg "The caller's BrincToken balance should be increase correct"}
        /// this.balanceOf(account) == old(this.balanceOf(account) + amount);
    /// #if_succeeds {:msg "The reserve balance should increase correct"} 
        /// _reserveAsset.balanceOf(address(this)) >= old(_reserveAsset.balanceOf(address(this)));
        // this will check if greater or equal to the old balance
        // will be equal in the case there is a 0 balance transfer
    /// #if_succeeds {:msg "The tax should go to the owner"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenCost := old(fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxDeducted := old(_removeBuyTax(reserveTokenCost)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + reserveTokenCost.sub(taxDeducted));
    function mint(address account, uint256 amount) public returns (bool) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenCost = fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount);

        uint256 taxDeducted = _removeBuyTax(reserveTokenCost);
        require(
            _reserveAsset.transferFrom(
                _msgSender(),
                address(this),
                reserveTokenCost
            ),
            "BrincToken:mint:Reserve asset transfer for mint failed"
        );
        require(
            _reserveAsset.transfer(
                owner(),
                reserveTokenCost.sub(taxDeducted)
            ),
            "BrincToken:mint:Tax transfer failed"
        );
        _mint(account, amount);
        return true;
    }

    /**
     * @dev allows for the minting of tokens based on a target amount of reserve asset
     * @param account the account to mint the tokens to
     * @param amount the uint256 amount of reserve tokens to spend minting
     *
     * @notice the difference between this function and the default mint function is if the
     * amount of main token desired is specified (this is the case in the default mint function)
     * or if a specific amount of reserve token is being spent - this function would be used if the
     * the user has a specific amount of reserve asset (eg Dai) that they wish to spend
     */
    /// #if_succeeds {:msg "The caller's BrincToken balance should be increase correct"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let tokensToMint := old(purchaseTargetAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// msg.sender != owner() ==> this.balanceOf(account) == old(this.balanceOf(account) + tokensToMint);
    /// #if_succeeds {:msg "The reserve balance should increase by exact amount"}
        /// let taxDeducted := old(_removeBuyTaxFromSpecificAmount(amount)) in   
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) + amount - amount.sub(taxDeducted));
    /// #if_succeeds {:msg "The tax should go to the owner"}
        /// let taxDeducted := old(_removeBuyTaxFromSpecificAmount(amount)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner())) + amount.sub(taxDeducted);
    /// #if_succeeds {:msg "The result should be true"} $result == true;
    function mintForSpecificReserveAmount(address account, uint256 amount) public returns (bool) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));

        uint256 taxDeducted = _removeBuyTaxFromSpecificAmount(amount);
        uint256 tokensToMint = purchaseTargetAmount(
            totalSupply(), 
            reserveBalance, 
            _fixedReserveRatio, 
            amount
        );

        require(
            _reserveAsset.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "BrincToken:mint:Reserve asset transfer for mint failed"
        );
        require(
            _reserveAsset.transfer(
                owner(),
                amount.sub(taxDeducted)
            ),
            "BrincToken:mint:Tax transfer failed"
        );
        _mint(account, tokensToMint);
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     * @param amount the uint256 amount of tokens to burn
     *
     * See {ERC20-_burn}.
     */

    /// #if_succeeds {:msg "The overridden burn should decrease caller's BrincToken balance"}
        /// this.balanceOf(_msgSender()) == old(this.balanceOf(_msgSender()) - amount);
    /// #if_succeeds {:msg "burn should add burn tax to the owner's balance"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burn should decrease BrincToken reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) - reserveTokenNet - taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burn should increase user's reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// msg.sender != owner() ==> _reserveAsset.balanceOf(_msgSender()) == old(_reserveAsset.balanceOf(_msgSender()) + reserveTokenNet);
    function burn(uint256 amount) public override {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenNet = liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
        _burn(_msgSender(), amount);

        uint256 taxAdded = _addSellTax(reserveTokenNet);
        require(_reserveAsset.transfer(owner(), taxAdded.sub(reserveTokenNet)), "BrincToken:burn:Tax transfer failed");
        require(_reserveAsset.transfer(_msgSender(), reserveTokenNet), "BrincToken:burn:Reserve asset transfer failed");
    }

    /**
     * @dev Allows an approved delgate to destroy tokens from another address
     * @param account the address to burn tokens from
     * @param amount the uint256 amount of tokens to approve
     */
    /// #if_succeeds {:msg "The overridden burnFrom should decrease caller's BrincToken balance"} 
        /// this.balanceOf(account) == old(this.balanceOf(account) - amount);
    /// #if_succeeds {:msg "burnFrom should add burn tax to the owner's balance"} 
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burnFrom should decrease BrincToken reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) - reserveTokenNet - taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burnFrom should increase user's reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(_msgSender()) == old(_reserveAsset.balanceOf(_msgSender()) + reserveTokenNet);
    function burnFrom(address account, uint256 amount) public override {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenNet = liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
        super.burnFrom(account, amount);

        uint256 taxAdded = _addSellTax(reserveTokenNet);
        require(_reserveAsset.transfer(owner(), taxAdded.sub(reserveTokenNet)), "BrincToken:burnFrom:Tax transfer failed");
        require(_reserveAsset.transfer(account, reserveTokenNet), "BrincToken:burnFrom:Reserve asset transfer failed");
    }

    // ERC20Pausable
    /**
     * @dev Pauses the contract's transfer, mint & burn functions
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function pause() public onlyOwner() {
        _pause();
    }
    /**
     * @dev Unpauses the contract's transfer, mint & burn functions
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function unpause() public onlyOwner() {
        _unpause();
    }

    // ERC20Snapshot
    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function snapshot() public onlyOwner() {
        _snapshot();
    }

    // Tax
    /**
     * @dev adds the buy tax to the cost of minting/buying tokens
     * @notice this function should be used when the user has not speicified a specific amount of
     * reserve tokens they are interested in spending, but rather a specific amount of collateralized
     * tokens they are interested in purchasing
     * @param reserveTokenAmount the initial amount that needs the taxed amount applied to it
     *
     * @return the post-tax cost to the user for minting
     */
    /// #if_succeeds {:msg "The correct tax is added to buy"}
        /// $result == reserveTokenAmount.mul(_buyTaxRate.add(_buyTaxScale)).div(_buyTaxScale);
    function _addBuyTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_buyTaxRate.add(_buyTaxScale)).div(_buyTaxScale);
    }

    /**
     * @dev reapplies the sell tax to the amount of reserves returned on burn/sell
     * @param reserveTokenAmount the initial amount that needs the taxed amount reapplied to it
     *
     * @return the pretax returns from selling
     */
    /// #if_succeeds {:msg "The correct tax is added to sell"}
        /// $result == reserveTokenAmount.mul(_sellTaxRate.add(_sellTaxScale)).div(_sellTaxScale);
    function _addSellTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_sellTaxRate.add(_sellTaxScale)).div(_sellTaxScale);
        // return (reserveTokenAmount.mul(_sellTaxScale)).div(_sellTaxScale.sub(_sellTaxRate));
    }

    /**
     * @dev removes the buy tax from the user-determined reserve token amount
     * @notice this function should be used when the user has speicified a specific amount of
     * reserve tokens they are interested in purchasing collateral tokens with, as opposed to 
     * a specific amount of collateralized
     * @param reserveTokenAmount the initial amount that needs the taxed amount removed from it
     *
     * @return the pretax cost of the collateral tokens
     */
    /// #if_succeeds {:msg "The correct tax removed from specific amount"}
        /// $result == reserveTokenAmount.mul(_buyTaxScale.sub(_buyTaxRate)).div(_buyTaxScale);
    function _removeBuyTaxFromSpecificAmount(uint256 reserveTokenAmount) internal view returns(uint256) {
        // uint256 upscaledTax = 1e18 - (_buyTaxRate.mul(1e16));
        // uint256 upscaledPreTax = reserveTokenAmount.mul(upscaledTax);
        // return upscaledPreTax / 1e18;
        return reserveTokenAmount.mul(_buyTaxScale.sub(_buyTaxRate)).div(_buyTaxScale);
    }

    /**
     * @dev removes the buy tax from the price of minting/buying (yielding the pretax amount)
     * @param reserveTokenAmount the initial amount that needs the tax rate removed from
     *
     * @return the pretax cost of the collateral tokens
     */
    /// #if_succeeds {:msg "The correct tax amount should be added"}
        /// $result == reserveTokenAmount.mul(_buyTaxScale).div(_buyTaxRate.add(_buyTaxScale));
    function _removeBuyTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_buyTaxScale).div(_buyTaxRate.add(_buyTaxScale));
    }

    /**
     * @dev removes the sell tax from the pretax returns of burning/selling
     * @param reserveTokenAmount the initial amount that needs the tax rate removed from
     *
     * @return the post-tax returns to the user from burning
     */
    /// #if_succeeds {:msg "The correct tax amount should be subtracted"}
        /// $result == reserveTokenAmount.mul(_sellTaxScale).div(_sellTaxRate.add(_sellTaxScale));
    function _removeSellTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_sellTaxScale).div(_sellTaxRate.add(_sellTaxScale));
        // return reserveTokenAmount.mul(_sellTaxScale.sub(_sellTaxRate)).div(_sellTaxScale);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20,ERC20Snapshot,ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

//import "./Initializable.sol";
import "./ERC777Upgradeable.sol";

//import "./ERC777.sol";

//import "./SafeMath.sol";

interface CustomEvents {
    /**
     * @dev Event to be emitted when fees is updated
     * @param operator Caller - msg.sender (owner)
     * @param from previous fees
     * @param to new fees
     */
    event FeesUpdate(
        address indexed operator,
        uint256 from,
        uint256 to,
        bytes data
    );
}

contract BeagleCoin is ERC777Upgradeable, CustomEvents {
    /* Public variables of the token */
    //string private _name; //fancy name: eg Simon Bucks
    //uint8 private _decimals; //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    //string private _symbol; //An identifier: eg BEAGLE
    string public version; //Just an arbitrary versioning scheme.
    address private _owner;

    address private _poolAddr;

    uint256 private _feesPercent;

    //donation account - account where 2% of transaction token goes
    //gas account - 1% of trasaction token goes
    //burn account - 1 % of transaction token goes
    //lottery account - 1% of transaction token goes
    function initialize(address poolAddr) public initializer {
        _owner = tx.origin; //set the owner of the contract
        //_poolAddr = 0xaa51546B5286500a698CcEcC0D09605054c43B17;
        _poolAddr = poolAddr;

        //ERC20(owner, _poolAddr);

        string memory _name = "Beagle";
        string memory _symbol = "BEAGLE";
        version = "1.0";

        uint256 totalSupply = 10**10 * 10**uint256(decimals()); //10 billion tokens with 8 decimal places
        _feesPercent = 4;

        //balances[tx.origin] = _totalSupply;

        address[] memory defaultOperators;
        __ERC777_init(_name, _symbol, defaultOperators);

        mint(msg.sender, totalSupply);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function poolAddress() public view returns (address) {
        return _poolAddr;
    }

    function fees() public view onlyOwner returns (uint256) {
        return _feesPercent;
    }

    modifier onlyOwner {
        require(_msgSender() == owner(), "BEAGLE: Only allowed by the Owner");
        _;
    }

    modifier onlyPoolAccount(address account) {
        require(account == _poolAddr, "BEAGLE: Only Pool Address allowed");
        _;
    }

    /**
     * @dev [OnlyOwner - can call this]
     * Creates new token and sends them to account
     * @param account The address to send the minted tokens to
     * @param amount Amounts to tokens to generate
     */
    function mint(address account, uint256 amount) public onlyOwner {
        super._mint(account, amount, "", "");
    }

    /**
     * @dev [OnlyOwner - can call this] [onlyPoolAccount - burn address can only be poolAddr]
     * PoolBurn - Burns token from callers account
     * @param amount Amounts to tokens to burn
     */
    function burnPool(uint256 amount, bytes memory data) public onlyOwner {
        super._burn(_poolAddr, amount, data, "");
    }

    /**
     * @dev Transfer ownership of the contract to another account.
     * Not this will not tranfer the contract ownership, but the logical ownership to perform miniting and burning.
     * @param newOwner The address to assign the new Ownership to
     */
    function tranferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Change the Migration Pool to another address.
     * @param newPool The address to transfer the pool fees from hereonforth.
     */
    function feesPoolMigrate(address newPool) public onlyOwner {
        _poolAddr = newPool;
    }

    /**
     * @dev Update the fees percentage.
     * @param newPercentage The new pool fees percentage.
     */
    function feesUpdate(uint256 newPercentage) public onlyOwner {
        emit FeesUpdate(_msgSender(), _feesPercent, newPercentage, "FeesUpdate");

        _feesPercent = newPercentage;
    }

    // removed custom burn, everyone is allowed to burn their assets
    /**
     * dev [OnlyOwner - can call this]
     * Reservoir Burn - Burns token from owner's account
     * param amount Amounts to tokens to burn
     * param data Data for registered hook
     */
    /* function burn(uint256 amount, bytes memory data) public override onlyOwner {
        super.burn(amount, data);
    } */

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return super.transfer(recipient, _tranferFees(amount));
    }

    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return super.transferFrom(holder, recipient, _tranferFees(amount));
    }

    /**
     * @dev Transfers the fees calculated by fn:_calculateFeesAmount.
     * Returns the remaining amount (amount - feesAmount)
     * @param amount The transaction/transfer token amount
     * @return (amount - feesAmount)
     */
    function _tranferFees(uint256 amount) internal returns (uint256) {
        uint256 feesAmount = _calculateFeesAmount(amount);

        if (feesAmount > 0) {
            //_burn(msg.sender, feesAmount);
            //if (from == address(0)) from = msg.sender;

            super.transfer(_poolAddr, feesAmount);
            //amount = amount.sub(feesAmount);
        }

        return amount - feesAmount;
    }

    /**
     * @dev Calculates fees for the transaction amount.
     * Reservoir(owner) and Pool accounts are exempted from fees.
     * @param amount The transaction/transfer token amount
     */
    function _calculateFeesAmount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 feesAmount = 0;

        //Reservoir and Pool accounts are excepted from Tranfer fees
        if (_msgSender() != owner() && _msgSender() != poolAddress()) {
            feesAmount = (amount / 100) * _feesPercent; //4 percent
        }

        return feesAmount;
    }
}

pragma solidity ^0.5.9;

contract Constant {
    string constant ERR_CONTRACT_SELF_ADDRESS = "ERR_CONTRACT_SELF_ADDRESS";

    string constant ERR_ZERO_ADDRESS = "ERR_ZERO_ADDRESS";

    string constant ERR_NOT_OWN_ADDRESS = "ERR_NOT_OWN_ADDRESS";

    string constant ERR_VALUE_IS_ZERO = "ERR_VALUE_IS_ZERO";

    string constant ERR_SAME_ADDRESS = "ERR_SAME_ADDRESS";

    string constant ERR_AUTHORIZED_ADDRESS_ONLY = "ERR_AUTHORIZED_ADDRESS_ONLY";

    modifier notOwnAddress(address _which) {
        require(msg.sender != _which, ERR_NOT_OWN_ADDRESS);
        _;
    }

    // validates an address is not zero
    modifier notZeroAddress(address _which) {
        require(_which != address(0), ERR_ZERO_ADDRESS);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThisAddress(address _which) {
        require(_which != address(this), ERR_CONTRACT_SELF_ADDRESS);
        _;
    }

    modifier notZeroValue(uint256 _value) {
        require(_value > 0, ERR_VALUE_IS_ZERO);
        _;
    }
}

contract Ownable is Constant {
    address public primaryOwner = address(0);

    address public authorityAddress = address(0);

    address public systemAddress = address(0);

    address public newAuthorityAddress = address(0);

    event OwnershipTransferred(
        string ownerType,
        address indexed previousOwner,
        address indexed newOwner
    );
    event AuthorityAddressChnageCall(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the `primaryOwner` and `systemAddress` and '_multisigAddress'
     * account.
     */
    constructor(address _systemAddress, address _authorityAddress)
        public
        notZeroAddress(_systemAddress)
    {
        require(msg.sender != _systemAddress, ERR_SAME_ADDRESS);

        require(_systemAddress != _authorityAddress, ERR_SAME_ADDRESS);

        require(msg.sender != _authorityAddress, ERR_SAME_ADDRESS);

        primaryOwner = msg.sender;

        systemAddress = _systemAddress;

        authorityAddress = _authorityAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == primaryOwner, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    modifier onlySystem() {
        require(msg.sender == systemAddress, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    modifier onlyOneOfOnwer() {
        require(
            msg.sender == primaryOwner || msg.sender == systemAddress,
            ERR_AUTHORIZED_ADDRESS_ONLY
        );
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == authorityAddress, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    /**
     * @dev change primary ownership
     * @param _which The address to which is new owner address
     */
    function changePrimaryOwner(address _which)
        public
        onlyAuthorized()
        notZeroAddress(_which)
        returns (bool)
    {
        require(
            _which != systemAddress &&
                _which != authorityAddress &&
                _which != primaryOwner,
            ERR_SAME_ADDRESS
        );

        emit OwnershipTransferred("PRIMARY_OWNER", primaryOwner, _which);

        primaryOwner = _which;

        return true;
    }

    /**
     * @dev change system address
     * @param _which The address to which is new system address
     */
    function changeSystemAddress(address _which)
        public
        onlyAuthorized()
        notThisAddress(_which)
        notZeroAddress(_which)
        returns (bool)
    {
        require(
            _which != systemAddress &&
                _which != authorityAddress &&
                _which != primaryOwner,
            ERR_SAME_ADDRESS
        );
        emit OwnershipTransferred("SYSTEM_ADDRESS", systemAddress, _which);
        systemAddress = _which;
        return true;
    }

    /**
     * @dev change system address
     * @param _which The address to which is new Authority address
     */
    function changeAuthorityAddress(address _which)
        public
        onlyAuthorized()
        notZeroAddress(_which)
        returns (bool)
    {
        require(
            _which != systemAddress &&
                _which != authorityAddress &&
                _which != primaryOwner,
            ERR_SAME_ADDRESS
        );
        newAuthorityAddress = _which;
        return true;
    }

    function acceptAuthorityAddress() public returns (bool) {
        require(msg.sender == newAuthorityAddress, ERR_AUTHORIZED_ADDRESS_ONLY);
        emit OwnershipTransferred(
            "AUTHORITY_ADDRESS",
            authorityAddress,
            newAuthorityAddress
        );
        authorityAddress = newAuthorityAddress;
        newAuthorityAddress = address(0);
        return true;
    }
}
interface IPrice {
    function getCurrencyPrice() external view returns (uint256);
}

contract CurrencyPrices is Ownable {
    mapping(address => address) public currencyContract;

    constructor(address _systemAddress, address _multisigAddress)
        public
        Ownable(_systemAddress, _multisigAddress)
    {}

    function setCurrencyPriceContract(address _currency, address _priceFeed)
        external
        onlySystem()
        returns (bool)
    {
        require(currencyContract[_currency] == address(0),"ERR_ADDRESS_IS_SET");
        currencyContract[_currency] = _priceFeed;
        return true;
    }

    function updateCurrencyPriceContract(address _currency, address _priceFeed)
        external
        onlyAuthorized()
        returns (bool)
    {
        currencyContract[_currency] = _priceFeed;
        return true;
    }

    function getCurrencyPrice(address _which) public view returns (uint256) {
        return IPrice(currencyContract[_which]).getCurrencyPrice();
    }
}
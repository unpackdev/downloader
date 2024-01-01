// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
   
   */

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PresaleOnly is Context {
    address public owner;
    uint256 public Adminfees = 0.01 ether;

    struct preSaleStruct {
        uint256 rate; // 1 eth
        uint256 startTime;
        uint256 endTime;
        uint256 hardCap;
        uint256 softCap;
        uint256 minContribution;
        uint256 maxContribution;
        address preSalecreator;
        bool Whitelist;
    }

    mapping(address => mapping(address => bool)) public whitelisted;

    mapping(address => mapping(address => uint256)) public contributions;

    mapping(address => preSaleStruct) public preSaleContractDetails;

    mapping(address => mapping(address => uint256)) public userBuyedToken; //amount of token revied by user

    // mapping(address => uint256) public contributions;         // amount of payment user has paid to buy token (in Eth)

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner can perform this operation"
        );
        _;
    }

    // Function to store the elements in the preSaleContractDetails mapping
    function storePreSaleDetails(
        address _contractAddress,
        uint256 _rate, //3000
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        bool _Whitelist
    ) public payable {
        require(msg.value >= Adminfees, "do not have balance");
        payable(owner).transfer(Adminfees);

        preSaleContractDetails[_contractAddress] = preSaleStruct({
            rate: _rate, // 1 eth =3000
            startTime: _startTime,
            endTime: _endTime,
            hardCap: _hardCap,
            softCap: _softCap,
            minContribution: _minContribution,
            maxContribution: _maxContribution,
            preSalecreator: msg.sender,
            Whitelist: _Whitelist
        });
    }

    //  Function to transfer tokens to presale addresses
    function addPresaleAddresses(
        address[] memory presaleAddresses,
        address _contractAddress
    ) public {
        require(
            msg.sender ==
                preSaleContractDetails[_contractAddress].preSalecreator,
            "uour are not xreator"
        );
        for (uint256 i = 0; i < presaleAddresses.length; i++) {
            address recipient = presaleAddresses[i];

            whitelisted[_contractAddress][recipient] = true;
        }
    }

    function buyTokens(
        uint256 tokensToBuy,
        address _contractAdress
    ) external payable {
        IERC20 token = IERC20(_contractAdress);

        require(
            block.timestamp >=
                preSaleContractDetails[_contractAdress].startTime &&
                block.timestamp <=
                preSaleContractDetails[_contractAdress].endTime,
            "Presale is not open"
        );
        require(
            contributions[_contractAdress][msg.sender] <=
                preSaleContractDetails[_contractAdress].maxContribution,
            "max rreach"
        );
        require(
            msg.value >=
                preSaleContractDetails[_contractAdress].minContribution,
            "can not contribute les than this"
        );

        uint256 valueInEth = (tokensToBuy /
            preSaleContractDetails[_contractAdress].rate) * 10 ** 18;


        address creator = preSaleContractDetails[_contractAdress]
            .preSalecreator;

        require(tokensToBuy > 0, "Ether amount must be greater than zero");
        require(msg.value >= valueInEth, "not enouh balance");

        if (preSaleContractDetails[_contractAdress].Whitelist == true) {

            require(
                whitelisted[_contractAdress][msg.sender] == true,
                "you are not allowed"
            );
            require(
                token.transferFrom(creator, msg.sender, tokensToBuy),
                "Token transfer failed"
            );
        } else if (preSaleContractDetails[_contractAdress].Whitelist == false) {
            require(
                token.transferFrom(creator, msg.sender, tokensToBuy),
                "Token transfer failed"
            );
        }


        userBuyedToken[_contractAdress][msg.sender] += tokensToBuy;

        contributions[_contractAdress][msg.sender] += valueInEth;

        payable(creator).transfer(valueInEth);

        emit TokensPurchased(msg.sender, tokensToBuy, valueInEth);
    }

    function withdrawFunds() external onlyOwner {
        address payable ownerPayable = payable(owner);
        ownerPayable.transfer(address(this).balance);
    }

    function withdrawUnsoldTokens(address _contractAddess) external onlyOwner {
        IERC20 token = IERC20(_contractAddess);
        require(
            token.transfer(owner, token.balanceOf(address(this))),
            "Token transfer failed"
        );
    }

    function setOwner (address _newFeecollector) public onlyOwner {
        owner =_newFeecollector;
    }

    function setAdminFee (uint256 _newfee) public onlyOwner{
        Adminfees= _newfee;
    }
}
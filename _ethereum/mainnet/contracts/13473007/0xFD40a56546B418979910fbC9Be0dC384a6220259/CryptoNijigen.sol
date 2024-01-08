// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IChildToken.sol";

contract CryptoNijigen is IChildToken, Initializable, OwnableUpgradeable, ERC20Upgradeable {
    using AddressUpgradeable for address;

    mapping(address => bool) adminMap;
    uint256 _ratio;

    modifier onlyAdmin() {
        require(adminMap[msg.sender], 'access deny');
        _;
    }

    event mintSuccess(address to, uint256 amount);
    event mintBatchSuccess(address[] accounts, uint256[] amounts);
    event burnSuccess(address to, uint256 amount);
    event burnBatchSuccess(address[] accounts, uint256[] amounts);
    event PaymentReleased(address to, uint256 amount);

    address transferFromWhiteAddress;

    function setTransferFromWhiteAddress(address whiteAddress) public onlyOwner {
        transferFromWhiteAddress = whiteAddress;
    }

    function initialize() initializer public {
        __ERC20_init("Crypto Nijigen", "NGN");
        __Ownable_init();
        _ratio = 80000;
    }

    function decimals()
    public
    view
    virtual
    override
    returns (uint8)
    {
        return 0;
    }

    function mint(address to, uint256 amount) external {
        require(adminMap[msg.sender], 'access deny');
        _mint(to, amount);
        emit mintSuccess(to, amount);
    }

    function mintBatch(address[] memory accounts, uint256[] memory amounts) public onlyAdmin {
        require(accounts.length == amounts.length, "mintBatch failed: accounts and amounts length mismatch");
        for (uint256 i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            uint256 amount = amounts[i];
            _mint(account, amount);
        }
        emit mintBatchSuccess(accounts, amounts);
    }

    function burnBatch(address[] memory accounts, uint256[] memory amounts) public onlyAdmin {
        require(accounts.length == amounts.length, "mintBatch failed: accounts and amounts length mismatch");
        for (uint256 i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            uint256 amount = amounts[i];
            _burn(account, amount);
        }
        emit burnBatchSuccess(accounts, amounts);
    }

    function burn(address to, uint256 amount) public onlyAdmin {
        _burn(to, amount);
        emit burnSuccess(to, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (msg.sender == transferFromWhiteAddress) {
            _transfer(sender, recipient, amount);
            return true;
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function addAdmin(address admin) public onlyOwner {
        adminMap[admin] = true;
    }

    function delAdmin(address admin) public onlyOwner {
        adminMap[admin] = false;
    }

    function deposit(address user, bytes calldata depositData)
    external
    override
    {
        require(adminMap[msg.sender], 'access deny');
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        require(adminMap[msg.sender], 'access deny');
        _burn(msg.sender, amount);
        emit burnSuccess(msg.sender, amount);
    }

    function safeMintNGN(address to, uint256 amount) external payable{
        require(msg.value * _ratio == amount * (10 ** 18) , 'CNGE002');
        _mint(to, amount);
        emit mintSuccess(to, amount);
    }

    function setRatio(uint256 ratio) external {
        _ratio = ratio;
    }

    function getRatio() public view returns (uint256) {
        return _ratio;
    }

    function release(address payable account) public virtual onlyOwner{
        uint256 payment = address(this).balance;
        require(payment != 0, "CNGE005");
        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }
}
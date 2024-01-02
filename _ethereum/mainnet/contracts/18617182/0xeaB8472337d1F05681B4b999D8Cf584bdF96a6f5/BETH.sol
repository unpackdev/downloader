//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Rebase.sol";

contract BETH is ERC20Rebase {
    constructor() initializer {}

    function initialize(
        string memory _domainName,
        address _admin,
        address[] memory _minters,
        address _oracle,
        address _owner,
        address _ethReceiver,
        address _operator
    ) public initializer {
        __ERC20_init();
        bytes32 _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_domainName)),
                keccak256(bytes("1.0")),
                block.chainid,
                address(this)
            )
        );
        _setDomainSeparator(_DOMAIN_SEPARATOR);
        require(_admin != address(0), "can not set address 0 as admin");
        require(_oracle != address(0), "can not set address 0 as oracle");
        require(_owner != address(0), "can not set address 0 as owner");
        require(_ethReceiver != address(0), "can not set address 0 as ethReceiver");
        require(_operator != address(0), "can not set address 0 as operator");

        _setPaused(false);

        _setExchangeRate(1e18);

        _setAdmin(_admin);
        _setOracle(_oracle);
        _setOwner(_owner);
        _setEthReceiver(_ethReceiver);
        _setOperator(_operator);

        emit OwnershipTransferred(address(0), _owner);
        emit AdminUpdated(address(0), _admin);
        emit OracleUpdated(address(0), _oracle);
        emit EthReceiverUpdated(address(0), _ethReceiver);
        emit OperatorUpdated(address(0), _operator);
        emit ExchangeRateUpdated(_oracle, 1e18);

        for (uint256 i = 0; i < _minters.length; i++) {
            require(_minters[i] != address(0), "can not set address 0 as minter");
            _setMinter(_minters[i], true);
            emit MinterUpdated(_minters[i], true);
        }
    }

    function version() public pure returns (string memory _version) {
        return "1.0";
    }

    // user function
    function deposit(address referral) external payable {
        return _deposit(msg.sender, referral);
    }

    function _deposit(address user, address referral) internal whenNotPaused notBlacklisted(user) {
        require(msg.value > 0, "deposit amount should be greater than 0");

        _mint(user, msg.value);

        uint256 share = msg.value * PRECISION / exchangeRate();
        emit DepositEth(user, msg.value, share, referral);
    }

    // minter function
    function mint(uint256 _amount) external whenNotPaused notBlacklisted(msg.sender) onlyMinter returns (bool) {
        return _mint(msg.sender, _amount);
    }

    function burn(uint256 _amount) external whenNotPaused notBlacklisted(msg.sender) onlyMinter returns (bool) {
        return _burn(msg.sender, _amount);
    }
    // oracle function

    function updateExchangeRate(uint256 newExchangeRate) external whenNotPaused onlyOracle {
        require(newExchangeRate > 0, "exchange rate should be greater than 0");
        _setExchangeRate(newExchangeRate);
        emit ExchangeRateUpdated(msg.sender, newExchangeRate);
    }

    // operator function
    // gas = 5000, please refer to the doc
    function moveToStakingAddress(uint256 amount) external onlyOperator {
        address _ethReceiver = ethReceiver();
        require(_ethReceiver != address(0), "eth receiver is not set");
        require(amount > 0, "zero amount");
        require(address(this).balance >= amount, "insufficient balance");
        (bool success,) = _ethReceiver.call{value: amount, gas: 5000}("");
        require(success, "transfer failed");
        emit MovedToStakingAddress(_ethReceiver, amount);
    }

    function supplyEth() external payable onlyOperator {
        require(msg.value > 0, "zero ETH amount");

        emit SuppliedEth(msg.sender, msg.value);
    }

    receive() external payable {
        _deposit(msg.sender, address(0));
    }

    // admin function

    function blacklist(address _account) external onlyAdmin {
        require(_account != address(0), "cannot black address zero");
        require(_getBlacklist()[_account] == false, "StakedTokenV1: account is already blacklisted");
        _getBlacklist()[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) external onlyAdmin {
        require(_account != address(0), "cannot unblack address zero");
        require(_getBlacklist()[_account], "StakedTokenV1: account is not blacklisted");
        _getBlacklist()[_account] = false;
        emit UnBlacklisted(_account);
    }

    function unpause() external onlyAdmin {
        _setPaused(false);
        emit Unpause();
    }

    function pause() external onlyAdmin {
        _setPaused(true);
        emit Pause();
    }

    function updateEthReceiver(address newEthReceiver) external onlyAdmin {
        require(newEthReceiver != address(0), "StakedTokenV1: newEthReceiver is the zero address");

        address currentReceiver = ethReceiver();
        require(newEthReceiver != currentReceiver, "StakedTokenV1: newEthReceiver is already the ethReceiver");

        _setEthReceiver(newEthReceiver);
        emit EthReceiverUpdated(currentReceiver, newEthReceiver);
    }

    function updateOperator(address newOperator) external onlyAdmin {
        require(newOperator != address(0), "StakedTokenV1: newOperator is the zero address");

        address currentOperator = operator();
        require(newOperator != currentOperator, "StakedTokenV1: newOperator is already the operator");
        _setOperator(newOperator);
        emit OperatorUpdated(currentOperator, newOperator);
    }

    function updateOracle(address newOracle) external onlyAdmin {
        address currentOracle = oracle();
        require(newOracle != address(0), "StakedTokenV1: oracle is the zero address");
        require(newOracle != currentOracle, "StakedTokenV1: new oracle is the same as oracle");
        _setOracle(newOracle);
        emit OracleUpdated(currentOracle, newOracle);
    }

    function updateMinter(address minter, bool isActive) external onlyAdmin {
        require(minter != address(0), "StakedTokenV1: minter is the zero address");
        require(isActive != isMinter(minter), "StakedTokenV1: minter status doesn't change");
        _setMinter(minter, isActive);
        emit MinterUpdated(minter, isActive);
    }

    function rescueERC20(address tokenContract, address to, uint256 amount) external onlyAdmin {
        uint256 size;
        assembly {
            size := extcodesize(tokenContract)
        }
        require(size > 0, "token contract must be a contract");
        require(to != address(0), "can not rescue to address 0");
        require(amount > 0, "can not rescue 0 amount");
        (bool success, bytes memory res) =
            tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success && (res.length == 0 || abi.decode(res, (bool))), "transfer failed");
    }

    // owner function

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }

    function updateAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Ownable: new admin is the zero address");
        emit AdminUpdated(admin(), newAdmin);
        _setAdmin(newAdmin);
    }
}

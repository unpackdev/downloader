// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./MathUpgradeable.sol";

contract DGLDToken is
    ERC20Upgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADD_WHITELIST_ROLE =
        keccak256("ADD_WHITELIST_ROLE");
    bytes32 public constant REMOVE_WHITELIST_ROLE =
        keccak256("REMOVE_WHITELIST_ROLE");
    bytes32 public constant SET_CUSTODY_FEE_ROLE =
        keccak256("SET_CUSTODY_FEE_ROLE");
    bytes32 public constant SET_FEE_ADDRESS_ROLE =
        keccak256("SET_FEE_ADDRESS_ROLE");
    bytes32 public constant SET_TRANSFER_FEE_ROLE =
        keccak256("SET_TRANSFER_FEE_ROLE");
    bytes32 public constant SET_TC_ROLE =
        keccak256("SET_TC_ROLE");

    // Stores the custody fee percentage in Basis Point. 100% = 10000
    uint256 public custodyFee;
    // Stores the transfer fee percentage in Basis Point. 100% = 10000
    uint256 public transferFee;
    // Tracks the number of gold bar minted
    uint256 public barCount;
    // Stores the wallet address where the fees are collected
    address public feeAddress;
    // Indicates if the fee mechanism is activated at the smart contract level
    bool public feeActivated;
    // Stores a key value pair to track all whitelisted addresses
    mapping(address => bool) public isWhiteListed;
    // Maps a barId to the equivalent amout of tokens stored on 18 digits
    mapping(bytes32 => uint256) barIds;

    // Stores the terms and conditions url
    string public tcURL;

    // Stores the timestamp when a user received or sent tokens
    // This timestamp is used to calculate the time elapsed between the last token movement and today
    mapping(address => uint256) private userFeesStartPeriod;

    /// @notice Logs any custody fee modification
    /// @param oldValue the old custody fee value
    /// @param newValue the new custody fee value
    event CustodyFeeUpdated(uint256 oldValue, uint256 newValue);
    /// @notice Logs any transfer fee modification
    /// @param oldValue the old transfer fee value
    /// @param newValue the new transfer fee value
    event TransferFeeUpdated(uint256 oldValue, uint256 newValue);
    /// @notice Logs when a user is whitelisted
    /// @param user the whitelisted user address
    event WhiteListed(address user);
    /// @notice Logs when a user is removed from the whitelist
    /// @param user the un-whitelisted user address
    event RemovedFromWhiteList(address user);
    /// @notice Logs any fee address modification
    /// @param oldAddress the old fee address
    /// @param newAddress the new fee address
    event FeeAddressUpdated(address oldAddress, address newAddress);
    /// @notice Logs when a gold bar is minted and token created
    /// @param to the user receving tokens
    /// @param barId the collateralized gold bar id
    /// @param creationFeeAmount the creation fee amount.
    event Mint(
        address to,
        uint256 amount,
        string barId,
        uint256 creationFeeAmount,
        string partnerId,
        string custodian,
        string producerId,
        uint256 fineness,
        string certificateOfDeposit,
        string inventoryReport
    );
    /// @notice Logs when tokens are burnt to redeem a gold bar
    /// @param from the user burning tokens
    /// @param amount the amount of tokens burnt
    /// @param redemptionFeeAmount the redemption fee amount.
    event Burn(
        address from,
        uint256 amount,
        string barId,
        uint256 redemptionFeeAmount
    );
    /// @notice Logs any T&Cs url modification
    /// @param oldUrl the old url value
    /// @param newUrl the new url value
    event TCUrlUpdated(string oldUrl, string newUrl);

    function initialize(
        string memory name,
        string memory symbol,
        address _feeAddress,
        bool isFeeActivated,
				address[] memory users,
				bytes32[] memory userRoles
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();

        require(
            _feeAddress != address(0),
            "DGLD: fee address cannot be zero address"
        );
				require(users.length == userRoles.length, "DGLD: user array must have the same length as roles array");

        feeAddress = _feeAddress;
        feeActivated = isFeeActivated;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADD_WHITELIST_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(REMOVE_WHITELIST_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SET_CUSTODY_FEE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SET_FEE_ADDRESS_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SET_TRANSFER_FEE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SET_TC_ROLE, DEFAULT_ADMIN_ROLE);

				uint256 totalUser = users.length;
				for (uint256 i = 0; i < totalUser; i++) {
					_setupRole(userRoles[i], users[i]);
				}
    }

    /// @notice Set the custody fee percentage in basis point
    /// @dev only granted address can call this function. Emits CustodyFeeUpdated event
    /// @param value the percentage value (max 10%)
    function setCustodyFee(uint256 value)
        public
        onlyRole(SET_CUSTODY_FEE_ROLE)
    {
        require(feeActivated, "setCustodyFee: Fee mechanism is not activated");
        require(value <= 10000, "setCustodyFee: fee percentage too high");
        uint256 oldValue = custodyFee;
        custodyFee = value;
        emit CustodyFeeUpdated(oldValue, custodyFee);
    }

    /// @notice Adds a user to the whitelist
    /// @dev only granted address can call this function. Emits WhiteListed event
    /// @param user user address
    function addToWhiteList(address user) public onlyRole(ADD_WHITELIST_ROLE) {
        _applyCustodyFees(user, address(0));
        isWhiteListed[user] = true;
        emit WhiteListed(user);
    }

    /// @notice Removes a user from the whitelist
    /// @dev only granted address can call this function. Emits RemovedFromWhiteList event
    /// @param user user address
    function removeFromWhiteList(address user)
        public
        onlyRole(REMOVE_WHITELIST_ROLE)
    {
        userFeesStartPeriod[user] = block.timestamp;
        isWhiteListed[user] = false;
        emit RemovedFromWhiteList(user);
    }

    /// @notice Set the fee wallet address
    /// @dev only granted address address can call this function. Emits FeeAddressUpdated event
    /// @param value the fee wallet address
    function setFeeAddress(address value)
        public
        onlyRole(SET_FEE_ADDRESS_ROLE)
    {
        require(
            value != address(0),
            "DGLD: fee address connot be address zero"
        );
        address oldFeeAddress = feeAddress;
        feeAddress = value;
        emit FeeAddressUpdated(oldFeeAddress, feeAddress);
    }

    /// @notice Set the transfer fee percentage in basis point
    /// @dev only granted address address can call this function. Emits TransferFeeUpdated event
    /// @param value the percentage value (max 10%)
    function setTransferFee(uint256 value)
        public
        onlyRole(SET_TRANSFER_FEE_ROLE)
    {
        require(feeActivated, "setTransferFee: Fee mechanism is not activated");
        require(value <= 10000, "setTransferFee: fee percentage too high");
        uint256 oldValue = transferFee;
        transferFee = value;
        emit TransferFeeUpdated(oldValue, transferFee);
    }

    /// @notice Mint tokens based on the bar fine weight
    /// @dev only granted address address can call this function. Emits Mint and Transfer event
    /// @param to the minted tokens receipient
    /// @param amount the amount of minted tokens
    /// @param barId the gold bar id
    /// @param creationFee the creation fee amount in wei
    function mint(
        address to,
        uint256 amount,
        string memory barId,
        uint16 creationFee,
        string memory partnerId,
        string memory custodian,
        string memory producerId,
        uint256 fineness,
        string memory certificateOfDeposit,
        string memory inventoryReport
    ) public onlyRole(MINTER_ROLE) {
        require(
            barIds[sha256(abi.encodePacked(barId))] == 0,
            "Bar id already exists"
        );
				require(creationFee <= 10000, "mint: creation fee percentage too high");

        barIds[sha256(abi.encodePacked(barId))] = amount;
        barCount += 1;

        uint256 creationFeeAmount = amount > 0
            ? (amount * creationFee) / 10000
            : 0;

        _applyCustodyFees(address(0), to);
        _mint(to, amount);

        userFeesStartPeriod[to] = block.timestamp;
        emit Mint(
            to,
            amount,
            barId,
            creationFeeAmount,
            partnerId,
            custodian,
            producerId,
            fineness,
            certificateOfDeposit,
            inventoryReport
        );
        if (creationFee > 0) {
            _transfer(to, feeAddress, creationFeeAmount);
        }
    }

    /// @notice transfer tokens between two holders and apply custody fees if eligible.
    /// @dev overrides the ERC20 transfer function
    /// @param recipient the tokens receipient
    /// @param amount the amount of transfered tokens
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _applyCustodyFees(msg.sender, recipient);

        if (
            feeActivated &&
            transferFee > 0 &&
            !(isWhiteListed[msg.sender] || isWhiteListed[recipient])
        ) {
            uint256 transferFeeAmount = amount > 0
                ? (amount * transferFee) / 10000
                : 0;
            if (
                MathUpgradeable.min(balanceOf(msg.sender), transferFeeAmount) >
                0
            )
                super.transfer(
                    feeAddress,
                    MathUpgradeable.min(
                        balanceOf(msg.sender),
                        transferFeeAmount
                    )
                );
        }
        if (balanceOf(msg.sender) > 0)
            super.transfer(
                recipient,
                MathUpgradeable.min(balanceOf(msg.sender), amount)
            );
        return true;
    }

    /// Overrides the strandard transferFrom method and apply custody fees if eligible.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _applyCustodyFees(from, to);

        if (
            feeActivated &&
            transferFee > 0 &&
            !(isWhiteListed[from] || isWhiteListed[to])
        ) {
            uint256 transferFeeAmount = amount > 0
                ? (amount * transferFee) / 10000
                : 0;
            if (MathUpgradeable.min(balanceOf(from), transferFeeAmount) > 0)
                _transfer(
                    from,
                    feeAddress,
                    MathUpgradeable.min(balanceOf(from), transferFeeAmount)
                );
        }
        if (balanceOf(from) > 0)
            super.transferFrom(
                from,
                to,
                MathUpgradeable.min(balanceOf(from), amount)
            );
        return true;
    }

    /// @notice Returns a gold bar fine weight
    /// @param barId the bar id
    /// @return gold bar fine weight
    function getBarWeight(string memory barId) public view returns (uint256) {
        require(bytes(barId).length > 0);

        return barIds[sha256(abi.encodePacked(barId))];
    }

    /// @notice Checks if user's token can be burnt to redeem a gold bar
    /// @param from holder address
    /// @param barId gold bar id
    /// @param redemptionFee redemption fee amount in wei
    /// @return boolean
    function canBurn(
        address from,
        string memory barId,
        uint256 redemptionFee
    ) public view returns (bool) {
        return _canBurn(from, barId, redemptionFee);
    }

    // Internal method called by public canBurn function
    function _canBurn(
        address from,
        string memory barId,
        uint256 redemptionFee
    ) internal view returns (bool) {
        require(
            barIds[sha256(abi.encodePacked(barId))] > 0,
            "Bar id not found"
        );
				require(redemptionFee <= 10000, "canBurn: redemption fee percentage too high");

        uint256 custodyFeesAmount = _computeCustodyFees(from);
        uint256 barWeight = barIds[sha256(abi.encodePacked(barId))];
				uint256 redemptionFeeAmount = barWeight > 0
            ? (barWeight * redemptionFee) / 10000
            : 0;
        return balanceOf(from) >= barWeight + custodyFeesAmount + redemptionFeeAmount;
    }

    /// @notice Burn user's tokens
    /// @dev only multi signature address can call this function. Emits Burn and Transfer event
    /// @param from the holder address
    /// @param barId the gold bar id
    /// @param redemptionFee the redemption fee amount in wei
    function burn(
        address from,
        string memory barId,
        uint256 redemptionFee
    ) public onlyRole(BURNER_ROLE) {
        require(_canBurn(from, barId, redemptionFee),"Insufficient funds");

        uint256 burnAmount = barIds[sha256(abi.encodePacked(barId))];
        delete barIds[sha256(abi.encodePacked(barId))];
        barCount -= 1;
				uint256 redemptionFeeAmount = burnAmount > 0
            ? (burnAmount * redemptionFee) / 10000
            : 0;

        _applyCustodyFees(from, address(0));
        _burn(from, burnAmount);
        emit Burn(from, burnAmount, barId, redemptionFeeAmount);
        if (redemptionFeeAmount > 0) _transfer(from, feeAddress, redemptionFeeAmount);
    }

    /// @notice Set the T&C url
    /// @dev only granted address can call this function. Emits TCUrlUpdated event
    /// @param url the T&C url
    function setTcURL(string memory url) public onlyRole(SET_TC_ROLE) {
        string memory oldUrl = tcURL;
        tcURL = url;
        emit TCUrlUpdated(oldUrl, tcURL);
    }

    function _applyCustodyFees(address sender, address recipient) private {
        if (
            feeActivated &&
            custodyFee > 0 &&
            !(isWhiteListed[sender] || isWhiteListed[recipient]) &&
            recipient != feeAddress
        ) {
            uint256 senderCustodyFeeAmount = _computeCustodyFees(sender);
            uint256 recipientCustodyFeeAmount = _computeCustodyFees(recipient);

            userFeesStartPeriod[sender] = block.timestamp;
            userFeesStartPeriod[recipient] = block.timestamp;

            if (
                sender != address(0) &&
                MathUpgradeable.min(balanceOf(sender), senderCustodyFeeAmount) >
                0
            )
                _transfer(
                    sender,
                    feeAddress,
                    MathUpgradeable.min(
                        balanceOf(sender),
                        senderCustodyFeeAmount
                    )
                );
            if (
                recipient != address(0) &&
                MathUpgradeable.min(
                    balanceOf(recipient),
                    recipientCustodyFeeAmount
                ) >
                0
            ) _transfer(recipient, feeAddress, recipientCustodyFeeAmount);
        }
    }

    function _computeCustodyFees(address account)
        private
        view
        returns (uint256)
    {
        if (account == address(0)) return 0;
        uint256 accountPreviousBalance = balanceOf(account);
        uint256 accountTimeElapsed = block.timestamp -
            userFeesStartPeriod[account];

        uint256 accountCustodyFeeAmount = (((accountPreviousBalance *
            accountTimeElapsed) / 365 days) * custodyFee) / 10000;
        return accountCustodyFeeAmount;
    }
}

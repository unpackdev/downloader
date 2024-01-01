// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./IOpenEditionMint.sol";
import "./Blacklist.sol";

abstract contract OpenEditionMintBase is Pausable, AccessControl, ReentrancyGuard, Blacklist, IOpenEditionMint {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    ///@notice Price of mint per item
    uint256 public price;

    ///@notice Total count of minted editions
    uint256 public totalSupply;

    ///@notice Start time of mint
    uint256 public startTime;
    ///@notice Duration of auction
    uint256 public duration;

    ///@notice Max count of editions minted
    uint256 public maxMint;

    address public beneficiary;

    ///@notice Start of current pause
    uint256 private pauseStart;
    ///@notice Total duration of pauses
    uint256 private pastPauseDelay;

    ///@notice Total free mint
    uint256 public totalFreeMint;

    mapping(address => uint256) public whitelist;

    ///@notice Pass
    IERC721Enumerable public pass;

    error Dissatisfied();

    constructor(
        uint256 price_,
        address pauser_,
        uint256 startTime_,
        uint256 duration_,
        uint256 maxMint_,
        address beneficiary_
    ) {
        require(address(pauser_) != address(0), "Pauser address must not be the zero address");
        require(price_ > 0, "Price must be greater than zero");
        require(startTime_ > block.timestamp, "Start time must be greater than current time");
        require(duration_ > 5 minutes, "Duration must be greater than 5 minutes");
        require(beneficiary_ != address(0), "Beneficiary must not be the zero address");
        require(maxMint_ > 0, "Max mint must be greater than zero");

        price = price_;
        startTime = startTime_;
        duration = duration_;
        beneficiary = beneficiary_;
        maxMint = maxMint_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, pauser_);
    }

    modifier ongoing() {
        if (block.timestamp < startTime || block.timestamp >= startTime + duration) {
            revert MintClosed();
        }
        _;
    }

    function mintEdition(address to) internal virtual returns (uint256);

    /// @notice Mint edition
    function mintMultiple(uint256 quantity)
        external
        payable
        override
        whenNotPaused
        nonReentrant
        ongoing
        onlyNotBlacklisted
    {
        require(quantity > 0, "Must mint at least one pass");
        uint256 payment = msg.value;

        if (totalSupply >= maxMint || totalSupply + quantity > maxMint) {
            revert MaxMintReached();
        }

        if (payment != price * quantity) {
            revert WrongPayment();
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 id =  mintEdition(_msgSender());
            emit Purchase(_msgSender(), id);
        }

        unchecked {
            totalSupply += quantity;
        }
    }

    /**
     * free mint*
     */
    function setWhiteList(address[] memory users, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        assembly {
            let length := mload(users)
            let lengthAmount := mload(amounts)

            if eq(length, lengthAmount) {
                let usersPtr := add(users, 0x20)
                let amountsPtr := add(amounts, 0x20)

                let i := 0
                for {} lt(i, length) {} {
                    let user := mload(add(usersPtr, mul(i, 0x20)))
                    let amount := mload(add(amountsPtr, mul(i, 0x20)))

                    mstore(0, user)
                    mstore(32, whitelist.slot)
                    let hash := keccak256(0, 64)
                    sstore(hash, amount)

                    i := add(i, 1)
                }
            }
        }
    }

    function freeMint() external whenNotPaused nonReentrant ongoing {
        if (whitelist[msg.sender] == 0) {
            revert Dissatisfied();
        }

        //处理free mint
        for (uint256 i = 0; i < whitelist[msg.sender]; i++) {
            uint256 id = mintEdition(msg.sender);
            emit Purchase(_msgSender(), id);
        }

        unchecked {
            totalFreeMint += whitelist[msg.sender];
            totalSupply += whitelist[msg.sender];
        }
        //set 0
        whitelist[msg.sender] = 0;
    }



    function setPauser(address pauser_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(pauser_) != address(0), "Pauser address must not be the zero address");

        _grantRole(PAUSER_ROLE, pauser_);
    }

    function setPrice(uint256 price_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(price_ > 0, "Price must be greater than zero");
        price = price_;

        emit PriceUpdated(price);
    }

    function setTimeLimits(uint256 startTime_, uint256 duration_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startTime_ > block.timestamp, "Start time must be greater than current time");
        require(duration_ > 5 minutes, "Duration must be greater than 5 minutes");

        startTime = startTime_;
        duration = duration_;
    }

    function setBeneficiary(address beneficiary_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beneficiary_ != address(0), "Beneficiary must not be the zero address");

        beneficiary = beneficiary_;
    }

    function setMaxMint(uint256 maxMint_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(maxMint_ > 0, "Max mint must be greater than zero");
        maxMint = maxMint_;
    }

    /// @notice Pause this contract
    /// @dev Can only be called by the use with DEFAULT_ADMIN_ROLE or PAUSER_ROLE
    function pause() public onlyRole(PAUSER_ROLE) {
        super._pause();
        pauseStart = block.timestamp;
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`.
    function unpause() public onlyRole(PAUSER_ROLE) {
        super._unpause();

        if (block.timestamp <= startTime) {
            return;
        }

        // Find the amount time the auction should have been live, but was paused
        unchecked {
            // Unchecked arithmetic: computed value will be < block.timestamp and >= 0
            if (pauseStart < startTime) {
                pastPauseDelay = block.timestamp - startTime;
            } else {
                pastPauseDelay += (block.timestamp - pauseStart);
            }
            duration += pastPauseDelay;
        }
    }

    function addBlacklist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addBlacklist(account);
    }

    function removeBlacklist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeBlacklist(account);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balanceAvailable = address(this).balance;
        (bool success,) = beneficiary.call{value: balanceAvailable}("");
        require(success, "Transfer failed");
    }
}

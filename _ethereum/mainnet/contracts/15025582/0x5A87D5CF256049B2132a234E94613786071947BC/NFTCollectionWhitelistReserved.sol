// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./NFTCollection.sol";
import "./MerkleProof.sol";

abstract contract NFTCollectionWhitelistReserved is NFTCollection {
    uint256 public limitPerAccount;
    uint256 public reservedAmount;
    bytes32 public whitelistRoot;

    mapping(address => uint256) public whitelistMintBalance;

    error ReservedSupplyExceeded(uint256 reservedAmount);
    error NotInPublicSale();
    error AllowanceExceeded();
    error NotWhitelistedOrAllowanceIncorrect();

    error AccountLimitExceeded();

    modifier whenAccountLimitNotExceeded(uint256 _amount) {
        if (
            balanceOf(msg.sender) + _amount - whitelistMintBalance[msg.sender] >
            limitPerAccount
        ) {
            revert AccountLimitExceeded();
        }
        _;
    }

    constructor(
        uint256 _reservedAmount,
        bytes32 _whitelistRoot,
        uint256 _limitPerAccount
    ) {
        reservedAmount = _reservedAmount;
        whitelistRoot = _whitelistRoot;
        limitPerAccount = _limitPerAccount;
    }

    function _mintAmount(uint256 _amount)
        internal
        virtual
        override
        whenAccountLimitNotExceeded(_amount)
    {
        if (_amount == 0) {
            revert MinimumOneNFT();
        }
        if (_amount > maxMintAmount) {
            revert MaxMintAmountExceeded();
        }
        if (_totalMinted() + _amount + reservedAmount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _safeMint(msg.sender, _amount);
    }

    function mintPresale(
        uint256 _amount,
        uint256 _allowance,
        bytes32[] calldata _proof
    ) external payable {
        if (!isWhitelisted(msg.sender, _allowance, _proof)) {
            revert NotWhitelistedOrAllowanceIncorrect();
        }
        if (whitelistMintBalance[msg.sender] + _amount > _allowance) {
            revert AllowanceExceeded();
        }

        if (reservedAmount < _amount) {
            revert ReservedSupplyExceeded(reservedAmount);
        }
        reservedAmount -= _amount;
        whitelistMintBalance[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function isWhitelisted(
        address _user,
        uint256 _allowance,
        bytes32[] memory _proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                whitelistRoot,
                keccak256(abi.encodePacked(_user, _allowance))
            );
    }

    function whitelistClaimed(address _account) public view returns (uint256) {
        return whitelistMintBalance[_account];
    }

    // only owner
    function setReservedAmount(uint256 _reservedAmount) external onlyOwner {
        reservedAmount = _reservedAmount;
    }

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }

    function setLimitPerAccount(uint256 _limit) external onlyOwner {
        limitPerAccount = _limit;
    }
}
